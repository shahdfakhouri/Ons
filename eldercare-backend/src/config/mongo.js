const mongoose = require("mongoose");

async function connectMongo() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.warn("⚠️ MONGODB_URI is not set. Mongo chat memory disabled.");
    return;
  }

  try {
    await mongoose.connect(uri);
    console.log("✅ Connected to MongoDB (Companion Memory)");
  } catch (err) {
    console.error("❌ MongoDB connection error:", err.message);
  }
}

module.exports = connectMongo;
