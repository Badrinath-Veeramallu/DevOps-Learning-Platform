const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/authMiddleware");
const {
  getQuiz,
  submitQuiz,
  getQuizStatus,
} = require("../controllers/quizController");

router.get("/:pathwayId", protect, getQuiz);
router.post("/:pathwayId/submit", protect, submitQuiz);
router.get("/:pathwayId/status", protect, getQuizStatus);

module.exports = router;
