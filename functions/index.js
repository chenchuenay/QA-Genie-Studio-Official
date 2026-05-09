const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();
const db = admin.firestore();

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

const FREE_GEN_LIMIT = 3;
const AD_GEN_LIMIT = 5;
const PRO_GEN_LIMIT = 20;
const FREE_EXPORT_LIMIT = 1;
const MAX_EXPORT_LIMIT = 50;
const PRO_EXPORT_LIMIT = 100;
const MAX_RETRIES = 2;

function today() { return new Date().toISOString().split("T")[0]; }

async function callGemini(prompt) {
  const url = `https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=${GEMINI_API_KEY}`;
  const res = await fetch(url, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({contents: [{parts: [{text: prompt}]}]})
  });
  const json = await res.json();
  if (!json.candidates) throw new Error("GEMINI_FAIL");
  return json.candidates[0].content.parts[0].text;
}

function cleanJSON(text) {
  const s = text.indexOf("{");
  const e = text.lastIndexOf("}");
  if (s === -1 || e === -1) throw new Error("INVALID_JSON");
  return text.substring(s, e + 1);
}

function validate(data, expectedCount) {
  if (!data.testCases || data.testCases.length !== expectedCount) throw new Error("INVALID_COUNT");
  for (const tc of data.testCases) {
    if (!tc.title || !tc.steps || tc.steps.length < 2) throw new Error("INVALID_STRUCTURE");
  }
}

exports.generate = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "You must be logged in.");
  const uid = context.auth.uid;
  const { module, feature, platform, notes, isPro, adToken } = data;
  if (!module || !feature) throw new functions.https.HttpsError("invalid-argument", "Missing fields");

  const ref = db.collection("usage").doc(uid);
  const now = today();

  await db.runTransaction(async (t) => {
    const doc = await t.get(ref);
    let usage = doc.exists ? doc.data() : { genCount: 0, exportCount: 0, lastReset: now, lastAdToken: null, isPro: false };
    if (usage.lastReset !== now) { usage.genCount = 0; usage.exportCount = 0; usage.lastReset = now; }
    const userIsPro = usage.isPro || isPro;
    if (!userIsPro) {
      if (usage.genCount >= FREE_GEN_LIMIT + AD_GEN_LIMIT) throw new Error("LIMIT_REACHED");
      if (usage.genCount >= FREE_GEN_LIMIT && !adToken) throw new Error("AD_REQUIRED");
      if (adToken && usage.lastAdToken === adToken) throw new Error("TOKEN_REUSED");
    } else {
      if (usage.genCount >= PRO_GEN_LIMIT) throw new Error("LIMIT_REACHED");
    }
    t.set(ref, usage, { merge: true });
  });

  const maxCases = isPro ? 20 : 10;
  const prompt = `Generate EXACTLY ${maxCases} QA test cases.\nSTRICT:\n- JSON only\n- include positive, negative, boundary, edge, security\n- min 3 steps\n- no duplicates\nModule: ${module}\nFeature: ${feature}\nPlatform: ${platform}\n${notes || ""}`;

  let parsed;
  for (let i = 0; i < MAX_RETRIES; i++) {
    try {
      const raw = await callGemini(prompt);
      const clean = cleanJSON(raw);
      parsed = JSON.parse(clean);
      validate(parsed, maxCases);
      break;
    } catch (e) {
      if (i === MAX_RETRIES - 1) throw new functions.https.HttpsError("internal", "Gemini generation failed after retries");
    }
  }

  parsed.testCases = parsed.testCases.map((tc, i) => ({
    ...tc,
    id: `TC_${module.replace(/ /g, "").toUpperCase()}_${(i + 1).toString().padStart(3, "0")}`,
    module, feature, platform, actualResult: "", status: "Not Executed"
  }));

  await ref.update({ genCount: admin.firestore.FieldValue.increment(1), lastAdToken: adToken || null });
  return parsed;
});

exports.exportTrack = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "You must be logged in.");
  const uid = context.auth.uid;
  const { isPro, adToken } = data;
  const ref = db.collection("usage").doc(uid);
  const now = today();

  await db.runTransaction(async (t) => {
    const doc = await t.get(ref);
    let usage = doc.exists ? doc.data() : { exportCount: 0, lastReset: now, lastAdToken: null, isPro: false };
    if (usage.lastReset !== now) { usage.exportCount = 0; usage.lastReset = now; }
    const userIsPro = usage.isPro || isPro;
    if (!userIsPro) {
      if (usage.exportCount >= MAX_EXPORT_LIMIT) throw new Error("LIMIT_REACHED");
      if (usage.exportCount >= FREE_EXPORT_LIMIT && !adToken) throw new Error("AD_REQUIRED");
      if (adToken && usage.lastAdToken === adToken) throw new Error("TOKEN_REUSED");
    } else {
      if (usage.exportCount >= PRO_EXPORT_LIMIT) throw new Error("LIMIT_REACHED");
    }
    t.update(ref, { exportCount: admin.firestore.FieldValue.increment(1), lastAdToken: adToken || null });
  });
  return { status: "ok" };
});
