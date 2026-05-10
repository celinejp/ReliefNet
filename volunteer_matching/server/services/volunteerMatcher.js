const Anthropic = require("@anthropic-ai/sdk");
const Need = require("../models/Need");
const Volunteer = require("../models/Volunteer");
const VolunteerMatch = require("../models/VolunteerMatch");

const client = new Anthropic();

async function runVolunteerMatching(io) {
  try {
    const unmatchedNeeds = await Need.find({ status: "unmatched" });
    if (unmatchedNeeds.length === 0) {
      console.log("No unmatched needs.");
      return [];
    }

    const availableVolunteers = await Volunteer.find({ status: "available" });
    if (availableVolunteers.length === 0) {
      console.log("No available volunteers.");
      return [];
    }

    const formattedNeeds = unmatchedNeeds.map(n => ({
      id: n._id.toString(),
      name: n.name,
      categories: n.categories,
      urgency: n.urgency,
      description: n.description,
      location: n.locationText,
      numberOfPeople: n.numberOfPeople
    }));

    const formattedVolunteers = availableVolunteers.map(v => ({
      id: v._id.toString(),
      name: v.name,
      categories: v.categories,
      description: v.description,
      location: v.locationText,
      capacity: v.capacity
    }));

    const prompt = `
You are a disaster relief coordinator matching people who need help with volunteers.

PEOPLE WHO NEED HELP:
${JSON.stringify(formattedNeeds, null, 2)}

AVAILABLE VOLUNTEERS:
${JSON.stringify(formattedVolunteers, null, 2)}

MATCHING RULES:
- Match based on overlapping categories
- Prioritize CRITICAL urgency needs first
- Consider location proximity if mentioned
- One volunteer matches one need only
- One need matches one volunteer only

Return ONLY valid JSON, no markdown, no extra text:
{
  "matches": [
    {
      "needId": "need id here",
      "volunteerId": "volunteer id here",
      "confidence": "high or medium or low",
      "reason": "short explanation"
    }
  ]
}

If no matches possible return: { "matches": [] }
`;

    const response = await client.messages.create({
      model: "claude-sonnet-4-5",
      max_tokens: 1000,
      messages: [{ role: "user", content: prompt }]
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
      return [];
    }

    const matches = parsed.matches;
    if (!matches || matches.length === 0) {
      console.log("Claude found no matches.");
      return [];
    }

    const savedMatches = [];
    for (const match of matches) {
      const savedMatch = await VolunteerMatch.create({
        needId: match.needId,
        volunteerId: match.volunteerId,
        confidence: match.confidence,
        aiReason: match.reason
      });

      await Need.findByIdAndUpdate(match.needId, {
        status: "matched",
        matchId: savedMatch._id
      });

      await Volunteer.findByIdAndUpdate(match.volunteerId, {
        status: "matched",
        matchId: savedMatch._id
      });

      savedMatches.push(savedMatch);
      console.log(`Match created: ${savedMatch._id}`);

      if (io) {
        io.emit("volunteer-match-found", {
          matchId: savedMatch._id.toString(),
          needId: match.needId,
          volunteerId: match.volunteerId,
          confidence: match.confidence,
          reason: match.reason
        });
      }
    }

    return savedMatches;
  } catch (error) {
    console.error("Error in volunteerMatcher:", error);
    return [];
  }
}

module.exports = { runVolunteerMatching };
