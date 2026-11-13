const mongoose = require("mongoose");

const quizAttemptSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    pathwayId: {
      type: String,
      required: true,
      trim: true,
    },
    score: {
      type: Number,
      required: true,
    },
    totalQuestions: {
      type: Number,
      required: true,
      default: 20,
    },
    percentage: {
      type: Number,
      required: true,
    },
    passed: {
      type: Boolean,
      required: true,
    },
    answers: {
      type: Map,
      of: Number, // questionId -> selectedOptionIndex (0..3)
      default: {},
    },
  },
  {
    timestamps: true,
  }
);

quizAttemptSchema.index({ userId: 1, pathwayId: 1, createdAt: -1 });

const QuizAttempt = mongoose.model("QuizAttempt", quizAttemptSchema);

module.exports = QuizAttempt;
