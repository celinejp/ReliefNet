import mongoose from "mongoose";

const NeedSchema = new mongoose.Schema({
  name: { type: String, required: true },
  phone: { type: String, required: true },
  categories: [{
    type: String,
    enum: ["food", "water", "medical", "transport", "shelter", "rescue", "other"],
  }],
  urgency: {
    type: String,
    enum: ["critical", "urgent", "normal"],
    default: "normal",
  },
  description: { type: String, default: "" },
  locationText: { type: String, default: "" },
  coordinates: {
    lat: { type: Number, default: null },
    lng: { type: Number, default: null },
  },
  numberOfPeople: { type: Number, default: 1 },
  status: {
    type: String,
    enum: ["unmatched", "matched", "resolved"],
    default: "unmatched",
  },
  matchId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "VolunteerMatch",
    default: null,
  },
  createdAt: { type: Date, default: Date.now },
});

export default mongoose.model("Need", NeedSchema);
