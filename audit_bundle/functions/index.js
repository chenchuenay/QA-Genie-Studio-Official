const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();
const db = admin.firestore();

// ------------------------------------------------------------------
// CONFIGURATION
// ------------------------------------------------------------------
const FORCE_BYPASS = false;
const REWARDED_GEN_LIMIT = 6;
const PRO_GEN_LIMIT = 15;
const FREE_GEN_LIMIT = 0; // Core: zero free generations
const REWARDED_EXPORT_LIMIT = 50;
const PRO_EXPORT_LIMIT = 100;

// UID allowlist for debug operations
const DEBUG_UIDS = [
  "0YbG4twHa3PQFEdasCgmImdYVfe2",
  "mLpeoHRXA5b8z7AwKhVc0kPWGv03",
];

function isDebugUser(uid) {
  return DEBUG_UIDS.includes(uid);
}

// ------------------------------------------------------------------
// Helper functions
// ------------------------------------------------------------------
function today() {
  return new Date().toISOString().split("T")[0];
}

function generateRequestId() {
  return `req_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;
}

async function getUsage(uid) {
  const doc = await db.collection("usage").doc(uid).get();
  if (!doc.exists) {
    return {
      genCount: 0,
      rewardedGenCount: 0,
      exportCount: 0,
      rewardedExportCount: 0,
      lastReset: today(),
      isPro: false,
      lastAdToken: null,
      proInterestCount: 0,
      firstProInterestAt: null,
      lastProInterestAt: null,
      proInterestSources: { proTab: 0, generationLimit: 0, exportLimit: 0 },
      lifetimeGeneratedCases: 0,
      lifetimeExports: 0,
      aiFailureFallbackCount: 0,
      validatorRejectedCount: 0,
      exportTargets: { excel: 0, jira: 0, xray: 0, pdf: 0 },
      fileExtensions: { xlsx: 0, csv: 0, json: 0, pdf: 0 },
      lifetimeTestCasesGenerated: 0,
      firstGenerationAt: null,
      lastGenerationAt: null,
      firstExportAt: null,
      lastExportAt: null,
      lastActiveAt: null,
    };
  }
  const data = doc.data();
  return {
    genCount: data.genCount ?? 0,
    rewardedGenCount: data.rewardedGenCount ?? 0,
    exportCount: data.exportCount ?? 0,
    rewardedExportCount: data.rewardedExportCount ?? 0,
    lastReset: data.lastReset ?? today(),
    isPro: data.isPro ?? false,
    lastAdToken: data.lastAdToken ?? null,
    proInterestCount: data.proInterestCount ?? 0,
    firstProInterestAt: data.firstProInterestAt ?? null,
    lastProInterestAt: data.lastProInterestAt ?? null,
    proInterestSources: data.proInterestSources ?? {
      proTab: 0,
      generationLimit: 0,
      exportLimit: 0,
    },
    lifetimeGeneratedCases: data.lifetimeGeneratedCases ?? 0,
    lifetimeExports: data.lifetimeExports ?? 0,
    aiFailureFallbackCount: data.aiFailureFallbackCount ?? 0,
    validatorRejectedCount: data.validatorRejectedCount ?? 0,
    exportTargets: data.exportTargets ?? { excel: 0, jira: 0, xray: 0, pdf: 0 },
    fileExtensions: data.fileExtensions ?? { xlsx: 0, csv: 0, json: 0, pdf: 0 },
    lifetimeTestCasesGenerated: data.lifetimeTestCasesGenerated ?? 0,
    firstGenerationAt: data.firstGenerationAt ?? null,
    lastGenerationAt: data.lastGenerationAt ?? null,
    firstExportAt: data.firstExportAt ?? null,
    lastExportAt: data.lastExportAt ?? null,
    lastActiveAt: data.lastActiveAt ?? null,
  };
}

// ------------------------------------------------------------------
// AUTH CREATE TRIGGER – totalUsers
// ------------------------------------------------------------------
exports.onUserCreate = functions.auth.user().onCreate(async (user) => {
  const analyticsRef = db.collection("analytics").doc("global");
  await analyticsRef.set(
    { totalUsers: admin.firestore.FieldValue.increment(1) },
    { merge: true },
  );
});

// ------------------------------------------------------------------
// DEEPSEEK API CALL
// ------------------------------------------------------------------
function extractJSONArray(text) {
  let start = text.indexOf("[");
  if (start === -1) return null;
  let stack = 0;
  let i = start;
  for (; i < text.length; i++) {
    if (text[i] === "[") stack++;
    else if (text[i] === "]") stack--;
    if (stack === 0) break;
  }
  if (stack !== 0) return null;
  const candidate = text.substring(start, i + 1);
  try {
    JSON.parse(candidate);
    return candidate;
  } catch (e) {
    return null;
  }
}

async function callDeepSeek(prompt, metadata) {
  const DEEPSEEK_API_KEY = process.env.DEEPSEEK_API_KEY;
  const url = "https://api.deepseek.com/v1/chat/completions";
  const startTime = Date.now();

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
    const latencyMs = Date.now() - startTime;
    const json = await res.json();

    if (!res.ok) {
      let errorCode = `HTTP_${res.status}`;
      if (res.status === 429) errorCode = "RATE_LIMIT";
      else if (res.status >= 500) errorCode = "SERVER_ERROR";
      return {
        success: false,
        error: { code: errorCode, message: JSON.stringify(json) },
        metadata: { ...metadata, latencyMs },
      };
    }

    let text = json.choices?.[0]?.message?.content;
    if (!text) {
      return {
        success: false,
        error: { code: "EMPTY_TEXT", message: "No text in DeepSeek response" },
        metadata: { ...metadata, latencyMs },
      };
    }

    const jsonArray = extractJSONArray(text);
    if (!jsonArray) {
      return {
        success: false,
        error: {
          code: "NO_ARRAY",
          message: "No valid JSON array found in response",
        },
        metadata: { ...metadata, latencyMs },
      };
    }
    let parsed;
    try {
      parsed = JSON.parse(jsonArray);
    } catch (e) {
      return {
        success: false,
        error: { code: "PARSE_ERROR", message: e.message },
        metadata: { ...metadata, latencyMs },
      };
    }

    const usage = json.usage || {};
    return {
      success: true,
      data: {
        text: JSON.stringify(parsed),
        usage: {
          promptTokens: usage.prompt_tokens ?? 0,
          completionTokens: usage.completion_tokens ?? 0,
          totalTokens: usage.total_tokens ?? 0,
        },
      },
      metadata: { ...metadata, latencyMs, model: "deepseek-chat" },
    };
  } catch (err) {
    return {
      success: false,
      error: { code: "CLIENT_ERROR", message: err.message },
      metadata: { ...metadata, latencyMs: Date.now() - startTime },
    };
  }
}

function transformTestCases(rawCases) {
  if (!Array.isArray(rawCases)) {
    console.error("transformTestCases: input is not an array", typeof rawCases);
    return [];
  }
  const transformed = [];
  for (let i = 0; i < rawCases.length; i++) {
    const tc = rawCases[i];
    const steps = (tc.steps || []).map((step) => ({
      action: step.action || "",
      data: step.data || "",
      expected: step.expected || "",
    }));
    if (steps.length === 0) {
      steps.push({
        action: "Execute the test flow",
        data: "",
        expected: "System behaves as expected",
      });
    }
    transformed.push({
      id: tc.id || "",
      title: tc.title || "Test Case",
      preconditions: Array.isArray(tc.preconditions)
        ? tc.preconditions
        : tc.preconditions
          ? [tc.preconditions]
          : [],
      steps: steps,
      expectedResult: tc.expectedResult || "",
      actualResult: "",
      priority: tc.priority || "Medium",
      status: "Not Executed",
      type: tc.type || "Functional",
    });
  }
  return transformed;
}
exports.getGuestName = functions.https.onCall(async () => {
  const globalRef = db.collection("analytics").doc("global");
  const result = await db.runTransaction(async (t) => {
    const doc = await t.get(globalRef);
    const count = (doc.data()?.guestCounter ?? 0) + 1;
    t.update(globalRef, { guestCounter: count });
    return count;
  });
  return { name: `Guest${result}` };
});

// ------------------------------------------------------------------
// MAIN GENERATION ENDPOINT
// ...
// ------------------------------------------------------------------
exports.generate = functions
  .runWith({ secrets: ["DEEPSEEK_API_KEY"], timeoutSeconds: 120 })
  .https.onCall(async (data, context) => {
    try {
      const requestId = generateRequestId();
      const functionVersion = "v2.0";
      const startTime = Date.now();

      let uid = context.auth ? context.auth.uid : "test_user_123";
      const { module, feature, platform, notes, isPro, adToken, prompt } = data;
      if (!module || !feature) {
        return {
          success: false,
          error: {
            code: "INVALID_ARGUMENT",
            message: "Missing module or feature",
          },
          metadata: {
            requestId,
            functionVersion,
            timestamp: new Date().toISOString(),
            latencyMs: Date.now() - startTime,
          },
        };
      }

      // ----- QUOTA CHECK (simplified, but working) -----
      let allowed = true;
      let userIsPro = false;
      if (!FORCE_BYPASS) {
        const usage = await getUsage(uid);
        const now = today();
        const resetNeeded = usage.lastReset !== now;
        const genCount = resetNeeded ? 0 : usage.genCount;
        const rewardedGenCount = resetNeeded ? 0 : usage.rewardedGenCount;
        userIsPro = usage.isPro || isPro;
        if (userIsPro) {
          if (genCount >= PRO_GEN_LIMIT) allowed = false;
        } else {
          if (genCount >= FREE_GEN_LIMIT) {
            if (rewardedGenCount >= REWARDED_GEN_LIMIT || !adToken)
              allowed = false;
          }
        }
        if (!allowed) {
          return {
            success: false,
            error: { code: "LIMIT_REACHED", message: "Daily limit reached" },
            metadata: {
              requestId,
              functionVersion,
              timestamp: new Date().toISOString(),
              latencyMs: Date.now() - startTime,
            },
          };
        }
      } else {
        userIsPro = isPro || false;
      }

      if (!prompt || typeof prompt !== "string") {
        throw new Error("Missing or invalid 'prompt' field");
      }

      const expectedCount = userIsPro ? 16 : 8;
      let aiResult = await callDeepSeek(prompt, {
        requestId,
        functionVersion,
        model: "deepseek-chat",
        isPro: userIsPro,
      });

      if (!aiResult.success) {
        return {
          success: false,
          error: aiResult.error,
          metadata: aiResult.metadata,
        };
      }

      let rawCases = JSON.parse(aiResult.data.text);
      // If the response is an object with a testCases array, extract it
      if (!Array.isArray(rawCases)) {
        if (rawCases.testCases && Array.isArray(rawCases.testCases)) {
          rawCases = rawCases.testCases;
        } else if (rawCases.data && Array.isArray(rawCases.data)) {
          rawCases = rawCases.data;
        } else {
          // Treat the whole object as a single test case
          rawCases = [rawCases];
        }
      }

      let testCases = transformTestCases(rawCases);
      // Trim to expected count (if more) or accept fewer (client will fill with fallback)
      if (testCases.length > expectedCount) {
        testCases = testCases.slice(0, expectedCount);
      }

      // Add module, feature, platform and generate proper IDs
      testCases = testCases.map((tc, i) => ({
        ...tc,
        id: `TC_${module.replace(/ /g, "").toUpperCase()}_${(i + 1).toString().padStart(3, "0")}`,
        module,
        feature,
        platform,
      }));

      // If we have fewer than expected, we still return them; the client will fill missing with fallback
      // But we set success to true so that the client receives these AI cases.

      return {
        success: true,
        data: { testCases },
        metadata: aiResult.metadata,
      };
    } catch (err) {
      console.error("Unhandled error in generate:", err);
      return {
        success: false,
        error: { code: "INTERNAL_ERROR", message: err.message },
        metadata: {
          requestId: generateRequestId(),
          functionVersion: "v2.0",
          timestamp: new Date().toISOString(),
        },
      };
    }
  });

// ------------------------------------------------------------------
// QUOTA CHECK ENDPOINTS
// ------------------------------------------------------------------
exports.checkGenerationQuota = functions.https.onCall(async (data, context) => {
  if (FORCE_BYPASS) return { allowed: true, reason: null, remaining: 999 };
  if (!context.auth)
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be logged in.",
    );
  const uid = context.auth.uid;
  const { afterRewardedAd } = data;
  const usage = await getUsage(uid);
  const now = today();
  const resetNeeded = usage.lastReset !== now;
  const genCount = resetNeeded ? 0 : usage.genCount;
  const rewardedGenCount = resetNeeded ? 0 : usage.rewardedGenCount;
  const isPro = usage.isPro;

  if (isPro) {
    const remaining = PRO_GEN_LIMIT - genCount;
    return {
      allowed: remaining > 0,
      reason: remaining > 0 ? null : "LIMIT_REACHED",
      remaining,
    };
  } else {
    if (genCount < FREE_GEN_LIMIT) {
      return {
        allowed: true,
        reason: null,
        remaining: FREE_GEN_LIMIT - genCount,
      };
    }
    if (!afterRewardedAd)
      return { allowed: false, reason: "AD_REQUIRED", remaining: 0 };
    const remaining = REWARDED_GEN_LIMIT - rewardedGenCount;
    return {
      allowed: remaining > 0,
      reason: remaining > 0 ? null : "LIMIT_REACHED",
      remaining,
    };
  }
});
exports.checkExportQuota = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be logged in.",
    );
  const uid = context.auth.uid;
  const { rewarded } = data;
  const usage = await getUsage(uid);
  const now = today();
  const resetNeeded = usage.lastReset !== now;
  const exportCount = resetNeeded ? 0 : usage.exportCount;
  const rewardedExportCount = resetNeeded ? 0 : usage.rewardedExportCount;
  const isPro = usage.isPro;

  if (isPro) {
    const remaining = PRO_EXPORT_LIMIT - exportCount;
    return {
      allowed: remaining > 0,
      reason: remaining > 0 ? null : "LIMIT_REACHED",
      remaining,
    };
  } else {
    if (!rewarded)
      return { allowed: false, reason: "AD_REQUIRED", remaining: 0 };
    const remaining = REWARDED_EXPORT_LIMIT - rewardedExportCount;
    return {
      allowed: remaining > 0,
      reason: remaining > 0 ? null : "LIMIT_REACHED",
      remaining,
    };
  }
});

// ------------------------------------------------------------------
// TRACKING – ANALYTICS
// ------------------------------------------------------------------

// ------------------------------------------------------------------
// TRACKING – ANALYTICS & RATINGS
// ------------------------------------------------------------------

/**
 * trackRating – called after user submits a 1-5 star rating
 * Payload: { rating } – integer 1-5
 */
exports.trackRating = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be logged in.",
    );
  }
  const uid = context.auth.uid;
  const { rating } = data;
  if (!rating || rating < 1 || rating > 5) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Rating must be between 1 and 5",
    );
  }

  const userRef = db.collection("usage").doc(uid);
  const analyticsRef = db.collection("analytics").doc("global");

  await db.runTransaction(async (t) => {
    // 1. Update user document
    t.set(
      userRef,
      {
        rating: admin.firestore.FieldValue.increment(1),
        [`ratingBreakdown.${rating}`]: admin.firestore.FieldValue.increment(1),
      },
      { merge: true },
    );

    // 2. Update global analytics
    t.set(
      analyticsRef,
      {
        totalRatings: admin.firestore.FieldValue.increment(1),
        [`ratingBreakdown.${rating}`]: admin.firestore.FieldValue.increment(1),
      },
      { merge: true },
    );
  });
  return { success: true };
});

/**
 * trackGeneration – called after successful generation
 * Payload: { generatedCount }
 */
exports.trackGeneration = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be logged in.",
    );
  }
  const uid = context.auth.uid;
  const { generatedCount } = data;
  if (!generatedCount || generatedCount <= 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "generatedCount must be positive",
    );
  }

  const userRef = db.collection("usage").doc(uid);
  const analyticsRef = db.collection("analytics").doc("global");
  const now = today();

  await db.runTransaction(async (t) => {
    const userDoc = await t.get(userRef);
    let userData = userDoc.exists ? userDoc.data() : {};
    const lastReset = userData.lastReset ?? now;
    let genCount = userData.genCount ?? 0;
    if (lastReset !== now) genCount = 0;
    const isPro = userData.isPro ?? false;

    // Update user
    const userUpdate = {
      genCount: genCount + 1,
      lifetimeGeneratedCases: admin.firestore.FieldValue.increment(1),
      lifetimeTestCasesGenerated:
        admin.firestore.FieldValue.increment(generatedCount),
      lastReset: now,
    };
    if (!isPro) {
      userUpdate.rewardedGenCount = admin.firestore.FieldValue.increment(1);
    }
    t.set(userRef, userUpdate, { merge: true });

    // Update global
    const globalUpdate = {
      totalGenerations: admin.firestore.FieldValue.increment(1),
      totalTestCasesGenerated:
        admin.firestore.FieldValue.increment(generatedCount),
    };
    if (isPro) {
      globalUpdate.proGeneratedCases =
        admin.firestore.FieldValue.increment(generatedCount);
    } else {
      globalUpdate.coreGeneratedCases =
        admin.firestore.FieldValue.increment(generatedCount);
    }
    t.set(analyticsRef, globalUpdate, { merge: true });
  });
  return { success: true };
});

/**
 * trackExport – called after any export (test cases or summary report)
 * Payload: { summary, target, extension }
 * target and extension are strings (e.g., "jira", "csv")
 */
exports.trackExport = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be logged in.",
    );
  const uid = context.auth.uid;
  const { summary = false, target, extension } = data;
  if (!target || !extension) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "target and extension required",
    );
  }

  const userRef = db.collection("usage").doc(uid);
  const analyticsRef = db.collection("analytics").doc("global");
  const now = today();

  await db.runTransaction(async (t) => {
    const userDoc = await t.get(userRef);
    let userData = userDoc.exists ? userDoc.data() : {};
    const lastReset = userData.lastReset ?? now;
    let exportCount = userData.exportCount ?? 0;
    if (lastReset !== now) exportCount = 0;

    // Update user
    const userUpdate = {
      exportCount: exportCount + 1,
      lifetimeExports: admin.firestore.FieldValue.increment(1),
      lastReset: now,
      [`exportTargets.${target}`]: admin.firestore.FieldValue.increment(1),
      [`fileExtensions.${extension}`]: admin.firestore.FieldValue.increment(1),
    };
    t.set(userRef, userUpdate, { merge: true });

    // Update global
    const globalUpdate = {
      totalExports: admin.firestore.FieldValue.increment(1),
      [`exportTargets.${target}`]: admin.firestore.FieldValue.increment(1),
      [`fileExtensions.${extension}`]: admin.firestore.FieldValue.increment(1),
    };
    if (summary) {
      globalUpdate.totalSummaryExports =
        admin.firestore.FieldValue.increment(1);
    }
    t.set(analyticsRef, globalUpdate, { merge: true });
  });
  return { success: true };
});
exports.getUserStats = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be logged in.",
    );
  const uid = context.auth.uid;
  const usage = await getUsage(uid);
  return {
    today: {
      generations: usage.genCount,
      exports: usage.exportCount,
    },
    allTime: {
      generations: usage.lifetimeGeneratedCases,
      exports: usage.lifetimeExports,
      testCases: usage.lifetimeTestCasesGenerated,
    },
    isPro: usage.isPro,
  };
});
/**
 * trackProInterest – called when user shows interest in Pro
 * Payload: { source } – one of "proTab", "generationLimit", "exportLimit"
 */
exports.trackProInterest = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be logged in.",
    );
  const uid = context.auth.uid;
  const { source } = data;
  const allowed = ["proTab", "generationLimit", "exportLimit"];
  if (!allowed.includes(source)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid source");
  }

  const userRef = db.collection("usage").doc(uid);
  const analyticsRef = db.collection("analytics").doc("global");
  const now = admin.firestore.Timestamp.now();

  await db.runTransaction(async (t) => {
    const userDoc = await t.get(userRef);
    let userData = userDoc.exists ? userDoc.data() : {};
    const proInterestCount = userData.proInterestCount ?? 0;
    const isFirst = proInterestCount === 0;

    // User updates
    const userUpdate = {
      proInterestCount: proInterestCount + 1,
      lastProInterestAt: now,
      [`proInterestSources.${source}`]: admin.firestore.FieldValue.increment(1),
    };
    if (isFirst) {
      userUpdate.firstProInterestAt = now;
    }
    t.set(userRef, userUpdate, { merge: true });

    // Global updates
    const globalUpdate = {
      totalProInterest: admin.firestore.FieldValue.increment(1),
      [`${source}Clicks`]: admin.firestore.FieldValue.increment(1),
    };
    if (isFirst) {
      globalUpdate.uniqueProInterestedUsers =
        admin.firestore.FieldValue.increment(1);
    }
    t.set(analyticsRef, globalUpdate, { merge: true });
  });
  return { success: true };
});

/**
 * trackAiFailure – called when AI fails completely
 */
exports.trackAiFailure = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be logged in.",
    );
  const uid = context.auth.uid;
  const userRef = db.collection("usage").doc(uid);
  const analyticsRef = db.collection("analytics").doc("global");

  await db.runTransaction(async (t) => {
    t.set(
      userRef,
      {
        aiFailureFallbackCount: admin.firestore.FieldValue.increment(1),
      },
      { merge: true },
    );
    t.set(
      analyticsRef,
      {
        totalAiFailures: admin.firestore.FieldValue.increment(1),
      },
      { merge: true },
    );
  });
  return { success: true };
});

/**
 * trackValidatorRejected – called when validator rejects AI cases
 * Payload: { rejectedCount }
 */
exports.trackValidatorRejected = functions.https.onCall(
  async (data, context) => {
    if (!context.auth)
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in.",
      );
    const uid = context.auth.uid;
    const { rejectedCount } = data;
    if (!rejectedCount || rejectedCount <= 0) return { success: true };

    const userRef = db.collection("usage").doc(uid);
    const analyticsRef = db.collection("analytics").doc("global");

    await db.runTransaction(async (t) => {
      t.set(
        userRef,
        {
          validatorRejectedCount:
            admin.firestore.FieldValue.increment(rejectedCount),
        },
        { merge: true },
      );
      t.set(
        analyticsRef,
        {
          totalValidatorRejections:
            admin.firestore.FieldValue.increment(rejectedCount),
        },
        { merge: true },
      );
    });
    return { success: true };
  },
);

// ------------------------------------------------------------------
// LEGACY QUOTA HELPERS (unchanged)
// ------------------------------------------------------------------
exports.resetDailyLimits = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be logged in.",
    );
  const uid = context.auth.uid;
  if (!isDebugUser(uid)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Debug operation not allowed.",
    );
  }
  const ref = db.collection("usage").doc(uid);
  await ref.set({
    genCount: 0,
    rewardedGenCount: 0,
    exportCount: 0,
    rewardedExportCount: 0,
    lastReset: today(),
    isPro: false,
    lastAdToken: null,
  });
  return { success: true };
});

exports.setUserPro = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be logged in.",
    );
  const uid = context.auth.uid;
  if (!isDebugUser(uid)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Debug operation not allowed.",
    );
  }
  const { isPro } = data;
  const ref = db.collection("usage").doc(uid);
  await ref.set({ isPro: !!isPro }, { merge: true });
  return { success: true };
});

exports.getQuotaStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be logged in.",
    );
  const uid = context.auth.uid;
  const usage = await getUsage(uid);
  const now = today();
  const resetNeeded = usage.lastReset !== now;
  const genCount = resetNeeded ? 0 : usage.genCount;
  const rewardedGenCount = resetNeeded ? 0 : usage.rewardedGenCount;
  const exportCount = resetNeeded ? 0 : usage.exportCount;
  const rewardedExportCount = resetNeeded ? 0 : usage.rewardedExportCount;
  const isPro = usage.isPro;

  if (isPro) {
    return {
      freeGensRemaining: 0,
      rewardedGensRemaining: 0,
      proGensRemaining: Math.max(0, PRO_GEN_LIMIT - genCount),
      rewardedExportsRemaining: Math.max(0, PRO_EXPORT_LIMIT - exportCount),
    };
  } else {
    return {
      freeGensRemaining: Math.max(0, FREE_GEN_LIMIT - genCount),
      rewardedGensRemaining: Math.max(0, REWARDED_GEN_LIMIT - rewardedGenCount),
      proGensRemaining: 0,
      rewardedExportsRemaining: Math.max(
        0,
        REWARDED_EXPORT_LIMIT - rewardedExportCount,
      ),
    };
  }
});

// ------------------------------------------------------------------
// LEGACY EXPORT TRACKING – with token reuse protection
// ------------------------------------------------------------------
exports.exportTrack = functions
  .runWith({ secrets: ["DEEPSEEK_API_KEY"] })
  .https.onCall(async (data, context) => {
    const requestId = generateRequestId();
    const startTime = Date.now();

    if (!context.auth) {
      return {
        success: false,
        error: { code: "UNAUTHENTICATED", message: "You must be logged in." },
        metadata: {
          requestId,
          timestamp: new Date().toISOString(),
          latencyMs: Date.now() - startTime,
        },
      };
    }
    const uid = context.auth.uid;
    const { isPro, adToken } = data;
    const ref = db.collection("usage").doc(uid);
    const now = today();

    let allowed = false;
    let errorCode = null;
    let errorMessage = null;

    await db.runTransaction(async (t) => {
      const doc = await t.get(ref);
      let usage = doc.exists ? doc.data() : {};
      const lastReset = usage.lastReset ?? now;
      let exportCount = usage.exportCount ?? 0;
      let rewardedExportCount = usage.rewardedExportCount ?? 0;
      if (lastReset !== now) {
        exportCount = 0;
        rewardedExportCount = 0;
      }
      const userIsPro = usage.isPro || isPro;
      if (userIsPro) {
        if (exportCount >= PRO_EXPORT_LIMIT) {
          errorCode = "LIMIT_REACHED";
          errorMessage = "Pro daily export limit reached.";
          return;
        }
      } else {
        if (rewardedExportCount >= REWARDED_EXPORT_LIMIT) {
          errorCode = "LIMIT_REACHED";
          errorMessage = "Rewarded export limit reached. Upgrade to Pro.";
          return;
        }
        if (!adToken) {
          errorCode = "AD_REQUIRED";
          errorMessage = "Rewarded ad required for export.";
          return;
        }
        if (usage.lastAdToken === adToken) {
          errorCode = "TOKEN_REUSED";
          errorMessage = "Ad token already used.";
          return;
        }
      }
      allowed = true;
      if (userIsPro) {
        t.update(ref, { exportCount: exportCount + 1 });
      } else {
        t.update(ref, {
          rewardedExportCount: rewardedExportCount + 1,
          lastAdToken: adToken,
        });
      }
    });

    if (!allowed) {
      return {
        success: false,
        error: { code: errorCode, message: errorMessage },
        metadata: {
          requestId,
          timestamp: new Date().toISOString(),
          latencyMs: Date.now() - startTime,
        },
      };
    }

    return {
      success: true,
      metadata: {
        requestId,
        timestamp: new Date().toISOString(),
        latencyMs: Date.now() - startTime,
      },
    };
  });
