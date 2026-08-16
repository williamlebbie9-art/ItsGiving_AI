const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

const openAiApiKey = defineSecret("OPENAI_API_KEY");

if (!admin.apps.length) {
  admin.initializeApp();
}

// Free-tier usage limits (mirrors the client).
const FREE_LIMITS = {
  faceScan: 1,
  coachInsight: 3,
  plan: 1,
};

/**
 * Verifies the Firebase ID token from the Authorization header.
 * Returns the UID, or null if the token is invalid/missing.
 */
async function verifyAuth(req) {
  const authHeader = req.headers.authorization || "";
  const token = authHeader.startsWith("Bearer ")
    ? authHeader.slice(7)
    : authHeader;
  if (!token) {
    return null;
  }
  try {
    const decoded = await admin.auth().verifyIdToken(token);
    return decoded.uid;
  } catch (e) {
    logger.warn("Auth verification failed", { error: e.message });
    return null;
  }
}

/**
 * Reads the user's usage counters from Firestore.
 * Returns { faceScanCount, coachInsightCount, planCount }.
 */
async function getUsage(uid) {
  try {
    const doc = await admin
      .firestore()
      .collection("users")
      .doc(uid)
      .collection("usage")
      .doc("counts")
      .get();
    if (!doc.exists) {
      return { faceScanCount: 0, coachInsightCount: 0, planCount: 0 };
    }
    const data = doc.data() || {};
    return {
      faceScanCount: data.faceScanCount || 0,
      coachInsightCount: data.coachInsightCount || 0,
      planCount: data.planCount || 0,
    };
  } catch (e) {
    logger.warn("Could not read usage", { error: e.message });
    return { faceScanCount: 0, coachInsightCount: 0, planCount: 0 };
  }
}

/**
 * Increments a usage counter for the user.
 */
async function incrementUsage(uid, field) {
  try {
    await admin
      .firestore()
      .collection("users")
      .doc(uid)
      .collection("usage")
      .doc("counts")
      .set({ [field]: admin.firestore.FieldValue.increment(1) }, { merge: true });
  } catch (e) {
    logger.warn("Could not increment usage", { error: e.message });
  }
}

/**
 * Checks whether the user is allowed to perform the given AI operation.
 * Returns { allowed: true } or { allowed: false, reason }.
 */
async function checkAccess(uid, operation) {
  const usage = await getUsage(uid);
  const limit = FREE_LIMITS[operation];
  if (limit == null) {
    return { allowed: true };
  }

  const count = usage[`${operation}Count`] || 0;
  if (count >= limit) {
    return {
      allowed: false,
      reason: `Free limit reached for ${operation}. Upgrade to Premium for unlimited access.`,
    };
  }
  return { allowed: true };
}

exports.generateDecision = onRequest(
  {
    cors: true,
    invoker: "public",
    secrets: [openAiApiKey],
    region: process.env.AI_FUNCTION_REGION || "us-central1",
    timeoutSeconds: 120,
    memory: "512MiB",
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Use POST for generateDecision." });
      return;
    }

    const { category, prompt, images = [], operation } = req.body ?? {};
    if (!prompt || typeof prompt !== "string") {
      res.status(400).json({ error: "prompt is required." });
      return;
    }

    // Verify the user is authenticated.
    const uid = await verifyAuth(req);
    if (!uid) {
      res.status(401).json({ error: "Authentication required." });
      return;
    }

    // Determine which usage bucket this request consumes.
    const op = typeof operation === "string" ? operation : "coachInsight";

    // Check access BEFORE making any expensive AI call.
    const access = await checkAccess(uid, op);
    if (!access.allowed) {
      res.status(403).json({ error: access.reason });
      return;
    }

    const normalizedCategory = typeof category === "string" ? category : "glowup";
    const provider = (process.env.AI_PROVIDER || "openai").toLowerCase();

    logger.info("Function received request", {
      uid,
      category: normalizedCategory,
      provider,
      operation: op,
      promptLength: prompt.length,
      imageCount: images.length,
    });

    try {
      const result = provider === "openai"
        ? await callOpenAi({ category: normalizedCategory, prompt, images })
        : await callGemini({ category: normalizedCategory, prompt, images });

      result.category = result.category || normalizedCategory;

      // Only increment usage AFTER a successful AI call.
      await incrementUsage(uid, `${op}Count`);

      res.status(200).json(result);
    } catch (error) {
      logger.error("generateDecision failed", error);
      res.status(500).json({
        error: "AI function failed.",
        details: error instanceof Error ? error.message : String(error),
      });
    }
  },
);

