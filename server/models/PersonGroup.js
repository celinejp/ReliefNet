import mongoose from "mongoose";

const PersonGroupSchema = new mongoose.Schema({
  reportIds: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "PersonReport",
    },
  ],
  confidence: {
    type: String,
    enum: ["high", "medium", "low"],
    default: "medium",
  },
  aiReason: { type: String, default: "" },
  representativeName: { type: String, default: "Unknown Person" },
  highestEmergency: {
    type: String,
    enum: ["critical", "stable", "unknown"],
    default: "unknown",
  },
  resolved: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

export default mongoose.model("PersonGroup", PersonGroupSchema);
