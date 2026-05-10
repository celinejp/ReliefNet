const express = require("express");
const router = express.Router();
const VolunteerMatch = require("../models/VolunteerMatch");
const { runVolunteerMatching } = require("../services/volunteerMatcher");

router.post("/", async (req, res) => {
  try {
    console.log("POST /api/match-volunteers — running AI matcher");
    const io = req.app.get("io");
    const matches = await runVolunteerMatching(io);
    res.json({
      success: true,
      message: `Found ${matches.length} matches`,
      matches
    });
  } catch (error) {
    console.error("Error running matcher:", error);
    res.status(500).json({ success: false, message: error.message });
  }
});

router.get("/", async (req, res) => {
  try {
    const matches = await VolunteerMatch.find()
      .populate("needId")
      .populate("volunteerId")
      .sort({ createdAt: -1 });
    res.json({ success: true, matches });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.patch("/:id/resolve", async (req, res) => {
  try {
    const match = await VolunteerMatch.findByIdAndUpdate(
      req.params.id,
      { resolved: true },
      { new: true }
    );
    if (!match) {
      return res.status(404).json({ success: false, message: "Match not found" });
    }
    res.json({ success: true, match });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
