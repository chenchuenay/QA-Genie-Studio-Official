const functions = require("firebase-functions");
const admin = require("firebase-admin");

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

  // ====================================================================
  // 5. MIGRATE MEMBER REGISTRY ENTRIES FROM uid-KEYED → email-KEYED
  // ====================================================================
  let registryMigrated = 0;
  let registryErrors = 0;
  {
    const regSnap = await db.collection("the_qag_registry").get();
    const memberProfileSnap = await db.collection("memberProfiles").get();
    const emailByUid = {};
    memberProfileSnap.forEach(d => {
      const d2 = d.data();
      if (d2.uid) emailByUid[d2.uid] = d.id;
    });

    const batch = db.batch();
    let ops = 0;
    regSnap.forEach(d => {
      const data = d.data();
      if (data.type !== "member") return;
      const docId = d.id;
      // Already email-keyed — skip
      if (docId.includes("@")) return;
      // Look up email from memberProfiles or from data.email field
      const email = data.email || emailByUid[docId];
      if (!email) {
        console.warn(`  Step 5: No email found for member registry ${docId} — skipping`);
        registryErrors++;
        return;
      }
      // Create new email-keyed entry, delete old uid-keyed entry
      batch.set(db.collection("the_qag_registry").doc(email), { ...data, email });
      batch.delete(d.ref);
      ops++;
      registryMigrated++;
      console.log(`  Step 5: ${docId} → ${email} migrated`);
    });
    if (ops > 0) {
      await batch.commit();
      console.log(`  Step 5: committed ${ops} batch writes`);
    }
    console.log(`✅ Member registry entries migrated: ${registryMigrated}`);
  }

  // ====================================================================
  // 6. BACKFILL MISSING deviceId ON GUEST REGISTRY ENTRIES
  // ====================================================================
  let deviceIdBackfilled = 0;
  {
    const regSnap = await db.collection("the_qag_registry").get();
    const batch = db.batch();
    let ops = 0;
    const guestUidsToFetch = [];
    regSnap.forEach(d => {
      const data = d.data();
      if (data.type !== "guest") return;
      if (data.deviceId) return; // already has deviceId
      guestUidsToFetch.push({ docId: d.id, ref: d.ref });
    });

    // Batch fetch guest docs to get deviceId
    for (const entry of guestUidsToFetch) {
      try {
        const guestDoc = await db.collection("guests").doc(entry.docId).get();
        if (guestDoc.exists) {
          const deviceId = guestDoc.data()?.identity?.deviceId;
          if (deviceId) {
            batch.update(entry.ref, { deviceId });
            ops++;
            deviceIdBackfilled++;
          }
        }
      } catch (e) {
        console.warn(`  Step 6: Error fetching guest ${entry.docId}: ${e.message}`);
      }
    }
    if (ops > 0) {
      await batch.commit();
      console.log(`  Step 6: committed ${ops} batch writes`);
    }
    console.log(`✅ Guest registry deviceId backfilled: ${deviceIdBackfilled}`);
  }

  // ====================================================================
  // 7. BACKFILL MISSING MEMBER REGISTRY ENTRIES FROM memberProfiles
  // ====================================================================
  let memberRegistryBackfilled = 0;
  {
    const regSnap = await db.collection("the_qag_registry").get();
    const existingRegistryEmails = new Set();
    regSnap.forEach(d => {
      const data = d.data();
      if (data.type === "member") existingRegistryEmails.add(d.id);
    });

    const batch = db.batch();
    let ops = 0;
    memberProfilesSnap.forEach(d => {
      const email = d.id;
      if (existingRegistryEmails.has(email)) return;
      const data = d.data();
      if (data.deletedAt) return; // skip deleted accounts
      batch.set(db.collection("the_qag_registry").doc(email), {
        type: "member",
        uid: data.uid,
        email,
        displayName: data.displayName || "",
        createdAt: data.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      });
      ops++;
      memberRegistryBackfilled++;
      console.log(`  Step 7: Created registry entry for ${email}`);
    });
    if (ops > 0) {
      await batch.commit();
      console.log(`  Step 7: committed ${ops} batch writes`);
    }
    console.log(`✅ Missing member registry entries created: ${memberRegistryBackfilled}`);
  }

  console.log("=== Cleanup migration complete ===");
  console.log(`  Member usage docs migrated: ${migrated}`);
  console.log(`  Members collection docs deleted: ${deletedMembersDocs}`);
  console.log(`  Guest registry entries backfilled: ${backfilledGuests}`);
  console.log(`  Member registry entries migrated to email-keyed: ${registryMigrated}`);
  console.log(`  Guest registry deviceId backfilled: ${deviceIdBackfilled}`);
  console.log(`  Missing member registry entries created: ${memberRegistryBackfilled}`);
  console.log(`  Errors: ${errors}`);

  return {
    migrated,
    deletedMembersDocs,
    backfilledGuests,
    registryMigrated,
    deviceIdBackfilled,
    memberRegistryBackfilled,
    errors: errors + registryErrors,
  };
});
