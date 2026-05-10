import "dotenv/config";
import cors from "cors";
import express from "express";
import mongoose from "mongoose";
import path from "path";
import { fileURLToPath } from "url";
import { Alert } from "./models/Alert.js";
import { categorizeIncident } from "./services/claudeCategorize.js";
import personReportRoutes from "./routes/person-reports.js";
import volunteerRoutes from "./routes/volunteers.js";
import donationRoutes from "./routes/donations.js";
import matchRoutes from "./routes/match-volunteers.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.use(cors());
app.use(express.json({ limit: "64kb" }));

app.get("/health", (_req, res) => {
  res.json({
    ok: true,
    mongo: mongoose.connection.readyState === 1,
    anthropic: Boolean(process.env.ANTHROPIC_API_KEY?.trim()),
  });
});

app.get("/api/alerts", async (req, res) => {
  try {
    const severity =
      typeof req.query.severity === "string" ? req.query.severity.trim() : "";
    const validSeverity =
      severity === "Critical" || severity === "Medium" || severity === "Low"
        ? severity
        : "";

    const limitRaw = Number(req.query.limit);
    const limit =
      Number.isFinite(limitRaw) && limitRaw > 0 && limitRaw <= 500
        ? Math.floor(limitRaw)
        : 200;

    const match = validSeverity ? { severity: validSeverity } : {};

    const pipeline = [
      { $match: match },
      {
        $addFields: {
          _prio: {
            $switch: {
              branches: [
                { case: { $eq: ["$severity", "Critical"] }, then: 0 },
                { case: { $eq: ["$severity", "Medium"] }, then: 1 },
                { case: { $eq: ["$severity", "Low"] }, then: 2 },
              ],
              default: 3,
            },
          },
        },
      },
      { $sort: { _prio: 1, createdAt: -1 } },
      { $limit: limit },
      { $project: { _prio: 0 } },
    ];

    const alerts = await Alert.aggregate(pipeline);
    res.json(alerts);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to list alerts." });
  }
});

app.get("/api/alerts/:id", async (req, res) => {
  try {
    const doc = await Alert.findById(req.params.id).lean();
    if (!doc) return res.status(404).json({ error: "Not found." });
    res.json(doc);
  } catch (err) {
    console.error(err);
    res.status(400).json({ error: "Invalid id." });
  }
});

app.post("/api/alerts", async (req, res) => {
  const message =
    typeof req.body?.message === "string"
      ? req.body.message.trim()
      : typeof req.body?.text === "string"
        ? req.body.text.trim()
        : "";

  if (!message) {
    return res.status(400).json({ error: "Provide `message` (string)." });
  }

  const alert = await Alert.create({
    rawMessage: message,
    processingStatus: "pending",
  });

  try {
    const ai = await categorizeIncident(message);
    alert.severity = ai.severity;
    alert.category = ai.category;
    alert.summary = ai.summary;
    alert.processingStatus = "complete";
    alert.aiError = "";
    await alert.save();
    return res.status(201).json(alert.toObject());
  } catch (err) {
    console.error(err);
    alert.processingStatus = "failed";
    alert.aiError = err instanceof Error ? err.message : String(err);
    await alert.save();
    return res.status(201).json(alert.toObject());
  }
});

const port = Number(process.env.PORT || 3000);
const mongoUri = process.env.MONGODB_URI?.trim();

if (!mongoUri) {
  console.error(
    [
      "Missing MONGODB_URI.",
      "",
      "1) From the server folder, create .env without overwriting an existing file:",
      "     npm run init-env",
      "",
      "2) Edit server/.env and paste your MongoDB Atlas connection string.",
      "",
      "If `cp .env.example .env` failed with “Not a directory”, you may have a "
        + "folder named `.env` — delete it first:",
      "     rm -rf .env",
      "",
      "3) Only run `npm start` after step 2 saves your URI.",
      "",
      "Tip: Paste ONE combined command so setup finishes before start:",
      "     npm run init-env && npm start",
    ].join("\n"),
  );
  process.exit(1);
}

function mongoSrvHostname(uri) {
  const m = String(uri).match(/^mongodb\+srv:\/\/[^@]+@([^/?#]+)/i);
  return m?.[1] ?? null;
}

function printMongoConnectionHelp(uri, err) {
  const host = mongoSrvHostname(uri);
  const firstLine = (err?.message ?? String(err)).split("\n")[0];
  console.error("\nMongoDB connection failed.");
  if (host) console.error(`  SRV host in MONGODB_URI: ${host}`);
  console.error(`  ${firstLine}`);
  console.error(
    [
      "",
      "Typical fixes for Atlas + mongoose:",
      "  1) Atlas → Database Access: username/password must match the URI (reset DB user password if unsure).",
      "  2) Atlas → Connect → Drivers: copy the full connection string, insert the password, paste as MONGODB_URI.",
      "     Encode special chars in the password (e.g. @ → %40, # → %23).",
      "  3) Atlas → Network Access: add your current public IP or 0.0.0.0/0 for local dev.",
      "  4) If you use Node 24+, try Node 20 LTS (nvm install 20 && nvm use 20) for TLS/driver compatibility.",
      "",
    ].join("\n"),
  );
}

try {
  await mongoose.connect(mongoUri, { serverSelectionTimeoutMS: 15_000 });
} catch (err) {
  printMongoConnectionHelp(mongoUri, err);
  process.exit(1);
}

// Person Report routes
app.use("/api/person-reports", personReportRoutes);
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// Volunteer & Need routes
app.use("/api", volunteerRoutes);

// Donation routes
app.use("/api/donations", donationRoutes);

// Volunteer matching routes
app.use("/api/match-volunteers", matchRoutes);

app.listen(port, "0.0.0.0", () => {
  console.log(`ReliefNet API listening on :${port}`);
});
