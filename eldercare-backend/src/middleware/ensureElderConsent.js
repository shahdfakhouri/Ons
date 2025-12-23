const db = require("../config/db");

module.exports = (req, res, next) => {
  const elderId = req.elder_id || req.params.elder_id;

  db.query(
    "SELECT visibility_consent FROM elders WHERE elder_id = ? LIMIT 1",
    [elderId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "DB error", err });
      if (!rows.length) return res.status(404).json({ msg: "Elder not found" });

      if (rows[0].visibility_consent !== 1) {
        return res.status(403).json({
          msg: "Elder visibility consent is OFF. Monitoring is not allowed.",
        });
      }

      next();
    }
  );
};
