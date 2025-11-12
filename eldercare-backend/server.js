require("dotenv").config();
const express = require("express");
const cors = require("cors");
const db = require("./src/config/db");

// Import routes
const authRoutes = require("./src/routes/auth.routes");
const adminRoutes = require("./src/routes/admin.routes");

const app = express();

//match 
const matchRoutes = require("./src/routes/match.routes");
app.use("/api/match", matchRoutes);


// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

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

// Health check
app.get("/health", (req, res) => res.json({ ok: true }));

// Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Server running on http://localhost:${PORT}`));
