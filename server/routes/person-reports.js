import express from "express";
import multer from "multer";
import path from "path";
import { fileURLToPath } from "url";
import PersonReport from "../models/PersonReport.js";
import PersonGroup from "../models/PersonGroup.js";
import { matchPersonReport } from "../services/personMatcher.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = express.Router();

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.join(__dirname, "../uploads/"));
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});
const upload = multer({ storage });

router.post("/", upload.single("photo"), async (req, res) => {
  console.log("POST /api/person-reports hit — body keys:", Object.keys(req.body));
  try {
    const {
      reportType, name, approximateAge, gender, descriptionText,
      isInjured, isUnconscious, emergencyLevel, locationText,
      lat, lng, lastSeenAt, reporterName, reporterPhone,
    } = req.body;

    const reportData = {
      reportType,
      name: name || "Unknown",
      approximateAge: approximateAge || "",
      gender: gender || "unknown",
      descriptionText,
      isInjured: isInjured === "true" || isInjured === true,
      isUnconscious: isUnconscious === "true" || isUnconscious === true,
      emergencyLevel: emergencyLevel || "unknown",
      locationText: locationText || "",
      coordinates: {
        lat: lat ? parseFloat(lat) : null,
        lng: lng ? parseFloat(lng) : null,
      },
      lastSeenAt: lastSeenAt ? new Date(lastSeenAt) : new Date(),
      reporterName,
      reporterPhone,
      photoUrl: req.file ? `/uploads/${req.file.filename}` : "",
    };

    const newReport = await PersonReport.create(reportData);

    matchPersonReport(newReport).then((group) => {
      if (group) console.log("New group created:", group._id);
    });

    res.status(201).json({
      success: true,
      message: "Report submitted. AI is checking for matches.",
      report: newReport,
    });
  } catch (error) {
    console.error("Error saving person report:", error);
    res.status(500).json({ success: false, message: "Server error", error });
  }
});

router.get("/", async (req, res) => {
  try {
    const reports = await PersonReport.find().sort({ createdAt: -1 });
    res.json({ success: true, reports });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error", error });
  }
});

router.get("/groups", async (req, res) => {
  try {
    const groups = await PersonGroup.find()
      .populate("reportIds")
      .sort({ createdAt: -1 });
    res.json({ success: true, groups });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error", error });
  }
});

router.patch("/groups/:id/resolve", async (req, res) => {
  try {
    const group = await PersonGroup.findByIdAndUpdate(
      req.params.id,
      { resolved: true },
      { new: true }
    );
    if (!group) {
      return res.status(404).json({ success: false, message: "Group not found" });
    }
    res.json({ success: true, message: "Group marked resolved", group });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error", error });
  }
});

export default router;
