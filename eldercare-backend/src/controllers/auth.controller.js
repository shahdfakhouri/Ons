const db = require("../config/db");
const bcrypt = require("bcryptjs");
const axios = require("axios");
const jwt = require("jsonwebtoken");

const JWT_SECRET = "2003"; // move to .env later for security

// role-table mapping
const roleTables = {
  admin: "admins",

  
  retirement_home: "retirement_homes",
  caregiver: "caregivers",
  elder: "elders",
  family: "family_members",
};

// 🟢 SIGNUP
exports.signup = async (req, res) => {
  const { name, email, password, telephone, role } = req.body;

  if (!name || !email || !password || !telephone || !role) {
    return res.status(400).json({ msg: "Please fill in all fields, including role" });
  }

  const table = roleTables[role.toLowerCase()];
  if (!table) return res.status(400).json({ msg: "Invalid role" });

  try {
    const emailColumn =
      role.toLowerCase() === "retirement_home"
        ? "contact_email"
        : "email";

    // check if user already exists
    db.query(`SELECT * FROM ${table} WHERE ${emailColumn} = ?`, [email], async (err, result) => {
      if (err) return res.status(500).json({ msg: "Database error", err });
      if (result.length > 0) return res.status(409).json({ msg: "User already exists" });

      // optional: fetch location by IP
      const userIP = "46.244.85.228";
      let address = "Unknown";

      try {
        const response = await axios.get(
          `https://api.ipgeolocation.io/ipgeo?apiKey=d184d7782ea44cddb96cbdb87f7c7c9e&ip=${userIP}`
        );
        const { city, latitude, longitude } = response.data;
        if (city && latitude && longitude) address = `${city} (${latitude}, ${longitude})`;
      } catch (error) {
        console.error("Error fetching location:", error.message);
      }

      // hash password
      const hashedPassword = await bcrypt.hash(password, 10);

      let sql, values;
      switch (role.toLowerCase()) {
        case "admin":
          sql = "INSERT INTO admins (name, email, password, phone) VALUES (?, ?, ?, ?)";
          values = [name, email, hashedPassword, telephone];
          break;

        case "retirement_home":
          sql = "INSERT INTO retirement_homes (name, contact_email, password, contact_phone, address, is_approved) VALUES (?, ?, ?, ?, ?, 0)";
          values = [name, email, hashedPassword, telephone, address];
          break;

        case "caregiver":
          sql =
            "INSERT INTO caregivers (name, email, password, phone, employment_type, is_approved) VALUES (?, ?, ?, ?, ?, 0)";
          values = [
            name,
            email,
            hashedPassword,
            telephone,
            req.body.employment_type || "freelance",
          ];
          break;

        case "elder":
          return res.status(403).json({ msg: "Elders cannot sign up directly" });

        case "family":
          sql =
            "INSERT INTO family_members (name, email, password, phone) VALUES (?, ?, ?, ?)";
          values = [name, email, hashedPassword, telephone];
          break;

        default:
          return res.status(400).json({ msg: "Invalid role" });
      }

      db.query(sql, values, (err) => {
        if (err) return res.status(500).json({ msg: "Error inserting user", err });

        if (role === "retirement_home" || role === "caregiver") {
          return res.status(201).json({
            msg: `${role} registered successfully but requires approval before logging in.`,
            address,
          });
        }

        res.status(201).json({ msg: `${role} registered successfully`, address });
      });
    });
  } catch (error) {
    console.error("Signup error:", error);
    res.status(500).json({ msg: "Internal server error", error });
  }
};

// 🟡 SIGNIN
exports.signin = async (req, res) => {
  const { email, password, role } = req.body;
  if (!email || !password || !role) {
    return res.status(400).json({ msg: "Please fill in all fields including role" });
  }

  const table = roleTables[role.toLowerCase()];
  if (!table) return res.status(400).json({ msg: "Invalid role" });

  const emailColumn =
    role.toLowerCase() === "retirement_home"
      ? "contact_email"
      : "email";

  db.query(`SELECT * FROM ${table} WHERE ${emailColumn} = ?`, [email], async (err, result) => {
    if (err) return res.status(500).json({ msg: "Database error", err });
    if (result.length === 0) {
      return res.status(400).json({ msg: "Invalid email or password" });
    }

    const user = result[0];

    if ((role === "retirement_home" || role === "caregiver") && user.is_approved === 0) {
      return res.status(403).json({ msg: "Your account is pending approval." });
    }

    if (!user.password) {
      return res.status(400).json({ msg: `${role} cannot sign in (no password set)` });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ msg: "Invalid email or password" });
    }

    const idField =
      role === "admin"
        ? "admin_id"
        : role === "caregiver"
        ? "caregiver_id"
        : role === "family"
        ? "family_id"
        : role === "retirement_home"
        ? "home_id"
        : "elder_id";

    const token = jwt.sign(
      { id: user[idField], email: email, role },
      JWT_SECRET,
      { expiresIn: "3h" }
    );

    res.status(200).json({
      msg: `${role} signed in successfully`,
      token,
    });
  });
};

// 🧪 TEST HASH — hash any string using bcrypt
exports.hashString = async (req, res) => {
  try {
    const { text } = req.body;

    if (!text) {
      return res.status(400).json({ msg: "Please provide a 'text' field in JSON body" });
    }

    const hashed = await bcrypt.hash(text, 10);

    res.status(200).json({
      original: text,
      hashed,
    });
  } catch (error) {
    console.error("Error hashing text:", error.message);
    res.status(500).json({ msg: "Server error", error });
  }
};

