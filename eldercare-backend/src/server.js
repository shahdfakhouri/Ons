const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const db = require("./config/db");
const authRoutes = require("./routes/authroutes");

dotenv.config();

const app = express();

// 🧩 Middleware setup
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true })); // ✅ handles form submissions too

// 🧠 Test database connection once at startup
db.getConnection((err, connection) => {
  if (err) {
    console.error("❌ Error connecting to MySQL:", err.message);
  } else {
    console.log("✅ MySQL connection pool created successfully (ons)");
    connection.release();
  }
});

// 🚦 Routes
app.use("/api/auth", authRoutes);

// 🩵 Root endpoint
app.get("/", (req, res) => {
  res.send("ElderCare backend is running 🚀");
});

// ⚙️ Start the server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`✅ Server running on port ${PORT}`));
