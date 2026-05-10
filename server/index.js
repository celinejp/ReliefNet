import "dotenv/config";
import cors from "cors";
import express from "express";
import mongoose from "mongoose";
import crypto from "node:crypto";
import { Alert } from "./models/Alert.js";
import { categorizeIncident } from "./services/claudeCategorize.js";
import {
  authConfigured,
  optionalBearerJwt,
  requireAdmin,
} from "./middleware/auth0Jwt.js";

const app = express();
app.use(cors());
app.use(express.json({ limit: "64kb" }));

app.get("/health", (_req, res) => {
  res.json({
    ok: true,
    mongo: mongoose.connection.readyState === 1,
    anthropic: Boolean(process.env.ANTHROPIC_API_KEY?.trim()),
    auth0: authConfigured(),
  });
});

app.get("/api/alerts", optionalBearerJwt, async (req, res) => {
  try {
    if (authConfigured()) {
      if (!req.authUser?.sub) {
        return res.status(401).json({ error: "Sign in required." });
      }
    }

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

    const match = {};
    if (validSeverity) match.severity = validSeverity;

    if (authConfigured() && req.authUser && !req.authUser.isAdmin) {
      match.auth0UserId = req.authUser.sub;
    }

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

app.get("/api/alerts/:id", optionalBearerJwt, async (req, res) => {
  try {
    const doc = await Alert.findById(req.params.id).lean();
    if (!doc) return res.status(404).json({ error: "Not found." });

    if (authConfigured()) {
      if (!req.authUser?.sub) {
        const publicGuest =
          doc.guestMode === true &&
          (doc.auth0UserId == null || doc.auth0UserId === "");
        if (!publicGuest) {
          return res.status(401).json({ error: "Sign in required." });
        }
        return res.json(doc);
      }
      const ownerId = doc.auth0UserId ?? null;
      const isOwner =
        ownerId != null && ownerId === req.authUser.sub;
      if (!req.authUser.isAdmin && !isOwner) {
        return res.status(403).json({ error: "Not allowed to view this alert." });
      }
    }

    res.json(doc);
  } catch (err) {
    console.error(err);
    res.status(400).json({ error: "Invalid id." });
  }
});

app.patch(
  "/api/alerts/:id/responder-status",
  optionalBearerJwt,
  requireAdmin,
  async (req, res) => {
    try {
      const status = req.body?.responderStatus;
      const allowed = ["open", "in_progress", "closed"];
      if (typeof status !== "string" || !allowed.includes(status)) {
        return res.status(400).json({
          error: `responderStatus must be one of: ${allowed.join(", ")}.`,
        });
      }

      const doc = await Alert.findByIdAndUpdate(
        req.params.id,
        { responderStatus: status },
        { new: true },
      ).lean();

      if (!doc) return res.status(404).json({ error: "Not found." });
      res.json(doc);
    } catch (err) {
      console.error(err);
      res.status(400).json({ error: "Invalid id." });
    }
  },
);

app.post("/api/alerts", optionalBearerJwt, async (req, res) => {
  const message =
    typeof req.body?.message === "string"
      ? req.body.message.trim()
      : typeof req.body?.text === "string"
        ? req.body.text.trim()
        : "";

  if (!message) {
    return res.status(400).json({ error: "Provide `message` (string)." });
  }

  const location =
    typeof req.body?.location === "string" ? req.body.location.trim() : "";
  const modeRaw =
    typeof req.body?.mode === "string" ? req.body.mode.trim().toLowerCase() : "";
  const mode = modeRaw === "offline" ? "offline" : "online";
  const sourceRaw =
    typeof req.body?.source === "string"
      ? req.body.source.trim().toLowerCase()
      : "";
  const source =
    sourceRaw === "offline_hub"
      ? "offline_hub"
      : sourceRaw === "local_cache"
        ? "local_cache"
        : "online_cloud";
  const syncStatusRaw =
    typeof req.body?.syncStatus === "string"
      ? req.body.syncStatus.trim().toLowerCase()
      : "";
  const syncStatus =
    syncStatusRaw === "pending"
      ? "pending"
      : syncStatusRaw === "failed"
        ? "failed"
        : "synced";

  const loggedIn = Boolean(req.authUser?.sub);
  const guestMode = !loggedIn;

  const alert = await Alert.create({
    rawMessage: message,
    processingStatus: "pending",
    auth0UserId: loggedIn ? req.authUser.sub : null,
    userEmail: loggedIn ? (req.authUser.email || "") : "",
    guestMode,
    location,
    mode,
    source,
    syncStatus,
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

app.post("/api/sync-alerts", optionalBearerJwt, async (req, res) => {
  try {
    const alerts = Array.isArray(req.body?.alerts) ? req.body.alerts : [];
    if (!alerts.length) {
      return res.status(400).json({ error: "Provide `alerts` (non-empty array)." });
    }

    const now = new Date();
    const makeFallbackClientAlertId = ({
      message,
      location,
      userId,
      userEmail,
      createdAt,
    }) => {
      const tsSec = Math.floor(new Date(createdAt || now).getTime() / 1000);
      const canonical = [
        String(message || "").trim().toLowerCase(),
        String(location || "").trim().toLowerCase(),
        String(userId || "").trim().toLowerCase(),
        String(userEmail || "").trim().toLowerCase(),
        String(tsSec),
      ].join("|");
      const digest = crypto
        .createHash("sha1")
        .update(canonical)
        .digest("hex")
        .slice(0, 16);
      return `sync_${digest}`;
    };

    const normalizeClientAlertId = (value) => {
      const id = String(value || "").trim();
      if (!id) return "";
      // Guard against legacy double-prefix forms (hub_hub_...)
      if (id.startsWith("hub_hub_")) return id.replace(/^hub_/, "");
      return id;
    };

    const docs = alerts
      .map((raw) => {
        const message =
          typeof raw?.message === "string" ? raw.message.trim() : "";
        if (!message) return null;
        const location =
          typeof raw?.location === "string" ? raw.location.trim() : "";
        const userIdRaw =
          typeof raw?.userId === "string" ? raw.userId.trim() : "";
        const userEmailRaw =
          typeof raw?.userEmail === "string" ? raw.userEmail.trim() : "";
        const createdAtRaw = new Date(raw?.createdAt || now);
        const createdAt = Number.isNaN(createdAtRaw.getTime()) ? now : createdAtRaw;
        const providedClientAlertId = normalizeClientAlertId(raw?.clientAlertId);
        const clientAlertId =
          providedClientAlertId ||
          makeFallbackClientAlertId({
            message,
            location,
            userId: req.authUser?.sub || userIdRaw || "",
            userEmail: req.authUser?.email || userEmailRaw || "",
            createdAt,
          });
        const loggedIn = Boolean(req.authUser?.sub || userIdRaw);
        return {
          rawMessage: message,
          processingStatus: "pending",
          auth0UserId: req.authUser?.sub || userIdRaw || null,
          clientAlertId,
          userEmail: req.authUser?.email || userEmailRaw || "",
          guestMode: !loggedIn,
          location,
          mode: "offline",
          source: "offline_hub",
          syncStatus: "synced",
          createdAt,
          updatedAt: now,
        };
      })
      .filter(Boolean);

    if (!docs.length) {
      return res.status(400).json({ error: "No valid alerts to sync." });
    }

    for (const doc of docs) {
      try {
        const ai = await categorizeIncident(doc.rawMessage);
        doc.severity = ai.severity;
        doc.category = ai.category;
        doc.summary = ai.summary;
        doc.processingStatus = "complete";
        doc.aiError = "";
      } catch (err) {
        doc.processingStatus = "failed";
        doc.aiError = err instanceof Error ? err.message : String(err);
      }
    }

    const result = [];
    for (const doc of docs) {
      // First pass: strict idempotency by clientAlertId.
      const byClientId = await Alert.findOneAndUpdate(
        { clientAlertId: doc.clientAlertId },
        {
          $set: {
            severity: doc.severity,
            category: doc.category,
            summary: doc.summary,
            processingStatus: doc.processingStatus,
            aiError: doc.aiError,
            syncStatus: "synced",
            updatedAt: new Date(),
          },
        },
        { new: true },
      ).lean();
      if (byClientId) {
        result.push(byClientId);
        continue;
      }

      // Second pass: fingerprint + nearby timestamp to absorb legacy id mismatches.
      const nearWindowMs = 2 * 60 * 1000;
      const byFingerprint = await Alert.findOneAndUpdate(
        {
          source: "offline_hub",
          mode: "offline",
          rawMessage: doc.rawMessage,
          location: doc.location,
          auth0UserId: doc.auth0UserId ?? null,
          userEmail: doc.userEmail || "",
          createdAt: {
            $gte: new Date(doc.createdAt.getTime() - nearWindowMs),
            $lte: new Date(doc.createdAt.getTime() + nearWindowMs),
          },
        },
        {
          $set: {
            severity: doc.severity,
            category: doc.category,
            summary: doc.summary,
            processingStatus: doc.processingStatus,
            aiError: doc.aiError,
            syncStatus: "synced",
            updatedAt: new Date(),
          },
        },
        { new: true, sort: { updatedAt: -1 } },
      ).lean();
      if (byFingerprint) {
        result.push(byFingerprint);
        continue;
      }

      // Final pass: insert new offline-hub alert.
      const inserted = await Alert.findOneAndUpdate(
        { clientAlertId: doc.clientAlertId },
        {
          $setOnInsert: {
            rawMessage: doc.rawMessage,
            auth0UserId: doc.auth0UserId,
            clientAlertId: doc.clientAlertId,
            userEmail: doc.userEmail,
            guestMode: doc.guestMode,
            location: doc.location,
            mode: "offline",
            source: "offline_hub",
            createdAt: doc.createdAt,
          },
          $set: {
            severity: doc.severity,
            category: doc.category,
            summary: doc.summary,
            processingStatus: doc.processingStatus,
            aiError: doc.aiError,
            syncStatus: "synced",
            updatedAt: new Date(),
          },
        },
        { upsert: true, new: true },
      ).lean();
      result.push(inserted);
    }
    return res.status(201).json(result);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Failed to sync offline alerts." });
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

app.listen(port, "0.0.0.0", () => {
  console.log(`ReliefNet API listening on :${port}`);
  if (authConfigured()) {
    console.log("Auth0 JWT verification enabled for protected routes.");
  } else {
    console.log(
      "Auth0 not configured (set AUTH0_ISSUER_BASE_URL + AUTH0_AUDIENCE to enforce login).",
    );
  }
});
