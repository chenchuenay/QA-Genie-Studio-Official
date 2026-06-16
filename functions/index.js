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

const CORE_CASES_PER_BATCH = 10;
const PRO_CASES_PER_BATCH = 20;

const CORE_EXPORT_LIMIT_PER_DAY = 50; // Core: 50 exports per day
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

// ------------------------------------------------------------------
// GENERATION (uses central constants)
// ------------------------------------------------------------------
exports.generate = functions
  .runWith({ secrets: ["DEEPSEEK_API_KEY"], timeoutSeconds: 120 })
  .https.onCall(async (data, context) => {
    if (!context.auth)
      return { success: false, error: { code: "UNAUTHENTICATED" } };
    const { module, feature, platform, adToken, prompt, deviceId, requestId } =
      data;
    if (!requestId)
      throw new functions.https.HttpsError(
        "invalid-argument",
        "requestId required",
      );
    const uid = context.auth.uid;
    const nowStr = today();

    // Verify ad token if provided (MATCH PATH WITH verifyRewardAd)
    if (adToken) {
      const tokenDoc = await db.collection("usage").doc(uid).collection("usedRewards").doc(adToken).get();
      if (!tokenDoc.exists)
        return { success: false, error: { code: "INVALID_AD_TOKEN" } };
    }

    try {
      const uRef = db.collection("usage").doc(uid);
      const gRef = db.collection("analytics").doc("global");
      const reqRef = db.collection("processed_requests").doc(requestId);
      const userRef = db.collection("users").doc(uid);
      const guestRef = db.collection("guests").doc(uid);
      const deviceRef = db.collection("deviceUsage").doc(deviceId);

      const generationData = await db.runTransaction(async (t) => {
        const [uDoc, gDoc, reqDoc, userDoc, guestDoc, deviceDoc] =
          await Promise.all([
            t.get(uRef),
            t.get(gRef),
            t.get(reqRef),
            t.get(userRef),
            t.get(guestRef),
            t.get(deviceRef),
          ]);
        if (reqDoc.exists) throw new Error("ALREADY_PROCESSED");

        let isPro = false,
          isGuest = false;
        if (userDoc.exists)
          isPro = userDoc.data()?.subscription?.planType === "pro";
        else if (guestDoc.exists) isGuest = true;
        else isGuest = true; // fallback

        // Quota check
        let allowed = false;
        let coreFreeCount = 0,
          rewardedCount = 0,
          proFreeCount = 0;
        if (!isGuest) {
          let metrics = uDoc.exists ? uDoc.data().metrics : {};
          if (metrics.lastReset !== nowStr) {
            metrics.coreFreeGenCount = 0;
            metrics.rewardedGenCount = 0;
            metrics.proFreeGenCount = 0;
            metrics.lastReset = nowStr;
          }
          coreFreeCount = metrics.coreFreeGenCount || 0;
          rewardedCount = metrics.rewardedGenCount || 0;
          proFreeCount = metrics.proFreeGenCount || 0;
          if (isPro) allowed = proFreeCount < PRO_FREE_BATCHES_PER_DAY;
          else
            allowed = adToken && rewardedCount < CORE_REWARDED_BATCHES_PER_DAY;
          if (!allowed)
            throw new Error(`LIMIT_REACHED|${getMsUntilReset()}`);
        } else {
          // Guest: only rewarded ads
          let devData = deviceDoc.exists
            ? deviceDoc.data()
            : { rewardedGenCount: 0, lastReset: nowStr, uid };
          if (devData.lastReset !== nowStr) devData.rewardedGenCount = 0;
          rewardedCount = devData.rewardedGenCount || 0;
          if (!adToken) throw new Error("REWARDED_AD_REQUIRED");
          allowed = rewardedCount < CORE_REWARDED_BATCHES_PER_DAY;
          if (!allowed) throw new Error(`LIMIT_REACHED|${getMsUntilReset()}`);
        }

        const caseCount = isPro ? PRO_CASES_PER_BATCH : CORE_CASES_PER_BATCH;
        // Increment counters
        if (!isGuest) {
          let metrics = uDoc.exists ? uDoc.data().metrics : {};
          if (isPro)
            metrics.proFreeGenCount = (metrics.proFreeGenCount || 0) + 1;
          else if (adToken)
            metrics.rewardedGenCount = (metrics.rewardedGenCount || 0) + 1;
          metrics.lifetimeGeneratedCases =
            (metrics.lifetimeGeneratedCases || 0) + caseCount;
          metrics.lastReset = nowStr;
          t.set(uRef, { metrics }, { merge: true });
        } else {
          let devData = deviceDoc.exists
            ? deviceDoc.data()
            : { rewardedGenCount: 0, lastReset: nowStr, uid };
          devData.rewardedGenCount = (devData.rewardedGenCount || 0) + 1;
          devData.lastReset = nowStr;
          devData.uid = uid;
          t.set(deviceRef, devData, { merge: true });
          let guestMetrics = uDoc.exists ? uDoc.data().metrics : {};
          guestMetrics.lifetimeGeneratedCases =
            (guestMetrics.lifetimeGeneratedCases || 0) + caseCount;
          t.set(uRef, { metrics: guestMetrics }, { merge: true });
        }

        t.set(reqRef, {
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        t.update(gRef, {
          totalGenerations: admin.firestore.FieldValue.increment(1),
          totalTestCaseGenerated:
            admin.firestore.FieldValue.increment(caseCount),
          [isPro ? "proGeneratedCases" : "coreGeneratedCases"]:
            admin.firestore.FieldValue.increment(caseCount),
        });
        return { isPro, caseCount };
      });

      const aiResult = await callDeepSeek(prompt);
      if (!aiResult.success) throw new Error(aiResult.error.code);
      
      let text = aiResult.data.text.trim();
      // ROBUST PARSING: Strip markdown blocks if present
      if (text.startsWith("```")) {
        text = text.replace(/^```[a-z]*\n/i, "").replace(/\n```$/i, "");
      }
      
      const cases = JSON.parse(text);
      return {
        success: true,
        data: {
          testCases: transformTestCases(
            cases,
            module,
            feature,
            platform || "Web",
            generationData.caseCount,
          ),
        },
      };
    } catch (err) {
      if (
        !["ALREADY_PROCESSED", "LIMIT_REACHED", "PRO_LIMIT_REACHED"].includes(
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
  const { summary, target, extension, exportType } = data;
  const type = exportType || target || (summary ? "summary" : "unknown");
  const ext = extension || (target === "pdf" ? "pdf" : target);
  const nowStr = today();

  const userDoc = await db.collection("users").doc(uid).get();
  const guestDoc = await db.collection("guests").doc(uid).get();
  const isPro =
    userDoc.exists && userDoc.data()?.subscription?.planType === "pro";
  const isGuest = guestDoc.exists;

  if (!isPro && !isGuest) {
    // Core user – check daily export limit
    const usageDoc = await db.collection("usage").doc(uid).get();
    let metrics = usageDoc.exists ? usageDoc.data().metrics : {};
    if (metrics.lastReset !== nowStr) metrics.exportCount = 0;
    const exportCount = metrics.exportCount || 0;
    if (exportCount >= CORE_EXPORT_LIMIT_PER_DAY) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "Daily export limit reached",
      );
    }
    await db
      .collection("usage")
      .doc(uid)
      .set(
        {
          metrics: {
            exportCount: admin.firestore.FieldValue.increment(1),
            lastReset: nowStr,
          },
        },
        { merge: true },
      );
  }

  await db
    .collection("usage")
    .doc(uid)
    .set(
      {
        exports: {
          lifetimeExports: admin.firestore.FieldValue.increment(1),
          [`exportTargets.${type}`]: admin.firestore.FieldValue.increment(1),
          [`fileExtensions.${ext}`]: admin.firestore.FieldValue.increment(1),
        },
      },
      { merge: true },
    );

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
exports.trackRating = functions.https.onCall(async (data) => {
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
// ANALYTICS & MONITORING (REQUIRED BY CLIENT)
// ------------------------------------------------------------------
exports.trackGeneration = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new Error("UNAUTHENTICATED");
  return { success: true }; // Analytics handled server-side in 'generate'
});

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
exports.getOrCreateGuestToken = functions.https.onCall(async (data) => {
  const { deviceId } = data;
  if (!deviceId)
    throw new functions.https.HttpsError(
      "invalid-argument",
      "deviceId required",
    );
  const mappingRef = db.collection("deviceGuestMapping").doc(deviceId);
  const mappingDoc = await mappingRef.get();
  let guestUid;
  let isNew = false;
  if (mappingDoc.exists) {
    guestUid = mappingDoc.data().guestUid;
    const guestDoc = await db.collection("guests").doc(guestUid).get();
    if (!guestDoc.exists) isNew = true;
  } else isNew = true;

  if (isNew) {
    guestUid = `guest_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const registryNumber = await getNextRegistryNumber();
    const displayName = `Guest${registryNumber}`;
    await db
      .collection("guests")
      .doc(guestUid)
      .set({
        identity: {
          uid: guestUid,
          displayName,
          type: "guest",
          deviceId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      });
    await db
      .collection("usage")
      .doc(guestUid)
      .set({ metrics: { lifetimeGeneratedCases: 0, lifetimeExports: 0 } });
    await db.collection("the_qag_registry").doc(guestUid).set({
      uid: guestUid,
      type: "guest",
      displayName,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await mappingRef.set({
      guestUid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  const customToken = await admin.auth().createCustomToken(guestUid);
  return { token: customToken, isNew };
});

// ------------------------------------------------------------------
// GET GUEST NAME (legacy, kept for compatibility)
// ------------------------------------------------------------------
exports.getGuestName = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  const guestRef = db.collection("guests").doc(uid);
  const doc = await guestRef.get();
  if (doc.exists && doc.data()?.identity?.displayName)
    return { name: doc.data().identity.displayName, isExisting: true };
  const registryNumber = await getNextRegistryNumber();
  const guestName = `Guest${registryNumber}`;
  await guestRef.set({
    identity: {
      uid,
      displayName: guestName,
      type: "guest",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
  });
  return { name: guestName, isExisting: false };
});

// ------------------------------------------------------------------
// GET USER DASHBOARD
// ------------------------------------------------------------------
exports.getUserDashboard = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  const [idDoc, usageDoc] = await Promise.all([
    db
      .collection(data.type === "guest" ? "guests" : "users")
      .doc(uid)
      .get(),
    db.collection("usage").doc(uid).get(),
  ]);
  return {
    identity: idDoc.exists ? idDoc.data().identity : null,
    metrics: usageDoc.exists ? usageDoc.data().metrics : null,
    exports: usageDoc.exists ? usageDoc.data().exports : null,
  };
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
          isPro,
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
    if (afterRewardedAd) {
      allowed = rewarded < CORE_REWARDED_BATCHES_PER_DAY;
      remaining = CORE_REWARDED_BATCHES_PER_DAY - rewarded;
    } else allowed = false;
  }
  return { allowed, remaining };
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
  const usedRewardsRef = db
    .collection("usage")
    .doc(uid)
    .collection("usedRewards")
    .doc(adTransactionId);
  const usedDoc = await usedRewardsRef.get();
  if (usedDoc.exists) return { verified: false, reason: "Token already used" };
  await usedRewardsRef.set({
    usedAt: admin.firestore.FieldValue.serverTimestamp(),
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
  const { email, displayName, deviceId } = data;
  // Cooldown check
  const cooldownRef = db
    .collection("deviceCooldown")
    .doc(`${deviceId}_${email}`);
  const cooldownDoc = await cooldownRef.get();
  if (cooldownDoc.exists && cooldownDoc.data().expires.toDate() > new Date()) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Account in cooldown",
    );
  } else if (cooldownDoc.exists) await cooldownRef.delete();

  const guestRef = db.collection("guests").doc(uid);
  const guestDoc = await guestRef.get();
  const isUpgrade = guestDoc.exists;

  if (isUpgrade) {
    const usageRef = db.collection("usage").doc(uid);
    const deviceUsageRef = db.collection("deviceUsage").doc(deviceId);
    await db.runTransaction(async (t) => {
      const usageDoc = await t.get(usageRef);
      const deviceDoc = await t.get(deviceUsageRef);
      let usageMetrics = usageDoc.exists ? usageDoc.data().metrics : {};
      const deviceRewarded = deviceDoc.exists
        ? deviceDoc.data().rewardedGenCount
        : 0;
      const nowStr = today();
      if (deviceRewarded > 0 && usageMetrics.lastReset !== nowStr) {
        usageMetrics.rewardedGenCount = deviceRewarded;
        usageMetrics.lastReset = nowStr;
      }
      t.set(usageRef, { metrics: usageMetrics }, { merge: true });
      t.delete(guestRef);
    });
    await db.collection("the_qag_registry").doc(uid).set(
      {
        type: "user",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  const userRef = db.collection("users").doc(uid);
  const userDoc = await userRef.get();
  const now = admin.firestore.FieldValue.serverTimestamp();
  const identity = {
    uid,
    email,
    displayName:
      displayName || (isUpgrade ? guestDoc.data().identity.displayName : ""),
    type: "user",
    deviceId: deviceId || "",
    createdAt: userDoc.exists
      ? userDoc.data()?.identity?.createdAt || now
      : now,
  };
  await userRef.set(
    {
      identity,
      subscription: { isPro: false, planType: "core", updatedAt: now },
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
  const { deviceId, email } = data;
  const batch = db.batch();
  const userDoc = await db.collection("users").doc(uid).get();
  const isUser = userDoc.exists;
  if (isUser) {
    batch.delete(userDoc.ref);
    if (email && deviceId) {
      const cooldownRef = db
        .collection("deviceCooldown")
        .doc(`${deviceId}_${email}`);
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
    await db.collection("deviceGuestMapping").doc(deviceId).delete();
  }
  batch.delete(db.collection("usage").doc(uid));
  batch.delete(db.collection("the_qag_registry").doc(uid));
  const reports = await db
    .collection("issue_reports")
    .where("uid", "==", uid)
    .get();
  reports.forEach((doc) =>
    batch.update(doc.ref, { uid: "deleted_user", displayName: "Deleted User" }),
  );
  await batch.commit();
  await admin.auth().deleteUser(uid);
  return { success: true };
});

// ------------------------------------------------------------------
// HELPER: CALL DEEPSEEK
// ------------------------------------------------------------------
async function callDeepSeek(prompt) {
  const DEEPSEEK_API_KEY = process.env.DEEPSEEK_API_KEY;
  const url = "https://api.deepseek.com/v1/chat/completions";
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${DEEPSEEK_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "deepseek-chat",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.2,
      }),
    });
    const json = await res.json();
    if (!res.ok)
      return { success: false, error: { code: `HTTP_${res.status}` } };
    return { success: true, data: { text: json.choices[0].message.content } };
  } catch (err) {
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
