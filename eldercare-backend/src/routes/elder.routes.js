const express = require("express");
const router = express.Router();
const elderController = require("../controllers/elder.controller");
const verifyToken = require("../middleware/authmiddleware");

router.get("/", verifyToken, elderController.getDashboard);
router.put("/update", verifyToken, elderController.updateProfile);

module.exports = router;
