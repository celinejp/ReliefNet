import "dotenv/config";
import cors from "cors";
import express from "express";
import mongoose from "mongoose";
import { Alert } from "./models/Alert.js";
import { categorizeIncident } from "./services/claudeCategorize.js";

const app = express();
app.use(cors());
app.use(express.json({ limit: "64kb" }));

app.get("/health", (_req, res) => {
  res.json({ ok: true, mongo: mongoose.connection.readyState === 1 });
});

app.get("/api/alerts", async (_req, res) => {
  try {
    const alerts = await Alert.find().sort({ createdAt: -1 }).limit(200).lean();
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

await mongoose.connect(mongoUri);

app.listen(port, "0.0.0.0", () => {
  console.log(`ReliefNet API listening on :${port}`);
});
