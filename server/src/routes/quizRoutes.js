const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/authMiddleware");
const {
  getQuiz,
  submitQuiz,
  getQuizStatus,
  getFastTrackQuiz,
  submitFastTrackQuiz,
} = require("../controllers/quizController");

// Fast-track routes must come BEFORE /:pathwayId to avoid shadowing
router.get("/:pathwayId/fast-track", protect, getFastTrackQuiz);
router.post("/:pathwayId/fast-track", protect, submitFastTrackQuiz);

router.get("/:pathwayId", protect, getQuiz);
router.post("/:pathwayId/submit", protect, submitQuiz);
router.get("/:pathwayId/status", protect, getQuizStatus);

module.exports = router;
