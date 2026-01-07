const router = require("express").Router();
const companionController = require("../controllers/companion.controller");

// Optional auth (enable later if you want):
// const verifyToken = require("../middleware/authmiddleware");
// router.use(verifyToken);

router.post("/chat", companionController.chat);

module.exports = router;
