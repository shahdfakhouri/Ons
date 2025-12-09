const express = require("express");
const router = express.Router();
const communityController = require("../controllers/community.controller");
const verifyToken = require("../middleware/authmiddleware");
const isAdmin = require("../middleware/adminMiddleware");

// 👥 PUBLIC (logged-in family/elders via family)

router.post("/posts", verifyToken, communityController.createPost);
router.get("/posts", verifyToken, communityController.getAllPosts);
router.get("/posts/:post_id", verifyToken, communityController.getPostById);
router.post("/posts/:post_id/comments", verifyToken, communityController.addComment);

// 🔐 ADMIN MODERATION

router.get(
  "/admin/posts/pending",
  verifyToken,
  isAdmin,
  communityController.getPendingPosts
);

router.put(
  "/admin/posts/:post_id/approve",
  verifyToken,
  isAdmin,
  communityController.approvePost
);

router.put(
  "/admin/posts/:post_id/hide",
  verifyToken,
  isAdmin,
  communityController.hidePost
);

router.delete(
  "/admin/posts/:post_id",
  verifyToken,
  isAdmin,
  communityController.deletePost
);

router.delete(
  "/admin/comments/:comment_id",
  verifyToken,
  isAdmin,
  communityController.deleteComment
);

module.exports = router;
