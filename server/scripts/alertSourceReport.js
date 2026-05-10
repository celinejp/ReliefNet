import "dotenv/config";
import mongoose from "mongoose";

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error("MONGODB_URI missing");

  await mongoose.connect(uri);
  const col = mongoose.connection.db.collection("alerts");

  const now = Date.now();
  const windows = [
    { label: "last_15m", ms: 15 * 60 * 1000 },
    { label: "last_1h", ms: 60 * 60 * 1000 },
    { label: "last_24h", ms: 24 * 60 * 60 * 1000 },
  ];

  const total = await col.countDocuments({});

  const bySource = await col
    .aggregate([
      {
        $group: {
          _id: "$source",
          count: { $sum: 1 },
        },
      },
      { $sort: { count: -1 } },
    ])
    .toArray();

  const bySyncStatus = await col
    .aggregate([
      {
        $group: {
          _id: "$syncStatus",
          count: { $sum: 1 },
        },
      },
      { $sort: { count: -1 } },
    ])
    .toArray();

  const bySourceAndSync = await col
    .aggregate([
      {
        $group: {
          _id: { source: "$source", syncStatus: "$syncStatus" },
          count: { $sum: 1 },
        },
      },
      { $sort: { count: -1 } },
    ])
    .toArray();

  const recent = {};
  for (const w of windows) {
    const since = new Date(now - w.ms);
    const rows = await col
      .aggregate([
        { $match: { createdAt: { $gte: since } } },
        {
          $group: {
            _id: "$source",
            count: { $sum: 1 },
          },
        },
        { $sort: { count: -1 } },
      ])
      .toArray();
    recent[w.label] = rows;
  }

  const latest = await col
    .find({})
    .project({
      _id: 1,
      source: 1,
      syncStatus: 1,
      mode: 1,
      rawMessage: 1,
      location: 1,
      userEmail: 1,
      clientAlertId: 1,
      createdAt: 1,
    })
    .sort({ createdAt: -1 })
    .limit(20)
    .toArray();

  console.log(
    JSON.stringify(
      {
        total,
        bySource,
        bySyncStatus,
        bySourceAndSync,
        recent,
        latest,
      },
      null,
      2,
    ),
  );

  await mongoose.disconnect();
}

main().catch(async (e) => {
  console.error(e);
  try {
    await mongoose.disconnect();
  } catch {}
  process.exit(1);
});
