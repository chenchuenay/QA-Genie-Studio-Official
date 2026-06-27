const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
const zlib = require("zlib");

admin.initializeApp();
const db = admin.firestore();
const TEST_CASES_BUCKET = (functions.config().test_cases && functions.config().test_cases.bucket) || "qa-genie-ai-dev-test-cases";
const bucket = admin.storage().bucket(TEST_CASES_BUCKET);

// ============================================================
// CENTRALIZED CONSTANTS – CHANGE QUOTAS HERE ONLY
// ============================================================
const CORE_FREE_BATCHES_PER_DAY = 0; // Core: 0 free generations
const CORE_REWARDED_BATCHES_PER_DAY = 6; // Core: 6 rewarded ad generations
const PRO_FREE_BATCHES_PER_DAY = 15; // Pro: 15 free generations

const RETURNING_GUEST_BATCHES_PER_DAY = 1; // Returning guest on same device: 1

const CORE_CASES_PER_BATCH = 10;
const PRO_CASES_PER_BATCH = 20;

const EXPORT_LIMIT_PER_DAY = 50; // 50 exports per day for all non-pro members
const COOLDOWN_HOURS = 24; // 24h cooldown after Google account deletion

// ------------------------------------------------------------------
// APP CHECK — enforce in prod, allow debug tokens in dev
// ------------------------------------------------------------------
const IS_DEV_PROJECT = process.env.GCLOUD_PROJECT === 'qa-genie-ai-dev';

function onCall(handler, runWithOpts = {}) {
  const fn = Object.keys(runWithOpts).length > 0
    ? functions.runWith(runWithOpts).https.onCall
    : functions.https.onCall;
  const wrappedHandler = async (data, context) => {
    // 1st gen onCall doesn't support enforceAppCheck option,
    // so we enforce it manually here
    if (!IS_DEV_PROJECT) {
      if (!context.app || !context.app.appId) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "App Check verification required"
        );
      }
    }
    return handler(data, context);
  };
  return fn(wrappedHandler);
}

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
const CACHE_TTL_MS = 10000;

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

// --------------------------------------------------------------
// CHECK SESSION BY EMAIL (before linking, auth dialog)
// --------------------------------------------------------------
exports.checkSessionByEmail = onCall(async (data, context) => {
  // No auth required — called before the user is signed in (auth dialog flow).
  const { email, deviceId } = data;
  if (!email || !deviceId)
    throw new functions.https.HttpsError("invalid-argument", "email and deviceId required");
  // Rate limit by email since no auth uid is available
  if (!checkRateLimit(`checkSession_${email}`, 10)) {
    throw new functions.https.HttpsError("resource-exhausted", "Rate limited");
  }

  log("info", `checkSessionByEmail: email=${email} deviceId=${deviceId}`);

  const profileDoc = await db.collection("memberProfiles").doc(email).get();
  if (!profileDoc.exists) {
    log("info", "checkSessionByEmail: no profile found");
    return { conflict: false };
  }

  const profileData = profileDoc.data();
  const uid = profileData.uid;
  const tier = profileData.subscription?.planType === "pro" ? "pro" : "core";
  log("info", `checkSessionByEmail: profile uid=${uid} tier=${tier}`);

  const sessionRef = db.collection("memberData").doc(tier).collection(uid).doc("_session");
  const session = await sessionRef.get();
  if (!session.exists) {
    log("info", "checkSessionByEmail: no session doc found");
    return { conflict: false, uid, tier };
  }
  const storedDeviceId = session.data().deviceId;
  log("info", `checkSessionByEmail: session deviceId=${storedDeviceId} vs incoming=${deviceId}`);
  if (storedDeviceId === deviceId) return { conflict: false, uid, tier };

  return { conflict: true, uid, tier };
});

// --------------------------------------------------------------
// REGISTER SESSION (after linking or cold start)
// Uses profile uid (not auth uid) for session path to handle
// uid changes after reinstall.
// --------------------------------------------------------------
exports.registerSession = onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  if (!checkRateLimit(`registerSession_${context.auth.uid}`, 20)) {
    throw new functions.https.HttpsError("resource-exhausted", "Rate limited");
  }
  const authUid = context.auth.uid;
  const { deviceId, force } = data;
  if (!deviceId)
    throw new functions.https.HttpsError("invalid-argument", "deviceId required");

  log("info", `registerSession: authUid=${authUid} deviceId=${deviceId} force=${force}`);

  // Try uid lookup first, fall back to email (handles reinstall uid change)
  let profile = await _getMemberProfileByUid(authUid);
  if (!profile && context.auth.token?.email) {
    log("info", `registerSession: uid lookup failed, trying email ${context.auth.token.email}`);
    const doc = await db.collection("memberProfiles").doc(context.auth.token.email).get();
    if (doc.exists) {
      profile = { email: doc.id, ref: doc.ref, data: doc.data() };
    }
  }
  if (!profile) {
    log("info", "registerSession: no profile found at all");
    return { conflict: false, tier: "core" };
  }

  // Use profile uid for session path — this is what checkSessionByEmail also uses
  const profileUid = profile.data.uid;
  const tier = profile.data.subscription?.planType === "pro" ? "pro" : "core";
  log("info", `registerSession: resolved profileUid=${profileUid} tier=${tier}`);

  const sessionRef = db.collection("memberData").doc(tier).collection(profileUid).doc("_session");
  const existing = await sessionRef.get();
  if (existing.exists && existing.data().deviceId !== deviceId && !force) {
    log("info", "registerSession: conflict detected");
    return { conflict: true, tier };
  }
  await sessionRef.set({
    deviceId,
    lastActive: admin.firestore.FieldValue.serverTimestamp(),
  });
  log("info", "registerSession: session saved");
  return { conflict: false, tier };
});

