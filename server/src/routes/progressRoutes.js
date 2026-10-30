const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/authMiddleware");
const { getProgress, toggleProgress } = require("../controllers/progressController");

router.get("/:pathwayId", protect, getProgress);
router.post("/:pathwayId/toggle", protect, toggleProgress);

module.exports = router;
