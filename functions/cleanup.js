const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Cleanup/Migration Script
 * Run this ONCE per environment to:
 * - Migrate member usage/{uid} → usage/{email} (email-keyed)
 * - Delete abandoned `members` collection
 * - Backfill missing the_qag_registry guests
 * - Recompute analytics/global from source docs
 */
exports.migrate = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Auth required");

  console.log("=== Starting cleanup migration ===");

  let migrated = 0;
  let deletedMembersDocs = 0;
  let backfilledGuests = 0;
  let errors = 0;

  // ====================================================================
  // 1. MIGRATE MEMBER usage/{uid} → usage/{email}
  // ====================================================================
  // Members are identified by type === "member" in their usage doc,
  // or by existing memberProfiles entry. Skip guest_* UIDs.
  const allUsageDocs = await db.collection("usage").get();
  const memberProfilesSnap = await db.collection("memberProfiles").get();
  const profileByUid = {};
  memberProfilesSnap.forEach(doc => {
    const data_ = doc.data();
    if (data_.uid && data_.email) {
      profileByUid[data_.uid] = data_.email;
    }
  });

  for (const doc of allUsageDocs.docs) {
    try {
      const uid = doc.id;
      const usageData = doc.data();

      // Skip guest UIDs
      if (uid.startsWith("guest_")) continue;

      // Determine if this is a member doc that needs migration
      const isMember = usageData?.type === "member" || profileByUid[uid];
      if (!isMember) continue;

      const email = usageData?.email || profileByUid[uid];
      if (!email) {
        console.warn(`  Skipping member ${uid}: no email found`);
        continue;
      }

      // Check if usage/{email} already exists
      const memberUsageRef = db.collection("usage").doc(email);
      const existing = await memberUsageRef.get();
      if (existing.exists) {
        // Already migrated — delete old uid-based doc
        await doc.ref.delete();
        console.log(`  ${uid}: already at ${email}, deleted old`);
        migrated++;
        continue;
      }

      // Copy data to email-keyed doc
      const newData = {
        ...usageData,
        email,
        uid,
        type: "member",
      };
      // Remove stale fields that don't belong at the top level
      delete newData.isGuest;
      await memberUsageRef.set(newData);

      // Delete old uid-based doc
      await doc.ref.delete();
      migrated++;
      console.log(`  ${uid} → ${email}: migrated`);
    } catch (e) {
      console.error(`Error migrating ${doc.id}:`, e);
      errors++;
    }
  }

  // ====================================================================
  // 2. DELETE ABANDONED `members` COLLECTION
  // ====================================================================
  {
    const membersSnap = await db.collection("members").get();
    if (!membersSnap.empty) {
      const batch = db.batch();
      let count = 0;
      membersSnap.forEach(d => {
        batch.delete(d.ref);
        count++;
      });
      await batch.commit();
      deletedMembersDocs = count;
      console.log(`✅ Deleted ${count} docs from members collection`);
    } else {
      console.log("✅ members collection already empty");
    }
  }

  // ====================================================================
  // 3. BACKFILL MISSING GUEST ENTRIES IN the_qag_registry
  // ====================================================================
  {
    const existingRegistry = await db.collection("the_qag_registry").get();
    const registeredUids = new Set();
    existingRegistry.forEach(d => registeredUids.add(d.id));

    const existingGuestUids = new Set();
    const guestsSnap = await db.collection("guests").get();
    guestsSnap.forEach(d => existingGuestUids.add(d.id));

    // Check all guest_* usage docs
    for (const doc of allUsageDocs.docs) {
      const uid = doc.id;
      if (!uid.startsWith("guest_")) continue;
      if (registeredUids.has(uid)) continue;

      const usageData = doc.data();
      const registryEntry = {
        uid,
        type: "guest",
        displayName: usageData?.identity?.displayName || `Guest_${uid.substr(6, 6)}`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // If there's a guest doc, include deviceDisplayName
      if (existingGuestUids.has(uid)) {
        const guestDoc = await db.collection("guests").doc(uid).get();
        if (guestDoc.exists && guestDoc.data()?.identity?.deviceDisplayName) {
          registryEntry.displayName = guestDoc.data().identity.deviceDisplayName;
        }
      }

      await db.collection("the_qag_registry").doc(uid).set(registryEntry);
      backfilledGuests++;
      console.log(`  Backfilled registry entry for guest ${uid}`);
    }
  }

  // ====================================================================
  // 4. RECOMPUTE analytics/global FROM SOURCE
  // ====================================================================
  {
    // Count members from memberProfiles
    let totalMembers = 0;
    memberProfilesSnap.forEach(d => {
      const d2 = d.data();
      if (!d2.deletedAt) totalMembers++;
    });

    // Count guests from the_qag_registry
    const regSnap = await db.collection("the_qag_registry").get();
    let guestCounter = 0;
    let registryCounter = 0;
    regSnap.forEach(d => {
      registryCounter++;
      if (d.data().type === "guest") guestCounter++;
    });

    // Re-check usage docs (post-migration, members are at email keys)
    const updatedUsageSnap = await db.collection("usage").get();
    const gen = {};
    const expTotals = {};
    const ratTotals = {};
    let proInterestTotal = 0;
    let proTabClicks = 0;
    const uniqueProUids = new Set();

    updatedUsageSnap.forEach(d => {
      const du = d.data();
      const g = du?.metrics?.generations;
      const e = du?.metrics?.exports;
      const r = du?.metrics?.ratings;
      const ints = du?.interests;

      if (g) {
        gen.total = (gen.total || 0) + (g.total || 0);
        gen.totalCases = (gen.totalCases || 0) + (g.totalCases || 0);
        gen.coreCases = (gen.coreCases || 0) + (g.coreCases || 0);
        gen.proCases = (gen.proCases || 0) + (g.proCases || 0);
        gen.aiFailures = (gen.aiFailures || 0) + (g.aiFailures || 0);
        gen.validatorRejections = (gen.validatorRejections || 0) + (g.validatorRejections || 0);
      }

      if (e) {
        expTotals.total = (expTotals.total || 0) + (e.total || 0);
        expTotals.summaryExports = (expTotals.summaryExports || 0) + (e.summaryExports || 0);
        if (e.targets) {
          if (!expTotals.targets) expTotals.targets = {};
          Object.keys(e.targets).forEach(k => {
            expTotals.targets[k] = (expTotals.targets[k] || 0) + (e.targets[k] || 0);
          });
        }
        if (e.extensions) {
          if (!expTotals.extensions) expTotals.extensions = {};
          Object.keys(e.extensions).forEach(k => {
            expTotals.extensions[k] = (expTotals.extensions[k] || 0) + (e.extensions[k] || 0);
          });
        }
      }

      if (r) {
        ratTotals.total = (ratTotals.total || 0) + (r.total || 0);
        if (r.breakdown) {
          if (!ratTotals.breakdown) ratTotals.breakdown = {};
          Object.keys(r.breakdown).forEach(k => {
            ratTotals.breakdown[k] = (ratTotals.breakdown[k] || 0) + (r.breakdown[k] || 0);
          });
        }
      }

      if (ints?.proInterestCount) {
        proInterestTotal += ints.proInterestCount;
        if (ints.proInterestSources?.tab) proTabClicks += ints.proInterestSources.tab;
        if (du.uid) uniqueProUids.add(du.uid);
      }
    });

    const globalData = {
      generation: {
        totalGenerations: gen.total || 0,
        totalTestCaseGenerated: gen.totalCases || 0,
        coreGeneratedCases: gen.coreCases || 0,
        proGeneratedCases: gen.proCases || 0,
        totalAiFailures: gen.aiFailures || 0,
        totalValidatorRejections: gen.validatorRejections || 0,
      },
      exports: {
        totalExports: expTotals.total || 0,
        totalSummaryExports: expTotals.summaryExports || 0,
        targets: expTotals.targets || {},
        extensions: expTotals.extensions || {},
      },
      ratings: {
        totalRatings: ratTotals.total || 0,
        breakdown: ratTotals.breakdown || {},
      },
      pro: {
        totalProInterest: proInterestTotal,
        proTabClicks: proTabClicks,
        uniqueProInterestedMembers: uniqueProUids.size,
      },
      other: {
        totalMembers,
        guestCounter,
        registryCounter,
      },
    };

    await db.collection("analytics").doc("global").set(globalData, { merge: true });
    console.log("✅ analytics/global recomputed");
  }

  console.log("=== Cleanup migration complete ===");
  console.log(`  Member usage docs migrated: ${migrated}`);
  console.log(`  Members collection docs deleted: ${deletedMembersDocs}`);
  console.log(`  Guest registry entries backfilled: ${backfilledGuests}`);
  console.log(`  Errors: ${errors}`);

  return {
    migrated,
    deletedMembersDocs,
    backfilledGuests,
    errors,
  };
});
