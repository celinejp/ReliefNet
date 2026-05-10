import mongoose from "mongoose";

const alertSchema = new mongoose.Schema(
  {
    rawMessage: { type: String, required: true, trim: true },
    severity: {
      type: String,
      enum: ["Critical", "Medium", "Low", null],
      default: null,
    },
    category: { type: String, default: "" },
    summary: { type: String, default: "" },
    processingStatus: {
      type: String,
      enum: ["pending", "complete", "failed"],
      default: "pending",
    },
    aiError: { type: String, default: "" },
    auth0UserId: { type: String, default: null, index: true },
    userEmail: { type: String, default: "" },
    guestMode: { type: Boolean, default: false },
    location: { type: String, default: "", trim: true },
    mode: {
      type: String,
      enum: ["online", "offline"],
      default: "online",
    },
    responderStatus: {
      type: String,
      enum: ["open", "in_progress", "closed"],
      default: "open",
    },
  },
  { timestamps: true },
);

export const Alert =
  mongoose.models.Alert || mongoose.model("Alert", alertSchema);
