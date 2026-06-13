const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
const crypto = require("crypto");

admin.initializeApp();
const db = admin.firestore();

// ------------------------------------------------------------------
// CONFIGURATION
// ------------------------------------------------------------------
const FORCE_BYPASS = false;
const CORE_DAILY_BATCHES_LIMIT = 6;
const PRO_DAILY_BATCHES_LIMIT = 15;
const CORE_CASES_PER_BATCH = 10;
const PRO_CASES_PER_BATCH = 20;

const FREE_GEN_LIMIT = 0; 
const PRO_EXPORT_LIMIT = 100;
const REWARDED_EXPORT_LIMIT = 50;

function today() { return new Date().toISOString().split("T")[0]; }
function generateRequestId() { return `req_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`; }

// ------------------------------------------------------------------
// GUEST NAME PERSISTENCE
// ------------------------------------------------------------------
exports.getGuestName = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  
  const guestRef = db.collection("guests").doc(uid);
  const doc = await guestRef.get();
  
  if (doc.exists && doc.data().identity?.displayName) {
    return { name: doc.data().identity.displayName, isExisting: true };
  }

  const globalRef = db.collection("analytics").doc("global");
  const result = await db.runTransaction(async (t) => {
    const d = await t.get(globalRef);
    const count = (d.data()?.guestCounter ?? 0) + 1;
    t.update(globalRef, { guestCounter: count });
    return count;
  });

  const guestName = `Guest${result}`;
  
  // Create Guest Pod
  await guestRef.set({
    identity: {
      uid: uid,
      displayName: guestName,
      type: "guest",
      deviceId: data.deviceId || "",
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    }
  });

  // Registry Entry
  await db.collection("the_qag_registry").doc(uid).set({
    uid: uid,
    identity: guestName,
    type: "guest"
  });

  return { name: guestName, isExisting: false };
});

// ------------------------------------------------------------------
// GET USER DASHBOARD - AGGREGATOR (1 READ)
// ------------------------------------------------------------------
exports.getUserDashboard = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Auth required");
  const uid = context.auth.uid;
  const isGuest = data.type === 'guest';
  const rootCollection = isGuest ? "guests" : "users";

  const [idDoc, metricDoc, ratingDoc] = await Promise.all([
    db.collection(rootCollection).doc(uid).get(),
    db.collection("usage").doc(uid).get(),
    db.collection("ratings").doc(uid).get()
  ]);
  
  const resetDate = new Date();
  resetDate.setUTCHours(24, 0, 0, 0);

  return {
    identity: idDoc.exists ? idDoc.data().identity : null,
    subscription: (isGuest || !idDoc.exists) ? null : idDoc.data().subscription,
    metrics: metricDoc.exists ? metricDoc.data().metrics : null,
    ratings: ratingDoc.exists ? ratingDoc.data() : null,
    resetTimestamp: resetDate.toISOString()
  };
});

