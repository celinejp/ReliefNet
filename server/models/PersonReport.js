import mongoose from "mongoose";

const PersonReportSchema = new mongoose.Schema({
  reportType: {
    type: String,
    enum: ["looking", "found"],
    required: true,
  },
  name: { type: String, default: "Unknown" },
  approximateAge: { type: String, default: "" },
  gender: {
    type: String,
    enum: ["male", "female", "unknown"],
    default: "unknown",
  },
  descriptionText: { type: String, required: true },
  isInjured: { type: Boolean, default: false },
  isUnconscious: { type: Boolean, default: false },
  emergencyLevel: {
    type: String,
    enum: ["critical", "stable", "unknown"],
    default: "unknown",
  },
  locationText: { type: String, default: "" },
  coordinates: {
    lat: { type: Number, default: null },
    lng: { type: Number, default: null },
  },
  lastSeenAt: { type: Date, default: Date.now },
  photoUrl: { type: String, default: "" },
  reporterName: { type: String, required: true },
  reporterPhone: { type: String, required: true },
  resolved: { type: Boolean, default: false },
  groupId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "PersonGroup",
    default: null,
  },
  createdAt: { type: Date, default: Date.now },
});

export default mongoose.model("PersonReport", PersonReportSchema);
