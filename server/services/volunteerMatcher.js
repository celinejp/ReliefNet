import Anthropic from "@anthropic-ai/sdk";
import Need from "../models/Need.js";
import Volunteer from "../models/Volunteer.js";
import VolunteerMatch from "../models/VolunteerMatch.js";

function getDistanceMiles(lat1, lng1, lat2, lng2) {
  if (!lat1 || !lng1 || !lat2 || !lng2) return null;
  const R = 3959;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) *
    Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) *
    Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

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

    const needsWithCandidates = unmatchedNeeds.map((need) => {
      const candidates = availableVolunteers
        .map((v) => {
          const dist = getDistanceMiles(
            need.coordinates?.lat, need.coordinates?.lng,
            v.coordinates?.lat, v.coordinates?.lng
          );
          return {
            id: v._id.toString(),
            name: v.name,
            categories: v.categories,
            description: v.description,
            location: v.locationText,
            capacity: v.capacity,
            distance_miles: dist !== null ? Math.round(dist * 10) / 10 : null,
          };
        })
        .filter((v) => v.distance_miles === null || v.distance_miles <= 15);

      return {
        need: {
          id: need._id.toString(),
          name: need.name,
          categories: need.categories,
          urgency: need.urgency,
          description: need.description,
          location: need.locationText,
          numberOfPeople: need.numberOfPeople,
        },
        candidates,
      };
    });

    const prompt = `
You are a disaster relief coordinator matching people who need help with volunteers.

DISTANCE RULE: Only match needs and volunteers within 15 miles of each other. Each candidate volunteer has a distance_miles field showing distance from the need. Ignore pairs where distance_miles > 15. If distance_miles is null, use location text to judge proximity.

NEEDS WITH NEARBY VOLUNTEER CANDIDATES (pre-filtered to within 15 miles):
${JSON.stringify(needsWithCandidates, null, 2)}

MATCHING RULES:
- Match based on overlapping categories
- Prioritize CRITICAL urgency needs first
- One volunteer matches one need only
- One need matches one volunteer only
- Only match from the candidates list provided for each need

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
        aiReason: match.reason,
      });

      await Need.findByIdAndUpdate(match.needId, {
        status: "matched",
        matchId: savedMatch._id,
      });

      await Volunteer.findByIdAndUpdate(match.volunteerId, {
        status: "matched",
        matchId: savedMatch._id,
      });

      savedMatches.push(savedMatch);
      console.log(`Match created: ${savedMatch._id}`);

      if (io) {
        io.emit("volunteer-match-found", {
          matchId: savedMatch._id.toString(),
          needId: match.needId,
          volunteerId: match.volunteerId,
          confidence: match.confidence,
          reason: match.reason,
        });
      }
    }

    return savedMatches;
  } catch (error) {
    console.error("Error in volunteerMatcher:", error);
    return [];
  }
}

export { runVolunteerMatching };