exports.generateGlowUpImage = onRequest(
  {
    cors: true,
    invoker: "public",
    secrets: [openAiApiKey],
    region: process.env.AI_FUNCTION_REGION || "us-central1",
    timeoutSeconds: 180,
    memory: "1GiB",
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Use POST for generateGlowUpImage." });
      return;
    }

    const { image, styleId, faceScanSummary } = req.body ?? {};
    if (!image || typeof image !== "object" || !image.data) {
      res.status(400).json({ error: "image with base64 data is required." });
      return;
    }

    // Verify the user is authenticated.
    const uid = await verifyAuth(req);
    if (!uid) {
      res.status(401).json({ error: "Authentication required." });
      return;
    }

    const style = glowUpStyles[styleId] || glowUpStyles["clean-girl"];
    logger.info("generateGlowUpImage request", {
      uid,
      styleId: style.id,
      prompt: style.generationPrompt,
      imageBytes: Math.round((image.data.length * 3) / 4),
    });

    try {
      const b64 = image.data.replace(/^data:image\/\w+;base64,/, "");
      const apiKey = openAiApiKey.value() || process.env.OPENAI_API_KEY || "";
      if (!apiKey) {
        throw new Error("OPENAI_API_KEY is missing.");
      }

      const model = process.env.OPENAI_IMAGE_MODEL || "gpt-image-1";
      const prompt = buildGlowUpPrompt(style, faceScanSummary);

      const response = await fetch("https://api.openai.com/v1/images/edits", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model,
          prompt,
          images: [
            {
              image_url: `data:${image.mimeType || "image/png"};base64,${b64}`,
            },
          ],
          size: "1024x1024",
          n: 1,
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        logger.error("OpenAI image generation failed", {
          status: response.status,
          safeError: errorText.slice(0, 500),
        });
        throw new Error(`OpenAI image generation failed: ${response.status} ${errorText}`);
      }

      const data = await response.json();
      const b64Json = data?.data?.[0]?.b64_json;
      if (!b64Json) {
        throw new Error("OpenAI image response missing b64_json.");
      }

      logger.info("OpenAI image response received", { status: response.status });
      res.status(200).json({
        image: b64Json,
        mimeType: "image/png",
        styleId: style.id,
        styleName: style.name,
      });
    } catch (error) {
      logger.error("generateGlowUpImage failed", error);
      res.status(500).json({
        error: "Image generation failed.",
        details: error instanceof Error ? error.message : String(error),
      });
    }
  },
);

const glowUpStyles = {
  "clean-girl": {
    id: "clean-girl",
    name: "Clean Girl",
    emoji: "✨",
    color: "#FF8FC7",
    generationPrompt:
      "Clean Girl aesthetic: natural, polished, fresh appearance with dewy skin, slicked-back low bun or glass hair, minimal makeup, neutral tones, gold minimal jewelry, white/beige/cream clothing.",
  },
  "soft-girl": {
    id: "soft-girl",
    name: "Soft Girl",
    emoji: "🎀",
    color: "#FFB6D9",
    generationPrompt:
      "Soft Girl aesthetic: soft feminine styling with pastel colors, gentle rosy makeup, soft waves or butterfly clips, lace and ribbon accents, blush cardigans and flowy skirts, dreamy romantic presentation.",
  },
  "old-money": {
    id: "old-money",
    name: "Old Money",
    emoji: "🖤",
    color: "#2E2140",
    generationPrompt:
      "Old Money aesthetic: elegant, sophisticated styling with refined sleek blowout or low chignon, minimal classic makeup, cashmere sweaters and tailored trousers, silk scarves, gold watch, timeless quiet luxury.",
  },
  glam: {
    id: "glam",
    name: "Glam",
    emoji: "💎",
    color: "#FF5FA2",
    generationPrompt:
      "Glam aesthetic: more defined makeup with polished eyes, contour, and glossy lips, elevated waves or sleek polished hair, statement accessories, elegant evening styling, confident high-gloss presentation.",
  },
  sporty: {
    id: "sporty",
    name: "Sporty",
    emoji: "🏃",
    color: "#FF8A65",
    generationPrompt:
      "Sporty aesthetic: fresh, athletic, natural styling with clean minimal makeup, high ponytail or braids, athleisure sets, sporty watch, lively energetic healthy presentation.",
  },
  minimalist: {
    id: "minimalist",
    name: "Minimalist",
    emoji: "🤍",
    color: "#B8A7FF",
    generationPrompt:
      "Minimalist aesthetic: simple, clean, understated styling with effortless natural hair, barely-there makeup, structured neutral clothing, subtle accessories, quiet refined simplicity.",
  },
};

