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

//add caregiver to home
exports.addCaregiverToHome = (req, res) => {
  const homeId = req.user.id;
  const { caregiver_id } = req.body;

  if (!caregiver_id) return res.status(400).json({ msg: "Missing caregiver_id" });

  // Check caregiver exists + approved
  const existsSql = "SELECT caregiver_id, is_approved FROM caregivers WHERE caregiver_id = ?";
  db.query(existsSql, [caregiver_id], (err0, rows0) => {
    if (err0) return res.status(500).json({ msg: "DB error checking caregiver", err: err0 });
    if (!rows0.length) return res.status(404).json({ msg: "Caregiver not found" });
    if (rows0[0].is_approved !== 1) return res.status(403).json({ msg: "Caregiver not approved yet" });

    // Check if already assigned to ANY home
    const checkSql = "SELECT home_id FROM home_caregivers WHERE caregiver_id = ?";
    db.query(checkSql, [caregiver_id], (err, result) => {
      if (err) return res.status(500).json({ msg: "Error checking caregiver", err });

      if (result.length > 0) {
        return res.status(400).json({
          msg: "Caregiver already assigned to a home",
          assigned_home_id: result[0].home_id
        });
      }

      // Insert
      const sql = "INSERT INTO home_caregivers (home_id, caregiver_id) VALUES (?, ?)";
      db.query(sql, [homeId, caregiver_id], (err2, result2) => {
        if (err2) return res.status(500).json({ msg: "Error adding caregiver", err: err2 });

        res.status(201).json({
          msg: "Caregiver assigned successfully ✅",
          home_id: homeId,
          caregiver_id,
          row_id: result2.insertId
        });
      });
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

// ✅ Assign caregiver to elder (with duplicate-check + notifications)
exports.assignCaregiverToElder = (req, res) => {
  const homeId = req.user.id;
  const { elder_id, caregiver_id } = req.body;

  if (!elder_id || !caregiver_id) {
    return res.status(400).json({ msg: "Please provide elder_id and caregiver_id" });
  }

  // 1) Check elder already assigned (current assignment table)
  const checkSql = "SELECT * FROM elder_assignments WHERE elder_id = ?";
  db.query(checkSql, [elder_id], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error checking assignment", err });

    if (result.length > 0) {
      return res.status(400).json({ msg: "This elder is already assigned to a caregiver" });
    }

    // 2) Insert CURRENT assignment
    const insertSql = `
      INSERT INTO elder_assignments (elder_id, caregiver_id, home_id, assigned_at)
      VALUES (?, ?, ?, NOW())
    `;

    db.query(insertSql, [elder_id, caregiver_id, homeId], (err2) => {
      if (err2) return res.status(500).json({ msg: "Error assigning caregiver", err: err2 });

      // 3) Insert HISTORY assignment (end_date stays NULL until removed)
      const historySql = `
        INSERT INTO elder_caregiver_assignments (elder_id, caregiver_id, start_date, end_date)
        VALUES (?, ?, CURDATE(), NULL)
      `;
      db.query(historySql, [elder_id, caregiver_id], (errH) => {
        // Don't fail the whole request if history insert fails (optional),
        // but log it so you can fix schema issues if any.
        if (errH) console.error("⚠️ Failed to insert elder_caregiver_assignments history:", errH);
      });

      // 4) Send notifications (caregiver)
      const contactSQL = `
        SELECT 
          c.name AS caregiver_name, c.phone AS caregiver_phone, c.email AS caregiver_email,
          e.name AS elder_name
        FROM caregivers c
        JOIN elders e ON e.elder_id = ?
        WHERE c.caregiver_id = ?
        LIMIT 1
      `;

      db.query(contactSQL, [elder_id, caregiver_id], async (err3, rows) => {
        if (!err3 && rows && rows.length) {
          const { caregiver_name, caregiver_phone, caregiver_email, elder_name } = rows[0];
          const msg = `👵 Hi ${caregiver_name}, you've been assigned to take care of elder ${elder_name} at your retirement home.`;

          try { if (caregiver_phone) await sendSMS(caregiver_phone, msg); } catch {}
          try { if (caregiver_email) await sendEmail(caregiver_email, "New Assignment", msg); } catch {}
        }
      });

      res.status(201).json({ msg: "Caregiver assigned to elder successfully ✅" });
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

  const sql =
    "DELETE FROM elder_assignments WHERE elder_id = ? AND caregiver_id = ? AND home_id = ?";

  db.query(sql, [elder_id, caregiver_id, homeId], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error removing assignment", err });

    if (result.affectedRows === 0) {
      return res.status(404).json({ msg: "No matching assignment found for this home" });
    }

    // Close history row
    const closeHistorySql = `
      UPDATE elder_caregiver_assignments
      SET end_date = CURDATE()
      WHERE elder_id = ? AND caregiver_id = ? AND end_date IS NULL
      ORDER BY start_date DESC
      LIMIT 1
    `;

    db.query(closeHistorySql, [elder_id, caregiver_id], (err2) => {
      if (err2) console.error("⚠️ Failed to close assignment history:", err2);
      // We still return success because the current assignment was removed.
      return res.status(200).json({ msg: "Assignment removed successfully ❎" });
    });
  });
};

const { sendSMS, sendEmail } = require("../services/notification.service");




/**
 * Helper: ensure this elder belongs to this retirement home (via elder_assignments)
 */
function ensureElderInHome(homeId, elderId) {
  return new Promise((resolve, reject) => {
    const sql = `SELECT 1 FROM elder_assignments WHERE home_id = ? AND elder_id = ? LIMIT 1`;
    db.query(sql, [homeId, elderId], (err, rows) => {
      if (err) return reject(err);
      resolve(rows.length > 0);
    });
  });
}

/**
 * 1) GET /api/retirement/elders
 * Monitoring list: elders in this home + caregiver + latest health + latest GPS + last_check_in
 */
exports.getHomeEldersMonitoring = (req, res) => {
  const homeId = req.user.id;

  const sql = `
    SELECT
      e.elder_id,
      e.name AS elder_name,
      e.age,
      e.gender,
      e.last_check_in,

      c.caregiver_id,
      c.name AS caregiver_name,

      hl.date AS last_health_at,
      hl.blood_pressure,
      hl.blood_sugar,
      hl.temperature,
      hl.notes,

      el.recorded_at AS last_location_at,
      el.latitude AS last_latitude,
      el.longitude AS last_longitude

    FROM elder_assignments ea
    JOIN elders e ON e.elder_id = ea.elder_id
    LEFT JOIN caregivers c ON c.caregiver_id = ea.caregiver_id

    LEFT JOIN health_logs hl
      ON hl.elder_id = e.elder_id
     AND hl.log_id = (
        SELECT h2.log_id
        FROM health_logs h2
        WHERE h2.elder_id = e.elder_id
        ORDER BY h2.date DESC
        LIMIT 1
     )

    LEFT JOIN elder_location el
      ON el.elder_id = e.elder_id
     AND el.location_id = (
        SELECT l2.location_id
        FROM elder_location l2
        WHERE l2.elder_id = e.elder_id
        ORDER BY l2.recorded_at DESC
        LIMIT 1
     )

    WHERE ea.home_id = ?
    ORDER BY el.recorded_at DESC, hl.date DESC;
  `;

  db.query(sql, [homeId], (err, rows) => {
    if (err) {
      console.error("Monitoring list error:", err);
      return res.status(500).json({ msg: "Error fetching elders monitoring list", err });
    }

    res.status(200).json({
      msg: "Home elders monitoring list retrieved ✅",
      elders: rows,
    });
  });
};



/**
 * 2) GET /api/retirement/elders/:elder_id
 * Elder details: profile + assigned caregiver + latest health + latest gps
 */
exports.getHomeElderDetails = async (req, res) => {
  const homeId = req.user.id;
  const elderId = req.params.elder_id;

  try {
    const allowed = await ensureElderInHome(homeId, elderId);
    if (!allowed) return res.status(403).json({ msg: "Access denied: elder not in this retirement home" });

    const sql = `
      SELECT
       
        e.elder_id,
        e.name,
        e.age,
        e.gender,
        e.dob,
        e.location,
        e.last_check_in,
        e.created_at,
        ea.caregiver_id,
        c.name AS caregiver_name,
        c.phone AS caregiver_phone,
        c.email AS caregiver_email,

        hl.date AS last_health_at,
        hl.blood_pressure,
        hl.blood_sugar,
        hl.temperature,
        hl.notes,

        el.recorded_at AS last_location_at,
        el.latitude AS last_latitude,
        el.longitude AS last_longitude

      FROM elders e
      JOIN elder_assignments ea ON ea.elder_id = e.elder_id
      LEFT JOIN caregivers c ON c.caregiver_id = ea.caregiver_id

      LEFT JOIN health_logs hl ON hl.log_id = (
        SELECT h2.log_id
        FROM health_logs h2
        WHERE h2.elder_id = e.elder_id
        ORDER BY h2.date DESC
        LIMIT 1
      )

      LEFT JOIN elder_location el ON el.location_id = (
        SELECT l2.location_id
        FROM elder_location l2
        WHERE l2.elder_id = e.elder_id
        ORDER BY l2.recorded_at DESC
        LIMIT 1
      )

      WHERE e.elder_id = ? AND ea.home_id = ?
      LIMIT 1;
    `;

    db.query(sql, [elderId, homeId], (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching elder details", err });
      if (!rows.length) return res.status(404).json({ msg: "Elder not found" });

      res.status(200).json({
        msg: "Elder details retrieved ✅",
        elder: rows[0],
      });
    });
  } catch (error) {
    console.error("getHomeElderDetails error:", error);
    res.status(500).json({ msg: "Server error", error: error.message });
  }
};

/**
 * 3) GET /api/retirement/elders/:elder_id/health-logs?limit=50
 */
exports.getHomeElderHealthLogs = async (req, res) => {
  const homeId = req.user.id;
  const elderId = req.params.elder_id;
  const limit = Math.min(Number(req.query.limit || 50), 500);

  try {
    const allowed = await ensureElderInHome(homeId, elderId);
    if (!allowed) return res.status(403).json({ msg: "Access denied: elder not in this retirement home" });

    const sql = `
      SELECT log_id, caregiver_id, elder_id, blood_pressure, blood_sugar, temperature, notes, date
      FROM health_logs
      WHERE elder_id = ?
      ORDER BY date DESC
      LIMIT ?;
    `;

    db.query(sql, [elderId, limit], (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching health logs", err });
      res.status(200).json({
        msg: "Health logs retrieved ✅",
        elder_id: elderId,
        logs: rows,
      });
    });
  } catch (error) {
    console.error("getHomeElderHealthLogs error:", error);
    res.status(500).json({ msg: "Server error", error: error.message });
  }
};

/**
 * 4) GET /api/retirement/elders/:elder_id/location-history?limit=200
 */
exports.getHomeElderLocationHistory = async (req, res) => {
  const homeId = req.user.id;
  const elderId = req.params.elder_id;
  const limit = Math.min(Number(req.query.limit || 200), 2000);

  try {
    const allowed = await ensureElderInHome(homeId, elderId);
    if (!allowed) return res.status(403).json({ msg: "Access denied: elder not in this retirement home" });

    const sql = `
      SELECT location_id, latitude, longitude, recorded_at
      FROM elder_location
      WHERE elder_id = ?
      ORDER BY recorded_at DESC
      LIMIT ?;
    `;

    db.query(sql, [elderId, limit], (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching location history", err });
      res.status(200).json({
        msg: "Location history retrieved ✅",
        elder_id: elderId,
        history: rows,
      });
    });
  } catch (error) {
    console.error("getHomeElderLocationHistory error:", error);
    res.status(500).json({ msg: "Server error", error: error.message });
  }
};

/**
 * 5) GET /api/retirement/alerts?status=open|resolved|all&limit=100
 * Alerts relevant to elders assigned to this home.
 */
exports.getHomeAlerts = (req, res) => {
  const homeId = req.user.id;
  const status = (req.query.status || "open").toLowerCase();
  const limit = Math.min(Number(req.query.limit || 100), 500);

  let sql = `
    SELECT
      n.id, n.type, n.message, n.severity, n.status, n.is_read, n.user_id, n.created_at, n.resolved_at,
      e.name AS elder_name
    FROM admin_notifications n
    JOIN elder_assignments ea ON ea.elder_id = n.user_id AND ea.home_id = ?
    JOIN elders e ON e.elder_id = ea.elder_id
    WHERE 1 = 1
  `;

  const params = [homeId];

  if (status !== "all") {
    sql += " AND n.status = ? ";
    params.push(status);
  }

  sql += " ORDER BY n.created_at DESC LIMIT ? ";
  params.push(limit);

  db.query(sql, params, (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching home alerts", err });
    res.status(200).json({
      msg: "Home alerts retrieved ✅",
      alerts: rows,
    });
  });
};
// ✅ PATCH /api/retirement/elders/:elder_id/check-in
exports.checkInElder = async (req, res) => {
  const homeId = req.user.id;
  const elderId = req.params.elder_id;
  const notes = req.body?.notes || null;

  try {
    const allowed = await ensureElderInHome(homeId, elderId);
    if (!allowed) {
      return res.status(403).json({ msg: "Access denied: elder not in this retirement home" });
    }

    // update elders table
    db.query(
      "UPDATE elders SET last_check_in = NOW() WHERE elder_id = ?",
      [elderId],
      (err, result) => {
        if (err) return res.status(500).json({ msg: "Error checking in elder", err });
        if (result.affectedRows === 0) return res.status(404).json({ msg: "Elder not found" });

        // optional history
        db.query(
          "INSERT INTO elder_attendance (elder_id, home_id, action, notes) VALUES (?, ?, 'check_in', ?)",
          [elderId, homeId, notes],
          () => {} // ignore insert errors if you didn't create the table yet
        );

        res.status(200).json({ msg: "Elder checked in ✅", elder_id: Number(elderId) });
      }
    );
  } catch (error) {
    console.error("checkInElder error:", error);
    res.status(500).json({ msg: "Server error", error: error.message });
  }
};

// ✅ PATCH /api/retirement/elders/:elder_id/check-out
exports.checkOutElder = async (req, res) => {
  const homeId = req.user.id;
  const elderId = req.params.elder_id;
  const notes = req.body?.notes || null;

  try {
    const allowed = await ensureElderInHome(homeId, elderId);
    if (!allowed) {
      return res.status(403).json({ msg: "Access denied: elder not in this retirement home" });
    }

    // we keep last_check_in as last activity time (still useful)
    db.query(
      "UPDATE elders SET last_check_in = NOW() WHERE elder_id = ?",
      [elderId],
      (err, result) => {
        if (err) return res.status(500).json({ msg: "Error checking out elder", err });
        if (result.affectedRows === 0) return res.status(404).json({ msg: "Elder not found" });

        // optional history
        db.query(
          "INSERT INTO elder_attendance (elder_id, home_id, action, notes) VALUES (?, ?, 'check_out', ?)",
          [elderId, homeId, notes],
          () => {}
        );

        res.status(200).json({ msg: "Elder checked out ✅", elder_id: Number(elderId) });
      }
    );
  } catch (error) {
    console.error("checkOutElder error:", error);
    res.status(500).json({ msg: "Server error", error: error.message });
  }
};

// ✅ GET /api/retirement/elders/:elder_id/attendance?limit=50
exports.getElderAttendance = async (req, res) => {
  const homeId = req.user.id;
  const elderId = req.params.elder_id;
  const limit = Math.min(Number(req.query.limit || 50), 500);

  try {
    const allowed = await ensureElderInHome(homeId, elderId);
    if (!allowed) {
      return res.status(403).json({ msg: "Access denied: elder not in this retirement home" });
    }

    const sql = `
      SELECT attendance_id, action, notes, created_at
      FROM elder_attendance
      WHERE elder_id = ? AND home_id = ?
      ORDER BY created_at DESC
      LIMIT ?;
    `;

    db.query(sql, [elderId, homeId, limit], (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching attendance", err });
      res.status(200).json({ msg: "Attendance retrieved ✅", elder_id: Number(elderId), history: rows });
    });
  } catch (error) {
    console.error("getElderAttendance error:", error);
    res.status(500).json({ msg: "Server error", error: error.message });
  }
};
// ▶ Start caregiver shift
exports.startCaregiverShift = (req, res) => {
  const homeId = req.user.id;
  const caregiverId = req.params.caregiver_id;
  const notes = req.body?.notes || null;

  const checkSql = `
    SELECT * FROM caregiver_shifts
    WHERE caregiver_id = ? AND home_id = ? AND shift_end IS NULL
  `;

  db.query(checkSql, [caregiverId, homeId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error checking shift", err });
    if (rows.length > 0) {
      return res.status(400).json({ msg: "Caregiver already on active shift" });
    }

    const sql = `
      INSERT INTO caregiver_shifts (caregiver_id, home_id, shift_start, notes)
      VALUES (?, ?, NOW(), ?)
    `;

    db.query(sql, [caregiverId, homeId, notes], (err2) => {
      if (err2) return res.status(500).json({ msg: "Error starting shift", err2 });
      res.status(201).json({ msg: "Caregiver shift started ✅", caregiver_id: caregiverId });
    });
  });
};
// ⏹ End caregiver shift
exports.endCaregiverShift = (req, res) => {
  const homeId = req.user.id;
  const caregiverId = req.params.caregiver_id;
  const notes = req.body?.notes || null;

  const sql = `
    UPDATE caregiver_shifts
    SET shift_end = NOW(), notes = COALESCE(notes, ?)
    WHERE caregiver_id = ? AND home_id = ? AND shift_end IS NULL
  `;

  db.query(sql, [notes, caregiverId, homeId], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error ending shift", err });
    if (result.affectedRows === 0) {
      return res.status(400).json({ msg: "No active shift found" });
    }

    res.status(200).json({ msg: "Caregiver shift ended ✅", caregiver_id: caregiverId });
  });
};
// 👀 Active caregivers now
exports.getActiveShifts = (req, res) => {
  const homeId = req.user.id;

  const sql = `
    SELECT 
      cs.shift_id,
      cs.shift_start,
      c.caregiver_id,
      c.name AS caregiver_name,
      c.phone,
      c.email
    FROM caregiver_shifts cs
    JOIN caregivers c ON c.caregiver_id = cs.caregiver_id
    WHERE cs.home_id = ? AND cs.shift_end IS NULL
    ORDER BY cs.shift_start ASC
  `;

  db.query(sql, [homeId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching active shifts", err });
    res.status(200).json({ msg: "Active caregivers retrieved ✅", active: rows });
  });
};
// 📅 Caregiver shift history
exports.getCaregiverShiftHistory = (req, res) => {
  const homeId = req.user.id;
  const caregiverId = req.params.caregiver_id;
  const limit = Math.min(Number(req.query.limit || 30), 200);

  const sql = `
    SELECT shift_id, shift_start, shift_end, notes
    FROM caregiver_shifts
    WHERE caregiver_id = ? AND home_id = ?
    ORDER BY shift_start DESC
    LIMIT ?
  `;

  db.query(sql, [caregiverId, homeId, limit], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching shift history", err });
    res.status(200).json({
      msg: "Caregiver shift history retrieved ✅",
      caregiver_id: caregiverId,
      shifts: rows
    });
  });
};
/**
 * POST /api/retirement/elders/:elder_id/daily-summary
 * Create or update today's summary for an elder (home scope)
 */
exports.upsertDailySummary = async (req, res) => {
  const homeId = req.user.id;
  const elderId = req.params.elder_id;

  const {
    summary_date, // optional: "2025-12-14" (defaults to today)
    mood,
    meals,
    activities,
    medication_taken,
    sleep_hours,
    notes,
  } = req.body;

  try {
    const allowed = await ensureElderInHome(homeId, elderId);
    if (!allowed) return res.status(403).json({ msg: "Access denied: elder not in this retirement home" });

    const dateSql = summary_date ? "?" : "CURDATE()";
    const paramsDate = summary_date ? [summary_date] : [];

    const sql = `
      INSERT INTO daily_summaries
        (elder_id, home_id, summary_date, mood, meals, activities, medication_taken, sleep_hours, notes, updated_at)
      VALUES
        (?, ?, ${dateSql}, ?, ?, ?, ?, ?, ?, NOW())
      ON DUPLICATE KEY UPDATE
        mood = VALUES(mood),
        meals = VALUES(meals),
        activities = VALUES(activities),
        medication_taken = VALUES(medication_taken),
        sleep_hours = VALUES(sleep_hours),
        notes = VALUES(notes),
        updated_at = NOW();
    `;

    const params = [
      elderId,
      homeId,
      ...paramsDate,
      mood || null,
      meals || null,
      activities || null,
      medication_taken === undefined ? null : (medication_taken ? 1 : 0),
      sleep_hours === undefined ? null : Number(sleep_hours),
      notes || null,
    ];

    db.query(sql, params, (err) => {
      if (err) return res.status(500).json({ msg: "Error saving daily summary", err });
      res.status(200).json({ msg: "Daily summary saved ✅", elder_id: Number(elderId), summary_date: summary_date || "today" });
    });
  } catch (error) {
    console.error("upsertDailySummary error:", error);
    res.status(500).json({ msg: "Server error", error: error.message });
  }
};

/**
 * GET /api/retirement/elders/:elder_id/daily-summary?date=YYYY-MM-DD
 * Fetch one daily summary (home scope)
 */
exports.getDailySummary = async (req, res) => {
  const homeId = req.user.id;
  const elderId = req.params.elder_id;
  const date = req.query.date; // optional

  try {
    const allowed = await ensureElderInHome(homeId, elderId);
    if (!allowed) return res.status(403).json({ msg: "Access denied: elder not in this retirement home" });

    const sql = `
      SELECT *
      FROM daily_summaries
      WHERE elder_id = ? AND home_id = ?
        AND summary_date = ${date ? "?" : "CURDATE()"}
      LIMIT 1;
    `;

    const params = date ? [elderId, homeId, date] : [elderId, homeId];

    db.query(sql, params, (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching daily summary", err });
      if (!rows.length) return res.status(404).json({ msg: "No summary found", elder_id: Number(elderId), date: date || "today" });

      res.status(200).json({ msg: "Daily summary retrieved ✅", summary: rows[0] });
    });
  } catch (error) {
    console.error("getDailySummary error:", error);
    res.status(500).json({ msg: "Server error", error: error.message });
  }
};

/**
 * GET /api/retirement/daily-summaries?date=YYYY-MM-DD
 * Get summaries for all elders in this home for a date (defaults today)
 */
exports.getHomeDailySummaries = (req, res) => {
  const homeId = req.user.id;
  const date = req.query.date;

  const sql = `
    SELECT
      ds.summary_id,
      ds.summary_date,
      ds.mood,
      ds.meals,
      ds.activities,
      ds.medication_taken,
      ds.sleep_hours,
      ds.notes,
      ds.updated_at,
      e.elder_id,
      e.name AS elder_name
    FROM daily_summaries ds
    JOIN elders e ON e.elder_id = ds.elder_id
    JOIN elder_assignments ea ON ea.elder_id = e.elder_id AND ea.home_id = ?
    WHERE ds.home_id = ?
      AND ds.summary_date = ${date ? "?" : "CURDATE()"}
    ORDER BY e.name ASC;
  `;

  const params = date ? [homeId, homeId, date] : [homeId, homeId];

  db.query(sql, params, (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching home daily summaries", err });
    res.status(200).json({ msg: "Home daily summaries retrieved ✅", date: date || "today", summaries: rows });
  });
};
// 💳 List payments for this retirement home
exports.getHomePayments = (req, res) => {
  const homeId = req.user.id;
  const status = (req.query.status || "all").toLowerCase();

  let sql = `
    SELECT 
      p.payment_id,
      p.family_id,
      fm.name AS family_name,
      fm.email AS family_email,
      fm.phone AS family_phone,

      p.target_type,
      p.target_id,
      p.amount,
      p.method,
      p.status,
      p.purpose,
      p.created_at
    FROM payments p
    LEFT JOIN family_members fm ON fm.family_id = p.family_id
    WHERE p.target_type = 'retirement_home'
      AND p.target_id = ?
  `;

  const params = [homeId];

  if (status !== "all") {
    sql += " AND p.status = ? ";
    params.push(status);
  }

  sql += " ORDER BY p.created_at DESC";

  db.query(sql, params, (err, rows) => {
    if (err) {
      console.error("getHomePayments error:", err);
      return res.status(500).json({ msg: "Error fetching home payments", err });
    }

    res.status(200).json({
      msg: "Home payments retrieved ✅",
      home_id: homeId,
      count: rows.length,
      payments: rows,
    });
  });
};
// 💳 Get one payment details (only if belongs to this home)
exports.getHomePaymentById = (req, res) => {
  const homeId = req.user.id;
  const paymentId = req.params.payment_id;

  const paymentSql = `
    SELECT 
      p.payment_id,
      p.family_id,
      fm.name AS family_name,
      fm.email AS family_email,
      fm.phone AS family_phone,

      p.target_type,
      p.target_id,
      p.amount,
      p.method,
      p.status,
      p.purpose,
      p.created_at
    FROM payments p
    LEFT JOIN family_members fm ON fm.family_id = p.family_id
    WHERE p.payment_id = ?
      AND p.target_type = 'retirement_home'
      AND p.target_id = ?
    LIMIT 1
  `;

  db.query(paymentSql, [paymentId, homeId], (err, rows) => {
    if (err) {
      console.error("getHomePaymentById error:", err);
      return res.status(500).json({ msg: "Error fetching payment", err });
    }

    if (!rows.length) {
      return res.status(404).json({ msg: "Payment not found for this retirement home" });
    }

    const payment = rows[0];

    // Optional: fetch related transactions
    const txSql = `
      SELECT 
        transaction_id,
        payment_id,
        from_role,
        to_role,
        from_id,
        to_id,
        amount,
        type,
        created_at
      FROM transactions
      WHERE payment_id = ?
      ORDER BY created_at ASC
    `;

    db.query(txSql, [paymentId], (err2, txRows) => {
      if (err2) {
        console.error("getHomePaymentById tx error:", err2);
        // still return payment even if tx fails
        return res.status(200).json({
          msg: "Payment retrieved ✅ (transactions failed)",
          payment,
          transactions: [],
          tx_error: err2,
        });
      }

      res.status(200).json({
        msg: "Payment details retrieved ✅",
        payment,
        transactions: txRows,
      });
    });
  });
};
// 💰 Transactions for this retirement home (money coming to the home)
exports.getHomeTransactions = (req, res) => {
  const homeId = req.user.id;
  const limit = Math.min(Number(req.query.limit || 100), 500);

  const sql = `
    SELECT 
      t.transaction_id,
      t.payment_id,
      t.from_role,
      t.to_role,
      t.from_id,
      t.to_id,
      t.amount,
      t.type,
      t.created_at
    FROM transactions t
    WHERE (
      (t.to_role = 'retirement_home' AND t.to_id = ?)
      OR
      (t.from_role = 'retirement_home' AND t.from_id = ?)
    )
    ORDER BY t.created_at DESC
    LIMIT ?
  `;

  db.query(sql, [homeId, homeId, limit], (err, rows) => {
    if (err) {
      console.error("getHomeTransactions error:", err);
      return res.status(500).json({ msg: "Error fetching home transactions", err });
    }

    res.status(200).json({
      msg: "Home transactions retrieved ✅",
      home_id: homeId,
      count: rows.length,
      transactions: rows,
    });
  });
};
/**
 * 🧨 CREATE incident
 * POST /api/retirement/incidents
 */
exports.createIncident = async (req, res) => {
  const homeId = req.user.id;
  const { elder_id, caregiver_id, type, severity, description } = req.body;

  if (!elder_id || !type || !description) {
    return res.status(400).json({ msg: "elder_id, type and description are required" });
  }

  try {
    // ✅ make sure elder exists AND is assigned to this home
    const allowed = await ensureElderInHome(homeId, elder_id);
    if (!allowed) {
      return res.status(404).json({ msg: "Elder not found in this retirement home" });
    }

    const sql = `
      INSERT INTO retirement_incidents
      (home_id, elder_id, caregiver_id, type, severity, description)
      VALUES (?, ?, ?, ?, ?, ?)
    `;

    db.query(
      sql,
      [homeId, elder_id, caregiver_id || null, type, severity || "medium", description],
      (err, result) => {
        if (err) {
          console.error("createIncident error:", err);
          return res.status(500).json({ msg: "Error creating incident", err });
        }

        res.status(201).json({
          msg: "Incident created successfully ✅",
          incident_id: result.insertId,
        });
      }
    );
  } catch (error) {
    console.error("createIncident catch:", error);
    res.status(500).json({ msg: "Server error", error: error.message });
  }
};


/**
 * 📋 LIST incidents for this home
 * GET /api/retirement/incidents
 */
exports.getHomeIncidents = (req, res) => {
  const homeId = req.user.id;
  const status = (req.query.status || "all").toLowerCase();

  let sql = `
    SELECT
      i.incident_id,
      i.type,
      i.severity,
      i.status,
      i.description,
      i.created_at,
      i.resolved_at,

      e.elder_id,
      e.name AS elder_name,

      c.caregiver_id,
      c.name AS caregiver_name
    FROM retirement_incidents i
    JOIN elders e ON e.elder_id = i.elder_id
    LEFT JOIN caregivers c ON c.caregiver_id = i.caregiver_id
    WHERE i.home_id = ?
  `;

  const params = [homeId];

  if (status !== "all") {
    sql += " AND i.status = ? ";
    params.push(status);
  }

  sql += " ORDER BY i.created_at DESC";

  db.query(sql, params, (err, rows) => {
    if (err) {
      console.error("getHomeIncidents error:", err);
      return res.status(500).json({ msg: "Error fetching incidents", err });
    }

    res.status(200).json({
      msg: "Incidents retrieved ✅",
      count: rows.length,
      incidents: rows,
    });
  });
};

/**
 * 🔍 INCIDENT DETAILS
 * GET /api/retirement/incidents/:incident_id
 */
exports.getIncidentById = (req, res) => {
  const homeId = req.user.id;
  const { incident_id } = req.params;

  const sql = `
    SELECT *
    FROM retirement_incidents
    WHERE incident_id = ? AND home_id = ?
    LIMIT 1
  `;

  db.query(sql, [incident_id, homeId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching incident", err });
    if (!rows.length) return res.status(404).json({ msg: "Incident not found" });

    res.status(200).json({
      msg: "Incident retrieved ✅",
      incident: rows[0],
    });
  });
};

/**
 * ✅ UPDATE incident status
 * PATCH /api/retirement/incidents/:incident_id/status
 */
exports.updateIncidentStatus = (req, res) => {
  const homeId = req.user.id;
  const { incident_id } = req.params;
  const { status } = req.body;

  if (!["open", "investigating", "resolved"].includes(status)) {
    return res.status(400).json({ msg: "Invalid status value" });
  }

  const sql = `
    UPDATE retirement_incidents
    SET status = ?, resolved_at = IF(? = 'resolved', NOW(), NULL)
    WHERE incident_id = ? AND home_id = ?
  `;

  db.query(sql, [status, status, incident_id, homeId], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error updating incident", err });
    if (result.affectedRows === 0)
      return res.status(404).json({ msg: "Incident not found" });

    res.status(200).json({ msg: "Incident status updated ✅" });
  });
};

