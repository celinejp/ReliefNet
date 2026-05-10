const express = require("express");
const router = express.Router();
const Donation = require("../models/Donation");

router.post("/", async (req, res) => {
  try {
    console.log("POST /api/donations — body:", req.body);
    const {
      donorName, donorPhone, type,
      amount, notes, locationText, lat, lng
    } = req.body;

    const donation = await Donation.create({
      donorName,
      donorPhone,
      type,
      amount: amount || "",
      notes: notes || "",
      locationText: locationText || "",
      coordinates: {
        lat: lat ? parseFloat(lat) : null,
        lng: lng ? parseFloat(lng) : null
      }
    });

    res.status(201).json({ success: true, donation });
  } catch (error) {
    console.error("Error saving donation:", error);
    res.status(500).json({ success: false, message: error.message });
  }
});

router.get("/", async (req, res) => {
  try {
    const donations = await Donation.find().sort({ createdAt: -1 });
    res.json({ success: true, donations });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
