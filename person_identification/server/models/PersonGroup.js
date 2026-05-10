// server/models/PersonGroup.js

const mongoose = require("mongoose");

const PersonGroupSchema = new mongoose.Schema({
  // Array of report IDs that all describe the same person
  reportIds: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "PersonReport",
    },
  ],

  // AI's confidence in the match
  confidence: {
    type: String,
    enum: ["high", "medium", "low"],
    default: "medium",
  },

  // AI explains WHY it thinks they're the same person
  aiReason: { type: String, default: "" },

  // Best summary name for this person across all reports
  representativeName: { type: String, default: "Unknown Person" },

  // Highest emergency level across all grouped reports
  highestEmergency: {
    type: String,
    enum: ["critical", "stable", "unknown"],
    default: "unknown",
  },

  // Is this case closed/resolved
  resolved: { type: Boolean, default: false },

  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("PersonGroup", PersonGroupSchema);