const express = require("express");
const router = express.Router();
const matchController = require("../controllers/match.controller");
const verifyToken = require("../middleware/authmiddleware");
const isAdmin = require("../middleware/adminMiddleware");

// Admin or family request
router.post("/find-match/:family_id", verifyToken, matchController.findBestMatch);

module.exports = router;