function buildGlowUpPrompt(style, faceScanSummary) {
  const summary = faceScanSummary && typeof faceScanSummary === "string"
    ? faceScanSummary.trim()
    : "";
  const summaryPart = summary
    ? ` Use these analysis details as styling guidance: ${summary}`
    : "";
  return (
    `Use the uploaded person as the identity reference. ` +
    `Create a realistic style transformation inspired by the ${style.name} aesthetic. ` +
    `Preserve the person's recognizable facial identity, facial proportions, skin tone, and natural features. ` +
    `Change only the requested styling elements: ${style.generationPrompt}` +
    summaryPart +
    ` Produce a realistic, flattering, photorealistic result suitable as personal style inspiration.`
  );
}

async function callOpenAi({ category, prompt, images }) {
  const apiKey = openAiApiKey.value() || process.env.OPENAI_API_KEY || "";
  if (!apiKey) {
    throw new Error("OPENAI_API_KEY is missing. Set it with Firebase Secrets or functions/.secret.local for emulation.");
  }

  const model = process.env.OPENAI_MODEL || "gpt-4o-mini";
  const userContent = images.length
    ? [
        { type: "text", text: prompt },
        ...images.map((image) => ({
          type: "image_url",
          image_url: {
            url: `data:${image.mimeType || "image/jpeg"};base64,${image.data || ""}`,
          },
        })),
      ]
    : prompt;

  logger.info("OpenAI request started", {
    model,
    imageCount: images.length,
  });

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      messages: [
        {
          role: "system",
          content: `You are its giving.AI — a warm, encouraging beauty and wellness coach.
Your goal is to help the user enhance their natural glow, NOT judge or rank them.
Analyze appearance-related characteristics in a supportive, non-medical way:
- Skin appearance and skincare opportunities
- Face shape and styling compatibility
- Hairstyle compatibility
- Brow styling
- Makeup/styling opportunities
- Overall grooming
- Wellness, sleep, and lifestyle habits that affect glow

Always use encouraging language like "Here's what you can enhance" instead of "Here's what's wrong."
Never make medical diagnoses or claim to objectively determine beauty.
Never mention prices, products to buy, or Product A vs Product B comparisons.
Focus on achievable improvements: skincare habits, grooming, hairstyle inspiration, fitness/wellness, sleep, posture, styling, and lifestyle.

When relevant, also suggest natural remedies to support the user's glow-up goals:
- Natural skincare ingredients (aloe vera, green tea, honey, oatmeal, rose water, jojoba oil, coconut oil, shea butter)
- Herbal teas and infusions (chamomile, green tea, peppermint, ginger, hibiscus)
- Dietary suggestions (antioxidant-rich foods, omega-3s, vitamin C, hydration with lemon/cucumber)
- Lifestyle remedies (adequate sleep, stress reduction, facial massage, dry brushing, cold water splashes)
- Natural hair care (coconut oil masks, aloe vera gel, rosemary rinse, egg masks)
- Always frame these as gentle, supportive suggestions — never as medical treatment or a replacement for professional care.

Return strict JSON only with exact keys: best_choice, alternatives, reasoning, pros, cons, confidence_score, and category.
best_choice must be a short plain string, not an object.
alternatives, pros, and cons must each be arrays of short strings.`,
        },
        { role: "user", content: userContent },
      ],
      response_format: { type: "json_object" },
      temperature: 0.4,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    logger.error("OpenAI request failed", {
      status: response.status,
      safeError: errorText.slice(0, 500),
    });
    throw new Error(`OpenAI request failed: ${response.status} ${errorText}`);
  }

  logger.info("OpenAI response received", { status: response.status });

  const data = await response.json();
  const content = data?.choices?.[0]?.message?.content ?? "{}";
  const parsed = JSON.parse(content);
  return normalizeDecisionResult(parsed, category);
}

