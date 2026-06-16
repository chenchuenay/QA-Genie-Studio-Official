const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Migration Script: usage -> Pod Architecture + Analytics Structure
 * Run this ONCE to:
 * - Move existing data into users/guests/usage/registry
 * - Ensure analytics/global has the complete schema with defaults
 */
exports.migrateDataToPods = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");

  // ====================================================================
  // 1. ENSURE ANALYTICS/GLOBAL HAS COMPLETE STRUCTURE (with defaults)
  // ====================================================================
  const globalRef = db.collection("analytics").doc("global");
  const globalDoc = await globalRef.get();

  const defaultAnalytics = {
    // Core counters
    coreGeneratedCases: 0,
    proGeneratedCases: 0,
    totalGenerations: 0,
    totalTestCaseGenerated: 0,
    totalAiFailures: 0,
    totalExports: 0,
    totalSummaryExports: 0,
    // Nested maps
    exportTargets: { excel: 0, jira: 0, pdf: 0, xray: 0 },
    fileExtensions: { csv: 0, json: 0, pdf: 0, xlsx: 0 },
    // Pro interest
    totalProInterest: 0,
    proTabClicks: 0,
    uniqueProInterestedUsers: 0,
    // Ratings
    totalRatings: 0,
    ratingBreakdown: { 2: 0, 3: 0, 4: 0, 5: 0 },
    // User counters
    guestCounter: 0,
    totalUsers: 0,
  };

  // Remove any old nested `users` field if present
  if (globalDoc.exists && globalDoc.data()?.users) {
    await globalRef.update({ users: admin.firestore.FieldValue.delete() });
  }

  // Merge defaults (only adds missing fields, preserves existing values)
  await globalRef.set(defaultAnalytics, { merge: true });
  console.log("✅ analytics/global structure ensured");

  // ====================================================================
  // 2. MIGRATE USER/GUEST DATA FROM OLD USAGE COLLECTION
  // ====================================================================
  const usageSnapshot = await db.collection("usage").get();
  let migrated = 0;
  let errors = 0;

  for (const doc of usageSnapshot.docs) {
    try {
      const uid = doc.id;
      const usageData = doc.data();
      const isGuest = usageData.isGuest || false;

      // ---- Identity pod (users or guests) ----
      const podRef = db.collection(isGuest ? "guests" : "users").doc(uid);
      const identity = {
        uid: uid,
        type: isGuest ? "guest" : "user",
        createdAt:
          usageData.createdAt || admin.firestore.FieldValue.serverTimestamp(),
        displayName:
          usageData.displayName || (isGuest ? `Guest_${uid.substr(0, 6)}` : ""),
      };
      // Only add email for non‑guest users
      if (!isGuest && usageData.email) {
        identity.email = usageData.email;
      }
      await podRef.set({ identity }, { merge: true });

      // ---- Metrics pod (usage) ----
      await db
        .collection("usage")
        .doc(uid)
        .set(
          {
            metrics: {
              genCount: usageData.genCount || 0,
              rewardedGenCount: usageData.rewardedGenCount || 0,
              proGenCount: usageData.proGenCount || 0,
              coreGenCount: usageData.genCount || 0, // fallback
              lifetimeGeneratedCases: usageData.lifetimeGeneratedCases || 0,
              lastReset:
                usageData.lastReset || new Date().toISOString().split("T")[0],
            },
          },
          { merge: true },
        );

      // ---- Registry (no email, no identity sub‑object) ----
      await db
        .collection("the_qag_registry")
        .doc(uid)
        .set(
          {
            uid: uid,
            type: isGuest ? "guest" : "user",
            displayName: identity.displayName,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );

      migrated++;
    } catch (e) {
      console.error(`Error migrating ${doc.id}:`, e);
      errors++;
    }
  }

  // ====================================================================
  // 3. (OPTIONAL) RECOMPUTE guestCounter & totalUsers FROM EXISTING DOCS
  // ====================================================================
  const usersCount = (await db.collection("users").get()).size;
  const guestsCount = (await db.collection("guests").get()).size;
  await globalRef.update({
    totalUsers: usersCount + guestsCount,
    guestCounter: guestsCount,
  });

  console.log(
    `✅ Migration completed: ${migrated} succeeded, ${errors} errors`,
  );
  console.log(
    `   totalUsers=${usersCount + guestsCount}, guestCounter=${guestsCount}`,
  );

  return {
    migrated,
    errors,
    totalUsers: usersCount + guestsCount,
    guestCounter: guestsCount,
  };
});
