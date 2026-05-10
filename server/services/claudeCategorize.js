import Anthropic, { NotFoundError } from "@anthropic-ai/sdk";

const ALLOWED = new Set(["Critical", "Medium", "Low"]);

/** Cached model ids from GET /v1/models (per process). */
let listedModelIdsCache = null;

/** Last model id that successfully completed a Messages request. */
let resolvedWorkingModel = null;

const STATIC_MODEL_FALLBACKS = [
  "claude-3-5-haiku-20241022",
  "claude-3-5-sonnet-20241022",
  "claude-3-opus-20240229",
  "claude-sonnet-4-5-20250929",
  "claude-haiku-4-20250514",
];

function modelPreferenceScore(id) {
  const s = id.toLowerCase();
  if (s.includes("sonnet")) return 4;
  if (s.includes("opus")) return 3;
  if (s.includes("haiku")) return 2;
  return 1;
}

function isModelNotFound(err) {
  if (!err || typeof err !== "object") return false;
  if (err instanceof NotFoundError) return true;
  if (err.status !== 404) return false;
  const inner = err.error?.error ?? err.error;
  return inner?.type === "not_found_error";
}

async function fetchListedModelIds(anthropic) {
  if (listedModelIdsCache !== null) return listedModelIdsCache;
  try {
    const page = await anthropic.models.list({ limit: 50 });
    const ids = page.data.map((m) => m.id).filter(Boolean);
    listedModelIdsCache = [...ids].sort(
      (a, b) => modelPreferenceScore(b) - modelPreferenceScore(a),
    );
  } catch {
    listedModelIdsCache = [];
  }
  return listedModelIdsCache;
}

async function buildModelCandidates(anthropic) {
  const explicit = process.env.CLAUDE_MODEL?.trim();
  const seen = new Set();
  const out = [];

  const add = (id) => {
    if (!id || seen.has(id)) return;
    seen.add(id);
    out.push(id);
  };

  if (resolvedWorkingModel) add(resolvedWorkingModel);
  if (explicit) add(explicit);

  for (const id of await fetchListedModelIds(anthropic)) add(id);
  for (const id of STATIC_MODEL_FALLBACKS) add(id);

  if (out.length === 0) {
    throw new Error(
      "No Claude model candidates. Create an API key at console.anthropic.com, set ANTHROPIC_API_KEY, " +
        "and optionally CLAUDE_MODEL to a model id shown for your workspace.",
    );
  }
  return out;
}

function extractJsonObject(text) {
  const trimmed = text.trim();
  const fence = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/i);
  const payload = fence ? fence[1].trim() : trimmed;
  const start = payload.indexOf("{");
  const end = payload.lastIndexOf("}");
  if (start === -1 || end === -1 || end <= start) {
    throw new Error("Claude response did not contain a JSON object.");
  }
  return JSON.parse(payload.slice(start, end + 1));
}

export async function categorizeIncident(rawMessage) {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    throw new Error("ANTHROPIC_API_KEY is not set.");
  }

  const anthropic = new Anthropic({ apiKey });

  const system = [
    "You are an emergency/disaster triage assistant.",
    "Given a messy user report, respond with ONLY a JSON object (no markdown, no prose) with keys:",
    '- "severity": one of "Critical", "Medium", "Low"',
    '- "category": short structured label (e.g. "Medical + Structural Collapse")',
    '- "summary": one concise professional sentence describing the incident',
    "If unclear, choose the safest severity (prefer Critical when safety is ambiguous).",
  ].join(" ");

  const user = `Disaster report:\n"""${rawMessage.trim()}"""`;

  const candidates = await buildModelCandidates(anthropic);
  let lastErr;

  for (const model of candidates) {
    try {
      const response = await anthropic.messages.create({
        model,
        max_tokens: 512,
        temperature: 0.2,
        system,
        messages: [{ role: "user", content: user }],
      });

      resolvedWorkingModel = model;

      const textBlocks = response.content.filter((b) => b.type === "text");
      const text = textBlocks.map((b) => b.text).join("\n").trim();
      if (!text) {
        throw new Error("Empty response from Claude.");
      }

      const parsed = extractJsonObject(text);
      let severity = parsed.severity;
      if (typeof severity !== "string" || !ALLOWED.has(severity)) {
        severity = "Medium";
      }

      const category =
        typeof parsed.category === "string" ? parsed.category.trim() : "";
      const summary =
        typeof parsed.summary === "string" ? parsed.summary.trim() : "";

      return {
        severity,
        category: category || "General",
        summary: summary || rawMessage.trim(),
      };
    } catch (err) {
      if (isModelNotFound(err)) {
        lastErr = err;
        if (resolvedWorkingModel === model) resolvedWorkingModel = null;
        continue;
      }
      throw err;
    }
  }

  throw lastErr instanceof Error
    ? lastErr
    : new Error("No Claude model accepted by the API for this key.");
}
