const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/authmiddleware");
const allowRoles = require("../middleware/roleMiddleware");
const reports = require("../controllers/reports.controller");

router.use(verifyToken, allowRoles(["retirement_home"]));

router.get("/weekly", reports.getWeeklyReport);
router.get("/monthly", reports.getMonthlyReport);

// optional persistence
router.post("/save", reports.saveReport);
router.get("/saved", reports.getSavedReports);

module.exports = router;
