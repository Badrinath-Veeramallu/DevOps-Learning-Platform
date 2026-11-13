const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/authMiddleware");
const {
  getActivity,
  getStreak,
  logClientActivity,
} = require("../controllers/activityController");

router.get("/", protect, getActivity);
router.get("/streak", protect, getStreak);
router.post("/log", protect, logClientActivity);

module.exports = router;
