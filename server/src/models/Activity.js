const mongoose = require("mongoose");

const activitySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    type: {
      type: String,
      required: true,
      enum: ["stop_completed", "lesson_viewed", "animation_finished"],
    },
    pathwayId: {
      type: String,
      default: "git",
      trim: true,
    },
    stopSlug: {
      type: String,
      required: true,
      trim: true,
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: false,
    versionKey: false,
  }
);

// Compound index on (userId, createdAt) as requested
activitySchema.index({ userId: 1, createdAt: 1 });

// Deduplication index for daily events check
activitySchema.index({ userId: 1, type: 1, stopSlug: 1, createdAt: -1 });

const Activity = mongoose.model("Activity", activitySchema);

module.exports = Activity;
