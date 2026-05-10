// server/services/personMatcher.js

const Anthropic = require("@anthropic-ai/sdk");
const PersonReport = require("../models/PersonReport");
const PersonGroup = require("../models/PersonGroup");

const client = new Anthropic();

async function matchPersonReport(newReport) {
  try {
    // Compare against ALL other unresolved reports
    // Now matches looking+found AND looking+looking AND found+found
    const existingReports = await PersonReport.find({
      resolved: false,
      _id: { $ne: newReport._id },
    });

    if (existingReports.length === 0) {
      console.log("No existing reports to compare against.");
      return null;
    }

    const formattedExisting = existingReports.map((r) => ({
      id: r._id.toString(),
      reportType: r.reportType,
      name: r.name,
      age: r.approximateAge,
      gender: r.gender,
      description: r.descriptionText,
      location: r.locationText,
      emergency: r.emergencyLevel,
      injured: r.isInjured,
      unconscious: r.isUnconscious,
      time: r.lastSeenAt,
    }));

    const newReportFormatted = {
      reportType: newReport.reportType,
      name: newReport.name,
      age: newReport.approximateAge,
      gender: newReport.gender,
      description: newReport.descriptionText,
      location: newReport.locationText,
      emergency: newReport.emergencyLevel,
      injured: newReport.isInjured,
      unconscious: newReport.isUnconscious,
      time: newReport.lastSeenAt,
    };

    const prompt = `
You are a disaster relief assistant identifying if multiple reports describe the same missing or found person.

NEW REPORT (type: ${newReport.reportType}):
${JSON.stringify(newReportFormatted, null, 2)}

EXISTING REPORTS:
${JSON.stringify(formattedExisting, null, 2)}

MATCHING RULES:
- Match reports of ANY type combination (looking+found, looking+looking, found+found)
- Two "looking" reports can match if families are searching for the same person
- Two "found" reports can match if witnesses saw the same person at different times
- Be generous — disaster descriptions are incomplete and messy
- Consider: age overlap, gender, clothing colors, physical features, location, injury details
- Ignore minor wording differences ("red jacket" vs "red coat" = same)

Return ONLY valid JSON, no markdown, no extra text:
{
  "matches": [
    {
      "id": "report id here",
      "confidence": "high or medium or low",
      "reason": "short explanation why they match"
    }
  ]
}

If no matches found return: { "matches": [] }
`;

    const response = await client.messages.create({
      model: "claude-sonnet-4-5",
      max_tokens: 1000,
      messages: [{ role: "user", content: prompt }],
    });

    const rawText = response.content[0].text.trim();

    let parsed;
    try {
      const cleaned = rawText
        .replace(/```json/g, "")
        .replace(/```/g, "")
        .trim();
      parsed = JSON.parse(cleaned);
    } catch (e) {
      console.error("Claude returned invalid JSON:", rawText);
      return null;
    }

    const matches = parsed.matches;
    if (!matches || matches.length === 0) {
      console.log("Claude found no matches.");
      return null;
    }

    const confidenceOrder = { high: 3, medium: 2, low: 1 };
    matches.sort(
      (a, b) =>
        confidenceOrder[b.confidence] - confidenceOrder[a.confidence]
    );
    const bestMatch = matches[0];

    const matchedReport = await PersonReport.findById(bestMatch.id);
    if (!matchedReport) return null;

    const emergencyRank = { critical: 3, stable: 1, unknown: 0 };
    const highestEmergency =
      emergencyRank[newReport.emergencyLevel] >=
      emergencyRank[matchedReport.emergencyLevel]
        ? newReport.emergencyLevel
        : matchedReport.emergencyLevel;

    const group = await PersonGroup.create({
      reportIds: [newReport._id, matchedReport._id],
      confidence: bestMatch.confidence,
      aiReason: bestMatch.reason,
      representativeName:
        newReport.name !== "Unknown" ? newReport.name : matchedReport.name,
      highestEmergency,
    });

    await PersonReport.updateMany(
      { _id: { $in: [newReport._id, matchedReport._id] } },
      { resolved: true, groupId: group._id }
    );

    console.log(`Match found! Group created: ${group._id}`);
    return group;
  } catch (error) {
    console.error("Error in personMatcher:", error);
    return null;
  }
}

module.exports = { matchPersonReport };
