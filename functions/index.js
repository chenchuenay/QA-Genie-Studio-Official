const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();
const db = admin.firestore();

// ============================================================
// CENTRALIZED CONSTANTS – CHANGE QUOTAS HERE ONLY
// ============================================================
const CORE_FREE_BATCHES_PER_DAY = 0; // Core: 0 free generations
const CORE_REWARDED_BATCHES_PER_DAY = 6; // Core: 6 rewarded ad generations
const PRO_FREE_BATCHES_PER_DAY = 15; // Pro: 15 free generations

const RETURNING_GUEST_BATCHES_PER_DAY = 1; // Returning guest on same device: 1

const CORE_CASES_PER_BATCH = 10;
const PRO_CASES_PER_BATCH = 20;

const EXPORT_LIMIT_PER_DAY = 50; // 50 exports per day for all non-pro users
const COOLDOWN_HOURS = 24; // 24h cooldown after Google account deletion

function today() {
  return new Date().toISOString().split("T")[0];
}

function getMsUntilReset() {
  const now = new Date();
  const reset = new Date();
  reset.setUTCHours(24, 0, 0, 0); // Assuming reset at midnight UTC
  return reset.getTime() - now.getTime();
}

function log(level, message, data = {}) {
  const timestamp = new Date().toISOString();
  console[level](`[${timestamp}] ${message}`, data);
}

// ------------------------------------------------------------------
// IN-MEMORY RATE LIMITER (per-instance, cleaned every 5 min)
// ------------------------------------------------------------------
const rateLimitStore = new Map();
const RATE_LIMIT_WINDOW_MS = 60000;

setInterval(() => {
  const cutoff = Date.now() - RATE_LIMIT_WINDOW_MS;
  for (const [key, entry] of rateLimitStore) {
    if (entry.windowStart < cutoff) rateLimitStore.delete(key);
  }
}, 300000);

function checkRateLimit(key, maxPerMinute = 20) {
  const now = Date.now();
  let entry = rateLimitStore.get(key);
  if (!entry || entry.windowStart < now - RATE_LIMIT_WINDOW_MS) {
    entry = { count: 0, windowStart: now };
  }
  entry.count++;
  rateLimitStore.set(key, entry);
  return entry.count <= maxPerMinute;
}

// ------------------------------------------------------------------
// IN-MEMORY FUNCTION RESULT CACHE (60s TTL, per-instance)
// ------------------------------------------------------------------
const functionCache = new Map();
const CACHE_TTL_MS = 60000;

setInterval(() => {
  const cutoff = Date.now() - CACHE_TTL_MS;
  for (const [key, entry] of functionCache) {
    if (entry.ts < cutoff) functionCache.delete(key);
  }
}, 120000);

async function getCachedOrFetch(cacheKey, ttl, fetchFn) {
  const cached = functionCache.get(cacheKey);
  if (cached && (Date.now() - cached.ts) < ttl) {
    return cached.data;
  }
  const data = await fetchFn();
  functionCache.set(cacheKey, { data, ts: Date.now() });
  return data;
}

// ------------------------------------------------------------------
// INPUT SANITISATION
// ------------------------------------------------------------------
function sanitisePrompt(prompt) {
  if (typeof prompt !== "string") return "";
  return prompt.replace(/<[^>]*>/g, "").replace(/[<>]/g, "").slice(0, 12000);
}

// ------------------------------------------------------------------
// HELPER: Get or create registry counter (total users+guests ever)
// ------------------------------------------------------------------
async function getNextRegistryNumber() {
  const globalRef = db.collection("analytics").doc("global");
  const result = await db.runTransaction(async (t) => {
    const doc = await t.get(globalRef);
    let counter = doc.data()?.registryCounter || 0;
    counter++;
    t.update(globalRef, { registryCounter: counter });
    return counter;
  });
  return result;
}

function getResetISO() {
  const now = new Date();
  const reset = new Date();
  reset.setUTCHours(24, 0, 0, 0);
  return reset.toISOString();
}

