const db = require("../config/db");

// caregiver can only access elders assigned to them
module.exports = function ensureAssignedToElder(req, res, next) {
  const caregiverId = req.user.id;
  const elderId = req.params.elder_id;

  if (!elderId) return res.status(400).json({ msg: "elder_id is required" });

  const sql = `
    SELECT assignment_id, home_id
    FROM elder_assignments
    WHERE elder_id = ? AND caregiver_id = ?
    LIMIT 1
  `;

  db.query(sql, [elderId, caregiverId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "DB error validating assignment", err });
    if (!rows.length) return res.status(403).json({ msg: "Access denied: elder not assigned to this caregiver" });

    // home_id may be NULL (freelance), that's OK
    req.assignment = rows[0]; // { assignment_id, home_id }
    next();
  });
};
