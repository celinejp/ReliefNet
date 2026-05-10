// server/models/PersonReport.js

const mongoose = require("mongoose");

const PersonReportSchema = new mongoose.Schema({
  // REPORT TYPE
  reportType: {
    type: String,
    enum: ["looking", "found"],
    required: true,
  },

  // IDENTITY
  name: { type: String, default: "Unknown" },
  approximateAge: { type: String, default: "" }, // "65" or "60-70"
  gender: {
    type: String,
    enum: ["male", "female", "unknown"],
    default: "unknown",
  },

  // THE MAIN DESCRIPTION — voice or typed, all goes here
  descriptionText: { type: String, required: true },
  // ^ This is the single text field where all clothing,
  //   appearance, context gets stored. Voice transcribes into this.

  // MEDICAL
  isInjured: { type: Boolean, default: false },
  isUnconscious: { type: Boolean, default: false },
  emergencyLevel: {
    type: String,
    enum: ["critical", "stable", "unknown"],
    default: "unknown",
  },

  // LOCATION
  locationText: { type: String, default: "" }, // "Near west bridge"
  coordinates: {
    lat: { type: Number, default: null },
    lng: { type: Number, default: null },
  },

  // TIME
  lastSeenAt: { type: Date, default: Date.now },

  // PHOTO
  photoUrl: { type: String, default: "" },

  // REPORTER CONTACT
  reporterName: { type: String, required: true },
  reporterPhone: { type: String, required: true },

  // MATCHING STATUS
  resolved: { type: Boolean, default: false },
  groupId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "PersonGroup",
    default: null,
  },

  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("PersonReport", PersonReportSchema);