// ------------------------------------------------------------------
// GENERATION (uses central constants) — combined flow
// Accepts rewardToken (new) or adToken (legacy) for ad verification.
// AI call runs BEFORE transaction so ad is only consumed on success.
// Returns usage data so client can update cache without refetch.
// ------------------------------------------------------------------
exports.generate = functions
  .runWith({ secrets: ["DEEPSEEK_API_KEY"], timeoutSeconds: 120 })
  .https.onCall(async (data, context) => {
    if (!context.auth)
      return { success: false, error: { code: "UNAUTHENTICATED" } };
    const { module, feature, platform, prompt, deviceId, requestId, adToken, rewardToken } =
      data;
    if (!requestId)
      throw new functions.https.HttpsError(
        "invalid-argument",
        "requestId required",
      );
    if (typeof prompt !== "string" || prompt.length > 50000)
      throw new functions.https.HttpsError(
        "invalid-argument",
        "prompt too large or missing",
      );
    if (typeof module !== "string" || module.length > 200)
      throw new functions.https.HttpsError(
        "invalid-argument",
        "module too large or missing",
      );
    if (typeof feature !== "string" || feature.length > 200)
      throw new functions.https.HttpsError(
        "invalid-argument",
        "feature too large or missing",
      );
    if (!checkRateLimit(`generate_${context.auth.uid}`, 10)) {
      return { success: false, error: { code: "RATE_LIMITED" } };
    }
    const uid = context.auth.uid;
    const nowStr = today();
    const adPresent = !!(adToken || rewardToken);

    try {
      const uRef = db.collection("usage").doc(uid);
      const gRef = db.collection("analytics").doc("global");
      const reqRef = db.collection("processed_requests").doc(requestId);
      const userRef = db.collection("users").doc(uid);
      const guestRef = db.collection("guests").doc(uid);
      const deviceRef = db.collection("deviceUsage").doc(deviceId);

      // Dedup check BEFORE calling DeepSeek — prevents wasted API calls on retries
      const reqSnap = await reqRef.get();
      if (reqSnap.exists) {
        const cached = reqSnap.data()?.response;
        if (cached) return { success: true, data: cached };
        return { success: false, error: { code: "ALREADY_PROCESSED" } };
      }

      const sanitizedPrompt = sanitisePrompt(prompt);
      const aiResult = await callDeepSeek(sanitizedPrompt);
      if (!aiResult.success) throw new Error(aiResult.error.code);

      let text = aiResult.data.text.trim();
      if (text.startsWith("```")) {
        text = text.replace(/^```[a-z]*\n/i, "").replace(/\n```$/i, "");
      }
      const parsed = JSON.parse(text);
      let cases;
      if (Array.isArray(parsed)) {
        cases = parsed;
      } else if (parsed && typeof parsed === 'object' && Array.isArray(parsed.testCases)) {
        cases = parsed.testCases;
      } else if (parsed && typeof parsed === 'object' && Array.isArray(parsed.data)) {
        cases = parsed.data;
      } else {
        throw new Error('INVALID_AI_RESPONSE');
      }

      const generationData = await db.runTransaction(async (t) => {
        const [uDoc, reqDoc, userDoc, guestDoc, deviceDoc] =
          await Promise.all([
            t.get(uRef),
            t.get(reqRef),
            t.get(userRef),
            t.get(guestRef),
            t.get(deviceRef),
          ]);
        if (reqDoc.exists) throw new Error("ALREADY_PROCESSED");

        // Handle rewardToken (new flow): create + consume atomically
        if (rewardToken) {
          const tokenRef = db.collection("usage").doc(uid).collection("usedRewards").doc(rewardToken);
          const tokenSnap = await t.get(tokenRef);
          if (tokenSnap.exists) throw new Error("AD_TOKEN_USED");
          t.set(tokenRef, {
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            usedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        // Handle adToken (legacy flow): verify + consume atomically
        if (adToken) {
          const tokenRef = db.collection("usage").doc(uid).collection("usedRewards").doc(adToken);
          const tokenSnap = await t.get(tokenRef);
          if (!tokenSnap.exists) throw new Error("INVALID_AD_TOKEN");
          const tokenData = tokenSnap.data();
          if (tokenData.createdAt) {
            const created = tokenData.createdAt.toDate ? tokenData.createdAt.toDate() : new Date(tokenData.createdAt);
            if (Date.now() - created.getTime() > 10 * 60 * 1000) {
              throw new Error("AD_TOKEN_EXPIRED");
            }
          }
        }

        let isPro = false,
          isGuest = false;
        if (userDoc.exists)
          isPro = userDoc.data()?.subscription?.planType === "pro";
        else if (guestDoc.exists) {
          isGuest = true;
          if (deviceId && guestDoc.data()?.identity?.deviceId &&
              guestDoc.data().identity.deviceId !== deviceId) {
            throw new Error("DEVICE_ID_MISMATCH");
          }
        } else isGuest = true;

        // Quota check
        let rewardedCount = 0,
          proFreeCount = 0,
          lifetimeCases = 0;
        if (!isGuest) {
          let metrics = uDoc.exists ? uDoc.data().metrics : {};
          if (metrics.lastReset !== nowStr) {
            metrics.rewardedGenCount = 0;
            metrics.proFreeGenCount = 0;
            metrics.lastReset = nowStr;
          }
          rewardedCount = metrics.rewardedGenCount || 0;
          proFreeCount = metrics.proFreeGenCount || 0;
          lifetimeCases = metrics.lifetimeGeneratedCases || 0;
          if (isPro) {
            if (!(proFreeCount < PRO_FREE_BATCHES_PER_DAY))
              throw new Error(`LIMIT_REACHED|${getMsUntilReset()}`);
          } else {
            if (!(adPresent && rewardedCount < CORE_REWARDED_BATCHES_PER_DAY))
              throw new Error(`LIMIT_REACHED|${getMsUntilReset()}`);
          }
        } else {
          let devData = deviceDoc.exists
            ? deviceDoc.data()
            : { rewardedGenCount: 0, lastReset: nowStr, uid };
          if (devData.lastReset !== nowStr) devData.rewardedGenCount = 0;
          rewardedCount = devData.rewardedGenCount || 0;
          const guestTier = guestDoc.data()?.guestTier || "first";
          const guestMax = guestTier === "returning" ? RETURNING_GUEST_BATCHES_PER_DAY : CORE_REWARDED_BATCHES_PER_DAY;
          if (!adPresent) throw new Error("REWARDED_AD_REQUIRED");
          if (!(rewardedCount < guestMax))
            throw new Error(`LIMIT_REACHED|${getMsUntilReset()}`);
        }

        const caseCount = isPro ? PRO_CASES_PER_BATCH : CORE_CASES_PER_BATCH;

        // Consume ad token(s)
        if (rewardToken) {
          t.delete(db.collection("usage").doc(uid).collection("usedRewards").doc(rewardToken));
        }
        if (adToken) {
          t.delete(db.collection("usage").doc(uid).collection("usedRewards").doc(adToken));
        }

        // Increment counters
        if (!isGuest) {
          let metrics = uDoc.exists ? uDoc.data().metrics : {};
          if (isPro)
            metrics.proFreeGenCount = (metrics.proFreeGenCount || 0) + 1;
          else if (adPresent)
            metrics.rewardedGenCount = (metrics.rewardedGenCount || 0) + 1;
          metrics.lifetimeGeneratedCases =
            (metrics.lifetimeGeneratedCases || 0) + caseCount;
          metrics.lastReset = nowStr;
          t.set(uRef, { type: "user", metrics }, { merge: true });
        } else {
          let devData = deviceDoc.exists
            ? deviceDoc.data()
            : { rewardedGenCount: 0, lastReset: nowStr, uid };
          devData.rewardedGenCount = (devData.rewardedGenCount || 0) + 1;
          devData.lastReset = nowStr;
          devData.uid = uid;
          t.set(deviceRef, devData, { merge: true });
          let guestMetrics = uDoc.exists ? uDoc.data().metrics : {};
          lifetimeCases = guestMetrics.lifetimeGeneratedCases || 0;
          guestMetrics.lifetimeGeneratedCases = lifetimeCases + caseCount;
          guestMetrics.rewardedGenCount = devData.rewardedGenCount;
          guestMetrics.lastReset = nowStr;
          t.set(uRef, { type: "guest", metrics: guestMetrics }, { merge: true });
          lifetimeCases += caseCount;
        }

        const responseTestCases = transformTestCases(
          cases, module, feature, platform || "Web", caseCount,
        );
        const responseUsage = {
          rewardedGenCount: rewardedCount + 1,
          proFreeGenCount: proFreeCount + (isPro ? 1 : 0),
          lifetimeGeneratedCases: lifetimeCases,
          resetTimestamp: getResetISO(),
        };
        t.set(reqRef, {
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          response: { testCases: responseTestCases, usage: responseUsage },
        });
        t.update(gRef, {
          totalGenerations: admin.firestore.FieldValue.increment(1),
          totalTestCaseGenerated:
            admin.firestore.FieldValue.increment(caseCount),
          [isPro ? "proGeneratedCases" : "coreGeneratedCases"]:
            admin.firestore.FieldValue.increment(caseCount),
        });
        return {
          isPro,
          caseCount,
          rewardedGenCount: rewardedCount,
          proFreeGenCount: proFreeCount,
          lifetimeGeneratedCases: lifetimeCases,
          testCases: responseTestCases,
          usage: responseUsage,
        };
      });

      return {
        success: true,
        data: {
          testCases: generationData.testCases,
          usage: generationData.usage,
        },
      };
    } catch (err) {
      if (
        !["ALREADY_PROCESSED", "LIMIT_REACHED", "PRO_LIMIT_REACHED", "AD_TOKEN_USED", "INVALID_AD_TOKEN", "AD_TOKEN_EXPIRED", "REWARDED_AD_REQUIRED", "DEVICE_ID_MISMATCH"].includes(
          err.message,
        )
      ) {
        db.collection("analytics")
          .doc("global")
          .update({ totalAiFailures: admin.firestore.FieldValue.increment(1) })
          .catch(() => {});
      }
      return { success: false, error: { code: err.message } };
    }
  });

// ------------------------------------------------------------------
// EXPORT TRACKING (respects core daily export limit)
// ------------------------------------------------------------------
exports.trackExport = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  if (!checkRateLimit(`trackExport_${uid}`, 10)) {
    throw new functions.https.HttpsError("resource-exhausted", "Rate limited");
  }
  const { summary, target, extension, exportType } = data;
  const type = exportType || target || (summary ? "summary" : "unknown");
  const ext = extension || (target === "pdf" ? "pdf" : target);
  const nowStr = today();

  const userDoc = await db.collection("users").doc(uid).get();
  const isPro =
    userDoc.exists && userDoc.data()?.subscription?.planType === "pro";

  if (!isPro) {
    // Non-pro (core + guest): check daily export limit
    const usageDoc = await db.collection("usage").doc(uid).get();
    let metrics = usageDoc.exists ? usageDoc.data().metrics : {};
    if (metrics.lastReset !== nowStr) metrics.exportCount = 0;
    const exportCount = metrics.exportCount || 0;
    if (exportCount >= EXPORT_LIMIT_PER_DAY) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "Daily export limit reached",
      );
    }
  }

  const usageUpdate = {
    exports: {
      lifetimeExports: admin.firestore.FieldValue.increment(1),
      [`exportTargets.${type}`]: admin.firestore.FieldValue.increment(1),
      [`fileExtensions.${ext}`]: admin.firestore.FieldValue.increment(1),
    },
  };
  usageUpdate.type = userDoc.exists ? "user" : "guest";
  if (!isPro) {
    usageUpdate.metrics = {
      exportCount: admin.firestore.FieldValue.increment(1),
      lastReset: nowStr,
    };
  }
  await db.collection("usage").doc(uid).set(usageUpdate, { merge: true });

  const globalUpdate = {
    totalExports: admin.firestore.FieldValue.increment(1),
    [`exportTargets.${type}`]: admin.firestore.FieldValue.increment(1),
    [`fileExtensions.${ext}`]: admin.firestore.FieldValue.increment(1),
  };
  if (summary)
    globalUpdate.totalSummaryExports = admin.firestore.FieldValue.increment(1);
  await db.collection("analytics").doc("global").update(globalUpdate);
  return { success: true };
});

