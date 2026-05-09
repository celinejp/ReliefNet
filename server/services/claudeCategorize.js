import Anthropic from "@anthropic-ai/sdk";

const ALLOWED = new Set(["Critical", "Medium", "Low"]);

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

  const model =
    process.env.CLAUDE_MODEL?.trim() || "claude-sonnet-4-20250514";

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

  const response = await anthropic.messages.create({
    model,
    max_tokens: 512,
    temperature: 0.2,
    system,
    messages: [{ role: "user", content: user }],
  });

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
}
