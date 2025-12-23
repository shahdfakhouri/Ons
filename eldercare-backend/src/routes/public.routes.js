const express = require("express");
const router = express.Router();

const publicController = require("../controllers/public.controller");

router.get("/caregivers/:id/reviews", publicController.getCaregiverReviews);
router.get("/retirement-homes/:id/reviews", publicController.getRetirementHomeReviews);


module.exports = router;
