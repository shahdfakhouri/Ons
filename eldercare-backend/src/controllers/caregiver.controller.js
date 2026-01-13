const db = require("../config/db");
const { saveHealthLogAndAlert } = require("../services/healthService");

// -------------------- helpers --------------------
function getCaregiverMeta(caregiverId) {
  return new Promise((resolve, reject) => {
    db.query(
      `SELECT caregiver_id, employment_type, home_id
       FROM caregivers
       WHERE caregiver_id = ?
       LIMIT 1`,
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
exports.getMedicationStats = (req, res) => {
  const elderId = Number(req.params.elder_id);
  const days = Math.min(Math.max(Number(req.query.days || 7), 1), 90); // 1..90

  // Summary counts + adherence
  const summarySql = `
    SELECT
      SUM(status='taken')   AS taken_count,
      SUM(status='missed')  AS missed_count,
      SUM(status='skipped') AS skipped_count,
      COUNT(*)              AS total_logs
    FROM medication_logs
    WHERE elder_id = ?
      AND created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
  `;

  // Per-medication breakdown
  const perMedSql = `
    SELECT
      m.medication_id,
      m.name,
      m.dosage,
      SUM(ml.status='taken')   AS taken_count,
      SUM(ml.status='missed')  AS missed_count,
      SUM(ml.status='skipped') AS skipped_count,
      COUNT(ml.log_id)         AS total_logs,
      MAX(ml.taken_at)         AS last_taken_at,
      MAX(ml.created_at)       AS last_logged_at
    FROM medications m
    LEFT JOIN medication_logs ml
      ON ml.medication_id = m.medication_id
     AND ml.elder_id = m.elder_id
     AND ml.created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
    WHERE m.elder_id = ?
      AND m.active = 1
    GROUP BY m.medication_id
    ORDER BY missed_count DESC, taken_count ASC, m.created_at DESC
  `;

  db.query(summarySql, [elderId, days], (err, summaryRows) => {
    if (err) return res.status(500).json({ msg: "Error fetching medication stats", err });

    const s = summaryRows[0] || { taken_count: 0, missed_count: 0, skipped_count: 0, total_logs: 0 };
    const adherence =
      s.total_logs > 0 ? Math.round((Number(s.taken_count) / Number(s.total_logs)) * 100) : null;

    db.query(perMedSql, [days, elderId], (err2, medsRows) => {
      if (err2) return res.status(500).json({ msg: "Error fetching per-medication stats", err: err2 });

      res.status(200).json({
        elder_id: elderId,
        window_days: days,
        summary: {
          ...s,
          adherence_percent: adherence,
        },
        per_medication: medsRows,
      });
    });
  });
};

// -------------------- 5) daily summary --------------------
exports.upsertDailySummary = (req, res) => {
  const caregiverId = req.user.id;
  const elderId = Number(req.params.elder_id);

  const {
    mood,
    meals,
    activities,
    medication_taken,
    sleep_hours,
    notes,
  } = req.body || {};

  // Get home_id from elder_assignments (works for internal + freelance)
  db.query(
    `SELECT home_id FROM elder_assignments WHERE elder_id = ? AND caregiver_id = ? LIMIT 1`,
    [elderId, caregiverId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error reading assignment", err });
      if (!rows.length) return res.status(403).json({ msg: "Access denied: elder not assigned" });

      const homeId = rows[0].home_id || null;

      const sql = `
        INSERT INTO daily_summaries
          (elder_id, caregiver_id, home_id, summary_date, mood, meals, activities, medication_taken, sleep_hours, notes, created_at, updated_at)
        VALUES
          (?, ?, ?, CURDATE(), ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ON DUPLICATE KEY UPDATE
          caregiver_id = VALUES(caregiver_id),
          home_id = VALUES(home_id),
          mood = VALUES(mood),
          meals = VALUES(meals),
          activities = VALUES(activities),
          medication_taken = VALUES(medication_taken),
          sleep_hours = VALUES(sleep_hours),
          notes = VALUES(notes),
          updated_at = NOW()
      `;

      db.query(
        sql,
        [
          elderId,
          caregiverId,
          homeId,
          mood || null,
          meals || null,
          activities || null,
          medication_taken ?? null,
          sleep_hours ?? null,
          notes || null,
        ],
        (err2) => {
          if (err2) return res.status(500).json({ msg: "Error saving daily summary", err: err2 });
          res.status(200).json({ msg: "Daily summary saved ✅" });
        }
      );
    }
  );
};

exports.getDailySummary = (req, res) => {
  const elderId = Number(req.params.elder_id);

  db.query(
    `SELECT * FROM daily_summaries WHERE elder_id = ? AND summary_date = CURDATE() LIMIT 1`,
    [elderId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching daily summary", err });
      res.status(200).json({ summary: rows[0] || null });
    }
  );
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

exports.updateIncidentStatus = (req, res) => {
  const caregiverId = req.user.id;
  const incidentId = Number(req.params.incident_id);
  const { status } = req.body || {};

  const allowed = ["open", "reviewing", "resolved", "closed"];
  if (!allowed.includes(status)) {
    return res.status(400).json({ msg: `Invalid status. Allowed: ${allowed.join(", ")}` });
  }

  db.query(
    `UPDATE incidents
     SET status = ?, updated_at = NOW()
     WHERE incident_id = ? AND caregiver_id = ?`,
    [status, incidentId, caregiverId],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "Error updating incident status", err });
      if (result.affectedRows === 0) {
        return res.status(404).json({ msg: "Incident not found or you don't have permission" });
      }
      res.status(200).json({ msg: "Incident status updated ✅" });
    }
  );
};

exports.getIncidentById = (req, res) => {
  const caregiverId = req.user.id;
  const incidentId = Number(req.params.incident_id);

  db.query(
    `SELECT i.*, e.name AS elder_name
     FROM incidents i
     JOIN elders e ON e.elder_id = i.elder_id
     WHERE i.incident_id = ? AND i.caregiver_id = ?
     LIMIT 1`,
    [incidentId, caregiverId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching incident", err });
      if (!rows.length) return res.status(404).json({ msg: "Incident not found" });
      res.status(200).json({ incident: rows[0] });
    }
  );
};

// -------------------- 7) check-in + location --------------------
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

exports.updateElderLocation = (req, res) => {
  const elderId = Number(req.params.elder_id);

  const { latitude, longitude } = req.body || {};

  if (latitude == null || longitude == null) {
    return res.status(400).json({ msg: "latitude and longitude are required" });
  }

  db.query(
    `INSERT INTO elder_location (elder_id, latitude, longitude, recorded_at)
     VALUES (?, ?, ?, NOW())`,
    [elderId, latitude, longitude],
    (err) => {
      if (err) {
        console.error("Location insert error:", err);
        return res.status(500).json({ msg: "Error saving location", err });
      }

      // Optional: keep elders.last known location (string) if you use it elsewhere
      const locationText = `${latitude},${longitude}`;
      db.query(
        `UPDATE elders SET location = ? WHERE elder_id = ?`,
        [locationText, elderId],
        () => {
          // ignore error here — location history already saved
          res.status(201).json({ msg: "Location saved ✅" });
        }
      );
    }
  );
};

exports.getElderLocationHistory = (req, res) => {
  const elderId = Number(req.params.elder_id);
  const limit = Math.min(Number(req.query.limit || 100), 500);

  db.query(
    `SELECT location_id, elder_id, latitude, longitude, recorded_at
     FROM elder_location
     WHERE elder_id = ?
     ORDER BY recorded_at DESC
     LIMIT ?`,
    [elderId, limit],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching location history", err });
      res.status(200).json({ history: rows });
    }
  );
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
       SET shift_end = NOW(), notes = ?
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
//status
exports.getElderStatus = (req, res) => {
  const elderId = req.params.elder_id;

  const sql = `
    SELECT
      e.elder_id,
      e.last_check_in,

      c.checkin_id AS last_checkin_id,
      c.caregiver_id AS last_checkin_by,
      c.checkin_time AS last_checkin_time

    FROM elders e
    LEFT JOIN checkins c
      ON c.checkin_id = (
        SELECT c2.checkin_id
        FROM checkins c2
        WHERE c2.elder_id = e.elder_id
        ORDER BY c2.checkin_time DESC
        LIMIT 1
      )
    WHERE e.elder_id = ?
    LIMIT 1
  `;

  db.query(sql, [elderId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching elder status", err });
    if (!rows.length) return res.status(404).json({ msg: "Elder not found" });

    const status = rows[0];

    // Optional: compute "is_recent_checkin" (e.g. last 8 hours)
    // If you don't want assumptions, remove this block.
    status.is_recent_checkin =
      status.last_checkin_time
        ? (Date.now() - new Date(status.last_checkin_time).getTime()) <= 8 * 60 * 60 * 1000
        : false;

    res.status(200).json({ msg: "Elder status retrieved ✅", status });
  });
};
//alerts 
exports.getMyAlerts = (req, res) => {
  const caregiverId = req.user.id;

  const sql = `
    SELECT
      n.id, n.type, n.message, n.severity, n.status, n.created_at,
      n.user_id AS elder_id,
      e.name AS elder_name
    FROM admin_notifications n
    JOIN elder_assignments ea
      ON ea.elder_id = n.user_id
     AND ea.caregiver_id = ?
    LEFT JOIN elders e ON e.elder_id = n.user_id
    WHERE n.status = 'open'
      AND (n.type IN ('health_alert','alert','emergency') OR n.type = '')
    ORDER BY n.created_at DESC
    LIMIT 200
  `;

  db.query(sql, [caregiverId], (err, rows) => {
    if (err) {
      console.error("Error fetching caregiver alerts:", err);
      return res.status(500).json({ msg: "Error fetching alerts", err });
    }
    res.status(200).json({ msg: "Alerts retrieved ✅", alerts: rows });
  });
};

exports.getElderAlerts = (req, res) => {
  const elderId = Number(req.params.elder_id);

  const sql = `
    SELECT id, type, message, severity, status, created_at
    FROM admin_notifications
    WHERE user_id = ?
      AND status = 'open'
      AND (type IN ('health_alert','alert','emergency') OR type = '')
    ORDER BY created_at DESC
    LIMIT 200
  `;

  db.query(sql, [elderId], (err, rows) => {
    if (err) {
      console.error("Error fetching elder alerts:", err);
      return res.status(500).json({ msg: "Error fetching elder alerts", err });
    }
    res.status(200).json({ msg: "Elder alerts retrieved ✅", alerts: rows });
  });
};
//9 visits 
//Upcoming visits for ALL assigned elders
exports.getMyUpcomingVisits = (req, res) => {
  const caregiverId = req.user.id;
  const limit = Math.min(Number(req.query.limit || 50), 500);
  const from = req.query.from || null; // optional YYYY-MM-DD
  const to = req.query.to || null;     // optional YYYY-MM-DD
  const status = (req.query.status || "all").toLowerCase(); // pending|approved|all

  let sql = `
    SELECT
      v.visit_id, v.scheduled_at, v.duration_minutes, v.status, v.notes,
      e.elder_id, e.name AS elder_name,
      f.family_id, f.name AS family_name, f.phone AS family_phone
    FROM visits v
    JOIN elder_assignments ea
      ON ea.elder_id = v.elder_id
     AND ea.caregiver_id = ?
    JOIN elders e ON e.elder_id = v.elder_id
    LEFT JOIN family_members f ON f.family_id = v.family_id
    WHERE v.scheduled_at >= NOW()
  `;

  const params = [caregiverId];

  if (from) {
    sql += " AND DATE(v.scheduled_at) >= ? ";
    params.push(from);
  }
  if (to) {
    sql += " AND DATE(v.scheduled_at) <= ? ";
    params.push(to);
  }
  if (status !== "all") {
    sql += " AND v.status = ? ";
    params.push(status);
  }

  sql += " ORDER BY v.scheduled_at ASC LIMIT ? ";
  params.push(limit);

  db.query(sql, params, (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching upcoming visits", err });
    res.status(200).json({ visits: rows });
  });
};
//Upcoming visits for ONE assigned elder
exports.getElderUpcomingVisits = (req, res) => {
  const elderId = Number(req.params.elder_id);
  const limit = Math.min(Number(req.query.limit || 50), 500);
  const status = (req.query.status || "all").toLowerCase();

  let sql = `
    SELECT
      v.visit_id, v.scheduled_at, v.duration_minutes, v.status, v.notes,
      f.family_id, f.name AS family_name, f.phone AS family_phone
    FROM visits v
    LEFT JOIN family_members f ON f.family_id = v.family_id
    WHERE v.elder_id = ?
      AND v.scheduled_at >= NOW()
  `;
  const params = [elderId];

  if (status !== "all") {
    sql += " AND v.status = ? ";
    params.push(status);
  }

  sql += " ORDER BY v.scheduled_at ASC LIMIT ? ";
  params.push(limit);

  db.query(sql, params, (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching elder upcoming visits", err });
    res.status(200).json({ visits: rows });
  });
};
//Family contact info for ONE assigned elder
exports.getElderFamilyContacts = (req, res) => {
  const elderId = Number(req.params.elder_id);

  const sql = `
    SELECT ef.id, ef.relation, ef.is_primary,
           f.family_id, f.name, f.email, f.phone
    FROM elder_family ef
    JOIN family_members f ON f.family_id = ef.family_id
    WHERE ef.elder_id = ?
    ORDER BY ef.is_primary DESC, ef.id DESC
  `;

  db.query(sql, [elderId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching family contacts", err });
    res.status(200).json({ family: rows });
  });
};
//request a visit 
exports.requestVisit = (req, res) => {
  const caregiverId = req.user.id;
  const elderId = Number(req.params.elder_id);

  const { scheduled_at, duration_minutes, notes, family_id } = req.body || {};

  if (!scheduled_at) {
    return res.status(400).json({ msg: "scheduled_at is required (e.g. '2025-12-25 16:00:00')" });
  }

  const dur = duration_minutes == null ? 30 : Number(duration_minutes);
  if (Number.isNaN(dur) || dur <= 0 || dur > 480) {
    return res.status(400).json({ msg: "duration_minutes must be between 1 and 480" });
  }

  // optional: ensure future date
  const when = new Date(scheduled_at);
  if (Number.isNaN(when.getTime())) {
    return res.status(400).json({ msg: "scheduled_at must be a valid datetime" });
  }
  if (when.getTime() < Date.now() - 60 * 1000) {
    return res.status(400).json({ msg: "scheduled_at must be in the future" });
  }

  const insertVisit = (finalFamilyId) => {
    const finalNotes = notes ? `[Caregiver request #${caregiverId}] ${notes}` : `[Caregiver request #${caregiverId}]`;

    db.query(
      `INSERT INTO visits (elder_id, family_id, scheduled_at, duration_minutes, status, notes)
       VALUES (?, ?, ?, ?, 'pending', ?)`,
      [elderId, finalFamilyId || null, scheduled_at, dur, finalNotes],
      (err, result) => {
        if (err) return res.status(500).json({ msg: "Error requesting visit", err });
        res.status(201).json({ msg: "Visit requested ✅ (pending approval)", visit_id: result.insertId });
      }
    );
  };

  // If family_id provided, use it directly
  if (family_id) return insertVisit(Number(family_id));

  // Else: auto-pick primary family for this elder (if exists)
  db.query(
    `SELECT family_id
     FROM elder_family
     WHERE elder_id = ?
     ORDER BY is_primary DESC, id DESC
     LIMIT 1`,
    [elderId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching elder family", err });
      const primaryFamilyId = rows.length ? rows[0].family_id : null;
      insertVisit(primaryFamilyId);
    }
  );
};
// =====================
// Family <-> Caregiver Chat
// =====================

// Helper: ensure conversation belongs to this caregiver
function ensureCaregiverInConversation(db, conversationId, caregiverId, cb) {
  db.query(
    `SELECT conversation_id FROM fc_conversations WHERE conversation_id=? AND caregiver_id=? LIMIT 1`,
    [conversationId, caregiverId],
    (err, rows) => {
      if (err) return cb(err);
      if (!rows.length) return cb(null, null);
      cb(null, rows[0]);
    }
  );
}

// 1) List my conversations
exports.listMyChats = (req, res) => {
  const caregiverId = req.user.id;

  const sql = `
    SELECT
      c.conversation_id,
      c.created_at,
      f.family_id,
      f.name AS family_name,
      f.email AS family_email,
      lm.message AS last_message,
      lm.created_at AS last_message_at,
      (
        SELECT COUNT(*)
        FROM fc_messages m
        WHERE m.conversation_id = c.conversation_id
          AND m.is_read = 0
          AND m.sender_role = 'family'
      ) AS unread_count
    FROM fc_conversations c
    JOIN family_members f ON f.family_id = c.family_id
    LEFT JOIN fc_messages lm
      ON lm.message_id = (
        SELECT m2.message_id
        FROM fc_messages m2
        WHERE m2.conversation_id = c.conversation_id
        ORDER BY m2.created_at DESC
        LIMIT 1
      )
    WHERE c.caregiver_id = ?
    ORDER BY COALESCE(lm.created_at, c.created_at) DESC;
  `;

  db.query(sql, [caregiverId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "DB error", err });
    res.json({ msg: "Chats retrieved", chats: rows });
  });
};

