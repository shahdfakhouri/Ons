const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/authmiddleware");
const allowRoles = require("../middleware/roleMiddleware");
const staffNotes = require("../controllers/staffNotes.controller");

// Retirement home only
router.use(verifyToken, allowRoles(["retirement_home"]));

// /api/retirement/notes
router.post("/", staffNotes.createNote);
router.get("/", staffNotes.getHomeNotes);

// /api/retirement/notes/elders/:elder_id
router.get("/elders/:elder_id", staffNotes.getElderNotes);

// /api/retirement/notes/:note_id
router.put("/:note_id", staffNotes.updateNote);
router.delete("/:note_id", staffNotes.deleteNote);

module.exports = router;
