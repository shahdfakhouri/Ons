const express = require("express");
const router = express.Router();
const verifyToken = require("../middleware/authmiddleware");
const allowRoles = require("../middleware/roleMiddleware");
const visitsController = require("../controllers/visits.controller");

router.use(verifyToken);
router.use(allowRoles(["retirement_home"]));

// family link
router.get("/elders/:elder_id/family", visitsController.getElderFamily);

// visits per elder
router.post("/elders/:elder_id/visits", visitsController.createVisit);
router.get("/elders/:elder_id/visits", visitsController.getElderVisits);

// home calendar + status update
router.get("/visits", visitsController.getHomeVisits);
router.put("/visits/:visit_id/status", visitsController.updateVisitStatus);

module.exports = router;
