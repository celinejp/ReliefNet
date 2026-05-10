const mongoose = require("mongoose");

const VolunteerSchema = new mongoose.Schema({
  name: { type: String, required: true },
  phone: { type: String, required: true },
  categories: [{
    type: String,
    enum: ["food", "water", "medical", "transport", "shelter", "rescue", "other"]
  }],
  description: { type: String, default: "" },
  locationText: { type: String, default: "" },
  coordinates: {
    lat: { type: Number, default: null },
    lng: { type: Number, default: null }
  },
  capacity: { type: Number, default: 1 },
  available: { type: Boolean, default: true },
  status: {
    type: String,
    enum: ["available", "matched", "busy"],
    default: "available"
  },
  matchId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "VolunteerMatch",
    default: null
  },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("Volunteer", VolunteerSchema);
