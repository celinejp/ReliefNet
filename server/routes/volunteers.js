import express from "express";
import multer from "multer";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import Need from "../models/Need.js";
import Volunteer from "../models/Volunteer.js";
import { runVolunteerMatching } from "../services/volunteerMatcher.js";

const router = express.Router();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const uploadDir = path.join(__dirname, "../uploads");
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) =>
    cb(null, `${Date.now()}${path.extname(file.originalname)}`),
});
const upload = multer({ storage });

function parseCategories(raw) {
  if (Array.isArray(raw)) return raw.filter(Boolean);
  if (typeof raw !== "string") return [];
  const v = raw.trim();
  if (!v) return [];
  try {
    const parsed = JSON.parse(v);
    if (Array.isArray(parsed)) return parsed.map(String).filter(Boolean);
  } catch {}
  return v.split(",").map((s) => s.trim()).filter(Boolean);
}

router.post("/needs", upload.single("photo"), async (req, res) => {
  try {
    console.log("POST /api/needs — body:", req.body);
    const { name, phone, categories, urgency, description, locationText, lat, lng, numberOfPeople } = req.body;

    const need = await Need.create({
      name,
      phone,
      categories: parseCategories(categories),
      urgency: urgency || "normal",
      description: description || "",
      photoUrl: req.file ? `/uploads/${req.file.filename}` : "",
      locationText: locationText || "",
      coordinates: {
        lat: lat ? parseFloat(lat) : null,
        lng: lng ? parseFloat(lng) : null,
      },
      numberOfPeople: numberOfPeople || 1,
    });

    res.status(201).json({ success: true, need });

    const io = req.app.get("io");
    runVolunteerMatching(io)
      .then((matches) => { if (matches.length > 0) console.log(`Auto-match found ${matches.length} matches`); })
      .catch((err) => console.error("Auto-match error:", err));
  } catch (error) {
    console.error("Error saving need:", error);
    res.status(500).json({ success: false, message: error.message });
  }
});

router.get("/needs", async (req, res) => {
  try {
    const needs = await Need.find().sort({ createdAt: -1 });
    res.json({ success: true, needs });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post("/volunteers", upload.single("photo"), async (req, res) => {
  try {
    console.log("POST /api/volunteers — body:", req.body);
    const { name, phone, categories, description, locationText, lat, lng, capacity } = req.body;

    const volunteer = await Volunteer.create({
      name,
      phone,
      categories: parseCategories(categories),
      description: description || "",
      photoUrl: req.file ? `/uploads/${req.file.filename}` : "",
      locationText: locationText || "",
      coordinates: {
        lat: lat ? parseFloat(lat) : null,
        lng: lng ? parseFloat(lng) : null,
      },
      capacity: capacity || 1,
    });

    res.status(201).json({ success: true, volunteer });

    const io = req.app.get("io");
    runVolunteerMatching(io)
      .then((matches) => { if (matches.length > 0) console.log(`Auto-match found ${matches.length} matches`); })
      .catch((err) => console.error("Auto-match error:", err));
  } catch (error) {
    console.error("Error saving volunteer:", error);
    res.status(500).json({ success: false, message: error.message });
  }
});

router.get("/volunteers", async (req, res) => {
  try {
    const volunteers = await Volunteer.find().sort({ createdAt: -1 });
    res.json({ success: true, volunteers });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

export default router;
