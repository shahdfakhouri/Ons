const db = require("../config/db");
const { notify } = require("../services/notification.service");

/**
 * Helper: verify elder belongs to this retirement home
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
 * 🏠 Retirement Home: Create medication plan
 * POST /api/retirement/elders/:elder_id/medications
 */
exports.createMedication = async (req, res) => {
  const homeId = req.user.id;
  const elderId = req.params.elder_id;

  const {
    name,
    dosage,
    frequency,
    instructions,
    start_date,
    end_date
  } = req.body;

  if (!name) return res.status(400).json({ msg: "name is required" });

  try {
    const allowed = await ensureElderInHome(homeId, elderId);
    if (!allowed) return res.status(403).json({ msg: "Access denied: elder not in this home" });

    const sql = `
      INSERT INTO medications
      (elder_id, home_id, created_by_role, created_by_id, name, dosage, frequency, instructions, start_date, end_date, active)
      VALUES (?, ?, 'retirement_home', ?, ?, ?, ?, ?, ?, ?, 1)
    `;

    db.query(
      sql,
      [elderId, homeId, homeId, name, dosage || null, frequency || null, instructions || null, start_date || null, end_date || null],
      (err, result) => {
        if (err) return res.status(500).json({ msg: "Error creating medication", err });
        res.status(201).json({ msg: "Medication plan created ✅", medication_id: result.insertId });
      }
    );
  } catch (error) {
    res.status(500).json({ msg: "Server error", error: error.message });
  }
};

/**
 * 🏠 Retirement Home: List medications for elder
 * GET /api/retirement/elders/:elder_id/medications
 */
exports.getElderMedications = async (req, res) => {
  const homeId = req.user.id;
  const elderId = req.params.elder_id;

  try {
    const allowed = await ensureElderInHome(homeId, elderId);
    if (!allowed) return res.status(403).json({ msg: "Access denied: elder not in this home" });

    const sql = `
      SELECT medication_id, name, dosage, frequency, instructions, start_date, end_date, active, created_at
      FROM medications
      WHERE elder_id = ? AND home_id = ?
      ORDER BY active DESC, created_at DESC
    `;

    db.query(sql, [elderId, homeId], (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching medications", err });
      res.status(200).json({ msg: "Medications retrieved ✅", medications: rows });
    });
  } catch (error) {
    res.status(500).json({ msg: "Server error", error: error.message });
  }
};

/**
 * 🧑‍⚕️ Caregiver: Log medication status (taken/missed/skipped)
 * POST /api/caregiver/elders/:elder_id/medication-log
 */
exports.logMedication = (req, res) => {
  const caregiverId = req.user.id;
  const elderId = req.params.elder_id;

  const { medication_id, scheduled_time, status, notes } = req.body;

  if (!medication_id || !status) {
    return res.status(400).json({ msg: "medication_id and status are required" });
  }

  if (!["taken", "missed", "skipped"].includes(status)) {
    return res.status(400).json({ msg: "Invalid status. Use taken/missed/skipped" });
  }

  const takenAt = status === "taken" ? new Date() : null;

  // Find home_id of this elder (if assigned)
  const homeSql = `SELECT home_id FROM elder_assignments WHERE elder_id = ? LIMIT 1`;
  db.query(homeSql, [elderId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error resolving home_id", err });

    const homeId = rows.length ? rows[0].home_id : null;

    const sql = `
      INSERT INTO medication_logs
      (medication_id, elder_id, caregiver_id, home_id, scheduled_time, status, taken_at, notes)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;

    db.query(
      sql,
      [
        medication_id,
        elderId,
        caregiverId,
        homeId,
        scheduled_time || null,
        status,
        takenAt,
        notes || null,
      ],
      async (err2, result) => {
        if (err2) return res.status(500).json({ msg: "Error saving medication log", err: err2 });

        // 🔔 alert if missed
        if (status === "missed") {
          // get med name
          db.query(
            "SELECT name, dosage FROM medications WHERE medication_id = ? LIMIT 1",
            [medication_id],
            async (err3, medRows) => {
              const med = medRows?.[0];
              const medLabel = med ? `${med.name}${med.dosage ? " (" + med.dosage + ")" : ""}` : `medication_id ${medication_id}`;
              const when = scheduled_time ? ` at ${scheduled_time}` : "";
              const msg = `💊 Medication MISSED: ${medLabel} for elder ${elderId}${when}.`;

              await notify({
                type: "health_alert",
                message: msg,
                userId: elderId,
                severity: "warning",
                email: process.env.TEST_EMAIL,
                phone: process.env.TEST_PHONE,
              });
            }
          );
        }

        res.status(201).json({ msg: "Medication log saved ✅", log_id: result.insertId });
      }
    );
  });
};

/**
 * 🏠 Retirement Home: Get medication logs for elder (optional date)
 * GET /api/retirement/elders/:elder_id/medication-logs?date=YYYY-MM-DD
 */
exports.getMedicationLogs = async (req, res) => {
  const homeId = req.user.id;
  const elderId = req.params.elder_id;
  const date = req.query.date; // optional

  try {
    const allowed = await ensureElderInHome(homeId, elderId);
    if (!allowed) return res.status(403).json({ msg: "Access denied: elder not in this home" });

    let sql = `
      SELECT ml.log_id, ml.medication_id, m.name, m.dosage,
             ml.status, ml.scheduled_time, ml.taken_at, ml.notes, ml.created_at,
             ml.caregiver_id
      FROM medication_logs ml
      JOIN medications m ON m.medication_id = ml.medication_id
      WHERE ml.elder_id = ? AND (ml.home_id = ? OR ml.home_id IS NULL)
    `;
    const params = [elderId, homeId];

    if (date) {
      sql += " AND DATE(ml.created_at) = ? ";
      params.push(date);
    }

    sql += " ORDER BY ml.created_at DESC";

    db.query(sql, params, (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching medication logs", err });
      res.status(200).json({ msg: "Medication logs retrieved ✅", logs: rows });
    });
  } catch (error) {
    res.status(500).json({ msg: "Server error", error: error.message });
  }
};