async function callGemini({ category, prompt, images }) {
  const apiKey = process.env.GEMINI_API_KEY || "";
  if (!apiKey) {
    throw new Error("GEMINI_API_KEY is missing in functions/.env or functions/.secret.local.");
  }

  const model = process.env.GEMINI_MODEL || "gemini-1.5-flash";
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        generationConfig: {
          temperature: 0.4,
          responseMimeType: "application/json",
        },
        contents: [
          {
            role: "user",
            parts: [
              { text: prompt },
              ...images.map((image) => ({
                inline_data: {
                  mime_type: image.mimeType || "image/jpeg",
                  data: image.data || "",
                },
              })),
            ],
          },
        ],
      }),
    },
  );

  if (!response.ok) {
    throw new Error(`Gemini request failed: ${response.status} ${await response.text()}`);
  }

  const data = await response.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}";
  const parsed = JSON.parse(stripJsonFence(text));
  return normalizeDecisionResult(parsed, category);
}

function normalizeDecisionResult(raw, fallbackCategory) {
  const safe = raw && typeof raw === "object" ? raw : {};
  const bestChoice = toReadableText(
    safe.best_choice ?? safe.bestChoice ?? safe.best ?? safe.recommendation ?? safe.top_pick,
  );
  const reasoning = toReadableText(
    safe.reasoning ?? safe.explanation ?? safe.why ?? safe.summary,
  );
  const confidence = toReadableText(
    safe.confidence_score ?? safe.confidenceScore ?? safe.confidence,
  );

  return {
    best_choice: bestChoice,
    alternatives: toStringArray(
      safe.alternatives ?? safe.options ?? safe.other_choices ?? safe.otherChoices,
    ),
    reasoning,
    pros: toStringArray(safe.pros ?? safe.benefits ?? safe.strengths),
    cons: toStringArray(safe.cons ?? safe.drawbacks ?? safe.weaknesses ?? safe.watchouts),
    confidence_score: confidence || "0.80",
    category: safe.category || fallbackCategory,
  };
}

function toStringArray(value) {
  if (Array.isArray(value)) {
    return value
      .map((item) => toReadableText(item))
      .filter((item) => item);
  }

  if (typeof value === "string") {
    return value
      .split(/\n|;|•/g)
      .map((item) => item.replace(/^[-*\s]+/, "").trim())
      .filter(Boolean);
  }

  const single = toReadableText(value);
  return single ? [single] : [];
}

function toReadableText(value) {
  if (value == null) {
    return "";
  }

  if (typeof value === "string") {
    return value.trim();
  }

  if (typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }

  if (Array.isArray(value)) {
    return value.map((item) => toReadableText(item)).filter(Boolean).join(", ");
  }

  if (typeof value === "object") {
    const primary = [
      value.name,
      value.title,
      value.destination,
      value.place,
      value.city,
      value.item,
      value.choice,
    ].find((item) => item != null && String(item).trim());

    const extras = [];
    if (value.budget != null && String(value.budget).trim()) {
      extras.push(`budget ${value.budget}`);
    }
    if (value.price != null && String(value.price).trim()) {
      extras.push(`price ${value.price}`);
    }
    if (value.type != null && String(value.type).trim()) {
      extras.push(String(value.type).trim());
    }
    if (value.itinerary && typeof value.itinerary === "object" && value.itinerary.days != null) {
      extras.push(`${value.itinerary.days} days`);
    }

    if (primary) {
      return [String(primary).trim(), ...extras].filter(Boolean).join(" • ");
    }

    return Object.entries(value)
      .slice(0, 3)
      .map(([key, item]) => `${key}: ${toReadableText(item)}`)
      .join(", ");
  }

  return String(value).trim();
}

function stripJsonFence(raw) {
  const trimmed = String(raw || "").trim();
  if (!trimmed.startsWith("```")) {
    return trimmed;
  }

  const lines = trimmed.split("\n");
  if (lines.length && lines[0].startsWith("```")) {
    lines.shift();
  }
  if (lines.length && lines[lines.length - 1].trim() === "```") {
    lines.pop();
  }
  return lines.join("\n").trim();
}