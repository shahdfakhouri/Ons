const db = require("../config/db");

/**
 * Helper: ensure elder belongs to this home (via elder_assignments)
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

// ✅ Create a note (internal)
exports.createNote = async (req, res) => {
  const homeId = req.user.id;
  const { elder_id, caregiver_id, title, note } = req.body;

  if (!note) return res.status(400).json({ msg: "note is required" });

  try {
    // if elder_id provided, make sure elder is in this home
    if (elder_id) {
      const allowed = await ensureElderInHome(homeId, elder_id);
      if (!allowed) return res.status(403).json({ msg: "Elder not in this retirement home" });
    }

    const sql = `
      INSERT INTO staff_notes (home_id, elder_id, caregiver_id, title, note, created_by_role, created_by_id)
      VALUES (?, ?, ?, ?, ?, 'retirement_home', ?)
    `;

    db.query(
      sql,
      [homeId, elder_id || null, caregiver_id || null, title || null, note, homeId],
      (err, result) => {
        if (err) return res.status(500).json({ msg: "Error creating note", err });
        res.status(201).json({ msg: "Note created ✅", note_id: result.insertId });
      }
    );
  } catch (e) {
    res.status(500).json({ msg: "Server error", error: e.message });
  }
};

// ✅ List notes (all notes for this home)
exports.getHomeNotes = (req, res) => {
  const homeId = req.user.id;

  const sql = `
    SELECT
      n.note_id, n.title, n.note, n.elder_id, e.name AS elder_name,
      n.caregiver_id, c.name AS caregiver_name,
      n.created_at, n.updated_at
    FROM staff_notes n
    LEFT JOIN elders e ON e.elder_id = n.elder_id
    LEFT JOIN caregivers c ON c.caregiver_id = n.caregiver_id
    WHERE n.home_id = ?
    ORDER BY n.created_at DESC
  `;

  db.query(sql, [homeId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "Error fetching notes", err });
    res.status(200).json({ msg: "Home notes retrieved ✅", notes: rows });
  });
};

// ✅ Notes for one elder in this home
exports.getElderNotes = async (req, res) => {
  const homeId = req.user.id;
  const elderId = req.params.elder_id;

  try {
    const allowed = await ensureElderInHome(homeId, elderId);
    if (!allowed) return res.status(403).json({ msg: "Elder not in this retirement home" });

    const sql = `
      SELECT note_id, title, note, caregiver_id, created_at, updated_at
      FROM staff_notes
      WHERE home_id = ? AND elder_id = ?
      ORDER BY created_at DESC
    `;

    db.query(sql, [homeId, elderId], (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching elder notes", err });
      res.status(200).json({ msg: "Elder notes retrieved ✅", elder_id: elderId, notes: rows });
    });
  } catch (e) {
    res.status(500).json({ msg: "Server error", error: e.message });
  }
};

// ✅ Update note (only within same home)
exports.updateNote = (req, res) => {
  const homeId = req.user.id;
  const noteId = req.params.note_id;
  const { title, note } = req.body;

  if (!title && !note) return res.status(400).json({ msg: "Provide title or note to update" });

  const sql = `
    UPDATE staff_notes
    SET title = COALESCE(?, title),
        note  = COALESCE(?, note)
    WHERE note_id = ? AND home_id = ?
  `;

  db.query(sql, [title || null, note || null, noteId, homeId], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error updating note", err });
    if (result.affectedRows === 0) return res.status(404).json({ msg: "Note not found" });
    res.status(200).json({ msg: "Note updated ✅" });
  });
};

// ✅ Delete note (only within same home)
exports.deleteNote = (req, res) => {
  const homeId = req.user.id;
  const noteId = req.params.note_id;

  const sql = `DELETE FROM staff_notes WHERE note_id = ? AND home_id = ?`;
  db.query(sql, [noteId, homeId], (err, result) => {
    if (err) return res.status(500).json({ msg: "Error deleting note", err });
    if (result.affectedRows === 0) return res.status(404).json({ msg: "Note not found" });
    res.status(200).json({ msg: "Note deleted ✅" });
  });
};