// 2) Get messages
exports.getChatMessages = (req, res) => {
  const caregiverId = req.user.id;
  const { conversation_id } = req.params;

  const limit = Math.min(parseInt(req.query.limit || "50", 10), 100);
  const offset = Math.max(parseInt(req.query.offset || "0", 10), 0);

  ensureCaregiverInConversation(db, conversation_id, caregiverId, (err, ok) => {
    if (err) return res.status(500).json({ msg: "DB error", err });
    if (!ok) return res.status(403).json({ msg: "Not allowed" });

    db.query(
      `SELECT message_id, sender_role, sender_id, message, is_read, created_at
       FROM fc_messages
       WHERE conversation_id=?
       ORDER BY created_at ASC
       LIMIT ? OFFSET ?`,
      [conversation_id, limit, offset],
      (err2, rows) => {
        if (err2) return res.status(500).json({ msg: "DB error", err: err2 });
        res.json({ msg: "Messages retrieved", messages: rows });
      }
    );
  });
};

// 3) Send message
exports.sendChatMessage = (req, res) => {
  const caregiverId = req.user.id;
  const { conversation_id } = req.params;
  const { message } = req.body;

  if (!message || !message.trim()) {
    return res.status(400).json({ msg: "Message is required" });
  }

  ensureCaregiverInConversation(db, conversation_id, caregiverId, (err, ok) => {
    if (err) return res.status(500).json({ msg: "DB error", err });
    if (!ok) return res.status(403).json({ msg: "Not allowed" });

    db.query(
      `INSERT INTO fc_messages (conversation_id, sender_role, sender_id, message)
       VALUES (?, 'caregiver', ?, ?)`,
      [conversation_id, caregiverId, message.trim()],
      (err2, result) => {
        if (err2) return res.status(500).json({ msg: "DB error", err: err2 });

        res.json({
          msg: "Message sent",
          message: {
            message_id: result.insertId,
            conversation_id: Number(conversation_id),
            sender_role: "caregiver",
            sender_id: caregiverId,
            message: message.trim()
          }
        });
      }
    );
  });
};

// 4) Mark family messages as read
exports.markChatRead = (req, res) => {
  const caregiverId = req.user.id;
  const { conversation_id } = req.params;

  ensureCaregiverInConversation(db, conversation_id, caregiverId, (err, ok) => {
    if (err) return res.status(500).json({ msg: "DB error", err });
    if (!ok) return res.status(403).json({ msg: "Not allowed" });

    db.query(
      `UPDATE fc_messages
       SET is_read = 1
       WHERE conversation_id = ?
         AND sender_role = 'family'
         AND is_read = 0`,
      [conversation_id],
      (err2) => {
        if (err2) return res.status(500).json({ msg: "DB error", err: err2 });
        res.json({ msg: "Chat marked as read" });
      }
    );
  });
};
