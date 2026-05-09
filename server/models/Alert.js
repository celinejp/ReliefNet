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
  },
  { timestamps: true },
);

export const Alert = mongoose.models.Alert || mongoose.model("Alert", alertSchema);
