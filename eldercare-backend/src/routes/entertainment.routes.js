const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/authmiddleware");
const allowRoles = require("../middleware/roleMiddleware");
const entertainmentController = require("../controllers/entertainment.controller");

// Feed
router.get("/feed", verifyToken, allowRoles(["elder"]), entertainmentController.getFeed);

// Favorites
router.post("/favorites/:item_id", verifyToken, allowRoles(["elder"]), entertainmentController.addFavorite);
router.get("/favorites", verifyToken, allowRoles(["elder"]), entertainmentController.getFavorites);
router.delete("/favorites/:item_id", verifyToken, allowRoles(["elder"]), entertainmentController.removeFavorite);

// Activity tracking
router.post("/activity", verifyToken, allowRoles(["elder"]), entertainmentController.upsertActivity);
router.get("/activity", verifyToken, allowRoles(["elder"]), entertainmentController.getMyActivity);
router.get("/continue", verifyToken, allowRoles(["elder"]), entertainmentController.getContinueWatching);

module.exports = router;
