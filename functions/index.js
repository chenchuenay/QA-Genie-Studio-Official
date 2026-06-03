const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();
const db = admin.firestore();

const GEMINI_API_KEY = process.env.GEMINI_API_KEY || "DEPLOY_TRIGGER";

const FREE_GEN_LIMIT = 3;
const AD_GEN_LIMIT = 5;
const PRO_GEN_LIMIT = 20;
const FREE_EXPORT_LIMIT = 1;
const MAX_EXPORT_LIMIT = 50;
const PRO_EXPORT_LIMIT = 100;
const MAX_RETRIES = 2;

function today() {
  return new Date().toISOString().split("T")[0];
}

async function callGemini(prompt) {
  console.log("=== GEMINI START ===");
  console.log("API_KEY_EXISTS:", !!GEMINI_API_KEY);
  console.log(
    "API_KEY_PREFIX:",
    GEMINI_API_KEY ? GEMINI_API_KEY.substring(0, 8) : "NULL",
  );

  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${GEMINI_API_KEY}`;

  console.log("MODEL_URL:", url);

  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      contents: [
        {
          parts: [
            {
              text: prompt,
            },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.2,
        responseMimeType: "application/json",
      },
    }),
  });

  console.log("GEMINI_HTTP_STATUS:", res.status);

  const json = await res.json();

  console.log("GEMINI_RAW_RESPONSE:", JSON.stringify(json, null, 2));

  if (!res.ok) {
    throw new Error(`GEMINI_HTTP_${res.status}: ${JSON.stringify(json)}`);
  }

  if (!json.candidates?.length) {
    throw new Error(`NO_CANDIDATES: ${JSON.stringify(json)}`);
  }

  const text = json.candidates[0]?.content?.parts?.[0]?.text;

  if (!text) {
    throw new Error(`EMPTY_TEXT_RESPONSE: ${JSON.stringify(json)}`);
  }

  console.log("GEMINI_TEXT_LENGTH:", text.length);
  console.log("=== GEMINI SUCCESS ===");

  return text;
}

function parseGeminiResponse(raw) {
  const clean = raw
    .replace(/```json/g, "")
    .replace(/```/g, "")
    .trim();

  let parsed = JSON.parse(clean);

  if (Array.isArray(parsed)) {
    parsed = {
      testCases: parsed,
    };
  }

  return parsed;
}

function validate(data, expectedCount) {
  if (!data.testCases || !Array.isArray(data.testCases)) {
    throw new Error("INVALID_RESPONSE");
  }

  if (data.testCases.length < expectedCount) {
    throw new Error("INVALID_COUNT");
  }

  data.testCases = data.testCases.slice(0, expectedCount);

  for (const tc of data.testCases) {
    const title = tc.title || tc.test_case_title;

    const steps = tc.steps;

    if (!title || !Array.isArray(steps) || steps.length < 2) {
      throw new Error("INVALID_STRUCTURE");
    }
  }
}

exports.generate = functions
  .runWith({
    secrets: ["GEMINI_API_KEY"],
  })
  .https.onCall(async (data, context) => {
    if (!context.auth)
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be logged in.",
      );
    const uid = context.auth.uid;
    const { module, feature, platform, notes, isPro, adToken } = data;
    if (!module || !feature)
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing fields",
      );

    const ref = db.collection("usage").doc(uid);
    const now = today();

    await db.runTransaction(async (t) => {
      const doc = await t.get(ref);
      let usage = doc.exists
        ? doc.data()
        : {
            genCount: 0,
            exportCount: 0,
            lastReset: now,
            lastAdToken: null,
            isPro: false,
          };
      if (usage.lastReset !== now) {
        usage.genCount = 0;
        usage.exportCount = 0;
        usage.lastReset = now;
      }
      const userIsPro = usage.isPro || isPro;
      if (!userIsPro) {
        if (usage.genCount >= FREE_GEN_LIMIT + AD_GEN_LIMIT)
          throw new Error("LIMIT_REACHED");
        if (usage.genCount >= FREE_GEN_LIMIT && !adToken)
          throw new Error("AD_REQUIRED");
        if (adToken && usage.lastAdToken === adToken)
          throw new Error("TOKEN_REUSED");
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

        parsed = parseGeminiResponse(raw);

        validate(parsed, maxCases);
        break;
      } catch (e) {
        console.error(`GEMINI_ATTEMPT_${i + 1}_FAILED`, e);

        if (i === MAX_RETRIES - 1) {
          throw new functions.https.HttpsError("internal", String(e));
        }
      }
    }

    parsed.testCases = parsed.testCases.map((tc, i) => ({
      id: `TC_${module.replace(/ /g, "").toUpperCase()}_${(i + 1)
        .toString()
        .padStart(3, "0")}`,

      title: tc.title || tc.test_case_title || `Test Case ${i + 1}`,

      preconditions: Array.isArray(tc.preconditions)
        ? tc.preconditions
        : tc.preconditions
          ? [tc.preconditions]
          : [],

      testData: tc.testData || [],

      steps: Array.isArray(tc.steps) ? tc.steps : [],

      expectedResult: tc.expectedResult || tc.expected_result || "",

      ActualResults: "",

      priority: tc.priority || "Medium",

      status: "Not Executed",

      type: tc.type || tc.test_type || "Functional",

      module,
      feature,
      platform,
    }));

    await ref.update({
      genCount: admin.firestore.FieldValue.increment(1),
      lastAdToken: adToken || null,
    });
    return parsed;
  });
exports.exportTrack = functions
  .runWith({
    secrets: ["GEMINI_API_KEY"],
  })
  .https.onCall(async (data, context) => {
    if (!context.auth)
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be logged in.",
      );
    const uid = context.auth.uid;
    const { isPro, adToken } = data;
    const ref = db.collection("usage").doc(uid);
    const now = today();

    await db.runTransaction(async (t) => {
      const doc = await t.get(ref);
      let usage = doc.exists
        ? doc.data()
        : { exportCount: 0, lastReset: now, lastAdToken: null, isPro: false };
      if (usage.lastReset !== now) {
        usage.exportCount = 0;
        usage.lastReset = now;
      }
      const userIsPro = usage.isPro || isPro;
      if (!userIsPro) {
        if (usage.exportCount >= MAX_EXPORT_LIMIT)
          throw new Error("LIMIT_REACHED");
        if (usage.exportCount >= FREE_EXPORT_LIMIT && !adToken)
          throw new Error("AD_REQUIRED");
        if (adToken && usage.lastAdToken === adToken)
          throw new Error("TOKEN_REUSED");
      } else {
        if (usage.exportCount >= PRO_EXPORT_LIMIT)
          throw new Error("LIMIT_REACHED");
      }
      t.update(ref, {
        exportCount: admin.firestore.FieldValue.increment(1),
        lastAdToken: adToken || null,
      });
    });
    return { status: "ok" };
  });
