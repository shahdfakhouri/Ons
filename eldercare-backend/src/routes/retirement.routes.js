const express = require("express");
const router = express.Router();
const retirementController = require("../controllers/retirement.controller");
const verifyToken = require("../middleware/authmiddleware");

router.get("/", verifyToken, retirementController.getDashboard);
router.put("/update", verifyToken, retirementController.updateProfile);

module.exports = router;
