const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Migration Script: usage -> Pod Architecture
 * Run this ONCE to move existing data into the new structure.
 */
exports.migrateDataToPods = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Auth required");

  const usageSnapshot = await db.collection("usage").get();
  let migrated = 0;
  let errors = 0;

  for (const doc of usageSnapshot.docs) {
    try {
      const uid = doc.id;
      const usageData = doc.data();
      const isGuest = usageData.isGuest || false; // Assume standard field if exists
      const email = usageData.email || "guest@qa"; 

      // 1. Create Identity Pod (users/guests)
      const podRef = db.collection(isGuest ? "guests" : "users").doc(uid);
      await podRef.set({
        identity: {
          uid: uid,
          email: email,
          type: isGuest ? "guest" : "user",
          createdAt: usageData.createdAt || admin.firestore.FieldValue.serverTimestamp(),
        },
        subscription: isGuest ? null : {
          isPro: usageData.isPro || false,
          planType: (usageData.isPro ? "pro" : "core"),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }
      }, { merge: true });

      // 2. Create Metrics Pod (usage)
      await db.collection("usage").doc(uid).set({
        metrics: {
          genCount: usageData.genCount || 0,
          rewardedGenCount: usageData.rewardedGenCount || 0,
          proGenCount: usageData.proGenCount || 0,
          coreGenCount: usageData.genCount || 0, // Migrating flat to new count
          lifetimeGeneratedCases: usageData.lifetimeGeneratedCases || 0,
          lastReset: usageData.lastReset || new Date().toISOString().split("T")[0]
        }
      }, { merge: true });

      // 3. Populate Registry
      await db.collection("the_qag_registry").doc(uid).set({
        uid: uid,
        identity: email,
        type: isGuest ? "guest" : "user"
      });

      migrated++;
    } catch (e) {
      console.error(`Error migrating ${doc.id}:`, e);
      errors++;
    }
  }

  return { migrated, errors };
});
