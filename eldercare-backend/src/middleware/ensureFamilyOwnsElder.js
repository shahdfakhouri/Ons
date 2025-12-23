const db = require("../config/db");

/**
 * Ensures the logged-in FAMILY owns (is linked to) the elder via elder_family.
 * Expects: req.user.role === "family" and req.user.id = family_id
 * Uses: elder_id from req.params.elder_id OR req.body.elder_id
 */
module.exports = (req, res, next) => {
  const familyId = req.user?.id;
  const elderId = req.params.elder_id || req.body.elder_id;

  if (!familyId) return res.status(401).json({ msg: "Unauthorized" });
  if (!elderId) return res.status(400).json({ msg: "elder_id is required" });

  const sql = `SELECT 1 FROM elder_family WHERE family_id = ? AND elder_id = ? LIMIT 1`;
  db.query(sql, [familyId, elderId], (err, rows) => {
    if (err) return res.status(500).json({ msg: "DB error", err });
    if (!rows.length) return res.status(403).json({ msg: "Access denied: elder not linked to this family" });

    // handy for controllers
    req.elder_id = Number(elderId);
    next();
  });
};
