import "dotenv/config";
import mongoose from "mongoose";

function keyFor(doc) {
  const tsSec = Math.floor(new Date(doc.createdAt || 0).getTime() / 1000) || 0;
  const msg = String(doc.rawMessage || "").trim().toLowerCase();
  const loc = String(doc.location || "").trim().toLowerCase();
  const uid = String(doc.auth0UserId || "").trim().toLowerCase();
  const email = String(doc.userEmail || "").trim().toLowerCase();
  return `${msg}|${loc}|${uid}|${email}|${tsSec}`;
}

async function main() {
  const apply = process.argv.includes("--apply");
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error("MONGODB_URI missing");

  await mongoose.connect(uri);
  const col = mongoose.connection.db.collection("alerts");

  const docs = await col
    .find({ source: "offline_hub", syncStatus: "synced" })
    .project({
      _id: 1,
      rawMessage: 1,
      location: 1,
      auth0UserId: 1,
      userEmail: 1,
      createdAt: 1,
      updatedAt: 1,
    })
    .toArray();

  const groups = new Map();
  for (const d of docs) {
    const k = keyFor(d);
    const arr = groups.get(k) || [];
    arr.push(d);
    groups.set(k, arr);
  }

  const toDelete = [];
  const summary = [];
  for (const [k, arr] of groups) {
    if (arr.length <= 1) continue;
    arr.sort((a, b) => new Date(a.updatedAt || 0) - new Date(b.updatedAt || 0));
    const keep = arr[arr.length - 1];
    const drop = arr.slice(0, -1);
    toDelete.push(...drop.map((d) => d._id));
    summary.push({
      key: k,
      count: arr.length,
      keep: String(keep._id),
      drop: drop.map((d) => String(d._id)),
    });
  }

  const report = {
    mode: apply ? "apply" : "dry-run",
    totalOfflineSynced: docs.length,
    duplicateGroups: summary.length,
    duplicateDocs: toDelete.length,
    sample: summary.slice(0, 10),
  };
  console.log(JSON.stringify(report, null, 2));

  if (apply && toDelete.length) {
    const result = await col.deleteMany({ _id: { $in: toDelete } });
    console.log(
      JSON.stringify(
        {
          deletedCount: result.deletedCount,
        },
        null,
        2,
      ),
    );
  }

  await mongoose.disconnect();
}

main().catch(async (e) => {
  console.error(e);
  try {
    await mongoose.disconnect();
  } catch {}
  process.exit(1);
});
