const express = require("express");
const router = express.Router();

const communityController = require("../controllers/community.controller");
const verifyToken = require("../middleware/authmiddleware");
const isAdmin = require("../middleware/adminMiddleware");

// existing
router.post("/posts", verifyToken, communityController.createPost);
router.get("/posts", verifyToken, communityController.getAllPosts);
router.get("/posts/:post_id", verifyToken, communityController.getPostById);
router.post("/posts/:post_id/comments", verifyToken, communityController.addComment);

// NEW: elder actions
router.post("/posts/:post_id/report", verifyToken, communityController.reportPost);
router.post("/comments/:comment_id/report", verifyToken, communityController.reportComment);
router.delete("/posts/:post_id", verifyToken, communityController.deleteMyPost);
router.delete("/comments/:comment_id", verifyToken, communityController.deleteMyComment);

// admin moderation (keep)
router.get("/admin/posts/pending", verifyToken, isAdmin, communityController.getPendingPosts);
router.put("/admin/posts/:post_id/approve", verifyToken, isAdmin, communityController.approvePost);
router.put("/admin/posts/:post_id/hide", verifyToken, isAdmin, communityController.hidePost);
router.delete("/admin/posts/:post_id", verifyToken, isAdmin, communityController.deleteMyPost);
router.delete("/admin/comments/:comment_id", verifyToken, isAdmin, communityController.deleteMyComment);

module.exports = router;
