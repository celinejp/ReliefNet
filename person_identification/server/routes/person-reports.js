// server/routes/person-reports.js

const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const PersonReport = require("../models/PersonReport");
const PersonGroup = require("../models/PersonGroup");
const { matchPersonReport } = require("../services/personMatcher");

// --- MULTER SETUP FOR PHOTO UPLOADS ---
// Photos will be saved in server/uploads/ folder
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, "uploads/"); // make sure this folder exists
  },
  filename: function (req, file, cb) {
    // name file as timestamp + original name to avoid duplicates
    cb(null, Date.now() + path.extname(file.originalname));
  },
});
const upload = multer({ storage });


// =============================================
// POST /api/person-reports
// Submit a new report (looking or found)
// =============================================
router.post("/", upload.single("photo"), async (req, res) => {
  console.log("POST /api/person-reports hit — body keys:", Object.keys(req.body));
  try {
    const {
      reportType,
      name,
      approximateAge,
      gender,
      descriptionText,
      isInjured,
      isUnconscious,
      emergencyLevel,
      locationText,
      lat,
      lng,
      lastSeenAt,
      reporterName,
      reporterPhone,
    } = req.body;

    // Build the new report object
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

    // Save to database
    const newReport = await PersonReport.create(reportData);

    // Run AI matching in the background (don't make user wait)
    matchPersonReport(newReport).then((group) => {
      // If your app uses Socket.io, emit the match here
      // Example: io.emit("person-match-found", group);
      if (group) {
        console.log("New group created:", group._id);
      }
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


// =============================================
// GET /api/person-reports
// Get all reports (for admin view)
// =============================================
router.get("/", async (req, res) => {
  try {
    const reports = await PersonReport.find().sort({ createdAt: -1 });
    res.json({ success: true, reports });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error", error });
  }
});


// =============================================
// GET /api/person-groups
// Get all matched groups
// =============================================
router.get("/groups", async (req, res) => {
  try {
    const groups = await PersonGroup.find()
      .populate("reportIds") // fills in full report data, not just IDs
      .sort({ createdAt: -1 });
    res.json({ success: true, groups });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error", error });
  }
});


// =============================================
// PATCH /api/person-reports/groups/:id/resolve
// Mark a group as resolved (person found/case closed)
// =============================================
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


router.use((req, res) => {
  console.log(`UNMATCHED in person-reports router: ${req.method} ${req.path}`);
  res.status(404).json({ success: false, message: `No route: ${req.method} ${req.path}` });
});

module.exports = router;