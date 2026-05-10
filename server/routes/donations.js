import express from "express";
import multer from "multer";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import Donation from "../models/Donation.js";

const router = express.Router();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const uploadDir = path.join(__dirname, "../uploads");
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) =>
    cb(null, `${Date.now()}${path.extname(file.originalname)}`),
});
const upload = multer({ storage });

router.post("/", upload.single("photo"), async (req, res) => {
  try {
    console.log("POST /api/donations — body:", req.body);
    const { donorName, donorPhone, type, amount, notes, locationText, lat, lng } = req.body;

    const donation = await Donation.create({
      donorName,
      donorPhone,
      type,
      amount: amount || "",
      notes: notes || "",
      photoUrl: req.file ? `/uploads/${req.file.filename}` : "",
      locationText: locationText || "",
      coordinates: {
        lat: lat ? parseFloat(lat) : null,
        lng: lng ? parseFloat(lng) : null,
      },
    });

    res.status(201).json({ success: true, donation });
  } catch (error) {
    console.error("Error saving donation:", error);
    res.status(500).json({ success: false, message: error.message });
  }
});

router.get("/", async (req, res) => {
  try {
    const donations = await Donation.find().sort({ createdAt: -1 });
    res.json({ success: true, donations });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

export default router;