// ------------------------------------------------------------------
// RATING (unchanged)
// ------------------------------------------------------------------
exports.trackRating = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Auth required");
  if (!checkRateLimit(`rating_${context.auth.uid}`, 3)) {
    return { success: false, error: { code: "RATE_LIMITED" } };
  }
  const { rating } = data;
  await db
    .collection("analytics")
    .doc("global")
    .update({
      totalRatings: admin.firestore.FieldValue.increment(1),
      [`ratingBreakdown.${rating}`]: admin.firestore.FieldValue.increment(1),
    });
  return { success: true };
});

// ------------------------------------------------------------------
// COOLDOWN CHECK (called before Google sign-in to enforce 24h cooldown)
// ------------------------------------------------------------------
exports.checkEmailCooldown = functions.https.onCall(async (data, context) => {
  const { email } = data;
  if (!email) {
    throw new functions.https.HttpsError("invalid-argument", "email required");
  }
  const snap = await db.collection("emailCooldown").doc(email).get();
  if (snap.exists) {
    const expires = snap.data().expires?.toDate();
    if (expires && expires > new Date()) {
      throw new functions.https.HttpsError("permission-denied", "Account in cooldown");
    }
    // Expired — clean up
    await snap.ref.delete();
  }
  return { success: true };
});

// ------------------------------------------------------------------
// ANALYTICS & MONITORING
// ------------------------------------------------------------------
exports.trackAiFailure = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new Error("UNAUTHENTICATED");
  await db.collection("analytics").doc("global").update({
    totalAiFailures: admin.firestore.FieldValue.increment(1)
  }).catch(() => {});
  return { success: true };
});

