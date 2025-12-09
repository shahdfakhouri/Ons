const db = require("../config/db");

// 🏠 GET Dashboard Overview
exports.getDashboard = (req, res) => {
  const homeId = req.user.id; // assuming JWT stores home_id

  const queries = {
  homeInfo: "SELECT name, city, monthly_cost, services, contact_email, contact_phone FROM retirement_homes WHERE home_id = ?",
  totalElders: "SELECT COUNT(*) AS total_elders FROM elder_assignments WHERE home_id = ?",
  totalCaregivers: "SELECT COUNT(*) AS total_caregivers FROM home_caregivers WHERE home_id = ?",
  
  // ✅ FIXED QUERY
  pendingPayments: `
    SELECT COUNT(*) AS pending_payments 
    FROM payments 
    WHERE target_type = 'retirement_home' 
    AND target_id = ? 
    AND status = 'pending'
  `,
  
  avgHealth: `
    SELECT 
      AVG(CAST(SUBSTRING_INDEX(blood_sugar, ' ', 1) AS DECIMAL(10,2))) AS avg_blood_sugar,
      AVG(CAST(SUBSTRING_INDEX(REPLACE(blood_pressure, '/','.'), ' ', 1) AS DECIMAL(10,2))) AS avg_blood_pressure,
      AVG(CAST(REPLACE(temperature, '°C','') AS DECIMAL(10,2))) AS avg_temp
    FROM health_logs hl
    JOIN elders e ON hl.elder_id = e.elder_id
    JOIN elder_assignments ea ON e.elder_id = ea.elder_id
    WHERE ea.home_id = ?
  `
};


  Promise.all([
    new Promise((resolve, reject) => db.query(queries.homeInfo, [homeId], (err, res) => err ? reject(err) : resolve(res[0]))),
    new Promise((resolve, reject) => db.query(queries.totalElders, [homeId], (err, res) => err ? reject(err) : resolve(res[0].total_elders))),
    new Promise((resolve, reject) => db.query(queries.totalCaregivers, [homeId], (err, res) => err ? reject(err) : resolve(res[0].total_caregivers))),
    new Promise((resolve, reject) => db.query(queries.pendingPayments, [homeId], (err, res) => err ? reject(err) : resolve(res[0].pending_payments))),
    new Promise((resolve, reject) => db.query(queries.avgHealth, [homeId], (err, res) => err ? reject(err) : resolve(res[0])))
  ])
    .then(([homeInfo, totalElders, totalCaregivers, pendingPayments, avgHealth]) => {
      res.status(200).json({
        msg: "Retirement home dashboard loaded successfully ✅",
        homeInfo,
        stats: {
          totalElders,
          totalCaregivers,
          pendingPayments,
          avgHealth
        }
      });
    })
    .catch((error) => {
      console.error("Dashboard error:", error);
      res.status(500).json({ msg: "Error loading dashboard", error });
    });
};

// 🧾 UPDATE Home Profile
exports.updateProfile = (req, res) => {
  const homeId = req.user.id;
  const { name, address, city, contact_email, contact_phone, services, monthly_cost } = req.body;

  const sql = `
    UPDATE retirement_homes
    SET name=?, address=?, city=?, contact_email=?, contact_phone=?, services=?, monthly_cost=?
    WHERE home_id=?;
  `;

  db.query(sql, [name, address, city, contact_email, contact_phone, services, monthly_cost, homeId], (err, result) => {
    if (err) {
      console.error("Profile update error:", err);
      return res.status(500).json({ msg: "Error updating profile", err });
    }

    res.status(200).json({ msg: "Profile updated successfully ✅" });
  });
};
// 🧑‍⚕️ Get all caregivers in this home
exports.getHomeCaregivers = (req, res) => {
  const homeId = req.user.id;
  const sql = `
    SELECT c.caregiver_id, c.name, c.email, c.phone, c.status, hc.assigned_at
    FROM home_caregivers hc
    JOIN caregivers c ON hc.caregiver_id = c.caregiver_id
    WHERE hc.home_id = ?;
  `;
  db.query(sql, [homeId], (err, results) => {
    if (err) return res.status(500).json({ msg: "Error fetching caregivers", err });
    res.status(200).json({ msg: "Caregivers retrieved successfully", caregivers: results });
  });
};

// ➕ Assign a caregiver to this home
exports.addCaregiverToHome = (req, res) => {
  const homeId = req.user.id;
  const { caregiver_id } = req.body;

  if (!caregiver_id) return res.status(400).json({ msg: "Missing caregiver_id" });

  // Check if caregiver already assigned
  const checkSql = "SELECT * FROM home_caregivers WHERE caregiver_id = ?";
  db.query(checkSql, [caregiver_id], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error checking caregiver", err });
    if (result.length > 0) return res.status(400).json({ msg: "Caregiver already assigned" });

    const sql = "INSERT INTO home_caregivers (home_id, caregiver_id) VALUES (?, ?)";
    db.query(sql, [homeId, caregiver_id], (err2) => {
      if (err2) return res.status(500).json({ msg: "Error adding caregiver", err2 });
      res.status(200).json({ msg: "Caregiver assigned successfully ✅" });
    });
  });
};

