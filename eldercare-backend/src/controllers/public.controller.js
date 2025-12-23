const db = require("../config/db");

exports.getCaregiverReviews = (req, res) => {
  const caregiverId = Number(req.params.id);
  if (Number.isNaN(caregiverId)) return res.status(400).json({ msg: "Invalid caregiver id" });

  db.query(
    `SELECT COUNT(*) AS total_reviews, ROUND(AVG(rating), 2) AS avg_rating
     FROM reviews
     WHERE target_role='caregiver' AND target_id = ?`,
    [caregiverId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching review summary", err });

      const summary = rows[0] || { total_reviews: 0, avg_rating: null };

      db.query(
        `SELECT rating, comment, created_at
         FROM reviews
         WHERE target_role='caregiver' AND target_id = ?
         ORDER BY created_at DESC
         LIMIT 10`,
        [caregiverId],
        (err2, latest) => {
          if (err2) return res.status(500).json({ msg: "Error fetching latest reviews", err: err2 });
          res.status(200).json({ summary, latest_reviews: latest });
        }
      );
    }
  );
};
// GET /api/retirement-homes/:id/reviews
exports.getRetirementHomeReviews = (req, res) => {
  const homeId = Number(req.params.id);
  if (Number.isNaN(homeId)) return res.status(400).json({ msg: "Invalid retirement home id" });

  db.query(
    `SELECT COUNT(*) AS total_reviews, ROUND(AVG(rating), 2) AS avg_rating
     FROM reviews
     WHERE target_role='retirement_home' AND target_id = ?`,
    [homeId],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "Error fetching review summary", err });

      const summary = rows[0] || { total_reviews: 0, avg_rating: null };

      db.query(
        `SELECT rating, comment, created_at
         FROM reviews
         WHERE target_role='retirement_home' AND target_id = ?
         ORDER BY created_at DESC
         LIMIT 10`,
        [homeId],
        (err2, latest) => {
          if (err2) return res.status(500).json({ msg: "Error fetching latest reviews", err: err2 });
          res.status(200).json({ summary, latest_reviews: latest });
        }
      );
    }
  );
};