exports.trackValidatorRejected = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new Error("UNAUTHENTICATED");
  const { rejectedCount } = data;
  if (!rejectedCount) return { success: true };
  await db.collection("analytics").doc("global").update({
    totalValidatorRejections: admin.firestore.FieldValue.increment(rejectedCount)
  }).catch(() => {});
  return { success: true };
});

// ------------------------------------------------------------------
// GET OR CREATE GUEST TOKEN (for "Continue as guest" button)
// ------------------------------------------------------------------
exports.getOrCreateGuestToken = functions.runWith({
  enforceAppCheck: false,
}).https.onCall(async (data) => {
  const { deviceId, forceReturning } = data;
  if (!deviceId)
    throw new functions.https.HttpsError(
      "invalid-argument",
      "deviceId required",
    );
  if (!checkRateLimit(`guestToken_${deviceId}`, 5)) {
    throw new functions.https.HttpsError("resource-exhausted", "Rate limited");
  }
  const mappingRef = db.collection("deviceGuestMapping").doc(deviceId);
  const mappingDoc = await mappingRef.get();
  let guestUid;
  let isNew = false;
  let guestTier = "first";
  if (mappingDoc.exists) {
    guestUid = mappingDoc.data().guestUid;
    const guestDoc = await db.collection("guests").doc(guestUid).get();
    if (!guestDoc.exists) {
      // Mapping exists but guest was consumed (upgraded to Google or deleted)
      isNew = true;
      guestTier = "returning";
    }
    // Else: same guest returning — restore them, keep their existing tier
  } else {
    isNew = true;
    guestTier = "first";
  }

  // After logout/delete, force a fresh returning guest with 1 quota
  if (forceReturning) {
    isNew = true;
    guestTier = "returning";
  }

  if (isNew) {
    guestUid = `guest_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const registryNumber = await getNextRegistryNumber();
    const displayName = `Guest${registryNumber}`;
    const batch = db.batch();
    batch.set(db.collection("guests").doc(guestUid), {
      identity: {
        uid: guestUid,
        displayName,
        type: "guest",
        deviceId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      guestTier,
    });
    batch.set(db.collection("usage").doc(guestUid), {
      type: "guest",
      metrics: { lifetimeGeneratedCases: 0 },
      exports: { lifetimeExports: 0 },
    });
    batch.set(db.collection("the_qag_registry").doc(guestUid), {
      uid: guestUid,
      type: "guest",
      displayName,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    batch.set(mappingRef, {
      guestUid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Reset device usage so the new returning guest gets a fresh 1 quota
    batch.set(db.collection("deviceUsage").doc(deviceId), {
      rewardedGenCount: 0,
      lastReset: today(),
      uid: guestUid,
    }, { merge: true });
    await batch.commit();
  }
  const customToken = await admin.auth().createCustomToken(guestUid);
  return { token: customToken, isNew, guestTier };
});

// ------------------------------------------------------------------
// CHECK EXPORT QUOTA
// ------------------------------------------------------------------
exports.checkExportQuota = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  const { rewarded = false } = data;
  const userDoc = await db.collection("users").doc(uid).get();
  const isPro = userDoc.exists && userDoc.data()?.subscription?.planType === "pro";
  const nowStr = today();
  let allowed = false, remaining = 0;

  if (isPro) {
    allowed = true;
    remaining = 999;
  } else {
    // Same 50/day limit for core users and guests
    const usageDoc = await db.collection("usage").doc(uid).get();
    let metrics = usageDoc.exists ? usageDoc.data().metrics : {};
    if (metrics.lastReset !== nowStr) metrics.exportCount = 0;
    const exportCount = metrics.exportCount || 0;
    allowed = exportCount < EXPORT_LIMIT_PER_DAY;
    remaining = EXPORT_LIMIT_PER_DAY - exportCount;
  }
  return { allowed, remaining };
});

// ------------------------------------------------------------------
// RESET DAILY LIMITS (debug only — used by dev menu)
// ------------------------------------------------------------------
exports.resetDailyLimits = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  const nowStr = today();
  await db.collection("usage").doc(uid).set({
    metrics: {
      rewardedGenCount: 0,
      proFreeGenCount: 0,
      exportCount: 0,
      lastReset: nowStr,
    },
  }, { merge: true });
  return { success: true };
});

// ------------------------------------------------------------------
// GET USER DASHBOARD
// ------------------------------------------------------------------
exports.getUserDashboard = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  const cacheKey = `dashboard_${uid}`;
  const cached = functionCache.get(cacheKey);
  if (cached && (Date.now() - cached.ts) < CACHE_TTL_MS) {
    return cached.data;
  }
  const idDoc = await db.collection("users").doc(uid).get();
  const isUser = idDoc.exists;
  const usageDoc = await db.collection("usage").doc(uid).get();
  let isGuest = false, guestDoc = null;
  if (!isUser) {
    guestDoc = await db.collection("guests").doc(uid).get();
    isGuest = guestDoc.exists;
  }
  const planType = isUser ? idDoc.data().subscription?.planType : null;
  function toISO(val) {
    if (!val) return null;
    if (typeof val.toDate === "function") return val.toDate().toISOString();
    if (val instanceof Date) return val.toISOString();
    return val;
  }
  const identity = isUser
    ? { displayName: idDoc.data()?.identity?.displayName, email: idDoc.data()?.identity?.email, createdAt: toISO(idDoc.data()?.identity?.createdAt) }
    : isGuest
      ? { ...guestDoc.data().identity, createdAt: toISO(guestDoc.data().identity?.createdAt) }
      : null;

  const nowStr = today();
  const metrics = usageDoc.exists ? usageDoc.data().metrics : {};
  const exports = usageDoc.exists ? usageDoc.data().exports : {};
  let rewardedGensRemaining = 0;
  let proGensRemaining = 0;
  const isPro = planType === "pro";

  if (isUser) {
    let rewarded = 0, proFree = 0;
    if (metrics.lastReset === nowStr) {
      rewarded = metrics.rewardedGenCount || 0;
      proFree = metrics.proFreeGenCount || 0;
    }
    rewardedGensRemaining = Math.max(0, CORE_REWARDED_BATCHES_PER_DAY - rewarded);
    proGensRemaining = Math.max(0, PRO_FREE_BATCHES_PER_DAY - proFree);
  } else if (isGuest) {
    let rewarded = 0;
    if (metrics.lastReset === nowStr) {
      rewarded = metrics.rewardedGenCount || 0;
    }
    const guestTier = guestDoc.data()?.guestTier || "first";
    const guestMax = guestTier === "returning" ? RETURNING_GUEST_BATCHES_PER_DAY : CORE_REWARDED_BATCHES_PER_DAY;
    rewardedGensRemaining = Math.max(0, guestMax - rewarded);
  }

  const result = {
    identity,
    isPro,
    metrics,
    exports,
    rewardedGensRemaining,
    proGensRemaining,
    guestTier: isGuest ? (guestDoc.data()?.guestTier || "first") : null,
    resetTimestamp: new Date(
      Date.UTC(
        new Date().getUTCFullYear(),
        new Date().getUTCMonth(),
        new Date().getUTCDate() + 1,
        0, 0, 0,
      ),
    ).toISOString(),
  };
  functionCache.set(cacheKey, { data: result, ts: Date.now() });
  return result;
});

// ------------------------------------------------------------------
// SET USER PRO
// ------------------------------------------------------------------
exports.setUserPro = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const { isPro } = data;
  const uid = context.auth.uid;
  await db
    .collection("users")
    .doc(uid)
    .set(
      {
        subscription: {
          planType: isPro ? "pro" : "core",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      },
      { merge: true },
    );
  return { success: true };
});

// ------------------------------------------------------------------
// TRACK PRO INTEREST
// ------------------------------------------------------------------
exports.trackProInterest = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  const { source } = data;
  const now = admin.firestore.FieldValue.serverTimestamp();
  const usageRef = db.collection("usage").doc(uid);
  const globalRef = db.collection("analytics").doc("global");
  await db.runTransaction(async (t) => {
    const uDoc = await t.get(usageRef);
    let interests = uDoc.data()?.interests || { proInterestCount: 0 };
    const isFirst = (interests.proInterestCount || 0) === 0;
    interests.proInterestCount = (interests.proInterestCount || 0) + 1;
    if (isFirst) interests.firstProInterestAt = now;
    interests.lastProInterestAt = now;
    if (!interests.proInterestSources) interests.proInterestSources = {};
    interests.proInterestSources[source] =
      (interests.proInterestSources[source] || 0) + 1;
    t.set(usageRef, { interests }, { merge: true });
    const globalUpdate = {
      totalProInterest: admin.firestore.FieldValue.increment(1),
      proTabClicks: admin.firestore.FieldValue.increment(
        source === "tab" ? 1 : 0,
      ),
    };
    if (isFirst)
      globalUpdate.uniqueProInterestedUsers =
        admin.firestore.FieldValue.increment(1);
    t.update(globalRef, globalUpdate);
  });
  return { success: true };
});

// ------------------------------------------------------------------
// HEALTH CHECK
// ------------------------------------------------------------------
exports.healthCheck = functions.https.onCall(async () => ({
  status: "ok",
  timestamp: new Date().toISOString(),
}));

// ------------------------------------------------------------------
// CHECK GENERATION QUOTA (client uses before showing ad)
// ------------------------------------------------------------------
exports.checkGenerationQuota = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  const { afterRewardedAd = false, deviceId } = data;
  const cacheKey = `quota_${uid}_${deviceId || ''}_${afterRewardedAd}`;
  const cached = functionCache.get(cacheKey);
  if (cached && (Date.now() - cached.ts) < CACHE_TTL_MS) {
    return cached.data;
  }
  const userDoc = await db.collection("users").doc(uid).get();
  const guestDoc = await db.collection("guests").doc(uid).get();
  const isUser = userDoc.exists;
  const isGuest = guestDoc.exists;
  const isPro = isUser && userDoc.data()?.subscription?.planType === "pro";
  const nowStr = today();
  let allowed = false,
    remaining = 0;

  if (isUser) {
    const usageDoc = await db.collection("usage").doc(uid).get();
    const metrics = usageDoc.exists ? usageDoc.data().metrics : {};
    let rewarded = 0,
      proFree = 0;
    if (metrics.lastReset === nowStr) {
      rewarded = metrics.rewardedGenCount || 0;
      proFree = metrics.proFreeGenCount || 0;
    }
    if (isPro) {
      allowed = proFree < PRO_FREE_BATCHES_PER_DAY;
      remaining = PRO_FREE_BATCHES_PER_DAY - proFree;
    } else {
      if (afterRewardedAd) {
        allowed = rewarded < CORE_REWARDED_BATCHES_PER_DAY;
        remaining = CORE_REWARDED_BATCHES_PER_DAY - rewarded;
      } else allowed = false;
    }
  } else if (isGuest && deviceId) {
    const deviceDoc = await db.collection("deviceUsage").doc(deviceId).get();
    let rewarded = 0;
    if (deviceDoc.exists && deviceDoc.data().lastReset === nowStr)
      rewarded = deviceDoc.data().rewardedGenCount || 0;
    const guestTier = guestDoc.data()?.guestTier || "first";
    const guestMax = guestTier === "returning" ? RETURNING_GUEST_BATCHES_PER_DAY : CORE_REWARDED_BATCHES_PER_DAY;
    if (afterRewardedAd) {
      allowed = rewarded < guestMax;
      remaining = guestMax - rewarded;
    } else allowed = false;
  }
  const quotaResult = { allowed, remaining };
  functionCache.set(cacheKey, { data: quotaResult, ts: Date.now() });
  return quotaResult;
});

// ------------------------------------------------------------------
// VERIFY REWARDED AD (stores token)
// ------------------------------------------------------------------
exports.verifyRewardAd = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  const { adTransactionId } = data;
  if (!adTransactionId)
    return { verified: false, reason: "Missing transaction ID" };
  if (!checkRateLimit(`verifyRewardAd_${uid}`, 10)) {
    return { verified: false, reason: "Rate limited" };
  }
  const usedRewardsRef = db
    .collection("usage")
    .doc(uid)
    .collection("usedRewards")
    .doc(adTransactionId);
  const usedDoc = await usedRewardsRef.get();
  if (usedDoc.exists) return { verified: false, reason: "Token already used" };
  await usedRewardsRef.set({
    usedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { verified: true };
});

// ------------------------------------------------------------------
// LINK GOOGLE ACCOUNT (with cooldown)
// ------------------------------------------------------------------
exports.linkGoogleAccount = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  if (!checkRateLimit(`linkGoogle_${uid}`, 3)) {
    throw new functions.https.HttpsError("resource-exhausted", "Rate limited");
  }
  const { email, displayName, deviceId } = data;
  // Cooldown check
  const cooldownRef = db
    .collection("emailCooldown")
    .doc(email);
  const cooldownDoc = await cooldownRef.get();
  if (cooldownDoc.exists && cooldownDoc.data().expires.toDate() > new Date()) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Account in cooldown",
    );
  } else if (cooldownDoc.exists) await cooldownRef.delete();

  const guestRef = db.collection("guests").doc(uid);
  const guestDoc = await guestRef.get();
  const usageRef = db.collection("usage").doc(uid);
  const userRef = db.collection("users").doc(uid);
  const userDoc = await userRef.get();

  let guestDisplayName = "";

  if (guestDoc.exists) {
    const guestData = guestDoc.data();
    guestDisplayName = guestData?.identity?.displayName || "";
    const guestTier = guestData?.guestTier || "first";

    if (guestTier === "returning") {
      // Returning guest upgrade → fresh start, reset usage
      await usageRef.set({
        type: "user",
        metrics: {
          rewardedGenCount: 0,
          proFreeGenCount: 0,
          lifetimeGeneratedCases: 0,
          lastReset: today(),
        },
      });
    }
    // First-time guest upgrade → usage doc already exists with type: "guest", leave it

    // Delete guest doc, update registry
    await guestRef.delete();
    await db.collection("the_qag_registry").doc(uid).set(
      {
        type: "user",
        uid,
        displayName: displayName || guestDisplayName,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  if (!guestDoc.exists && !userDoc.exists) {
    // Fresh Google sign-in (no prior guest) — create usage doc
    await usageRef.set({
      type: "user",
      metrics: {
        rewardedGenCount: 0,
        proFreeGenCount: 0,
        lifetimeGeneratedCases: 0,
        lastReset: today(),
      },
    });
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const identity = {
    uid,
    email,
    displayName: displayName || guestDisplayName || "",
    type: "user",
    deviceId: deviceId || "",
    createdAt: userDoc.exists
      ? userDoc.data()?.identity?.createdAt || now
      : now,
  };
  await userRef.set(
    {
      identity,
      subscription: { planType: "core", updatedAt: now },
    },
    { merge: true },
  );
  return { success: true };
});

// ------------------------------------------------------------------
// DELETE ACCOUNT (with cooldown for Google accounts)
// ------------------------------------------------------------------
exports.deleteAccount = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  if (!checkRateLimit(`deleteAccount_${uid}`, 2)) {
    throw new functions.https.HttpsError("resource-exhausted", "Rate limited");
  }
  const { deviceId, email } = data;
  const batch = db.batch();
  const userDoc = await db.collection("users").doc(uid).get();
  const isUser = userDoc.exists;
  if (isUser) {
    batch.delete(userDoc.ref);
    if (email) {
      const cooldownRef = db
        .collection("emailCooldown")
        .doc(email);
      batch.set(cooldownRef, {
        expires: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + COOLDOWN_HOURS * 60 * 60 * 1000),
        ),
        reason: "account_deleted",
      });
    }
  } else {
    const guestDoc = await db.collection("guests").doc(uid).get();
    if (guestDoc.exists) batch.delete(guestDoc.ref);
    // Don't delete deviceGuestMapping — mark as deleted for cooldown
    const mappingRef = db.collection("deviceGuestMapping").doc(deviceId);
    batch.set(mappingRef, {
      guestUid: uid,
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  batch.delete(db.collection("usage").doc(uid));
  batch.delete(db.collection("the_qag_registry").doc(uid));
  // deviceUsage/{deviceId} is NOT deleted — it carries the device's daily quota
  // across account resets. This prevents quota abuse via delete-recreate.
  const reports = await db
    .collection("issue_reports")
    .where("uid", "==", uid)
    .get();
  reports.forEach((doc) =>
    batch.update(doc.ref, { uid: "deleted_user" }),
  );
  await batch.commit();
  await admin.auth().deleteUser(uid);
  return { success: true };
});

// ------------------------------------------------------------------
// SUBMIT ISSUE REPORT
// ------------------------------------------------------------------
exports.submitIssueReport = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  if (!checkRateLimit(`submitIssue_${context.auth.uid}`, 5)) {
    throw new functions.https.HttpsError("resource-exhausted", "Rate limited");
  }
  const { issueType, title, description, platform, deviceModel, appVersion, screen, steps } = data;
  const uid = context.auth.uid;
  const ref = await db.collection("issue_reports").add({
    uid,
    issueType: issueType || "Bug",
    title: title || "",
    description: description || "",
    steps: steps || "",
    platform: platform || null,
    deviceModel: deviceModel || null,
    appVersion: appVersion || null,
    screen: screen || "unknown",
    status: "open",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { success: true, id: ref.id };
});

// ------------------------------------------------------------------
// GET MY ISSUE REPORTS
// ------------------------------------------------------------------
exports.getMyIssueReports = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  const snapshot = await db.collection("issue_reports")
    .where("uid", "==", uid)
    .orderBy("createdAt", "desc")
    .get();
  const reports = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  return { reports };
});

// ------------------------------------------------------------------
// RECORD UPDATE DISMISSAL
// ------------------------------------------------------------------
exports.recordUpdateDismissal = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  await db.collection("usage").doc(uid).set({
    metrics: { updateDismissals: admin.firestore.FieldValue.increment(1) },
  }, { merge: true });
  return { success: true };
});

// ------------------------------------------------------------------
// HELPER: CALL DEEPSEEK
// ------------------------------------------------------------------
const SYSTEM_PROMPT = `You are a QA test case generator. Generate professional, execution-ready test cases.

Output a JSON object with a single key "testCases" containing an array of test case objects.

Each test case object MUST have:
- id (string)
- title (string, descriptive and specific)
- module (string)
- feature (string)
- platform (string)
- preconditions (array of strings)
- testData (string, realistic input data)
- steps (array of objects with action/data/expected)
- expectedResult (string, measurable outcome)
- priority ("High", "Medium", or "Low")
- type ("POSITIVE", "NEGATIVE", "BOUNDARY", "SECURITY", "VALIDATION", or "SESSION")
- categoryLock (string)
- intent_id (string)

Rules:
- Use realistic data, observable actions, measurable expected results
- No generic phrases like "works correctly" or "as expected"
- No markdown, no explanations, no code blocks
- Each test case must be unique and execution-ready`;

async function callDeepSeek(prompt) {
  const DEEPSEEK_API_KEY = process.env.DEEPSEEK_API_KEY;
  const url = "https://api.deepseek.com/v1/chat/completions";
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 45000);
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${DEEPSEEK_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "deepseek-v4-flash",
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: prompt },
        ],
        temperature: 0.15,
        max_tokens: 8192,
        response_format: { type: "json_object" },
        extra_body: { thinking: { type: "disabled" } },
      }),
      signal: controller.signal,
    });
    clearTimeout(timeoutId);
    const json = await res.json();
    if (!res.ok)
      return { success: false, error: { code: `HTTP_${res.status}` } };

    const choice = json.choices && json.choices[0];
    if (!choice)
      return { success: false, error: { code: "EMPTY_CHOICES" } };

    const content = choice.message && choice.message.content;
    if (!content || content.trim().length === 0)
      return { success: false, error: { code: "EMPTY_RESPONSE" } };

    if (choice.finish_reason === "length")
      return { success: false, error: { code: "TRUNCATED" } };

    return { success: true, data: { text: content } };
  } catch (err) {
    clearTimeout(timeoutId);
    if (err.name === "AbortError") {
      return { success: false, error: { code: "TIMEOUT" } };
    }
    return { success: false, error: { code: "CLIENT_ERROR" } };
  }
}

function transformTestCases(rawCases, module, feature, platform, limit) {
  return rawCases.slice(0, limit).map((tc, i) => ({
    id: `TC_${module.replace(/ /g, "").toUpperCase()}_${(i + 1).toString().padStart(3, "0")}`,
    title: tc.title || "Test Case",
    preconditions: Array.isArray(tc.preconditions) ? tc.preconditions : [],
    steps: (tc.steps || []).map((s) => ({
      action: s.action || "",
      data: s.data || "",
      expected: s.expected || "",
    })),
    expectedResult: tc.expectedResult || "Success",
    actualResult: "",
    priority: tc.priority || "Medium",
    status: "Not Executed",
    type: tc.type || "Functional",
    module,
    feature,
    platform,
  }));
}
