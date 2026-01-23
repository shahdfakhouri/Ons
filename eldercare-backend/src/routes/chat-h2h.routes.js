const express = require("express");
const router = express.Router();

const ctrl = require("../controllers/h2hChat.controller");
const verifyToken = require("../middleware/authmiddleware"); // adjust if different

router.use(verifyToken);

router.post("/conversations", ctrl.createOrGetConversation);
router.get("/conversations", ctrl.listMyConversations);
router.get("/conversations/:id/messages", ctrl.getMessages);
router.post("/conversations/:id/messages", ctrl.sendMessage);

module.exports = router;
