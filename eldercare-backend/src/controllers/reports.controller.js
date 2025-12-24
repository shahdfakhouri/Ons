const db = require("../config/db");

function getWeeklyRange(startDate) {
  // startDate = YYYY-MM-DD
  const start = new Date(startDate);
  const end = new Date(start);
  end.setDate(start.getDate() + 7);
  return { start, end };
}

function getMonthlyRange(monthStr) {
  // monthStr = YYYY-MM (example: 2025-12)
  const [y, m] = monthStr.split("-").map(Number);
  const start = new Date(y, m - 1, 1);
  const end = new Date(y, m, 1);
  return { start, end };
}

function toSqlDate(d) {
  return d.toISOString().slice(0, 10);
}

async function runQuery(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.query(sql, params, (err, rows) => (err ? reject(err) : resolve(rows)));
  });
}

async function buildReport(homeId, start, end) {
  const startDate = toSqlDate(start);
  const endDate = toSqlDate(end);

  // ✅ elders in this home
  const elders = await runQuery(
    `SELECT COUNT(DISTINCT elder_id) AS total FROM elder_assignments WHERE home_id = ?`,
    [homeId]
  );

  // ✅ incidents summary (change created_at if your table uses a different column)
  const incidentsTotal = await runQuery(
    `SELECT COUNT(*) AS total
     FROM retirement_incidents
     WHERE home_id = ?
       AND DATE(created_at) >= ?
       AND DATE(created_at) < ?`,
    [homeId, startDate, endDate]
  );

  const incidentsByType = await runQuery(
    `SELECT type, COUNT(*) AS count
     FROM retirement_incidents
     WHERE home_id = ?
       AND DATE(created_at) >= ?
       AND DATE(created_at) < ?
     GROUP BY type
     ORDER BY count DESC`,
    [homeId, startDate, endDate]
  );

  // ✅ health logs averages for elders in this home (health_logs.date exists in your DB)
  const healthAverages = await runQuery(
    `
    SELECT
      AVG(CAST(SUBSTRING_INDEX(hl.blood_sugar, ' ', 1) AS DECIMAL(10,2))) AS avg_blood_sugar,
      AVG(CAST(REPLACE(hl.temperature, '°C','') AS DECIMAL(10,2))) AS avg_temp,

      AVG(CAST(SUBSTRING_INDEX(hl.blood_pressure, '/', 1) AS DECIMAL(10,2))) AS avg_systolic,
      AVG(CAST(SUBSTRING_INDEX(hl.blood_pressure, '/', -1) AS DECIMAL(10,2))) AS avg_diastolic,

      COUNT(*) AS total_logs
    FROM health_logs hl
    JOIN elder_assignments ea ON ea.elder_id = hl.elder_id
    WHERE ea.home_id = ?
      AND hl.date >= ?
      AND hl.date < ?;
    `,
    [homeId, startDate, endDate]
  );

  // ✅ payments summary (adjust created_at if needed)
  const payments = await runQuery(
    `
    SELECT
      COUNT(*) AS total_payments,
      SUM(CASE WHEN status='completed' THEN amount ELSE 0 END) AS completed_amount,
      SUM(CASE WHEN status='pending' THEN 1 ELSE 0 END) AS pending_count
    FROM payments
    WHERE target_type='retirement_home'
      AND target_id = ?
      AND DATE(created_at) >= ?
      AND DATE(created_at) < ?;
    `,
    [homeId, startDate, endDate]
  );

  return {
    period: { start: startDate, end: endDate },
    home_id: homeId,
    elders: { total: elders[0]?.total || 0 },
    incidents: {
      total: incidentsTotal[0]?.total || 0,
      by_type: incidentsByType,
    },
    health: healthAverages[0] || {},
    payments: payments[0] || {},
  };
}

// ✅ GET weekly report
exports.getWeeklyReport = async (req, res) => {
  try {
    const homeId = req.user.id;
    const start = req.query.start; // YYYY-MM-DD (required)
    if (!start) return res.status(400).json({ msg: "Missing ?start=YYYY-MM-DD" });

    const { start: s, end } = getWeeklyRange(start);
    const report = await buildReport(homeId, s, end);

    res.status(200).json({ msg: "Weekly report generated ✅", report });
  } catch (err) {
    console.error(err);
    res.status(500).json({ msg: "Error generating weekly report", err: err.message });
  }
};

// ✅ GET monthly report
exports.getMonthlyReport = async (req, res) => {
  try {
    const homeId = req.user.id;
    const month = req.query.month; // YYYY-MM (required)
    if (!month) return res.status(400).json({ msg: "Missing ?month=YYYY-MM" });

    const { start, end } = getMonthlyRange(month);
    const report = await buildReport(homeId, start, end);

    res.status(200).json({ msg: "Monthly report generated ✅", report });
  } catch (err) {
    console.error(err);
    res.status(500).json({ msg: "Error generating monthly report", err: err.message });
  }
};

// ✅ Save a report (optional)
exports.saveReport = async (req, res) => {
  try {
    const homeId = req.user.id;
    const { period_type, period_start, period_end, payload } = req.body;

    if (!period_type || !period_start || !period_end || !payload) {
      return res.status(400).json({ msg: "Missing period_type/period_start/period_end/payload" });
    }

    const sql = `
      INSERT INTO retirement_reports (home_id, period_type, period_start, period_end, payload)
      VALUES (?, ?, ?, ?, ?)
    `;
    db.query(sql, [homeId, period_type, period_start, period_end, JSON.stringify(payload)], (err, result) => {
      if (err) return res.status(500).json({ msg: "Error saving report", err });
      res.status(201).json({ msg: "Report saved ✅", report_id: result.insertId });
    });
  } catch (err) {
    res.status(500).json({ msg: "Server error", err: err.message });
  }
};

// ✅ List saved reports (optional)
exports.getSavedReports = (req, res) => {
  const homeId = req.user.id;

  const sql = `
    SELECT report_id, period_type, period_start, period_end, created_at
    FROM retirement_reports
    WHERE home_id = ?
    ORDER BY created_at DESC
  `;
  db.query(sql, [homeId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching saved reports", err });
    res.status(200).json({ msg: "Saved reports retrieved ✅", reports: rows });
  });
};
