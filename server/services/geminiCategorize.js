import { GoogleGenerativeAI } from "@google/generative-ai";

const ALLOWED = new Set(["Critical", "Medium", "Low"]);

function extractJsonObject(text) {
  const trimmed = text.trim();
  const fence = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/i);
  const payload = fence ? fence[1].trim() : trimmed;
  const start = payload.indexOf("{");
  const end = payload.lastIndexOf("}");
  if (start === -1 || end === -1 || end <= start) {
    throw new Error("Model response did not contain a JSON object.");
  }
  return JSON.parse(payload.slice(start, end + 1));
}

/**
 * Uses Google Gemini to classify disaster reports into severity / category / summary.
 * @param {string} rawMessage
 * @returns {Promise<{ severity: string, category: string, summary: string }>}
 */
export async function categorizeIncident(rawMessage) {
  const apiKey = process.env.GEMINI_API_KEY?.trim();
  if (!apiKey) {
    throw new Error("GEMINI_API_KEY is not set.");
  }

  const modelId =
    process.env.GEMINI_MODEL?.trim() || "gemini-2.0-flash";

  const genAI = new GoogleGenerativeAI(apiKey);

  const systemInstruction = [
    "You are an emergency and disaster triage assistant.",
    'Respond with a single JSON object only. Keys: "severity", "category", "summary".',
    'severity must be exactly one of: "Critical", "Medium", "Low".',
    'category is a short structured label (e.g. "Medical + Structural Collapse").',
    "summary is one concise professional sentence describing the incident.",
    "If the situation is ambiguous for safety, prefer Critical over lower severities.",
  ].join(" ");

  const model = genAI.getGenerativeModel({
    model: modelId,
    systemInstruction,
    generationConfig: {
      temperature: 0.2,
      maxOutputTokens: 512,
      responseMimeType: "application/json",
    },
  });

  const userText = `Disaster report:\n${JSON.stringify(rawMessage.trim())}`;

  const result = await model.generateContent({
    contents: [{ role: "user", parts: [{ text: userText }] }],
  });

  const text = result.response.text();
  if (!text?.trim()) {
    throw new Error("Empty response from Gemini.");
  }

  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch {
    parsed = extractJsonObject(text);
  }

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
}