// ------------------------------------------------------------------
// HELPER: Get or create registry counter (total users ever)
// ------------------------------------------------------------------
async function getNextRegistryNumber() {
  const counterRef = db.collection("counters").doc("registry");
  const result = await db.runTransaction(async (t) => {
    const doc = await t.get(counterRef);
    let counter = doc.exists ? (doc.data().value || 0) : 0;
    counter++;
    t.set(counterRef, { value: counter }, { merge: true });
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
// HELPER: Usage doc path — usage/{email} for members, usage/{uid} for guests
// ------------------------------------------------------------------
function usageRef(context) {
  const email = context.auth?.token?.email;
  const uid = context.auth?.uid;
  if (email) return { ref: db.collection("usage").doc(email), uid, email };
  return { ref: db.collection("usage").doc(uid), uid, email: null };
}

// --------------------------------------------------------------
// HELPER: Look up memberProfiles doc by uid (email is the doc ID)
// Returns { email, ref, data } or null.
// --------------------------------------------------------------
async function _getMemberProfileByUid(uid) {
  const snap = await db
    .collection("memberProfiles")
    .where("uid", "==", uid)
    .limit(1)
    .get();
  if (snap.empty) return null;
  const doc = snap.docs[0];
  return { email: doc.id, ref: doc.ref, data: doc.data() };
}

// --------------------------------------------------------------
// Returns the tier ("core" or "pro") for a given uid.
// Defaults to "core" if profile not found.
// --------------------------------------------------------------
async function _getMemberTier(uid) {
  const profile = await _getMemberProfileByUid(uid);
  if (!profile) return "core";
  return profile.data.subscription?.planType === "pro" ? "pro" : "core";
}

// ------------------------------------------------------------------
// GENERATION (uses central constants) — combined flow
// Accepts rewardToken (new) or adToken (legacy) for ad verification.
// AI call runs BEFORE transaction so ad is only consumed on success.
// Returns usage data so client can update cache without refetch.
// ------------------------------------------------------------------
exports.generate = onCall(async (data, context) => {
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

    // Resolve memberProfiles (email-based doc) before transaction
    let memberProfileEmail = null;
    try {
      const profileResult = await _getMemberProfileByUid(uid);
      if (profileResult) memberProfileEmail = profileResult.email;
    } catch (_) {}

    try {
      const { ref: uRef, email: memberEmail } = usageRef(context);
      const reqRef = db.collection("processed_requests").doc(requestId);
      const memberProfileRef = memberProfileEmail
        ? db.collection("memberProfiles").doc(memberProfileEmail)
        : db.collection("_void").doc(uid);
      const guestRef = db.collection("guests").doc(uid);
      const deviceRef = db.collection("deviceUsage").doc(deviceId);

      // Dedup check BEFORE calling DeepSeek — prevents double charges
      const reqSnap = await reqRef.get();
      if (reqSnap.exists) {
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

      if (!Array.isArray(cases) || cases.length === 0) {
        throw new Error('EMPTY_AI_RESPONSE');
      }

      const generationData = await db.runTransaction(async (t) => {
        const [uDoc, reqDoc, memberProfileDoc, guestDoc, deviceDoc] =
          await Promise.all([
            t.get(uRef),
            t.get(reqRef),
            t.get(memberProfileRef),
            t.get(guestRef),
            t.get(deviceRef),
          ]);
        if (reqDoc.exists) throw new Error("ALREADY_PROCESSED");

        // Handle rewardToken (new flow): create + consume atomically
        if (rewardToken) {
          const tokenRef = uRef.collection("usedRewards").doc(rewardToken);
          const tokenSnap = await t.get(tokenRef);
          if (tokenSnap.exists) throw new Error("AD_TOKEN_USED");
          t.set(tokenRef, {
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            usedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        // Handle adToken (legacy flow): verify + consume atomically
        if (adToken) {
          const tokenRef = uRef.collection("usedRewards").doc(adToken);
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
        if (memberProfileDoc.exists)
          isPro = memberProfileDoc.data()?.subscription?.planType === "pro";
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
          t.delete(uRef.collection("usedRewards").doc(rewardToken));
        }
        if (adToken) {
          t.delete(uRef.collection("usedRewards").doc(adToken));
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
          const prevGen = metrics.generations || {};
          t.set(uRef, {
            uid,
            type: "member",
            metrics: {
              ...metrics,
              generations: {
                total: (prevGen.total || 0) + 1,
                totalCases: (prevGen.totalCases || 0) + caseCount,
                coreCases: isPro ? (prevGen.coreCases || 0) : (prevGen.coreCases || 0) + caseCount,
                proCases: isPro ? (prevGen.proCases || 0) + caseCount : (prevGen.proCases || 0),
                aiFailures: prevGen.aiFailures || 0,
                validatorRejections: prevGen.validatorRejections || 0,
              },
              exportCount: uDoc.data()?.metrics?.exportCount ?? 0,
              updateDismissals: uDoc.data()?.metrics?.updateDismissals ?? 0,
            },
            exports: uDoc.data()?.exports ?? {
              lifetimeExports: 0,
              exportTargets: {},
              fileExtensions: {},
            },
            interests: uDoc.data()?.interests ?? { proInterestCount: 0 },
          });
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
          const guestPrevGen = guestMetrics.generations || {};
          t.set(uRef, {
            uid,
            type: "guest",
            metrics: {
              ...guestMetrics,
              generations: {
                total: (guestPrevGen.total || 0) + 1,
                totalCases: (guestPrevGen.totalCases || 0) + caseCount,
                coreCases: (guestPrevGen.coreCases || 0) + caseCount,
                proCases: guestPrevGen.proCases || 0,
                aiFailures: guestPrevGen.aiFailures || 0,
                validatorRejections: guestPrevGen.validatorRejections || 0,
              },
              exportCount: uDoc.data()?.metrics?.exportCount ?? 0,
              updateDismissals: uDoc.data()?.metrics?.updateDismissals ?? 0,
            },
            exports: uDoc.data()?.exports ?? {
              lifetimeExports: 0,
              exportTargets: {},
              fileExtensions: {},
            },
            interests: uDoc.data()?.interests ?? { proInterestCount: 0 },
          });
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
          uid,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          // No response field — never store test case content per data policy
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
        !["ALREADY_PROCESSED", "LIMIT_REACHED", "PRO_LIMIT_REACHED", "AD_TOKEN_USED", "INVALID_AD_TOKEN", "AD_TOKEN_EXPIRED", "REWARDED_AD_REQUIRED", "DEVICE_ID_MISMATCH", "EMPTY_AI_RESPONSE"].includes(
          err.message,
        )
      ) {
        const { ref: failRef } = usageRef(context);
        failRef.set({
          metrics: { generations: { aiFailures: admin.firestore.FieldValue.increment(1) } },
        }, { merge: true }).catch(() => {});
      }
      return { success: false, error: { code: err.message } };
    }
}, { secrets: ["DEEPSEEK_API_KEY"], timeoutSeconds: 60 });

// ------------------------------------------------------------------
// RECORD EXPORT METRICS (per-user, no analytics/global write)
// ------------------------------------------------------------------
exports.recordExportMetrics = onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  if (!checkRateLimit(`recordExport_${context.auth.uid}`, 10)) {
    throw new functions.https.HttpsError("resource-exhausted", "Rate limited");
  }
  const { summary, target, extension, exportType } = data;
  const type = exportType || target || (summary ? "summary" : "unknown");
  const ext = extension || (target === "pdf" ? "pdf" : target);
  const nowStr = today();
  const { ref: uRef, uid } = usageRef(context);

  const profile = await _getMemberProfileByUid(uid);
  const isPro = profile ? profile.data.subscription?.planType === "pro" : false;

  if (!isPro) {
    // Non-pro (core + guest): check daily export limit
    const usageDoc = await uRef.get();
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
    metrics: {
      exports: {
        total: admin.firestore.FieldValue.increment(1),
        [`targets.${type}`]: admin.firestore.FieldValue.increment(1),
        [`extensions.${ext}`]: admin.firestore.FieldValue.increment(1),
      },
    },
  };
  if (summary) {
    usageUpdate.metrics.exports.totalSummaryExports = admin.firestore.FieldValue.increment(1);
  }
  if (!isPro) {
    usageUpdate.metrics.exportCount = admin.firestore.FieldValue.increment(1);
    usageUpdate.metrics.lastReset = nowStr;
  }
  await uRef.set(usageUpdate, { merge: true });
  return { success: true };
});

// ------------------------------------------------------------------
// RATING (unchanged)
// ------------------------------------------------------------------
exports.recordRating = onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Auth required");
  if (!checkRateLimit(`rating_${context.auth.uid}`, 3)) {
    return { success: false, error: { code: "RATE_LIMITED" } };
  }
  const { rating } = data;
  const { ref: uRef } = usageRef(context);
  await uRef.set({
    metrics: {
      ratings: {
        total: admin.firestore.FieldValue.increment(1),
        [`breakdown.${rating}`]: admin.firestore.FieldValue.increment(1),
      },
    },
  }, { merge: true });
  return { success: true };
});

// ------------------------------------------------------------------
// COOLDOWN CHECK (called before Google sign-in to enforce 24h cooldown)
// ------------------------------------------------------------------
exports.checkEmailCooldown = onCall(async (data, context) => {
  const { email } = data;
  if (!email) {
    throw new functions.https.HttpsError("invalid-argument", "email required");
  }
  if (!checkRateLimit(`emailCooldown_${email}`, 10)) {
    throw new functions.https.HttpsError("resource-exhausted", "Rate limited");
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
// RECORD VALIDATOR REJECTIONS (per-user, client-triggered)
// ------------------------------------------------------------------
exports.recordValidatorRejected = onCall(async (data, context) => {
  if (!context.auth) throw new Error("UNAUTHENTICATED");
  if (!checkRateLimit(`validatorReject_${context.auth.uid}`, 10)) {
    return { success: false, error: { code: "RATE_LIMITED" } };
  }
  const { rejectedCount } = data;
  if (!rejectedCount) return { success: true };
  const { ref: uRef } = usageRef(context);
  await uRef.set({
    metrics: { generations: { validatorRejections: admin.firestore.FieldValue.increment(rejectedCount) } },
  }, { merge: true }).catch(() => {});
  return { success: true };
});

// ------------------------------------------------------------------
// GET OR CREATE GUEST TOKEN (for "Continue as guest" button)
// ------------------------------------------------------------------
exports.getOrCreateGuestToken = onCall(async (data) => {
  // App Check enforced in onCall helper for prod
  const { deviceId, forceReturning, caller, androidId } = data;
  console.log(`[getOrCreateGuestToken] CALLED | deviceId=${deviceId} | androidId=${androidId} | forceReturning=${forceReturning} | caller=${caller}`);
  if (!deviceId || typeof deviceId !== "string" || deviceId.length < 8 || deviceId.length > 128 || !/^[a-zA-Z0-9_\-]+$/.test(deviceId))
    throw new functions.https.HttpsError(
      "invalid-argument",
      "deviceId required",
    );
  if (!checkRateLimit(`guestToken_${deviceId}`, 5)) {
    console.log(`[getOrCreateGuestToken] RATE LIMITED | deviceId=${deviceId}`);
    throw new functions.https.HttpsError("resource-exhausted", "Rate limited");
  }
  let deviceDocId = deviceId;
  let mappingRef = db.collection("deviceGuestMapping").doc(deviceId);
  let mappingDoc = await mappingRef.get();
  // If deviceId not found, cross-reference by ANDROID_ID for migration
  if (!mappingDoc.exists && androidId && androidId !== deviceId) {
    console.log(`[getOrCreateGuestToken] trying androidId=${androidId} as fallback`);
    const altRef = db.collection("deviceGuestMapping").doc(androidId);
    const altDoc = await altRef.get();
    if (altDoc.exists) {
      console.log(`[getOrCreateGuestToken] FOUND by androidId`);
      mappingDoc = altDoc;
      deviceDocId = androidId;
    }
  }

  if (mappingDoc.exists) {
    // Device already mapped → ALWAYS returning (1 quota), never first
    const existingUid = mappingDoc.data().guestUid;
    console.log(`[getOrCreateGuestToken] MAPPING EXISTS | guestUid=${existingUid} | deviceDocId=${deviceDocId}`);
    const existingGuestDoc = await db.collection("guests").doc(existingUid).get();
    if (existingGuestDoc.exists) {
      // Reuse existing guest with returning tier
      console.log(`[getOrCreateGuestToken] REUSING existing guest as returning | uid=${existingUid}`);
      const reuseBatch = db.batch();
      reuseBatch.update(db.collection("guests").doc(existingUid), { guestTier: "returning" });
      reuseBatch.set(db.collection("usage").doc(existingUid), {
        type: "guest",
        metrics: { lifetimeGeneratedCases: 0 },
        exports: { lifetimeExports: 0 },
      });
      reuseBatch.set(db.collection("deviceUsage").doc(deviceDocId), {
        rewardedGenCount: 0,
        lastReset: today(),
        uid: existingUid,
      }, { merge: true });
      await reuseBatch.commit();
      const customToken = await admin.auth().createCustomToken(existingUid);
      return { token: customToken, isNew: false, guestTier: "returning" };
    }
    // Guest doc consumed (upgraded/deleted) → create new returning guest
    console.log(`[getOrCreateGuestToken] GUEST CONSUMED | creating new returning guest`);
    const newUid = `guest_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const registryNumber = await getNextRegistryNumber();
    const displayName = `Guest${registryNumber}`;
    const batch = db.batch();
    // Delete old registry entry
    batch.delete(db.collection("the_qag_registry").doc(existingUid));
    batch.set(db.collection("guests").doc(newUid), {
      identity: { uid: newUid, displayName, type: "guest", deviceId, createdAt: admin.firestore.FieldValue.serverTimestamp() },
      guestTier: "returning",
    });
    batch.set(db.collection("usage").doc(newUid), {
      type: "guest", metrics: { lifetimeGeneratedCases: 0 }, exports: { lifetimeExports: 0 },
    });
    batch.set(db.collection("the_qag_registry").doc(newUid), {
      uid: newUid, type: "guest", displayName, createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    batch.set(db.collection("deviceGuestMapping").doc(deviceDocId), {
      guestUid: newUid, androidId: androidId || null, createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    if (androidId && androidId !== deviceDocId) {
      batch.set(db.collection("deviceGuestMapping").doc(androidId), {
        guestUid: newUid, deviceId: deviceDocId, createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    batch.set(db.collection("deviceUsage").doc(deviceDocId), {
      rewardedGenCount: 0, lastReset: today(), uid: newUid,
    }, { merge: true });
    await batch.commit();
    const customToken = await admin.auth().createCustomToken(newUid);
    return { token: customToken, isNew: true, guestTier: "returning" };
  }

  // No mapping for this device
  let isNew = false;
  let guestTier = "first";
  let guestUid;
  if (forceReturning) {
    // Explicit returning (sign-out / delete) → create returning guest
    console.log(`[getOrCreateGuestToken] NO MAPPING + forceReturning | creating returning guest`);
    isNew = true;
    guestTier = "returning";
  } else {
    // Truly new device → first-time guest (6 quotas)
    console.log(`[getOrCreateGuestToken] NO MAPPING | creating first-time guest`);
    isNew = true;
    guestTier = "first";
  }

  if (isNew) {
    guestUid = `guest_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const registryNumber = await getNextRegistryNumber();
    const displayName = `Guest${registryNumber}`;
    console.log(`[getOrCreateGuestToken] CREATING NEW guest | uid=${guestUid} | tier=${guestTier} | displayName=${displayName}`);
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
      androidId: androidId || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Also index by ANDROID_ID for resilience across data clear
    if (androidId && androidId !== deviceDocId) {
      batch.set(db.collection("deviceGuestMapping").doc(androidId), {
        guestUid,
        deviceId: deviceDocId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    batch.set(db.collection("deviceUsage").doc(deviceId), {
      rewardedGenCount: 0,
      lastReset: today(),
      uid: guestUid,
    }, { merge: true });
    await batch.commit();
    console.log(`[getOrCreateGuestToken] BATCH COMMITTED | guest created in Firestore`);
  } else {
    console.log(`[getOrCreateGuestToken] NOT NEW | returning existing guest | uid=${guestUid} | tier=${guestTier}`);
  }
  const customToken = await admin.auth().createCustomToken(guestUid);
  return { token: customToken, isNew, guestTier };
});

// ------------------------------------------------------------------
// CHECK EXPORT QUOTA
// ------------------------------------------------------------------
exports.checkExportQuota = onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  const { rewarded = false } = data;
  const profile = await _getMemberProfileByUid(uid);
  const isPro = profile ? profile.data.subscription?.planType === "pro" : false;
  const nowStr = today();
  let allowed = false, remaining = 0;

  if (isPro) {
    allowed = true;
    remaining = 999;
  } else {
    // Same 50/day limit for core members and guests
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
exports.resetDailyLimits = onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const { ref: uRef } = usageRef(context);
  const nowStr = today();
  await uRef.set({
    metrics: {
      rewardedGenCount: 0,
      proFreeGenCount: 0,
      exportCount: 0,
      lastReset: nowStr,
    },
  }, { merge: true });

  // Cleanup processed_requests older than 24h (batch delete, max 500)
  try {
    const oldCutoff = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const snapshot = await db.collection("processed_requests").get();
    const batch = db.batch();
    let count = 0;
    snapshot.forEach((doc) => {
      if (count >= 500) return;
      const processedAt = doc.data()?.processedAt?.toDate();
      if (processedAt && processedAt < oldCutoff) {
        batch.delete(doc.ref);
        count++;
      }
    });
    if (count > 0) {
      await batch.commit();
      console.log(`🧹 Cleaned up ${count} old processed_requests`);
    }
  } catch (e) {
    console.error("❌ Failed to cleanup processed_requests:", e);
  }

  return { success: true };
});

// ------------------------------------------------------------------
// GET MEMBER DASHBOARD
// ------------------------------------------------------------------
exports.getMemberDashboard = onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  const cacheKey = `dashboard_${uid}`;
  const cached = functionCache.get(cacheKey);
  if (cached && (Date.now() - cached.ts) < CACHE_TTL_MS) {
    return cached.data;
  }
  const profile = await _getMemberProfileByUid(uid);
  const isMember = !!profile;
  const usageDoc = await (isMember
    ? db.collection("usage").doc(profile.data.email).get()
    : db.collection("usage").doc(uid).get()
  );
  let isGuest = false, guestDoc = null;
  if (!isMember) {
    guestDoc = await db.collection("guests").doc(uid).get();
    isGuest = guestDoc.exists;
  }
  const planType = profile ? profile.data.subscription?.planType : null;
  function toISO(val) {
    if (!val) return null;
    if (typeof val.toDate === "function") return val.toDate().toISOString();
    if (val instanceof Date) return val.toISOString();
    return val;
  }
  const identity = isMember
    ? { displayName: profile.data.displayName || "", email: profile.data.email || "", createdAt: toISO(profile.data.createdAt) }
    : isGuest
      ? { ...guestDoc.data().identity, createdAt: toISO(guestDoc.data().identity?.createdAt) }
      : null;

  const nowStr = today();
  const metrics = usageDoc.exists ? usageDoc.data().metrics : {};
  const exports = usageDoc.exists ? usageDoc.data().exports : {};
  let rewardedGensRemaining = 0;
  let proGensRemaining = 0;
  const isPro = planType === "pro";

  if (isMember) {
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
// SET MEMBER PRO
// ------------------------------------------------------------------
exports.setMemberPro = onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const { isPro } = data;
  const uid = context.auth.uid;
  const profile = await _getMemberProfileByUid(uid);
  if (!profile) throw new functions.https.HttpsError("not-found", "Member profile not found");
  await db
    .collection("memberProfiles")
    .doc(profile.email)
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
// RECORD PRO INTEREST (per-user, no analytics/global write)
// ------------------------------------------------------------------
exports.recordProInterest = onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const { ref: uRef, uid } = usageRef(context);
  const { source } = data;
  const now = admin.firestore.FieldValue.serverTimestamp();
  await db.runTransaction(async (t) => {
    const uDoc = await t.get(uRef);
    let interests = uDoc.data()?.interests || { proInterestCount: 0 };
    interests.proInterestCount = (interests.proInterestCount || 0) + 1;
    if (interests.proInterestCount === 1) interests.firstProInterestAt = now;
    interests.lastProInterestAt = now;
    if (!interests.proInterestSources) interests.proInterestSources = {};
    interests.proInterestSources[source] =
      (interests.proInterestSources[source] || 0) + 1;
    t.set(uRef, { uid, interests }, { merge: true });
  });
  return { success: true };
});

// ------------------------------------------------------------------
// RECOMPUTE ANALYTICS (aggregate from source docs into analytics/global)
// ------------------------------------------------------------------
exports.recomputeAnalytics = onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");

  // 1. Count members from memberProfiles
  const memberSnap = await db.collection("memberProfiles").get();
  let totalMembers = 0;
  memberSnap.forEach(d => {
    const d2 = d.data();
    if (!d2.deletedAt) totalMembers++;
  });

  // 2. Count guests from the_qag_registry
  const regSnap = await db.collection("the_qag_registry").get();
  let guestCounter = 0;
  let registryCounter = 0;
  regSnap.forEach(d => {
    registryCounter++;
    if (d.data().type === "guest") guestCounter++;
  });

  // 3. Aggregate from all usage docs
  const usageSnap = await db.collection("usage").get();
  const genTotals = {};
  const exportTotals = {};
  const ratingTotals = {};
  let proInterestTotal = 0;
  let proTabClicks = 0;
  let uniqueProInterested = 0;
  const seenProInterestUids = new Set();

  usageSnap.forEach(d => {
    const du = d.data();
    const gen = du?.metrics?.generations;
    const exp = du?.metrics?.exports;
    const rat = du?.metrics?.ratings;
    const ints = du?.interests;

    if (gen) {
      genTotals.total = (genTotals.total || 0) + (gen.total || 0);
      genTotals.totalCases = (genTotals.totalCases || 0) + (gen.totalCases || 0);
      genTotals.coreCases = (genTotals.coreCases || 0) + (gen.coreCases || 0);
      genTotals.proCases = (genTotals.proCases || 0) + (gen.proCases || 0);
      genTotals.aiFailures = (genTotals.aiFailures || 0) + (gen.aiFailures || 0);
      genTotals.validatorRejections = (genTotals.validatorRejections || 0) + (gen.validatorRejections || 0);
    }

    if (exp) {
      exportTotals.total = (exportTotals.total || 0) + (exp.total || 0);
      exportTotals.summaryExports = (exportTotals.summaryExports || 0) + (exp.summaryExports || 0);
      if (exp.targets) {
        if (!exportTotals.targets) exportTotals.targets = {};
        Object.keys(exp.targets).forEach(k => {
          exportTotals.targets[k] = (exportTotals.targets[k] || 0) + (exp.targets[k] || 0);
        });
      }
      if (exp.extensions) {
        if (!exportTotals.extensions) exportTotals.extensions = {};
        Object.keys(exp.extensions).forEach(k => {
          exportTotals.extensions[k] = (exportTotals.extensions[k] || 0) + (exp.extensions[k] || 0);
        });
      }
    }

    if (rat) {
      ratingTotals.total = (ratingTotals.total || 0) + (rat.total || 0);
      if (rat.breakdown) {
        if (!ratingTotals.breakdown) ratingTotals.breakdown = {};
        Object.keys(rat.breakdown).forEach(k => {
          ratingTotals.breakdown[k] = (ratingTotals.breakdown[k] || 0) + (rat.breakdown[k] || 0);
        });
      }
    }

    if (ints?.proInterestCount) {
      proInterestTotal += ints.proInterestCount;
      if (ints.proInterestSources?.tab) {
        proTabClicks += ints.proInterestSources.tab;
      }
      if (du.uid) seenProInterestUids.add(du.uid);
    }
  });

  const globalData = {
    generation: {
      totalGenerations: genTotals.total || 0,
      totalTestCaseGenerated: genTotals.totalCases || 0,
      coreGeneratedCases: genTotals.coreCases || 0,
      proGeneratedCases: genTotals.proCases || 0,
      totalAiFailures: genTotals.aiFailures || 0,
      totalValidatorRejections: genTotals.validatorRejections || 0,
    },
    exports: {
      totalExports: exportTotals.total || 0,
      totalSummaryExports: exportTotals.summaryExports || 0,
      targets: exportTotals.targets || {},
      extensions: exportTotals.extensions || {},
    },
    ratings: {
      totalRatings: ratingTotals.total || 0,
      breakdown: ratingTotals.breakdown || {},
    },
    pro: {
      totalProInterest: proInterestTotal,
      proTabClicks: proTabClicks,
      uniqueProInterestedMembers: seenProInterestUids.size,
    },
    other: {
      totalMembers,
      guestCounter,
      registryCounter,
    },
  };

  await db.collection("analytics").doc("global").set(globalData, { merge: true });
  return { success: true, data: globalData };
});

// ------------------------------------------------------------------
// HEALTH CHECK
// ------------------------------------------------------------------
exports.healthCheck = onCall(async () => ({
  status: "ok",
  timestamp: new Date().toISOString(),
}));

// ------------------------------------------------------------------
// CHECK GENERATION QUOTA (client uses before showing ad)
// ------------------------------------------------------------------
exports.checkGenerationQuota = onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  const { afterRewardedAd = false, deviceId } = data;
  const cacheKey = `quota_${uid}_${deviceId || ''}_${afterRewardedAd}`;
  const cached = functionCache.get(cacheKey);
  if (cached && (Date.now() - cached.ts) < CACHE_TTL_MS) {
    return cached.data;
  }
  const profile = await _getMemberProfileByUid(uid);
  const guestDoc = await db.collection("guests").doc(uid).get();
  const isMember = !!profile;
  const isGuest = guestDoc.exists;
  const isPro = profile ? profile.data.subscription?.planType === "pro" : false;
  const nowStr = today();
  let allowed = false,
    remaining = 0;

  if (isMember) {
    const { ref: memberURef } = usageRef(context);
    const usageDoc = await memberURef.get();
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
exports.verifyRewardAd = onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const { ref: uRef } = usageRef(context);
  const { adTransactionId } = data;
  if (!adTransactionId)
    return { verified: false, reason: "Missing transaction ID" };
  if (!checkRateLimit(`verifyRewardAd_${context.auth.uid}`, 10)) {
    return { verified: false, reason: "Rate limited" };
  }
  const usedRewardsRef = uRef.collection("usedRewards").doc(adTransactionId);
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
exports.linkGoogleAccount = onCall(async (data, context) => {
  if (!context.auth) {
    console.log(`[linkGoogleAccount] UNAUTHENTICATED`);
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  }
  const uid = context.auth.uid;
  console.log(`[linkGoogleAccount] CALLED | uid=${uid} | email=${data.email}`);
  if (!checkRateLimit(`linkGoogle_${uid}`, 3)) {
    console.log(`[linkGoogleAccount] RATE LIMITED`);
    throw new functions.https.HttpsError("resource-exhausted", "Rate limited");
  }
  const { email, displayName, deviceId, previousGuestUid } = data;
  if (email && context.auth.token?.email && email !== context.auth.token.email) {
    console.log(`[linkGoogleAccount] EMAIL MISMATCH | data.email=${email} | token.email=${context.auth.token.email}`);
    throw new functions.https.HttpsError("permission-denied", "Email mismatch");
  }
  const cooldownRef = db
    .collection("emailCooldown")
    .doc(email);
  const cooldownDoc = await cooldownRef.get();
  if (cooldownDoc.exists && cooldownDoc.data().expires.toDate() > new Date()) {
    console.log(`[linkGoogleAccount] EMAIL IN COOLDOWN | email=${email}`);
    throw new functions.https.HttpsError(
      "permission-denied",
      "Account in cooldown",
    );
  } else if (cooldownDoc.exists) await cooldownRef.delete();

  // Clean up orphaned guest from credential-already-in-use scenario
  // We keep deviceGuestMapping so the device is never eligible for first-time guest again.
  if (previousGuestUid && previousGuestUid !== uid) {
    console.log(`[linkGoogleAccount] cleaning orphaned guest | previousGuestUid=${previousGuestUid}`);
    try {
      await db.collection("guests").doc(previousGuestUid).delete();
      await db.collection("the_qag_registry").doc(previousGuestUid).delete();
      console.log(`[linkGoogleAccount] orphaned guest cleaned | previousGuestUid=${previousGuestUid}`);
    } catch (e) {
      console.warn(`[linkGoogleAccount] failed to clean orphaned guest: ${e.message}`);
    }
  }

  const guestRef = db.collection("guests").doc(uid);
  const guestDoc = await guestRef.get();
  const memberUsageRef = email ? db.collection("usage").doc(email) : db.collection("usage").doc(uid);
  const usageRef = db.collection("usage").doc(uid);
  console.log(`[linkGoogleAccount] guestDoc.exists=${guestDoc.exists}`);

  let guestDisplayName = "";

  if (guestDoc.exists) {
    console.log(`[linkGoogleAccount] GUEST EXISTS | upgrading to member`);

    // Check if this Google account is already a registered member
    const existingMemberUsage = await memberUsageRef.get();
    if (existingMemberUsage.exists && existingMemberUsage.data()?.type === "member") {
      // Google account already has member data — just delete the guest, preserve member
      console.log(`[linkGoogleAccount] Google account is already a member | preserving existing data`);
      await guestRef.delete();
      await db.collection("the_qag_registry").doc(uid).delete().catch(() => {});
      await usageRef.delete().catch(() => {});
    } else {
      const guestData = guestDoc.data();
      guestDisplayName = guestData?.identity?.displayName || "";
      const guestTier = guestData?.guestTier || "first";

      if (guestTier === "returning") {
        // Returning guest upgrade → fresh start, reset usage at new email key
        await memberUsageRef.set({
          type: "member",
          email,
          uid,
          metrics: {
            rewardedGenCount: 0,
            proFreeGenCount: 0,
            lifetimeGeneratedCases: 0,
            lastReset: today(),
          },
        });
      } else {
        // First-time guest upgrade — copy existing usage to email key
        const oldData = await usageRef.get();
        const oldUsage = oldData.exists ? oldData.data() : {};
        await memberUsageRef.set({
          ...oldUsage,
          type: "member",
          email,
          uid,
        });
      }

      // Delete old uid-based usage doc
      if (email) await usageRef.delete().catch(() => {});
    }

    // Delete guest doc
    await guestRef.delete();
    console.log(`[linkGoogleAccount] GUEST DELETED`);
  }

  if (!guestDoc.exists) {
    const existingUsage = await memberUsageRef.get();
    if (existingUsage.exists) {
      // Returning member — preserve existing metrics, don't nuke quota
      console.log(`[linkGoogleAccount] RETURNING MEMBER | preserving usage metrics`);
      await memberUsageRef.set({ type: "member", email, uid }, { merge: true });
    } else {
      console.log(`[linkGoogleAccount] FRESH MEMBER | creating usage doc`);
      await memberUsageRef.set({
        type: "member",
        email,
        uid,
        metrics: {
          rewardedGenCount: 0,
          proFreeGenCount: 0,
          lifetimeGeneratedCases: 0,
          lastReset: today(),
        },
      });
    }
  }

  // Ensure registry entry exists for ALL Google accounts (not just guest upgrades)
  await db.collection("the_qag_registry").doc(uid).set(
    {
      type: "member",
      uid,
      displayName: displayName || guestDisplayName || "",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  // Create / update email → uid mapping for cross-reinstall identity resolution.
  // Preserve the original uid so getMemberSuites can redirect to the first-ever UID
  // after reinstall (when Firebase Auth issues a new UID).
  let recoveredCreatedAt = null;
  if (email) {
    const profileRef = db.collection("memberProfiles").doc(email);
    const existingProfile = await profileRef.get();
    const originalUid = existingProfile.exists ? existingProfile.data().uid : uid;
    if (existingProfile.exists && existingProfile.data().createdAt) {
      recoveredCreatedAt = existingProfile.data().createdAt;
    }
    const now = admin.firestore.FieldValue.serverTimestamp();
    // Preserve existing subscription tier (Pro users re-linking should keep Pro)
    const existingPlanType = existingProfile.exists
      ? (existingProfile.data().subscription?.planType || "core")
      : "core";
    const profileData = {
      uid: originalUid,
      email,
      displayName: displayName || guestDisplayName || "",
      type: "member",
      deviceId: deviceId || "",
      subscription: { planType: existingPlanType, updatedAt: now },
      createdAt: recoveredCreatedAt || admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: now,
    };
    // Store previousGuestUid so getMemberSuites can redirect and find orphaned suites
    if (previousGuestUid && previousGuestUid !== uid) {
      profileData.previousGuestUid = previousGuestUid;
      console.log(`[linkGoogleAccount] storing previousGuestUid=${previousGuestUid} in memberProfiles for suite redirect`);
    }
    await profileRef.set(profileData, { merge: true });

    // Create session doc so multi-device conflict detection works immediately
    try {
      const sessionTier = existingProfile.exists
        ? (existingProfile.data().subscription?.planType === "pro" ? "pro" : "core")
        : "core";
      const sessionRef = db
        .collection("memberData").doc(sessionTier)
        .collection(originalUid).doc("_session");
      await sessionRef.set({
        deviceId: deviceId || "",
        lastActive: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log("warn", `linkGoogleAccount: failed to create _session for ${originalUid}`, { error: e.message });
    }
  }

  return { success: true };
});

// ------------------------------------------------------------------
// DELETE ACCOUNT (with cooldown for Google accounts)
// ------------------------------------------------------------------
exports.deleteAccount = onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  if (!checkRateLimit(`deleteAccount_${uid}`, 2)) {
    throw new functions.https.HttpsError("resource-exhausted", "Rate limited");
  }
  const { deviceId, email } = data;
  const batch = db.batch();
  const profile = await _getMemberProfileByUid(uid);
  const isMember = !!profile;
  if (isMember) {
    if (email) {
      const cooldownRef = db
        .collection("emailCooldown")
        .doc(email);
      batch.set(cooldownRef, {
        uid,
        email,
        expires: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + COOLDOWN_HOURS * 60 * 60 * 1000),
        ),
        reason: "account_deleted",
      });
      // Preserve original data in memberProfiles so re-registration recovers the join date
      batch.set(db.collection("memberProfiles").doc(email), {
        uid,
        email,
        type: "member",
        createdAt: profile.data.createdAt || admin.firestore.FieldValue.serverTimestamp(),
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
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
  const usageDelete = isMember && profile.data.email
    ? db.collection("usage").doc(profile.data.email)
    : db.collection("usage").doc(uid);
  batch.delete(usageDelete);
  batch.delete(db.collection("the_qag_registry").doc(uid));
  // deviceUsage/{deviceId} is NOT deleted — it carries the device's daily quota
  // across account resets. This prevents quota abuse via delete-recreate.
  const userEmail = email || context.auth.token.email;
  const reports = userEmail
    ? await Promise.all([
        db.collection("issue_reports").doc("open").collection(userEmail).get(),
        db.collection("issue_reports").doc("working").collection(userEmail).get(),
        db.collection("issue_reports").doc("fixed").collection(userEmail).get(),
      ]).then(([o, w, f]) => [...o.docs, ...w.docs, ...f.docs])
    : [];
  reports.forEach((doc) =>
    batch.update(doc.ref, { uid: "deleted_member" }),
  );
  await batch.commit();

  // Clean up synced suites under memberData/{tier}/{uid}/{date}/suites/{serial}
  try {
    const tier = await _getMemberTier(uid);
    const suiteBatch = db.batch();
    const gcsPromises = [];

    // New path: memberData/{tier}/{uid}/{date}/suites/{serial}
    const uidDocRef = db.collection("memberData").doc(tier).collection(uid);
    const dateDocs = await uidDocRef.get();
    for (const dateDoc of dateDocs.docs) {
      const suitesSnap = await dateDoc.ref.collection("suites").get();
      for (const suiteDoc of suitesSnap.docs) {
        suiteBatch.delete(suiteDoc.ref);
        gcsPromises.push(
          bucket.file(`memberData/${tier}/${uid}/${dateDoc.id}/suites/${suiteDoc.id}.json`)
            .delete().catch(() => {}),
        );
      }
    }

    // Legacy path: memberData/{uid}/dates/{date}/suites/{serial} (pre-tier restructure)
    const legacyColRef = db.collection("memberData").doc(uid).collection("dates");
    const legacyDateDocs = await legacyColRef.get();
    for (const dateDoc of legacyDateDocs.docs) {
      const suitesSnap = await dateDoc.ref.collection("suites").get();
      for (const suiteDoc of suitesSnap.docs) {
        suiteBatch.delete(suiteDoc.ref);
      }
    }

    await suiteBatch.commit();
    await Promise.all(gcsPromises);
  } catch (e) {
    log("warn", `deleteAccount: suite cleanup failed for ${uid}`, { error: e.message });
  }

  await admin.auth().deleteUser(uid);
  return { success: true };
});

// ------------------------------------------------------------------
// SUBMIT ISSUE REPORT
// ------------------------------------------------------------------
exports.submitIssueReport = onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  if (!checkRateLimit(`submitIssue_${context.auth.uid}`, 5)) {
    throw new functions.https.HttpsError("resource-exhausted", "Rate limited");
  }
  const email = context.auth.token.email;
  if (!email)
    throw new functions.https.HttpsError("failed-precondition", "Email required");
  const { issueType, title, description, platform, deviceModel, appVersion, screen } = data;
  const uid = context.auth.uid;

  // Atomically get next serial in open (per-status sequential)
  const counterRef = db.collection("issue_reports").doc("_counters");
  const serial = await db.runTransaction(async (t) => {
    const snap = await t.get(counterRef);
    const current = snap.exists && typeof snap.data().openMax === "number" ? snap.data().openMax : 0;
    const next = current + 1;
    t.set(counterRef, {
      openMax: next,
      openCount: admin.firestore.FieldValue.increment(1),
    }, { merge: true });
    return next;
  });

  const docData = {
    uid,
    email,
    issueType: issueType || "Bug",
    title: title || "",
    description: description || "",
    platform: platform || null,
    deviceModel: deviceModel || null,
    appVersion: appVersion || null,
    screen: screen || "unknown",
    status: "open",
    serial,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const serialStr = String(serial);
  await db.collection("issue_reports").doc("open").collection(email).doc(serialStr).set(docData);

  return { success: true, id: serialStr };
});

// ------------------------------------------------------------------
// GET MY ISSUE REPORTS
// ------------------------------------------------------------------
exports.getMyIssueReports = onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  const email = context.auth.token.email;
  if (!email)
    throw new functions.https.HttpsError("failed-precondition", "Email required");

  const counterRef = db.collection("issue_reports").doc("_counters");

  // Migrate old-format reports (flat issue_reports/{id}) to new path
  const oldSnap = await db.collection("issue_reports")
    .where("uid", "==", uid)
    .limit(50)
    .get();
  if (!oldSnap.empty) {
    for (const doc of oldSnap.docs) {
      const data = doc.data();
      const status = data.status === "fixed" ? "fixed" : data.status === "working" ? "working" : "open";
      await db
        .collection("issue_reports")
        .doc(status)
        .collection(email)
        .add({
          uid,
          email,
          issueType: data.issueType || "Bug",
          title: data.title || "",
          description: data.description || "",
          platform: data.platform || null,
          deviceModel: data.deviceModel || null,
          appVersion: data.appVersion || null,
          screen: data.screen || "unknown",
          status: data.status || "open",
          createdAt: data.createdAt || admin.firestore.FieldValue.serverTimestamp(),
        });
      await doc.ref.delete();
    }
  }

  // Migrate fixea-path docs to correct status subcollection with new serial
  const fixeaSnap = await db.collection("issue_reports").doc("fixea").collection(email).get();
  if (!fixeaSnap.empty) {
    for (const doc of fixeaSnap.docs) {
      const d = doc.data();
      const targetStatus = ["open", "working", "fixed"].includes(d.status) ? d.status : "open";
      const newSerial = await db.runTransaction(async (t) => {
        const counterSnap = await t.get(counterRef);
        const c = counterSnap.data() || {};
        const nextMax = (c[targetStatus + "Max"] || 0) + 1;
        const destRef = db.collection("issue_reports").doc(targetStatus).collection(email).doc(String(nextMax));
        t.set(destRef, { ...d, status: targetStatus, serial: nextMax });
        t.set(counterRef, {
          [targetStatus + "Max"]: nextMax,
          [targetStatus + "Count"]: (c[targetStatus + "Count"] || 0) + 1,
        }, { merge: true });
        return nextMax;
      });
      await doc.ref.delete();
    }
  }

  // Query new-format reports by email per status subcollection.
  // No collectionGroup needed — avoids requiring composite indexes.
  const statuses = ["open", "working", "fixed"];
  const reports = [];

  for (const status of statuses) {
    const snap = await db.collection("issue_reports")
      .doc(status)
      .collection(email)
      .where("uid", "==", uid)
      .get();
    for (const doc of snap.docs) {
      reports.push({ id: doc.id, ...doc.data() });
    }
  }

  // Sort descending by createdAt (no server-side orderBy to keep queries simple)
  reports.sort((a, b) => {
    const aTime = a.createdAt?.toMillis ? a.createdAt.toMillis() : 0;
    const bTime = b.createdAt?.toMillis ? b.createdAt.toMillis() : 0;
    return bTime - aTime;
  });
  return { reports };
});

// ------------------------------------------------------------------
// UPDATE ISSUE REPORT STATUS (admin callable — use from Functions Test tab)
// ------------------------------------------------------------------
exports.updateIssueReportStatus = onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  if (!checkRateLimit(`updateIssueStatus_${context.auth.uid}`, 10)) {
    throw new functions.https.HttpsError("resource-exhausted", "Rate limited");
  }

  const { email, serial, newStatus } = data;
  if (!email || !serial || !newStatus)
    throw new functions.https.HttpsError("invalid-argument", "email, serial, and newStatus required");
  if (!["open", "working", "fixed"].includes(newStatus))
    throw new functions.https.HttpsError("invalid-argument", "newStatus must be one of: open, working, fixed");

  // Find the doc across all 3 status subcollections
  const statuses = ["open", "working", "fixed"];
  let foundRef = null;
  let foundStatus = null;

  for (const s of statuses) {
    const ref = db.collection("issue_reports").doc(s).collection(email).doc(serial);
    const snap = await ref.get();
    if (snap.exists) {
      foundRef = ref;
      foundStatus = s;
      break;
    }
  }

  if (!foundRef)
    throw new functions.https.HttpsError("not-found", `Report ${serial} for ${email} not found in any status`);

  if (foundStatus === newStatus)
    return { success: true, message: `Already ${newStatus}` };

  // Atomically: assign new serial (per-status), move doc, update counters
  const counterRef = db.collection("issue_reports").doc("_counters");
  const newSerial = await db.runTransaction(async (t) => {
    const snap = await t.get(foundRef);
    if (!snap.exists) throw new functions.https.HttpsError("not-found", "Report deleted before move");

    const counterSnap = await t.get(counterRef);
    const c = counterSnap.data() || {};
    const nextMax = (c[newStatus + "Max"] || 0) + 1;

    const destRef = db.collection("issue_reports").doc(newStatus).collection(email).doc(String(nextMax));
    t.set(destRef, { ...snap.data(), status: newStatus, serial: nextMax });
    t.delete(foundRef);
    t.set(counterRef, {
      [foundStatus + "Count"]: Math.max(0, (c[foundStatus + "Count"] || 1) - 1),
      [newStatus + "Count"]: (c[newStatus + "Count"] || 0) + 1,
      [newStatus + "Max"]: nextMax,
    }, { merge: true });

    return nextMax;
  });

  return { success: true, serial: newSerial, newStatus };
});

// ------------------------------------------------------------------
// MOVE ISSUE ON STATUS CHANGE (Firestore trigger)
// Validates status — invalid values (e.g. "fixea") are IGNORED, not moved.
// ------------------------------------------------------------------
exports.moveIssueOnStatusChange = functions.firestore
  .document("issue_reports/{status}/{email}/{serial}")
  .onWrite(async (change, context) => {
    const after = change.after.data();
    if (!after) return;

    const { status: pathStatus, email, serial } = context.params;
    if (pathStatus === "_counters" || pathStatus === "fixea") return;

    const newStatus = after.status;
    if (!["open", "working", "fixed"].includes(newStatus)) return;
    if (newStatus === pathStatus) return;

    const counterRef = db.collection("issue_reports").doc("_counters");

    const data = after;

    await db.runTransaction(async (t) => {
      const counterSnap = await t.get(counterRef);
      const c = counterSnap.data() || {};
      const nextMax = (c[newStatus + "Max"] || 0) + 1;

      const destRef = db.collection("issue_reports").doc(newStatus).collection(email).doc(String(nextMax));
      t.set(destRef, { ...data, status: newStatus, serial: nextMax });
      t.delete(change.after.ref);

      t.set(counterRef, {
        [pathStatus + "Count"]: Math.max(0, (c[pathStatus + "Count"] || 1) - 1),
        [newStatus + "Count"]: (c[newStatus + "Count"] || 0) + 1,
        [newStatus + "Max"]: nextMax,
      }, { merge: true });
    });
  });

// ------------------------------------------------------------------
// RECORD UPDATE DISMISSAL
// ------------------------------------------------------------------
exports.recordUpdateDismissal = onCall(async (data, context) => {
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
const SYSTEM_PROMPT = `You are a QA test case generator. Generate professional, realistic, execution-ready test cases for the given module, feature, and platform.

Output a JSON object with a single key "testCases" containing an array of test case objects.

Each test case object MUST have:
- id (string)
- title (string, descriptive and specific)
- module (string)
- feature (string)
- platform (string)
- preconditions (array of strings)
- testData (string, realistic input data — use concise symbolic values like password_min_len, valid_email_1, rate_limit_1000ms)
- steps (array of objects with action/data/expected)
- expectedResult (string, measurable outcome)
- priority ("High", "Medium", or "Low")
- type ("POSITIVE", "NEGATIVE", "BOUNDARY", "SECURITY", "VALIDATION", or "SESSION")
- categoryLock (string)
- intent_id (string)

PRIORITY GUIDELINES:
- High: Security, authentication, payment, session, critical business flows
- Medium: Validation, boundary, retry, data integrity
- Low: Positive UI flows, cosmetic, informational

PLATFORM GUIDELINES:
- WEB: Use browser/UI terminology (page, element, navigation)
- MOBILE: Use mobile/app terminology (screen, tap, swipe, device)
- API: Use request/response terminology (endpoint, status code, schema)

QUALITY RULES:
- Use realistic data, observable actions, measurable expected results
- Use senior QA terminology
- Vary titles, steps, and expected results across cases
- Semantic duplicates are not allowed
- No generic phrases like "works correctly" or "as expected"
- No markdown, no explanations, no code blocks
- Each test case must be unique and execution-ready`;

function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function callDeepSeek(prompt) {
  const DEEPSEEK_API_KEY = process.env.DEEPSEEK_API_KEY;
  const url = "https://api.deepseek.com/v1/chat/completions";
  const MAX_RETRIES = 2;
  let lastError = null;

  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 55000);
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
      if (!res.ok) {
        const code = `HTTP_${res.status}`;
        if (attempt < MAX_RETRIES && [429, 502, 503].includes(res.status)) {
          lastError = { success: false, error: { code } };
          await delay(Math.pow(2, attempt - 1) * 1000);
          continue;
        }
        return { success: false, error: { code } };
      }

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
        // Timeout: DeepSeek already received & processed tokens → DO NOT RETRY (double bill)
        return { success: false, error: { code: "TIMEOUT" } };
      }
      return { success: false, error: { code: "CLIENT_ERROR" } };
    }
  }
  return lastError || { success: false, error: { code: "MAX_RETRIES" } };
}

// --------------------------------------------------------------
// Push a suite under memberData/{tier}/{uid}/{date}/suites/{serialNumber}
// Cases go to GCS (best-effort), metadata always persists to Firestore.
// --------------------------------------------------------------
exports.pushMemberSuite = onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  const { suiteData, date, serialNumber } = data;
  if (!suiteData || !date)
    throw new functions.https.HttpsError("invalid-argument", "date and suiteData required");
  if (!checkRateLimit(`pushSuite_${uid}`, 30)) {
    throw new functions.https.HttpsError("resource-exhausted", "Rate limited");
  }

  const { cases, platform, title, ...metadata } = suiteData;
  metadata.uid = uid;
  metadata.date = date;

  const tier = await _getMemberTier(uid);

  // Determine serialNumber: if re-syncing, reuse existing; else atomically generate
  let serialStr = serialNumber;
  if (!serialStr) {
    await db.runTransaction(async (t) => {
      const counterRef = db
        .collection("memberData").doc(tier)
        .collection(uid).doc("_counter_suites");
      const counterDoc = await t.get(counterRef);
      const next = (counterDoc.exists ? counterDoc.data().value : 0) + 1;
      t.set(counterRef, { value: next });
      serialStr = String(next);
    });
  } else {
    // Client-provided serialNumber: verify suite belongs to this uid or is new
    const existingMeta = await dateRef.collection("suites").doc(serialStr).get();
    if (existingMeta.exists && existingMeta.data().uid !== uid) {
      throw new functions.https.HttpsError("permission-denied", "Serial number belongs to another user");
    }
  }

  const dateRef = db
    .collection("memberData").doc(tier)
    .collection(uid).doc(date);
  const suiteRef = dateRef.collection("suites").doc(serialStr);

  // Write cases to GCS (best-effort — metadata always saves)
  let gcsError = null;
  if (Array.isArray(cases) && cases.length > 0) {
    try {
      const gzipped = zlib.gzipSync(JSON.stringify(cases));
      await bucket
        .file(`memberData/${tier}/${uid}/${date}/suites/${serialStr}.json`)
        .save(gzipped, {
          metadata: { contentType: "application/json", contentEncoding: "gzip" },
        });
    } catch (e) {
      gcsError = e.message;
      log("error", `pushMemberSuite: GCS write failed for ${uid}/${date}/${serialStr}`, { error: e.message });
    }
  }

  // Write metadata to Firestore; also ensure the date doc exists for retrieval
  await Promise.all([
    suiteRef.set(metadata),
    dateRef.set({ uid, date, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true }),
  ]);
  return { success: true, serialNumber: serialStr, gcsError };
});

// --------------------------------------------------------------
// Helper: read all suite docs under memberData/{tier}/{uid}
// Iterates {date}/suites (no collectionGroup index needed).
// --------------------------------------------------------------
async function _getMemberSuites(uid, tier) {
  const suites = [];
  const uidColRef = db.collection("memberData").doc(tier).collection(uid);
  const dateDocs = await uidColRef.get();
  for (const dateDoc of dateDocs.docs) {
    if (dateDoc.id.startsWith("_")) continue; // skip counter docs
    const suitesSnap = await dateDoc.ref.collection("suites").get();
    for (const suiteDoc of suitesSnap.docs) {
      suites.push({
        _date: dateDoc.id,
        _serial: suiteDoc.id,
        ...suiteDoc.data(),
      });
    }
  }
  return suites;
}

// --------------------------------------------------------------
// Get all synced suites: metadata from Firestore, cases from GCS.
// Uses memberData/{tier}/{uid}/{date}/suites/{serialNumber}.
// --------------------------------------------------------------
exports.getMemberSuites = onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  if (!checkRateLimit(`getSuites_${uid}`, 10)) {
    throw new functions.https.HttpsError("resource-exhausted", "Rate limited");
  }
  try {
    let effectiveUid = uid;
    const initialTier = await _getMemberTier(effectiveUid);
    let tier = initialTier;
    let suites = await _getMemberSuites(effectiveUid, tier);

    // UID redirect via memberProfiles if no suites found (handles reinstall)
    if (suites.length === 0) {
      const email = context.auth.token?.email;
      if (email) {
        const profileDoc = await db.collection("memberProfiles").doc(email).get();
        if (profileDoc.exists) {
          const profileData = profileDoc.data();
          if (profileData.uid && profileData.uid !== uid) {
            effectiveUid = profileData.uid;
            tier = await _getMemberTier(effectiveUid);
            log("info", `getMemberSuites: redirecting from ${uid} to profile uid ${effectiveUid} (email ${email})`);
            suites = await _getMemberSuites(effectiveUid, tier);
          }
          if (suites.length === 0 && profileData.previousGuestUid && profileData.previousGuestUid !== effectiveUid) {
            effectiveUid = profileData.previousGuestUid;
            tier = await _getMemberTier(effectiveUid);
            log("info", `getMemberSuites: redirecting from ${uid} to previousGuestUid ${effectiveUid} (email ${email})`);
            suites = await _getMemberSuites(effectiveUid, tier);
          }
        }
      }
    }

    const result = await Promise.all(suites.map(async (s) => {
      let cases = [];
      try {
        const [content] = await bucket
          .file(`memberData/${tier}/${effectiveUid}/${s._date}/suites/${s._serial}.json`)
          .download();
        const raw = content.toString();
        // GCS auto-decompresses when contentEncoding:gzip is set
        cases = JSON.parse(raw);
      } catch (e) {
        log("warn", `GCS read failed for suite ${s._serial}: ${e.message || e}`, { uid: effectiveUid, date: s._date });
      }
      const suiteId = `${s._date}/${s._serial}`;
      return { suiteId, ...s, cases };
    }));

    return { success: true, suites: result };
  } catch (e) {
    return { success: false, error: e.message, suites: [] };
  }
});

// --------------------------------------------------------------
// Delete a suite: Firestore metadata + GCS cases.
// suiteId format: "date/serialNumber"
// --------------------------------------------------------------
exports.deleteMemberSuite = onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  const { suiteId } = data;
  if (!suiteId)
    throw new functions.https.HttpsError("invalid-argument", "suiteId required");
  try {
    const parts = suiteId.split('/');
    if (parts.length !== 2)
      throw new functions.https.HttpsError("invalid-argument", "suiteId must be in format 'date/serialNumber'");
    const [date, serial] = parts;

    // Resolve effectiveUid (try current uid, then redirect via memberProfiles)
    let effectiveUid = uid;
    const email = context.auth.token?.email;
    if (email) {
      const profileDoc = await db.collection("memberProfiles").doc(email).get();
      if (profileDoc.exists) {
        const profileData = profileDoc.data();
        if (profileData.uid && profileData.uid !== uid) {
          effectiveUid = profileData.uid;
        } else if (profileData.previousGuestUid && profileData.previousGuestUid !== uid) {
          effectiveUid = profileData.previousGuestUid;
        }
      }
    }

    const tier = await _getMemberTier(effectiveUid);
    const uidDocRef = db.collection("memberData").doc(tier).collection(effectiveUid);

    await uidDocRef.doc(date).collection("suites").doc(serial).delete();

    try {
      await bucket.file(`memberData/${tier}/${effectiveUid}/${date}/suites/${serial}.json`).delete();
    } catch (_) {}

    return { success: true };
  } catch (e) {
    return { success: false, error: e.message };
  }
});

function transformTestCases(rawCases, module, feature, platform, limit) {
  return rawCases.slice(0, limit).map((tc, i) => ({
    id: `TC_${module.replace(/ /g, "").toUpperCase()}_${(i + 1).toString().padStart(3, "0")}`,
    title: tc.title || "Test Case",
    preconditions: Array.isArray(tc.preconditions) ? tc.preconditions : [],
    testData: tc.testData || '',
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
