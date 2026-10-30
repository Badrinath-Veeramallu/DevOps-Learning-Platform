const mongoose = require("mongoose");

const progressSchema = new mongoose.Schema(
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
      default: "git",
      trim: true,
    },
    completedModules: {
      type: [String],
      default: [],
    },
    lastUpdated: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

progressSchema.index({ userId: 1, pathwayId: 1 }, { unique: true });

const Progress = mongoose.model("Progress", progressSchema);

module.exports = Progress;
