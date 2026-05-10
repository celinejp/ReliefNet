require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*", methods: ["GET", "POST", "PATCH"] }
});

app.set("io", io);

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const volunteerRoutes = require("./routes/volunteers");
const donationRoutes = require("./routes/donations");
const matchRoutes = require("./routes/match-volunteers");

app.use("/api", volunteerRoutes);
app.use("/api/donations", donationRoutes);
app.use("/api/match-volunteers", matchRoutes);

app.get("/health", (req, res) => {
  res.json({ status: "ok", feature: "volunteer-matching" });
});

io.on("connection", (socket) => {
  console.log("Client connected:", socket.id);
  socket.on("disconnect", () => {
    console.log("Client disconnected:", socket.id);
  });
});

const PORT = process.env.PORT || 4000;
const MONGO_URI = process.env.MONGO_URI;

mongoose.connect(MONGO_URI)
  .then(() => {
    console.log("MongoDB connected");
    server.listen(PORT, "0.0.0.0", () => {
      console.log(`Volunteer matching server running on port ${PORT}`);
    });
  })
  .catch((err) => console.error("MongoDB connection error:", err));
