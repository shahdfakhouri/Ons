// src/routes/auth.routes.js
const express = require("express");
const router = express.Router();

// ✅ add the .js extension and destructure the two handlers
const { signup, signin,hashString } = require("../controllers/auth.controller.js");

// endpoints
router.post("/signup", signup);
router.post("/signin", signin);
router.post("/hashString",hashString);
module.exports = router;