// ------------------------------------------------------------------
// GENERATION - ATOMIC
// ------------------------------------------------------------------
exports.generate = functions
  .runWith({ secrets: ["DEEPSEEK_API_KEY"], timeoutSeconds: 120 })
  .https.onCall(async (data, context) => {
    const requestId = generateRequestId();
    if (!context.auth) return { success: false, error: { code: "UNAUTHENTICATED" } };

    const { module, feature, platform, isPro, adToken, prompt, deviceId } = data;
    const uid = context.auth.uid;
    const now = today();

    try {
      // 1. Quota check & lock (Atomic Transaction)
      await db.runTransaction(async (t) => {
        const uRef = db.collection("usage").doc(uid);
        const dRef = deviceId ? db.collection("deviceUsage").doc(deviceId) : null;

        const [uDoc, dDoc] = await Promise.all([t.get(uRef), dRef ? t.get(dRef) : Promise.resolve(null)]);

        let u = uDoc.exists ? uDoc.data() : { lastReset: now, proGenCount: 0, coreGenCount: 0 };
        let d = (dDoc && dDoc.exists) ? dDoc.data() : { lastReset: now, coreGenCount: 0 };

        if (u.lastReset !== now) { u.coreGenCount = 0; u.lastReset = now; }
        if (d.lastReset !== now) { d.coreGenCount = 0; d.lastReset = now; }

        if (!isPro) {
          if (u.coreGenCount === 0 && d.coreGenCount > 0) u.coreGenCount = d.coreGenCount;
          if (d.coreGenCount >= CORE_DAILY_BATCHES_LIMIT) throw new Error("LIMIT_REACHED");
        }
      });

      // 2. Call AI (Independent of Transaction)
      const aiResult = await callDeepSeek(prompt, { requestId });
      if (!aiResult.success) throw new Error(aiResult.error.code);

      const rawCases = JSON.parse(aiResult.data.text);
      const limitPerBatch = isPro ? PRO_CASES_PER_BATCH : CORE_CASES_PER_BATCH;
      const transformedCases = transformTestCases(Array.isArray(rawCases) ? rawCases : (rawCases.testCases || [rawCases]), module, feature, 'Web', limitPerBatch);

      // 3. Post-Generation Update (Atomic)
      await db.runTransaction(async (t) => {
        const uRef = db.collection("usage").doc(uid);
        const dRef = deviceId ? db.collection("deviceUsage").doc(deviceId) : null;
        const [uDoc, dDoc] = await Promise.all([t.get(uRef), dRef ? t.get(dRef) : Promise.resolve(null)]);
        let u = uDoc.exists ? uDoc.data() : { lastReset: now, proGenCount: 0, coreGenCount: 0 };
        let d = (dDoc && dDoc.exists) ? dDoc.data() : { lastReset: now, coreGenCount: 0 };

        if (isPro) {
          u.proGenCount = (u.proGenCount || 0) + 1;
        } else {
          u.coreGenCount = (u.coreGenCount || 0) + 1;
          d.coreGenCount = (d.coreGenCount || 0) + 1;
          if (dRef) t.set(dRef, d, { merge: true });
        }
        t.set(uRef, u, { merge: true });
      });

      return { success: true, data: { testCases: transformedCases } };
    } catch (err) {
      return { success: false, error: { code: err.message === "LIMIT_REACHED" ? "LIMIT_REACHED" : "INTERNAL_ERROR" } };
    }
    });

