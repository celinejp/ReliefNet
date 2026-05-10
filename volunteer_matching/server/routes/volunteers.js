const express = require("express");
const router = express.Router();
const Need = require("../models/Need");
const Volunteer = require("../models/Volunteer");

router.post("/needs", async (req, res) => {
  try {
    console.log("POST /api/needs — body:", req.body);
    const {
      name, phone, categories, urgency,
      description, locationText, lat, lng, numberOfPeople
    } = req.body;

    const need = await Need.create({
      name,
      phone,
      categories: categories || [],
      urgency: urgency || "normal",
      description: description || "",
      locationText: locationText || "",
      coordinates: {
        lat: lat ? parseFloat(lat) : null,
        lng: lng ? parseFloat(lng) : null
      },
      numberOfPeople: numberOfPeople || 1
    });

    res.status(201).json({ success: true, need });

    const { runVolunteerMatching } = require('../services/volunteerMatcher');
    const io = req.app.get('io');
    runVolunteerMatching(io)
      .then((matches) => { if (matches.length > 0) console.log(`Auto-match found ${matches.length} matches`); })
      .catch((err) => console.error('Auto-match error:', err));
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

router.post("/volunteers", async (req, res) => {
  try {
    console.log("POST /api/volunteers — body:", req.body);
    const {
      name, phone, categories,
      description, locationText, lat, lng, capacity
    } = req.body;

    const volunteer = await Volunteer.create({
      name,
      phone,
      categories: categories || [],
      description: description || "",
      locationText: locationText || "",
      coordinates: {
        lat: lat ? parseFloat(lat) : null,
        lng: lng ? parseFloat(lng) : null
      },
      capacity: capacity || 1
    });

    res.status(201).json({ success: true, volunteer });

    const { runVolunteerMatching } = require('../services/volunteerMatcher');
    const io = req.app.get('io');
    runVolunteerMatching(io)
      .then((matches) => { if (matches.length > 0) console.log(`Auto-match found ${matches.length} matches`); })
      .catch((err) => console.error('Auto-match error:', err));
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

module.exports = router;
