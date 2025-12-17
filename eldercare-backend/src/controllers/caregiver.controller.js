const db = require("../config/db");
const { saveHealthLogAndAlert } = require("../services/healthService");

// -------------------- helpers --------------------
function getCaregiverMeta(caregiverId) {
  return new Promise((resolve, reject) => {
    db.query(
      "SELECT caregiver_id, employment_type, home_id FROM caregivers WHERE caregiver_id = ? LIMIT 1",
      [caregiverId],
      (err, rows) => {
        if (err) return reject(err);
        resolve(rows[0] || null);
      }
    );
  });
}

// -------------------- 1) dashboard + profile --------------------
exports.getDashboard = (req, res) => {
  res.status(200).json({ msg: "Caregiver dashboard ✅", caregiver_id: req.user.id });
};

exports.getMyProfile = (req, res) => {
  db.query(
    `SELECT caregiver_id, name, email, phone, employment_type, home_id, city, skills,
            expected_salary, hours_per_day, status, is_approved, created_at
     FROM caregivers
     WHERE caregiver_id = ?
     LIMIT 1`,
    [req.user.id],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching profile", err });
      res.status(200).json({ profile: rows[0] || null });
    }
  );
};

exports.updateProfile = (req, res) => {
  const caregiverId = req.user.id;
  const { phone, city, skills, expected_salary, hours_per_day, status, latitude, longitude } = req.body;

  db.query(
    `UPDATE caregivers
     SET phone = COALESCE(?, phone),
         city = COALESCE(?, city),
         skills = COALESCE(?, skills),
         expected_salary = COALESCE(?, expected_salary),
         hours_per_day = COALESCE(?, hours_per_day),
         status = COALESCE(?, status),
         latitude = COALESCE(?, latitude),
         longitude = COALESCE(?, longitude)
     WHERE caregiver_id = ?`,
    [phone, city, skills, expected_salary, hours_per_day, status, latitude, longitude, caregiverId],
    (err) => {
      if (err) return res.status(500).json({ msg: "Error updating profile", err });
      res.status(200).json({ msg: "Profile updated ✅" });
    }
  );
};

// -------------------- 2) assigned elders --------------------
exports.getAssignedElders = (req, res) => {
  db.query(
    `SELECT e.elder_id, e.name, e.age, e.gender, e.home_id, e.location, e.last_check_in,
            ea.home_id AS assignment_home_id, ea.assigned_at
     FROM elder_assignments ea
     JOIN elders e ON e.elder_id = ea.elder_id
     WHERE ea.caregiver_id = ?
     ORDER BY ea.assigned_at DESC`,
    [req.user.id],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching assigned elders", err });
      res.status(200).json({ elders: rows });
    }
  );
};

exports.getElderDetails = (req, res) => {
  const elderId = req.params.elder_id;
  db.query(
    `SELECT e.elder_id, e.name, e.age, e.gender, e.location, e.last_check_in,
            rh.home_id, rh.name AS home_name, rh.city AS home_city
     FROM elders e
     LEFT JOIN retirement_homes rh ON rh.home_id = e.home_id
     WHERE e.elder_id = ?
     LIMIT 1`,
    [elderId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching elder details", err });
      res.status(200).json({ elder: rows[0] || null });
    }
  );
};

// -------------------- 3) health logs --------------------
exports.logElderHealth = async (req, res) => {
  try {
    const caregiverId = req.user.id;
    const elderId = req.params.elder_id;
    const { blood_pressure, blood_sugar, temperature, notes, heart_rate } = req.body;

    const result = await saveHealthLogAndAlert({
      caregiver_id: caregiverId,
      elder_id: elderId,
      blood_pressure: blood_pressure || null,
      blood_sugar: blood_sugar || null,
      temperature: temperature || null,
      notes: notes || null,
      heart_rate: heart_rate || null,
    });

    res.status(201).json({ msg: "Health log saved ✅", log_id: result.insertId, alerts: result.alerts });
  } catch (error) {
    res.status(500).json({ msg: "Error logging health", error: error.message });
  }
};