// Helper: Call DeepSeek API
async function callDeepSeek(prompt, metadata) {
  const DEEPSEEK_API_KEY = process.env.DEEPSEEK_API_KEY;
  const url = "https://api.deepseek.com/v1/chat/completions";
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: { Authorization: `Bearer ${DEEPSEEK_API_KEY}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "deepseek-chat",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.2,
      }),
    });
    const json = await res.json();
    if (!res.ok) return { success: false, error: { code: `HTTP_${res.status}`, message: JSON.stringify(json) } };
    return { success: true, data: { text: json.choices[0].message.content } };
  } catch (err) {
    return { success: false, error: { code: "CLIENT_ERROR", message: err.message } };
  }
}

// Helper: Transform cases
function transformTestCases(rawCases, module, feature, platform, limit) {
  if (!Array.isArray(rawCases)) {
    console.error("transformTestCases: input is not an array", typeof rawCases);
    return [];
  }
  
  // Trim to limit
  const cases = rawCases.slice(0, limit);
  
  return cases.map((tc, i) => ({
    id: `TC_${module.replace(/ /g, "").toUpperCase()}_${(i + 1).toString().padStart(3, "0")}`,
    title: tc.title || "Test Case",
    preconditions: Array.isArray(tc.preconditions) ? tc.preconditions : [],
    steps: (tc.steps || []).map(s => ({ action: s.action || "", data: s.data || "", expected: s.expected || "" })),
    expectedResult: tc.expectedResult || "",
    actualResult: "",
    priority: tc.priority || "Medium",
    status: "Not Executed",
    type: tc.type || "Functional",
    module,
    feature,
    platform,
  }));
}

// ------------------------------------------------------------------
// ACCOUNT DELETION - TOMBSTONE
// ------------------------------------------------------------------
exports.deleteAccount = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Auth required");
  
  const uid = context.auth.uid;
  const now = today();
  const resetTimestamp = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

  const userDoc = await db.collection(data.type === 'guest' ? 'guests' : 'users').doc(uid).get();
  const userData = userDoc.exists ? userDoc.data() : {};
  const deviceId = userData.identity?.deviceId;

  await db.runTransaction(async (t) => {
    t.set(db.collection(data.type === 'guest' ? 'guests' : 'users').doc(uid), { 
      identity: { email: "[DELETED]", displayName: "[DELETED]" },
      subscription: { isPro: false }
    }, { merge: true });
    
    t.delete(db.collection("usage").doc(uid));
    t.delete(db.collection("ratings").doc(uid));
    t.delete(db.collection("the_qag_registry").doc(uid));

    if (deviceId) {
      t.set(db.collection("blocked_devices").doc(deviceId), { resetAt: resetTimestamp });
    }
  });

  await admin.auth().deleteUser(uid);
  return { success: true };
});

exports.migrateDataToPods = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Auth required");

  const usageSnapshot = await db.collection("usage").get();
  let migrated = 0;

  for (const doc of usageSnapshot.docs) {
    const uid = doc.id;
    const old = doc.data();
    
    // DEBUG LOG
    console.log(`DEBUG_MIGRATION: UID=${uid}, RawData=${JSON.stringify(old)}`);
    
    // PRIMARY GUEST DETECTION
    const isGuest = (old.displayName || old.guestName) && (!old.email || old.email === 'unknown' || old.email === '');
    const podColl = isGuest ? "guests" : "users";

    // 1. Identity Pod (Strict separation: Guest NO subscription/email)
    const identityPod = {
      identity: {
        uid: uid,
        type: isGuest ? "guest" : "user",
        deviceId: old.deviceId || "",
        createdAt: old.createdAt || admin.firestore.FieldValue.serverTimestamp(),
        ...(isGuest 
            ? { displayName: old.displayName || old.guestName || "Guest" } 
            : { email: old.email || "unknown" })
      }
    };
    
    // Only add subscription for Users
    if (!isGuest) {
      identityPod.subscription = {
        isPro: !!old.isPro,
        planType: old.isPro ? "pro" : "core",
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };
    }
    
    // Overwrite the Pod document completely
    await db.collection(podColl).doc(uid).set(identityPod);

    // 2. Metrics Pod (Complete telemetry mapping)
    await db.collection("usage").doc(uid).set({
      uid: uid,
      metrics: {
        genCount: old.genCount || 0,
        rewardedGenCount: old.rewardedGenCount || 0,
        proGenCount: old.proGenCount || 0,
        coreGenCount: old.genCount || 0,
        lifetimeGeneratedCases: old.lifetimeGeneratedCases || 0,
        lifetimeTestCasesGenerated: old.lifetimeTestCasesGenerated || 0,
        lastReset: old.lastReset || today()
      },
      exports: {
        exportCount: old.exportCount || 0,
        rewardedExportCount: old.rewardedExportCount || 0,
        lifetimeExports: old.lifetimeExports || 0,
        exportTargets: old.exportTargets || {},
        fileExtensions: old.fileExtensions || {}
      },
      interests: {
        proInterestCount: old.proInterestCount || 0,
        firstProInterestAt: old.firstProInterestAt || null,
        lastProInterestAt: old.lastProInterestAt || null,
        proInterestSources: old.proInterestSources || {}
      },
      diagnostics: {
        aiFailureFallbackCount: old.aiFailureFallbackCount || 0,
        validatorRejectedCount: old.validatorRejectedCount || 0
      },
      analytics: {
        firstGenerationAt: old.firstGenerationAt || null,
        lastGenerationAt: old.lastGenerationAt || null,
        firstExportAt: old.firstExportAt || null,
        lastExportAt: old.lastExportAt || null,
        lastActiveAt: old.lastActiveAt || null,
        lastAdToken: old.lastAdToken || null
      }
    });

    // 3. Registry
    await db.collection("the_qag_registry").doc(uid).set({
      uid: uid,
      identity: isGuest ? (old.displayName || old.guestName || "Guest") : (old.email || "unknown"),
      type: isGuest ? "guest" : "user"
    });

    migrated++;
  }
  return { status: "Strict Pod Migration Complete", processed: migrated };
});

exports.checkGenerationQuota = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Auth required");
  
  const uid = context.auth.uid;
  const { afterRewardedAd } = data;
  const uDoc = await db.collection("usage").doc(uid).get();
  const usage = uDoc.exists ? uDoc.data().metrics : { genCount: 0, rewardedGenCount: 0 };
  const isPro = await db.collection("users").doc(uid).get().then(d => d.exists && d.data().subscription?.isPro);

  if (isPro) {
    const remaining = PRO_DAILY_BATCHES_LIMIT - (usage.proGenCount || 0);
    return { allowed: remaining > 0, reason: remaining > 0 ? null : "LIMIT_REACHED", remaining };
  } else {
    const remaining = CORE_DAILY_BATCHES_LIMIT - (usage.coreGenCount || 0);
    if (remaining > 0) return { allowed: true, reason: null, remaining };
    if (!afterRewardedAd) return { allowed: false, reason: "AD_REQUIRED", remaining: 0 };
    return { allowed: false, reason: "LIMIT_REACHED", remaining: 0 };
  }
});
