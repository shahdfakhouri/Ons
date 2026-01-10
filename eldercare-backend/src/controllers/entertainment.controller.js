const db = require("../config/db");

// 1) Feed
exports.getFeed = (req, res) => {
  db.query(
    `SELECT item_id, type, title, url, thumbnail_url, provider, duration_sec, tags
     FROM entertainment_items
     WHERE is_active = 1
     ORDER BY created_at DESC
     LIMIT 50`,
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "DB error", details: err.message });
      res.json({ items: rows });
    }
  );
};

// 2) Add favorite
exports.addFavorite = (req, res) => {
  const elder_id = req.user.elder_id;
  const item_id = Number(req.params.item_id);

  if (!item_id) return res.status(400).json({ msg: "Invalid item_id" });

  db.query(
    `INSERT INTO entertainment_favorites (elder_id, item_id)
     VALUES (?, ?)`,
    [elder_id, item_id],
    (err) => {
      // handle duplicate favorite gracefully
      if (err && err.code === "ER_DUP_ENTRY") {
        return res.status(200).json({ msg: "Already in favorites ✅" });
      }
      if (err) return res.status(500).json({ msg: "DB error", details: err.message });
      res.status(201).json({ msg: "Added to favorites ✅" });
    }
  );
};

// 3) Get favorites
exports.getFavorites = (req, res) => {
  const elder_id = req.user.elder_id;

  db.query(
    `SELECT i.item_id, i.type, i.title, i.url, i.thumbnail_url, i.provider, i.duration_sec, i.tags, f.created_at AS favorited_at
     FROM entertainment_favorites f
     JOIN entertainment_items i ON i.item_id = f.item_id
     WHERE f.elder_id = ?
     ORDER BY f.created_at DESC`,
    [elder_id],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "DB error", details: err.message });
      res.json({ favorites: rows });
    }
  );
};

// 4) Remove favorite
exports.removeFavorite = (req, res) => {
  const elder_id = req.user.elder_id;
  const item_id = Number(req.params.item_id);

  if (!item_id) return res.status(400).json({ msg: "Invalid item_id" });

  db.query(
    `DELETE FROM entertainment_favorites
     WHERE elder_id = ? AND item_id = ?`,
    [elder_id, item_id],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "DB error", details: err.message });
      if (!result.affectedRows) return res.status(404).json({ msg: "Not in favorites" });
      res.json({ msg: "Removed from favorites ✅" });
    }
  );
};

// 5) Upsert activity (watched/listened progress)
exports.upsertActivity = (req, res) => {
  const elder_id = req.user.elder_id;

  const {
    item_id,
    activity_type = "watched",
    status = "started",
    progress_percent = null,
    last_position_sec = null,
    notes = null
  } = req.body;

  const id = Number(item_id);
  if (!id) return res.status(400).json({ msg: "item_id is required" });

  // validation (soft)
  const allowedType = ["watched", "listened", "played", "read"];
  const allowedStatus = ["started", "ongoing", "completed"];

  if (!allowedType.includes(activity_type)) {
    return res.status(400).json({ msg: "Invalid activity_type" });
  }
  if (!allowedStatus.includes(status)) {
    return res.status(400).json({ msg: "Invalid status" });
  }

  db.query(
    `INSERT INTO entertainment_activity
      (elder_id, item_id, activity_type, status, progress_percent, last_position_sec, notes)
     VALUES (?, ?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       status = VALUES(status),
       progress_percent = VALUES(progress_percent),
       last_position_sec = VALUES(last_position_sec),
       notes = VALUES(notes),
       updated_at = CURRENT_TIMESTAMP`,
    [elder_id, id, activity_type, status, progress_percent, last_position_sec, notes],
    (err) => {
      if (err) return res.status(500).json({ msg: "DB error", details: err.message });
      res.json({ msg: "Activity saved ✅" });
    }
  );
};

// 6) Get activity history
exports.getMyActivity = (req, res) => {
  const elder_id = req.user.elder_id;

  db.query(
    `SELECT a.activity_id, a.activity_type, a.status, a.progress_percent, a.last_position_sec, a.notes,
            a.updated_at, a.created_at,
            i.item_id, i.type, i.title, i.url, i.thumbnail_url, i.provider, i.duration_sec
     FROM entertainment_activity a
     JOIN entertainment_items i ON i.item_id = a.item_id
     WHERE a.elder_id = ?
     ORDER BY a.updated_at DESC
     LIMIT 100`,
    [elder_id],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "DB error", details: err.message });
      res.json({ activity: rows });
    }
  );
};

// 7) Continue watching/listening (most helpful for elder UX)
exports.getContinueWatching = (req, res) => {
  const elder_id = req.user.elder_id;

  db.query(
    `SELECT a.activity_type, a.status, a.progress_percent, a.last_position_sec, a.updated_at,
            i.item_id, i.type, i.title, i.url, i.thumbnail_url, i.provider, i.duration_sec
     FROM entertainment_activity a
     JOIN entertainment_items i ON i.item_id = a.item_id
     WHERE a.elder_id = ?
       AND a.status IN ('started','ongoing')
     ORDER BY a.updated_at DESC
     LIMIT 20`,
    [elder_id],
    (err, rows) => {
      if (err) return res.status(500).json({ msg: "DB error", details: err.message });
      res.json({ continue: rows });
    }
  );
};
