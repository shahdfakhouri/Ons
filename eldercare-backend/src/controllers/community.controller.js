const db = require("../config/db");

// 📝 Create a new community post (elder only)
exports.createPost = (req, res) => {
  const elder_id = req.user.elder_id;      // ✅ correct
  const role = (req.user.role || "").toLowerCase();

  if (role !== "elder") {
    return res.status(403).json({ msg: "Only elders can create community posts." });
  }

  const { title, content, category } = req.body;
  if (!title || !content) {
    return res.status(400).json({ msg: "Title and content are required." });
  }

  const sql = `
    INSERT INTO community_posts (user_id, title, content, category, is_approved)
    VALUES (?, ?, ?, ?, 0)
  `;

  db.query(sql, [elder_id, title, content, category || null], (err, result) => {
    if (err) {
      console.error("Error creating post:", err);
      return res.status(500).json({ msg: "Error creating post", details: err.message });
    }

    res.status(201).json({
      msg: "Post created and pending admin approval ✅",
      post_id: result.insertId,
    });
  });
};


// 📜 Get all posts (elders/family see only approved, admin can see all)
exports.getAllPosts = (req, res) => {
  const role = req.user.role;
  const { category, includePending } = req.query;

  let sql = `
    SELECT 
      p.post_id,
      p.title,
      p.content,
      p.category,
      p.created_at,
      p.is_approved,
      e.name AS author_name
    FROM community_posts p
    JOIN elders e ON p.user_id = e.elder_id
 `;

  const conditions = [];
  const params = [];

  // Non-admins see only approved posts
  if (role.toLowerCase() !== "admin" || includePending !== "true") {
    conditions.push("p.is_approved = 1");
  }

  if (category) {
    conditions.push("p.category = ?");
    params.push(category);
  }

  if (conditions.length) {
    sql += " WHERE " + conditions.join(" AND ");
  }

  sql += " ORDER BY p.created_at DESC";

  db.query(sql, params, (err, results) => {
    if (err) {
      console.error("Error fetching posts:", err);
      return res.status(500).json({ msg: "Error fetching posts", err });
    }

    res.status(200).json({
      msg: "Community posts retrieved",
      posts: results,
    });
  });
};

// 🔍 Get one post with its comments
exports.getPostById = (req, res) => {
  const post_id = Number(req.params.post_id);
  const elder_id = req.user.elder_id;

  db.query(
    `SELECT post_id, user_id, title, content, category, created_at, is_approved
     FROM community_posts
     WHERE post_id = ?
       AND (is_approved = 1 OR user_id = ?)`,
    [post_id, elder_id],
    (err, postRows) => {
      if (err) return res.status(500).json({ msg: "DB error", details: err.message });
      if (!postRows.length) return res.status(404).json({ msg: "Post not found" });

      db.query(
        `SELECT comment_id, user_id, comment, created_at
         FROM community_comments
         WHERE post_id = ?
         ORDER BY created_at ASC`,
        [post_id],
        (err2, commentRows) => {
          if (err2) return res.status(500).json({ msg: "DB error", details: err2.message });
          res.json({ post: postRows[0], comments: commentRows });
        }
      );
    }
  );
};

// 💬 Add a comment to a post (elder only)
exports.addComment = (req, res) => {
  const post_id = Number(req.params.post_id);
  const elder_id = req.user.elder_id;

  const text = (req.body.content || req.body.comment || req.body.comment_text || "").trim();
  if (!text) return res.status(400).json({ msg: "Comment text is required" });

  db.query(
    `INSERT INTO community_comments (post_id, user_id, comment)
     VALUES (?, ?, ?)`,
    [post_id, elder_id, text],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "DB error", details: err.message });
      res.status(201).json({ msg: "Comment added", comment_id: result.insertId });
    }
  );
};

//
// 🔐 ADMIN MODERATION
//

exports.getPendingPosts = (req, res) => {
  const sql = `
    SELECT 
      p.post_id,
      p.title,
      p.content,
      p.category,
      p.created_at,
      e.name AS author_name
    FROM community_posts p
    JOIN elders e ON p.user_id = e.elder_id
    WHERE p.is_approved = 0
    ORDER BY p.created_at DESC
  `;

  db.query(sql, (err, results) => {
    if (err) {
      console.error("Error fetching pending posts:", err);
      return res.status(500).json({ msg: "Error fetching pending posts", err });
    }

    res.status(200).json({
      msg: "Pending posts retrieved",
      posts: results,
    });
  });
};


// ✅ Approve a post
exports.approvePost = (req, res) => {
  const { post_id } = req.params;

  const sql = "UPDATE community_posts SET is_approved = 1 WHERE post_id = ?";
  db.query(sql, [post_id], (err, result) => {
    if (err) {
      console.error("Error approving post:", err);
      return res.status(500).json({ msg: "Error approving post", err });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ msg: "Post not found" });
    }

    res.status(200).json({ msg: "Post approved successfully ✅" });
  });
};

// 🚫 Hide a post (soft moderation)
exports.hidePost = (req, res) => {
  const { post_id } = req.params;

  const sql = "UPDATE community_posts SET is_approved = 0 WHERE post_id = ?";
  db.query(sql, [post_id], (err, result) => {
    if (err) {
      console.error("Error hiding post:", err);
      return res.status(500).json({ msg: "Error hiding post", err });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ msg: "Post not found" });
    }

    res.status(200).json({ msg: "Post hidden from community ❌" });
  });
};

