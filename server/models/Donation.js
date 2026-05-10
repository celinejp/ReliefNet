import mongoose from "mongoose";

const DonationSchema = new mongoose.Schema({
  donorName: { type: String, required: true },
  donorPhone: { type: String, required: true },
  type: {
    type: String,
    enum: ["money", "food", "water", "clothes", "medicine", "other"],
    required: true,
  },
  amount: { type: String, default: "" },
  notes: { type: String, default: "" },
  locationText: { type: String, default: "" },
  coordinates: {
    lat: { type: Number, default: null },
    lng: { type: Number, default: null },
  },
  status: {
    type: String,
    enum: ["available", "claimed", "delivered"],
    default: "available",
  },
  createdAt: { type: Date, default: Date.now },
});

export default mongoose.model("Donation", DonationSchema);
