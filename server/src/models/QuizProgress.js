const mongoose = require("mongoose");

const quizProgressSchema = new mongoose.Schema(
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
    hasPassed: {
      type: Boolean,
      default: false,
    },
    bestScore: {
      type: Number,
      default: 0,
    },
    totalQuestions: {
      type: Number,
      default: 20,
    },
    attemptsCount: {
      type: Number,
      default: 0,
    },
    firstPassedAt: {
      type: Date,
      default: null,
    },
    lastAttemptAt: {
      type: Date,
      default: Date.now,
    },
    latestAttemptId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "QuizAttempt",
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

quizProgressSchema.index({ userId: 1, pathwayId: 1 }, { unique: true });

const QuizProgress = mongoose.model("QuizProgress", quizProgressSchema);

module.exports = QuizProgress;
