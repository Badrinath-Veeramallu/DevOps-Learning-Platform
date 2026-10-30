const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/authMiddleware");
const { getActivity, logClientActivity } = require("../controllers/activityController");

router.get("/", protect, getActivity);
router.post("/log", protect, logClientActivity);

module.exports = router;