// ❌ Remove caregiver from home
exports.removeCaregiverFromHome = (req, res) => {
  const homeId = req.user.id;
  const caregiverId = req.params.id;

  const sql = "DELETE FROM home_caregivers WHERE home_id = ? AND caregiver_id = ?";
  db.query(sql, [homeId, caregiverId], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error removing caregiver", err });
    if (result.affectedRows === 0)
      return res.status(404).json({ msg: "Caregiver not found or not assigned to this home" });

    res.status(200).json({ msg: "Caregiver removed successfully ❎" });
  });
};

// 🧭 Get all available caregivers (not assigned to any home)
exports.getAvailableCaregivers = (req, res) => {
  const sql = `
    SELECT c.caregiver_id, c.name, c.email, c.phone, c.status
    FROM caregivers c
    WHERE c.caregiver_id NOT IN (SELECT caregiver_id FROM home_caregivers)
    AND c.is_approved = 1;
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ msg: "Error fetching available caregivers", err });
    res.status(200).json({ msg: "Available caregivers retrieved", caregivers: results });
  });
};
// 🧓 Get all elder-caregiver assignments for this home
exports.getElderAssignments = (req, res) => {
  const homeId = req.user.id;

  const sql = `
    SELECT 
  ea.elder_id,
  e.name AS elder_name,
  c.caregiver_id,
  c.name AS caregiver_name,
  ea.assigned_at
    FROM elder_assignments ea
    JOIN elders e ON ea.elder_id = e.elder_id
    JOIN caregivers c ON ea.caregiver_id = c.caregiver_id
    WHERE ea.home_id = ?
    ORDER BY ea.assigned_at DESC;
  `;

  db.query(sql, [homeId], (err, results) => {
    if (err) return res.status(500).json({ msg: "Error fetching assignments", err });
    res.status(200).json({ msg: "Elder-caregiver assignments retrieved", data: results });
  });
};

// ➕ Assign caregiver to elder
exports.assignCaregiverToElder = (req, res) => {
  const homeId = req.user.id;
  const { elder_id, caregiver_id } = req.body;

  if (!elder_id || !caregiver_id) {
    return res.status(400).json({ msg: "Please provide elder_id and caregiver_id" });
  }

  // Check if elder already has a caregiver
  const checkSql = "SELECT * FROM elder_assignments WHERE elder_id = ?";
  db.query(checkSql, [elder_id], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error checking assignment", err });

    if (result.length > 0) {
      return res.status(400).json({ msg: "This elder is already assigned to a caregiver" });
    }

    // Insert the new assignment
    const sql = `
      INSERT INTO elder_assignments (elder_id, caregiver_id, home_id)
      VALUES (?, ?, ?)
    `;
    db.query(sql, [elder_id, caregiver_id, homeId], (err2) => {
      if (err2) return res.status(500).json({ msg: "Error assigning caregiver", err2 });
      res.status(200).json({ msg: "Caregiver assigned to elder successfully ✅" });
    });
  });
};

// ❌ Remove assignment (no id column version)
exports.removeElderAssignment = (req, res) => {
  const homeId = req.user.id;
  const { elder_id, caregiver_id } = req.body;

  if (!elder_id || !caregiver_id) {
    return res.status(400).json({ msg: "Please provide elder_id and caregiver_id" });
  }

  const sql = "DELETE FROM elder_assignments WHERE elder_id = ? AND caregiver_id = ? AND home_id = ?";
  db.query(sql, [elder_id, caregiver_id, homeId], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error removing assignment", err });

    if (result.affectedRows === 0) {
      return res.status(404).json({ msg: "No matching assignment found for this home" });
    }

    res.status(200).json({ msg: "Assignment removed successfully ❎" });
  });
};
const { sendSMS, sendEmail } = require("../services/notification.service");

// ✅ Assign caregiver to elder
exports.assignCaregiverToElder = (req, res) => {
  const homeId = req.user.id;
  const { elder_id, caregiver_id } = req.body;

  if (!elder_id || !caregiver_id) {
    return res.status(400).json({ msg: "Missing elder_id or caregiver_id" });
  }

  const sql = "INSERT INTO elder_assignments (elder_id, caregiver_id, home_id, assigned_at) VALUES (?, ?, ?, NOW())";
  db.query(sql, [elder_id, caregiver_id, homeId], (err) => {
    if (err) return res.status(500).json({ msg: "Error assigning caregiver", err });

    // Fetch contact details for notifications
    const contactSQL = `
      SELECT c.name AS caregiver_name, c.phone AS caregiver_phone, c.email AS caregiver_email, e.name AS elder_name
      FROM caregivers c JOIN elders e ON e.elder_id = ?
      WHERE c.caregiver_id = ?`;
    db.query(contactSQL, [elder_id, caregiver_id], async (err, [result]) => {
      if (!err && result) {
        const { caregiver_name, caregiver_phone, caregiver_email, elder_name } = result;
        const msg = `👵 Hi ${caregiver_name}, you've been assigned to take care of elder ${elder_name} at your retirement home.`;
        await sendSMS(caregiver_phone, msg);
        await sendEmail(caregiver_email, "New Assignment", msg);
      }
    });

    res.status(201).json({ msg: "Caregiver assigned successfully ✅" });
  });
};

