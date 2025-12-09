const db = require("../config/db");

// 📝 Create a new community post (elder only)
exports.createPost = (req, res) => {
  const userId = req.user.id;          // elder_id from JWT
  const role = req.user.role;

  if (role.toLowerCase() !== "elder") {
    return res
      .status(403)
      .json({ msg: "Only elders can create community posts." });
  }

  const { title, content, category } = req.body;

  if (!title || !content) {
    return res.status(400).json({ msg: "Title and content are required." });
  }

  const sql = `
    INSERT INTO community_posts (user_id, title, content, category, is_approved)
    VALUES (?, ?, ?, ?, 0)   -- pending until admin approves
  `;

  db.query(sql, [userId, title, content, category || null], (err, result) => {
    if (err) {
      console.error("Error creating post:", err);
      return res.status(500).json({ msg: "Error creating post", err });
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
  const role = req.user.role;
  const { post_id } = req.params;

  // 1) Get the post
  let postSql = `
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
  WHERE p.post_id = ?
`;


  const params = [post_id];

  // Non-admins must not see unapproved posts
  if (role.toLowerCase() !== "admin") {
    postSql += " AND p.is_approved = 1";
  }

  db.query(postSql, params, (err, postRows) => {
    if (err) {
      console.error("Error fetching post:", err);
      return res.status(500).json({ msg: "Error fetching post", err });
    }
    if (!postRows.length) {
      return res.status(404).json({ msg: "Post not found" });
    }

    const post = postRows[0];

    // 2) Get comments
    const commentsSql = `
      SELECT 
        c.comment_id,
        c.comment,
        c.created_at,
        e.name AS author_name
      FROM community_comments c
      JOIN elders e ON c.user_id = e.elder_id
      WHERE c.post_id = ?
      ORDER BY c.created_at ASC
    `;

    db.query(commentsSql, [post_id], (err2, comments) => {
      if (err2) {
        console.error("Error fetching comments:", err2);
        return res.status(500).json({ msg: "Error fetching comments", err2 });
      }

      res.status(200).json({
        msg: "Post with comments retrieved",
        post,
        comments,
      });
    });
  });
};

// 💬 Add a comment to a post (elder only)
exports.addComment = (req, res) => {
  const userId = req.user.id; // elder_id
  const role = req.user.role;
  const { post_id } = req.params;
  const { comment } = req.body;

  if (role.toLowerCase() !== "elder") {
    return res
      .status(403)
      .json({ msg: "Only elders can comment in the community." });
  }

  if (!comment) {
    return res.status(400).json({ msg: "Comment text is required" });
  }

  const checkSql = "SELECT is_approved FROM community_posts WHERE post_id = ?";
  db.query(checkSql, [post_id], (err, rows) => {
    if (err) {
      console.error("Error checking post:", err);
      return res.status(500).json({ msg: "Error checking post", err });
    }
    if (!rows.length) {
      return res.status(404).json({ msg: "Post not found" });
    }
    if (!rows[0].is_approved) {
      return res.status(403).json({ msg: "Cannot comment on a post that is not approved yet" });
    }

    const sql = `
      INSERT INTO community_comments (post_id, user_id, comment)
      VALUES (?, ?, ?)
    `;
    db.query(sql, [post_id, userId, comment], (err2, result) => {
      if (err2) {
        console.error("Error adding comment:", err2);
        return res.status(500).json({ msg: "Error adding comment", err2 });
      }

      res.status(201).json({
        msg: "Comment added successfully ✅",
        comment_id: result.insertId,
      });
    });
  });
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
exports.deletePost = (req, res) => {
  const { post_id } = req.params;

  // delete comments first (FK)
  const deleteCommentsSql = "DELETE FROM community_comments WHERE post_id = ?";
  db.query(deleteCommentsSql, [post_id], (err) => {
    if (err) {
      console.error("Error deleting comments:", err);
      return res.status(500).json({ msg: "Error deleting comments", err });
    }

    const deletePostSql = "DELETE FROM community_posts WHERE post_id = ?";
    db.query(deletePostSql, [post_id], (err2, result) => {
      if (err2) {
        console.error("Error deleting post:", err2);
        return res.status(500).json({ msg: "Error deleting post", err2 });
      }
      if (result.affectedRows === 0) {
        return res.status(404).json({ msg: "Post not found" });
      }

      res.status(200).json({ msg: "Post and its comments deleted 🗑️" });
    });
  });
};

// 🗑️ Delete a single comment
exports.deleteComment = (req, res) => {
  const { comment_id } = req.params;

  const sql = "DELETE FROM community_comments WHERE comment_id = ?";
  db.query(sql, [comment_id], (err, result) => {
    if (err) {
      console.error("Error deleting comment:", err);
      return res.status(500).json({ msg: "Error deleting comment", err });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ msg: "Comment not found" });
    }

    res.status(200).json({ msg: "Comment deleted successfully ❎" });
  });
};
