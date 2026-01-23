// server.js (FINAL)
require("dotenv").config();
console.log("✅ BOOTED: MAIN SERVER FILE");

const express = require("express");
const cors = require("cors");
const path = require("path");

const db = require("./src/config/db");
const connectMongo = require("./src/config/mongo");

const app = express();

// ✅ connect Mongo (chat/companion)
connectMongo();

// ✅ Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// ✅ Test MySQL connection
db.getConnection((err, connection) => {
  if (err) console.error("❌ MySQL connection error:", err.message);
  else {
    console.log("✅ Connected to MySQL database (Ons)");
    connection.release();
  }
});

// =======================
// Routes imports
// =======================
const authRoutes = require("./src/routes/auth.routes");
const adminRoutes = require("./src/routes/admin.routes");
const elderRoutes = require("./src/routes/elder.routes");
const caregiverRoutes = require("./src/routes/caregiver.routes");
const familyRoutes = require("./src/routes/family.routes");
const retirementRoutes = require("./src/routes/retirement.routes");
const notificationsRoutes = require("./src/routes/notifications.routes");
const trackerRoutes = require("./src/routes/tracker.routes");
const deviceHealthRoutes = require("./src/routes/deviceHealth.routes");
const medicationRoutes = require("./src/routes/medication.routes");
const visitsRoutes = require("./src/routes/visits.routes");
const emergencyRoutes = require("./src/routes/emergency.routes");
const staffNotesRoutes = require("./src/routes/staffNotes.routes");
const reportsRoutes = require("./src/routes/reports.routes");
const publicRoutes = require("./src/routes/public.routes");
const communityRoutes = require("./src/routes/community.routes");
const entertainmentRoutes = require("./src/routes/entertainment.routes");
const companionRoutes = require("./src/routes/companion.routes");
const matchRoutes = require("./src/routes/match.routes");
const paymentRoutes = require("./src/routes/payment.routes");
const transactionRoutes = require("./src/routes/transaction.routes");
const h2hChatRoutes = require("./src/routes/chat-h2h.routes");

// =======================
// Routes mounting
// =======================
app.use("/api/auth", authRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/elder", elderRoutes);
app.use("/api/caregiver", caregiverRoutes);
app.use("/api/retirement", retirementRoutes);
app.use("/api/family", familyRoutes);

app.use("/api/tracker", trackerRoutes);
app.use("/api/health", deviceHealthRoutes);
app.use("/api/medication", medicationRoutes);

app.use("/api/retirement/visits", visitsRoutes);
app.use("/api/emergency", emergencyRoutes);
app.use("/api/retirement/notes", staffNotesRoutes);
app.use("/api/retirement/reports", reportsRoutes);

app.use("/api", publicRoutes);
app.use("/api/community", communityRoutes);
app.use("/api/entertainment", entertainmentRoutes);

app.use("/api/notifications", notificationsRoutes);
app.use("/api/companion", companionRoutes);

app.use("/api/match", matchRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/transactions", transactionRoutes);

// ✅ NEW: Caregiver ↔ Family chat
app.use("/api/chat-h2h", h2hChatRoutes);

// Health check
app.get("/health", (req, res) => res.json({ ok: true }));

// ✅ Start server LAST
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Server running on http://localhost:${PORT}`));
