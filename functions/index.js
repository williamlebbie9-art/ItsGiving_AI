const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

const openAiApiKey = defineSecret("OPENAI_API_KEY");

if (!admin.apps.length) {
  admin.initializeApp();
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

    const { category, prompt, images = [] } = req.body ?? {};
    if (!prompt || typeof prompt !== "string") {
      res.status(400).json({ error: "prompt is required." });
      return;
    }

    const normalizedCategory = typeof category === "string" ? category : "products";
    const provider = (process.env.AI_PROVIDER || "openai").toLowerCase();

    try {
      const result = provider === "openai"
        ? await callOpenAi({ category: normalizedCategory, prompt, images })
        : await callGemini({ category: normalizedCategory, prompt, images });

      result.category = result.category || normalizedCategory;
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

// (RevenueCat webhook removed)

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
          content: "Return strict JSON only with exact keys: best_choice, alternatives, reasoning, pros, cons, confidence_score, and category. best_choice must be a short plain string, not an object. alternatives, pros, and cons must each be arrays of short strings.",
        },
        { role: "user", content: userContent },
      ],
      response_format: { type: "json_object" },
      temperature: 0.4,
    }),
  });

  if (!response.ok) {
    throw new Error(`OpenAI request failed: ${response.status} ${await response.text()}`);
  }

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
