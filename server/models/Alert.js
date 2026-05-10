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
    clientAlertId: { type: String, default: "", trim: true },
    userEmail: { type: String, default: "" },
    guestMode: { type: Boolean, default: false },
    location: { type: String, default: "", trim: true },
    mode: {
      type: String,
      enum: ["online", "offline"],
      default: "online",
    },
    source: {
      type: String,
      enum: ["online_cloud", "offline_hub", "local_cache"],
      default: "online_cloud",
    },
    syncStatus: {
      type: String,
      enum: ["pending", "synced", "failed"],
      default: "synced",
    },
    responderStatus: {
      type: String,
      enum: ["open", "in_progress", "closed"],
      default: "open",
    },
  },
  { timestamps: true },
);

// Enforce idempotent offline syncs: same non-empty clientAlertId cannot be inserted twice.
alertSchema.index(
  { clientAlertId: 1 },
  {
    unique: true,
    partialFilterExpression: {
      clientAlertId: { $type: "string", $ne: "" },
    },
  },
);

export const Alert =
  mongoose.models.Alert || mongoose.model("Alert", alertSchema);