exports.getElderHealthLogs = (req, res) => {
  const elderId = req.params.elder_id;
  const limit = Math.min(Number(req.query.limit || 50), 500);

  db.query(
    `SELECT log_id, caregiver_id, elder_id, blood_pressure, blood_sugar, temperature, notes, date
     FROM health_logs
     WHERE elder_id = ?
     ORDER BY date DESC
     LIMIT ?`,
    [elderId, limit],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching health logs", err });
      res.status(200).json({ logs: rows });
    }
  );
};

// -------------------- 4) medications --------------------
exports.getElderMedicationPlan = (req, res) => {
  const elderId = req.params.elder_id;
  db.query(
    `SELECT medication_id, name, dosage, frequency, instructions, start_date, end_date, active, created_at
     FROM medications
     WHERE elder_id = ? AND active = 1
     ORDER BY created_at DESC`,
    [elderId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching medication plan", err });
      res.status(200).json({ medications: rows });
    }
  );
};

// checklist = meds + today's latest status (no schedule table, so this is the safest MVP)
exports.getTodayMedicationChecklist = (req, res) => {
  const elderId = req.params.elder_id;
  db.query(
    `SELECT
        m.medication_id, m.name, m.dosage, m.frequency, m.instructions,
        MAX(CASE WHEN DATE(ml.created_at) = CURDATE() THEN ml.status END) AS today_status,
        MAX(CASE WHEN DATE(ml.created_at) = CURDATE() THEN ml.taken_at END) AS today_taken_at
     FROM medications m
     LEFT JOIN medication_logs ml
       ON ml.medication_id = m.medication_id AND ml.elder_id = m.elder_id
     WHERE m.elder_id = ? AND m.active = 1
     GROUP BY m.medication_id
     ORDER BY m.created_at DESC`,
    [elderId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error building checklist", err });
      res.status(200).json({ checklist: rows });
    }
  );
};

exports.getMedicationLogs = (req, res) => {
  const elderId = req.params.elder_id;
  const date = req.query.date; // YYYY-MM-DD optional

  let sql = `
    SELECT ml.log_id, ml.medication_id, m.name, m.dosage,
           ml.status, ml.scheduled_time, ml.taken_at, ml.notes, ml.created_at, ml.caregiver_id
    FROM medication_logs ml
    JOIN medications m ON m.medication_id = ml.medication_id
    WHERE ml.elder_id = ?
  `;
  const params = [elderId];

  if (date) {
    sql += " AND DATE(ml.created_at) = ? ";
    params.push(date);
  }

  sql += " ORDER BY ml.created_at DESC";

  db.query(sql, params, (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching medication logs", err });
    res.status(200).json({ logs: rows });
  });
};

// -------------------- 5) daily summary --------------------
exports.upsertDailySummary = (req, res) => {
  const caregiverId = req.user.id;
  const elderId = req.params.elder_id;
  const homeId = req.assignment?.home_id || null; // null for freelance assignments

  const { summary_date, mood, meals, activities, medication_taken, sleep_hours, notes } = req.body;

  const dateSql = summary_date ? "?" : "CURDATE()";
  const paramsDate = summary_date ? [summary_date] : [];

  db.query(
    `INSERT INTO daily_summaries
       (elder_id, caregiver_id, home_id, summary_date, mood, meals, activities, medication_taken, sleep_hours, notes, updated_at)
     VALUES
       (?, ?, ?, ${dateSql}, ?, ?, ?, ?, ?, ?, NOW())
     ON DUPLICATE KEY UPDATE
       caregiver_id = VALUES(caregiver_id),
       home_id = VALUES(home_id),
       mood = VALUES(mood),
       meals = VALUES(meals),
       activities = VALUES(activities),
       medication_taken = VALUES(medication_taken),
       sleep_hours = VALUES(sleep_hours),
       notes = VALUES(notes),
       updated_at = NOW()`,
    [
      elderId,
      caregiverId,
      homeId,
      ...paramsDate,
      mood || null,
      meals || null,
      activities || null,
      medication_taken === undefined ? null : (medication_taken ? 1 : 0),
      sleep_hours === undefined ? null : Number(sleep_hours),
      notes || null,
    ],
    (err) => {
      if (err) return res.status(500).json({ msg: "Error saving daily summary", err });
      res.status(200).json({ msg: "Daily summary saved ✅" });
    }
  );
};

