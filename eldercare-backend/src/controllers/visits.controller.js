const db = require("../config/db");

// helper: verify elder belongs to this home (use elder_assignments if you use it)
function ensureElderInHome(homeId, elderId) {
  return new Promise((resolve, reject) => {
    const sql = `SELECT 1 FROM elder_assignments WHERE home_id = ? AND elder_id = ? LIMIT 1`;
    db.query(sql, [homeId, elderId], (err, rows) => {
      if (err) return reject(err);
      resolve(rows.length > 0);
    });
  });
}

// 1) GET /api/retirement/elders/:elder_id/family
exports.getElderFamily = async (req, res) => {
  const homeId = req.user.id;
  const elderId = req.params.elder_id;

  try {
    const allowed = await ensureElderInHome(homeId, elderId);
    if (!allowed) return res.status(403).json({ msg: "Access denied: elder not in this home" });

    const sql = `
      SELECT ef.id, ef.relation, ef.is_primary,
             f.family_id, f.name, f.email, f.phone
      FROM elder_family ef
      JOIN family_members f ON f.family_id = ef.family_id
      WHERE ef.elder_id = ?
      ORDER BY ef.is_primary DESC, ef.id DESC;
    `;
    db.query(sql, [elderId], (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching elder family", err });
      res.status(200).json({ msg: "Family list retrieved ✅", family: rows });
    });
  } catch (e) {
    res.status(500).json({ msg: "Server error", error: e.message });
  }
};

// 2) POST /api/retirement/elders/:elder_id/visits
exports.createVisit = async (req, res) => {
  const homeId = req.user.id;
  const elderId = req.params.elder_id;

  const { family_id, scheduled_at, duration_minutes, notes } = req.body || {};
  if (!scheduled_at) return res.status(400).json({ msg: "scheduled_at is required (YYYY-MM-DD HH:MM:SS)" });

  try {
    const allowed = await ensureElderInHome(homeId, elderId);
    if (!allowed) return res.status(403).json({ msg: "Access denied: elder not in this home" });

    const sql = `
      INSERT INTO visits (home_id, elder_id, family_id, scheduled_at, duration_minutes, status, notes, created_by_role, created_by_id)
      VALUES (?, ?, ?, ?, ?, 'pending', ?, 'retirement_home', ?)
    `;
    db.query(
      sql,
      [homeId, elderId, family_id || null, scheduled_at, duration_minutes || 60, notes || null, homeId],
      (err, result) => {
        if (err) return res.status(500).json({ msg: "Error creating visit", err });
        res.status(201).json({ msg: "Visit scheduled ✅", visit_id: result.insertId });
      }
    );
  } catch (e) {
    res.status(500).json({ msg: "Server error", error: e.message });
  }
};

// 3) GET /api/retirement/elders/:elder_id/visits
exports.getElderVisits = async (req, res) => {
  const homeId = req.user.id;
  const elderId = req.params.elder_id;

  try {
    const allowed = await ensureElderInHome(homeId, elderId);
    if (!allowed) return res.status(403).json({ msg: "Access denied: elder not in this home" });

    const sql = `
      SELECT v.visit_id, v.scheduled_at, v.duration_minutes, v.status, v.notes,
             f.family_id, f.name AS family_name, f.phone AS family_phone
      FROM visits v
      LEFT JOIN family_members f ON f.family_id = v.family_id
      WHERE v.home_id = ? AND v.elder_id = ?
      ORDER BY v.scheduled_at DESC;
    `;
    db.query(sql, [homeId, elderId], (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching visits", err });
      res.status(200).json({ msg: "Visits retrieved ✅", visits: rows });
    });
  } catch (e) {
    res.status(500).json({ msg: "Server error", error: e.message });
  }
};

// 4) GET /api/retirement/visits?from=YYYY-MM-DD&to=YYYY-MM-DD&status=pending|approved|all
exports.getHomeVisits = (req, res) => {
  const homeId = req.user.id;
  const from = req.query.from || "2000-01-01";
  const to = req.query.to || "2100-01-01";
  const status = (req.query.status || "all").toLowerCase();

  let sql = `
    SELECT v.visit_id, v.scheduled_at, v.duration_minutes, v.status, v.notes,
           e.elder_id, e.name AS elder_name,
           f.family_id, f.name AS family_name
    FROM visits v
    JOIN elders e ON e.elder_id = v.elder_id
    LEFT JOIN family_members f ON f.family_id = v.family_id
    WHERE v.home_id = ? AND DATE(v.scheduled_at) BETWEEN ? AND ?
  `;
  const params = [homeId, from, to];

  if (status !== "all") {
    sql += " AND v.status = ? ";
    params.push(status);
  }

  sql += " ORDER BY v.scheduled_at ASC;";

  db.query(sql, params, (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching home visits", err });
    res.status(200).json({ msg: "Home visits calendar ✅", visits: rows });
  });
};

// 5) PUT /api/retirement/visits/:visit_id/status
exports.updateVisitStatus = (req, res) => {
  const homeId = req.user.id;
  const visitId = req.params.visit_id;
  const { status } = req.body || {};

  const allowed = ["pending", "approved", "cancelled", "completed"];
  if (!allowed.includes(status)) return res.status(400).json({ msg: `Invalid status. Use: ${allowed.join(", ")}` });

  const sql = `UPDATE visits SET status = ? WHERE visit_id = ? AND home_id = ?`;
  db.query(sql, [status, visitId, homeId], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error updating status", err });
    if (result.affectedRows === 0) return res.status(404).json({ msg: "Visit not found in this home" });
    res.status(200).json({ msg: "Visit status updated ✅" });
  });
};
