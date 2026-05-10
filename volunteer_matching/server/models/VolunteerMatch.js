const mongoose = require("mongoose");

const VolunteerMatchSchema = new mongoose.Schema({
  needId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Need",
    required: true
  },
  volunteerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Volunteer",
    required: true
  },
  confidence: {
    type: String,
    enum: ["high", "medium", "low"],
    default: "medium"
  },
  aiReason: { type: String, default: "" },
  resolved: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("VolunteerMatch", VolunteerMatchSchema);