exports.getDailySummary = (req, res) => {
  const elderId = req.params.elder_id;
  const date = req.query.date; // optional

  const sql = `
    SELECT summary_id, elder_id, caregiver_id, home_id, summary_date, mood, meals, activities,
           medication_taken, sleep_hours, notes, created_at, updated_at
    FROM daily_summaries
    WHERE elder_id = ? AND summary_date = ${date ? "?" : "CURDATE()"}
    LIMIT 1
  `;
  const params = date ? [elderId, date] : [elderId];

  db.query(sql, params, (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching daily summary", err });
    res.status(200).json({ summary: rows[0] || null });
  });
};

// -------------------- 6) incidents --------------------
exports.createIncident = (req, res) => {
  const caregiverId = req.user.id;
  const elderId = req.params.elder_id;
  const homeId = req.assignment?.home_id || null;

  const { type, severity, title, description, occurred_at } = req.body;

  // If your incidents table requires home_id NOT NULL, then block freelance here:
  // if (!homeId) return res.status(403).json({ msg: "Incidents are retirement-home only for now" });

  db.query(
    `INSERT INTO incidents (home_id, elder_id, caregiver_id, type, severity, title, description, occurred_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [homeId, elderId, caregiverId, type || "other", severity || "medium", title || null, description || null, occurred_at || null],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "Error creating incident", err });
      res.status(201).json({ msg: "Incident created ✅", incident_id: result.insertId });
    }
  );
};

exports.getMyIncidents = (req, res) => {
  const caregiverId = req.user.id;

  db.query(
    `SELECT i.incident_id, i.elder_id, e.name AS elder_name,
            i.type, i.severity, i.status, i.title, i.description, i.occurred_at, i.created_at
     FROM incidents i
     JOIN elders e ON e.elder_id = i.elder_id
     WHERE i.caregiver_id = ?
     ORDER BY i.created_at DESC`,
    [caregiverId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching incidents", err });
      res.status(200).json({ incidents: rows });
    }
  );
};

// -------------------- 7) check-in --------------------
exports.checkInElder = (req, res) => {
  const caregiverId = req.user.id;
  const elderId = req.params.elder_id;

  db.query("INSERT INTO checkins (elder_id, caregiver_id) VALUES (?, ?)", [elderId, caregiverId], (err) => {
    if (err) return res.status(500).json({ msg: "Error creating check-in", err });

    db.query("UPDATE elders SET last_check_in = NOW() WHERE elder_id = ?", [elderId], (err2) => {
      if (err2) return res.status(500).json({ msg: "Check-in saved but failed to update elder", err2 });
      res.status(201).json({ msg: "Check-in saved ✅" });
    });
  });
};

// -------------------- 8) shifts (INTERNAL ONLY) --------------------
exports.startMyShift = async (req, res) => {
  try {
    const caregiverId = req.user.id;
    const notes = req.body?.notes || null;

    const meta = await getCaregiverMeta(caregiverId);
    if (!meta) return res.status(404).json({ msg: "Caregiver not found" });

    // internal-only (since caregiver_shifts.home_id is NOT NULL in schema)
    if (meta.employment_type !== "internal" || !meta.home_id) {
      return res.status(403).json({ msg: "Shift tracking is for internal (retirement-home) caregivers only" });
    }

    db.query(
      "SELECT shift_id FROM caregiver_shifts WHERE caregiver_id = ? AND home_id = ? AND shift_end IS NULL",
      [caregiverId, meta.home_id],
      (err, active) => {
        if (err) return res.status(500).json({ msg: "Error checking active shift", err });
        if (active.length) return res.status(400).json({ msg: "You already have an active shift" });

        db.query(
          "INSERT INTO caregiver_shifts (caregiver_id, home_id, shift_start, notes) VALUES (?, ?, NOW(), ?)",
          [caregiverId, meta.home_id, notes],
          (err2, result) => {
            if (err2) return res.status(500).json({ msg: "Error starting shift", err2 });
            res.status(201).json({ msg: "Shift started ✅", shift_id: result.insertId });
          }
        );
      }
    );
  } catch (e) {
    res.status(500).json({ msg: "Server error starting shift", error: e.message });
  }
};

exports.endMyShift = async (req, res) => {
  try {
    const caregiverId = req.user.id;
    const notes = req.body?.notes || null;

    const meta = await getCaregiverMeta(caregiverId);
    if (!meta) return res.status(404).json({ msg: "Caregiver not found" });

    if (meta.employment_type !== "internal" || !meta.home_id) {
      return res.status(403).json({ msg: "Shift tracking is for internal (retirement-home) caregivers only" });
    }

    db.query(
      `UPDATE caregiver_shifts
       SET shift_end = NOW(), notes = COALESCE(notes, ?)
       WHERE caregiver_id = ? AND home_id = ? AND shift_end IS NULL`,
      [notes, caregiverId, meta.home_id],
      (err, result) => {
        if (err) return res.status(500).json({ msg: "Error ending shift", err });
        if (!result.affectedRows) return res.status(400).json({ msg: "No active shift found" });
        res.status(200).json({ msg: "Shift ended ✅" });
      }
    );
  } catch (e) {
    res.status(500).json({ msg: "Server error ending shift", error: e.message });
  }
};

exports.getMyActiveShift = async (req, res) => {
  try {
    const meta = await getCaregiverMeta(req.user.id);
    if (!meta) return res.status(404).json({ msg: "Caregiver not found" });

    if (meta.employment_type !== "internal" || !meta.home_id) {
      return res.status(200).json({ active_shift: null, note: "Freelance caregivers have no shift tracking" });
    }

    db.query(
      `SELECT shift_id, home_id, shift_start, shift_end, notes
       FROM caregiver_shifts
       WHERE caregiver_id = ? AND home_id = ? AND shift_end IS NULL
       ORDER BY shift_start DESC
       LIMIT 1`,
      [req.user.id, meta.home_id],
      (err, rows) => {
        if (err) return res.status(500).json({ msg: "Error fetching active shift", err });
        res.status(200).json({ active_shift: rows[0] || null });
      }
    );
  } catch (e) {
    res.status(500).json({ msg: "Server error", error: e.message });
  }
};

exports.getMyShiftHistory = async (req, res) => {
  try {
    const meta = await getCaregiverMeta(req.user.id);
    if (!meta) return res.status(404).json({ msg: "Caregiver not found" });

    if (meta.employment_type !== "internal" || !meta.home_id) {
      return res.status(200).json({ shifts: [], note: "Freelance caregivers have no shift tracking" });
    }

    const limit = Math.min(Number(req.query.limit || 30), 200);

    db.query(
      `SELECT shift_id, home_id, shift_start, shift_end, notes, created_at
       FROM caregiver_shifts
       WHERE caregiver_id = ? AND home_id = ?
       ORDER BY shift_start DESC
       LIMIT ?`,
      [req.user.id, meta.home_id, limit],
      (err, rows) => {
        if (err) return res.status(500).json({ msg: "Error fetching shift history", err });
        res.status(200).json({ shifts: rows });
      }
    );
  } catch (e) {
    res.status(500).json({ msg: "Server error", error: e.message });
  }
};