// 🗑️ Delete post + its comments
exports.deleteMyPost = (req, res) => {
  const elder_id = req.user.elder_id;
  const role = (req.user.role || "").toLowerCase();
  const post_id = Number(req.params.post_id);

  if (role !== "elder") return res.status(403).json({ msg: "Only elders can delete their posts." });
  if (!post_id) return res.status(400).json({ msg: "Invalid post_id" });

  // delete comments first
  db.query("DELETE FROM community_comments WHERE post_id = ?", [post_id], (err) => {
    if (err) return res.status(500).json({ msg: "Error deleting comments", details: err.message });

    db.query(
      "DELETE FROM community_posts WHERE post_id = ? AND user_id = ?",
      [post_id, elder_id],
      (err2, result) => {
        if (err2) return res.status(500).json({ msg: "Error deleting post", details: err2.message });
        if (!result.affectedRows) return res.status(404).json({ msg: "Post not found or not yours" });
        res.status(200).json({ msg: "Post deleted ✅" });
      }
    );
  });
};

// 🗑️ Delete a single comment
exports.deleteMyComment = (req, res) => {
  const elder_id = req.user.elder_id;
  const role = (req.user.role || "").toLowerCase();
  const comment_id = Number(req.params.comment_id);

  if (role !== "elder") return res.status(403).json({ msg: "Only elders can delete their comments." });
  if (!comment_id) return res.status(400).json({ msg: "Invalid comment_id" });

  db.query(
    "DELETE FROM community_comments WHERE comment_id = ? AND user_id = ?",
    [comment_id, elder_id],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "Error deleting comment", details: err.message });
      if (!result.affectedRows) return res.status(404).json({ msg: "Comment not found or not yours" });
      res.status(200).json({ msg: "Comment deleted ✅" });
    }
  );
};

exports.reportPost = (req, res) => {
  const elder_id = req.user.elder_id;
  const role = (req.user.role || "").toLowerCase();
  const post_id = Number(req.params.post_id);
  const { reason } = req.body || {};

  if (role !== "elder") return res.status(403).json({ msg: "Only elders can report." });
  if (!post_id) return res.status(400).json({ msg: "Invalid post_id" });

  db.query(
    `INSERT INTO community_reports (reporter_elder_id, post_id, reason)
     VALUES (?, ?, ?)`,
    [elder_id, post_id, reason || null],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "Failed to report post", details: err.message });
      res.status(201).json({ msg: "Reported ✅", report_id: result.insertId });
    }
  );
};

exports.reportComment = (req, res) => {
  const elder_id = req.user.elder_id;
  const role = (req.user.role || "").toLowerCase();
  const comment_id = Number(req.params.comment_id);
  const { reason } = req.body || {};

  if (role !== "elder") return res.status(403).json({ msg: "Only elders can report." });
  if (!comment_id) return res.status(400).json({ msg: "Invalid comment_id" });

  db.query(
    `INSERT INTO community_reports (reporter_elder_id, comment_id, reason)
     VALUES (?, ?, ?)`,
    [elder_id, comment_id, reason || null],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "Failed to report comment", details: err.message });
      res.status(201).json({ msg: "Reported ✅", report_id: result.insertId });
    }
  );
};

exports.deleteMyPost = (req, res) => {
  const elder_id = req.user.elder_id;
  const role = (req.user.role || "").toLowerCase();
  const post_id = Number(req.params.post_id);

  if (role !== "elder") return res.status(403).json({ msg: "Only elders can delete their posts." });
  if (!post_id) return res.status(400).json({ msg: "Invalid post_id" });

  // delete comments first then post, but ONLY if owned by elder
  db.query("DELETE FROM community_comments WHERE post_id = ?", [post_id], (err) => {
    if (err) return res.status(500).json({ msg: "Error deleting comments", err });

    db.query(
      "DELETE FROM community_posts WHERE post_id = ? AND user_id = ?",
      [post_id, elder_id],
      (err2, result) => {
        if (err2) return res.status(500).json({ msg: "Error deleting post", err2 });
        if (!result.affectedRows) return res.status(404).json({ msg: "Post not found or not yours" });
        res.status(200).json({ msg: "Post deleted ✅" });
      }
    );
  });
};

exports.deleteMyComment = (req, res) => {
  const elder_id = req.user.elder_id;
  const role = (req.user.role || "").toLowerCase();
  const comment_id = Number(req.params.comment_id);

  if (role !== "elder") return res.status(403).json({ msg: "Only elders can delete their comments." });
  if (!comment_id) return res.status(400).json({ msg: "Invalid comment_id" });

  db.query(
    "DELETE FROM community_comments WHERE comment_id = ? AND user_id = ?",
    [comment_id, elder_id],
    (err, result) => {
      if (err) return res.status(500).json({ msg: "Error deleting comment", err });
      if (!result.affectedRows) return res.status(404).json({ msg: "Comment not found or not yours" });
      res.status(200).json({ msg: "Comment deleted ✅" });
    }
  );
};
