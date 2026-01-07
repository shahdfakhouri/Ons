require("dotenv").config();
const express = require("express");
const cors = require("cors");
const db = require("./src/config/db");
const connectMongo = require("./src/config/mongo");
const companionRoutes = require("./src/routes/companion.routes");



// Import routes
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

const path = require("path");
const app = express();

connectMongo();


//match 
const matchRoutes = require("./src/routes/match.routes");
app.use("/api/match", matchRoutes);

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// Test DB connection
db.getConnection((err, connection) => {
  if (err) console.error("❌ MySQL connection error:", err.message);
  else {
    console.log("✅ Connected to MySQL database (Ons)");
    connection.release();
  }
});

// ✅ Routes
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

//Notifications 
app.use("/api/notifications", notificationsRoutes);
// Health check
app.get("/health", (req, res) => res.json({ ok: true }));

// Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Server running on http://localhost:${PORT}`));

//Payment
const paymentRoutes = require("./src/routes/payment.routes");
app.use("/api/payments", paymentRoutes);

//transaction
const transactionRoutes = require("./src/routes/transaction.routes");
app.use("/api/transactions", transactionRoutes);

app.use("/api/companion", companionRoutes);
