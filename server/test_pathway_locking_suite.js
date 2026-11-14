const assert = require("assert");

const PATHWAY_CURRICULA = {
  git: [
    "git-01",
    "git-02",
    "git-03",
    "git-04",
    "git-05",
    "git-06",
    "git-07",
  ],
  linux: [
    "linux-01",
    "linux-02",
    "linux-03",
    "linux-04",
    "linux-05",
    "linux-06",
  ],
  docker: [
    "docker-01",
    "docker-02",
    "docker-03",
    "docker-04",
    "docker-05",
    "docker-06",
    "docker-07",
  ],
};

// Mock In-memory store
let db = {};

const mockProgressModel = {
  findOne: async ({ userId, pathwayId }) => {
    const key = `${userId}_${pathwayId}`;
    if (!db[key]) return null;
    return {
      userId,
      pathwayId,
      completedModules: [...db[key].completedModules],
      lastUpdated: db[key].lastUpdated,
      save: async function () {
        db[key] = {
          userId: this.userId,
          pathwayId: this.pathwayId,
          completedModules: [...this.completedModules],
          lastUpdated: this.lastUpdated,
        };
      },
    };
  },
  create: async ({ userId, pathwayId, completedModules = [] }) => {
    const key = `${userId}_${pathwayId}`;
    db[key] = { userId, pathwayId, completedModules: [...completedModules], lastUpdated: new Date() };
    return {
      userId,
      pathwayId,
      completedModules: [...db[key].completedModules],
      lastUpdated: db[key].lastUpdated,
      save: async function () {
        db[key] = {
          userId: this.userId,
          pathwayId: this.pathwayId,
          completedModules: [...this.completedModules],
          lastUpdated: this.lastUpdated,
        };
      },
    };
  },
};

/**
 * Sequential rules:
 * - Git: Always unlocked by default.
 * - Linux: Locked until ALL Git modules (7) are completed.
 * - Docker: Locked until ALL Linux lessons (6) are completed AND Git remains complete.
 * - Kubernetes: Locked until ALL Docker modules (7) are completed.
 */
async function getPathwayLockStatus(userId) {
  const gitModules = PATHWAY_CURRICULA.git;
  const linuxModules = PATHWAY_CURRICULA.linux;
  const dockerModules = PATHWAY_CURRICULA.docker;

  const [gitDoc, linuxDoc, dockerDoc] = await Promise.all([
    mockProgressModel.findOne({ userId, pathwayId: "git" }),
    mockProgressModel.findOne({ userId, pathwayId: "linux" }),
    mockProgressModel.findOne({ userId, pathwayId: "docker" }),
  ]);

  const cleanGitCompleted = [...new Set(gitDoc?.completedModules || [])].filter((id) =>
    gitModules.includes(id)
  );
  const cleanLinuxCompleted = [...new Set(linuxDoc?.completedModules || [])].filter((id) =>
    linuxModules.includes(id)
  );
  const cleanDockerCompleted = [...new Set(dockerDoc?.completedModules || [])].filter((id) =>
    dockerModules.includes(id)
  );

  const isGitComplete =
    gitModules.length > 0 &&
    gitModules.every((id) => cleanGitCompleted.includes(id));

  const isLinuxComplete =
    isGitComplete &&
    linuxModules.length > 0 &&
    linuxModules.every((id) => cleanLinuxCompleted.includes(id));

  const isDockerComplete =
    isLinuxComplete &&
    dockerModules.length > 0 &&
    dockerModules.every((id) => cleanDockerCompleted.includes(id));

  return {
    git: {
      isLocked: false,
      isCompleted: isGitComplete,
      totalModules: gitModules.length,
      completedCount: cleanGitCompleted.length,
      completedModules: cleanGitCompleted,
      lockReason: null,
    },
    linux: {
      isLocked: !isGitComplete,
      isCompleted: isLinuxComplete,
      totalModules: linuxModules.length,
      completedCount: cleanLinuxCompleted.length,
      completedModules: cleanLinuxCompleted,
      lockReason: !isGitComplete
        ? "Linux pathway is locked. Complete all Git modules to unlock."
        : null,
    },
    docker: {
      isLocked: !isLinuxComplete,
      isCompleted: isDockerComplete,
      totalModules: dockerModules.length,
      completedCount: cleanDockerCompleted.length,
      completedModules: cleanDockerCompleted,
      lockReason: !isGitComplete
        ? "Docker pathway is locked. Complete all Git modules first."
        : !isLinuxComplete
          ? "Complete the Linux module to unlock the Docker module."
          : null,
    },
    kubernetes: {
      isLocked: !isDockerComplete,
      isCompleted: false,
      totalModules: 12,
      completedCount: 0,
      completedModules: [],
      lockReason: !isGitComplete
        ? "Kubernetes pathway is locked. Complete all Git modules first."
        : !isLinuxComplete
          ? "Kubernetes pathway is locked. Complete all Linux lessons first."
          : !isDockerComplete
            ? "Kubernetes pathway is locked. Complete all Docker modules to unlock."
            : null,
    },
  };
}

async function getProgress(req, res) {
  try {
    const pathwayId = req.params.pathwayId || "git";
    const userId = req.user._id;

    if (pathwayId === "linux" || pathwayId === "docker" || pathwayId === "kubernetes") {
      const lockStatus = await getPathwayLockStatus(userId);
      if (lockStatus[pathwayId] && lockStatus[pathwayId].isLocked) {
        return res.status(403).json({
          success: false,
          pathwayId,
          isLocked: true,
          message: lockStatus[pathwayId].lockReason || `Pathway "${pathwayId}" is locked.`,
        });
      }
    }

    let progress = await mockProgressModel.findOne({ userId, pathwayId });
    if (!progress) {
      progress = await mockProgressModel.create({
        userId,
        pathwayId,
        completedModules: [],
      });
    }

    const pathwayModules = PATHWAY_CURRICULA[pathwayId];
    let uniqueModules = [...new Set(progress.completedModules || [])];
    if (pathwayModules) {
      uniqueModules = uniqueModules.filter((id) => pathwayModules.includes(id));
    }

    return res.status(200).json({
      success: true,
      pathwayId,
      completedModules: uniqueModules,
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
}

async function toggleProgress(req, res) {
  try {
    const pathwayId = req.params.pathwayId || "git";
    const { moduleId } = req.body;
    const userId = req.user._id;

    if (!moduleId || typeof moduleId !== "string") {
      return res.status(400).json({ success: false, message: "moduleId is required" });
    }

    const pathwayModules = PATHWAY_CURRICULA[pathwayId];
    if (!pathwayModules) {
      return res.status(400).json({ success: false, message: `Unknown pathway: "${pathwayId}"` });
    }

    if (pathwayId === "linux" || pathwayId === "docker" || pathwayId === "kubernetes") {
      const lockStatus = await getPathwayLockStatus(userId);
      if (lockStatus[pathwayId] && lockStatus[pathwayId].isLocked) {
        return res.status(403).json({
          success: false,
          pathwayId,
          moduleId,
          isLocked: true,
          message: lockStatus[pathwayId].lockReason || `Pathway "${pathwayId}" is locked.`,
        });
      }
    }

    const moduleIndex = pathwayModules.indexOf(moduleId);
    if (moduleIndex === -1) {
      return res.status(400).json({ success: false, message: `Invalid moduleId "${moduleId}"` });
    }

    let progress = await mockProgressModel.findOne({ userId, pathwayId });
    if (!progress) {
      progress = await mockProgressModel.create({
        userId,
        pathwayId,
        completedModules: [],
      });
    }

    const currentModules = [...new Set(progress.completedModules || [])].filter((id) =>
      pathwayModules.includes(id)
    );
    const isAlreadyCompleted = currentModules.includes(moduleId);
    let isNowCompleted;

    if (isAlreadyCompleted) {
      const allowedPrefix = pathwayModules.slice(0, moduleIndex);
      progress.completedModules = currentModules.filter((id) => allowedPrefix.includes(id));
      isNowCompleted = false;
    } else {
      if (moduleIndex > 0) {
        const precedingModuleId = pathwayModules[moduleIndex - 1];
        if (!currentModules.includes(precedingModuleId)) {
          return res.status(400).json({
            success: false,
            message: `Cannot complete module "${moduleId}" out of sequence.`,
          });
        }
      }

      progress.completedModules = [...new Set([...currentModules, moduleId])];
      isNowCompleted = true;
    }

    progress.lastUpdated = new Date();
    await progress.save();

    return res.status(200).json({
      success: true,
      pathwayId,
      moduleId,
      isCompleted: isNowCompleted,
      completedModules: progress.completedModules,
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
}

async function logClientActivity(req, res) {
  try {
    const userId = req.user._id;
    const { type, pathwayId = "git", stopSlug } = req.body;

    if (!type || (type !== "lesson_viewed" && type !== "animation_finished")) {
      return res.status(400).json({ success: false, message: "Invalid activity type" });
    }

    if (!stopSlug || typeof stopSlug !== "string") {
      return res.status(400).json({ success: false, message: "stopSlug is required" });
    }

    if (pathwayId === "linux" || pathwayId === "docker" || pathwayId === "kubernetes") {
      const lockStatus = await getPathwayLockStatus(userId);
      if (lockStatus[pathwayId] && lockStatus[pathwayId].isLocked) {
        return res.status(403).json({
          success: false,
          isLocked: true,
          message: lockStatus[pathwayId].lockReason || `Cannot log activity for locked pathway "${pathwayId}".`,
        });
      }
    }

    return res.status(200).json({ success: true, logged: true });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
}

function createRes() {
  const response = {
    statusCode: 200,
    data: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(data) {
      this.data = data;
      return this;
    },
  };
  return response;
}

async function runTests() {
  console.log("=== RUNNING PATHWAY SEQUENTIAL LOCKING TEST SUITE ===");
  const userId = "test_user_pathway_locking";
  db = {};

  // 1. Initial State: Git unlocked, Linux locked, Docker locked, Kubernetes locked
  let status = await getPathwayLockStatus(userId);
  assert.strictEqual(status.git.isLocked, false, "Git must be unlocked initially");
  assert.strictEqual(status.linux.isLocked, true, "Linux must be locked initially");
  assert.strictEqual(status.docker.isLocked, true, "Docker must be locked initially");
  assert.strictEqual(status.kubernetes.isLocked, true, "Kubernetes must be locked initially");
  console.log("  [PASS] Initial state: Git unlocked, Linux locked, Docker locked, Kubernetes locked");

  // 2. Reject GET /api/progress/linux when locked
  let res = createRes();
  await getProgress({ user: { _id: userId }, params: { pathwayId: "linux" } }, res);
  assert.strictEqual(res.statusCode, 403, "GET Linux must return 403 when locked");
  assert.strictEqual(res.data.isLocked, true);
  console.log("  [PASS] Direct GET /api/progress/linux rejected with 403");

  // 3. Reject POST /api/progress/linux/toggle when locked
  res = createRes();
  await toggleProgress(
    { user: { _id: userId }, params: { pathwayId: "linux" }, body: { moduleId: "linux-01" } },
    res
  );
  assert.strictEqual(res.statusCode, 403, "Toggle Linux must return 403 when locked");
  console.log("  [PASS] Toggle /api/progress/linux/toggle rejected with 403");

  // 4. Reject activity log for Linux when locked
  res = createRes();
  await logClientActivity(
    { user: { _id: userId }, body: { type: "lesson_viewed", pathwayId: "linux", stopSlug: "linux-01" } },
    res
  );
  assert.strictEqual(res.statusCode, 403, "Activity log for locked Linux must return 403");
  console.log("  [PASS] Activity log rejected with 403 for locked pathway");

  // 5. Complete Git modules 1 to 6 - Linux, Docker, and Kubernetes remain locked
  for (let i = 1; i <= 6; i++) {
    const moduleId = `git-0${i}`;
    res = createRes();
    await toggleProgress({ user: { _id: userId }, params: { pathwayId: "git" }, body: { moduleId } }, res);
    assert.strictEqual(res.statusCode, 200);
  }
  status = await getPathwayLockStatus(userId);
  assert.strictEqual(status.git.completedCount, 6);
  assert.strictEqual(status.git.isCompleted, false);
  assert.strictEqual(status.linux.isLocked, true, "Linux must remain locked with only 6 Git modules complete");
  assert.strictEqual(status.docker.isLocked, true, "Docker must remain locked");
  console.log("  [PASS] 6 of 7 Git completed: Linux, Docker, Kubernetes remain locked");

  // 6. Complete Module 7 in Git - Linux unlocks! Docker and Kubernetes remain locked
  res = createRes();
  await toggleProgress({ user: { _id: userId }, params: { pathwayId: "git" }, body: { moduleId: "git-07" } }, res);
  assert.strictEqual(res.statusCode, 200);
  status = await getPathwayLockStatus(userId);
  assert.strictEqual(status.git.completedCount, 7);
  assert.strictEqual(status.git.isCompleted, true);
  assert.strictEqual(status.linux.isLocked, false, "Linux MUST be unlocked when all Git modules are complete");
  assert.strictEqual(status.docker.isLocked, true, "Docker MUST remain locked until Linux is completed");
  assert.strictEqual(status.kubernetes.isLocked, true, "Kubernetes MUST remain locked");
  console.log("  [PASS] All 7 Git modules completed: Linux unlocked, Docker & Kubernetes locked");

  // 7. Access Linux now succeeds
  res = createRes();
  await getProgress({ user: { _id: userId }, params: { pathwayId: "linux" } }, res);
  assert.strictEqual(res.statusCode, 200);
  console.log("  [PASS] GET /api/progress/linux now succeeds with 200");

  // 8. Complete Linux lessons 1 through 5 - Docker remains locked
  for (let i = 1; i <= 5; i++) {
    const moduleId = `linux-0${i}`;
    res = createRes();
    await toggleProgress({ user: { _id: userId }, params: { pathwayId: "linux" }, body: { moduleId } }, res);
    assert.strictEqual(res.statusCode, 200);
  }
  status = await getPathwayLockStatus(userId);
  assert.strictEqual(status.linux.completedCount, 5);
  assert.strictEqual(status.linux.isCompleted, false);
  assert.strictEqual(status.docker.isLocked, true, "Docker must remain locked with only 5 Linux lessons complete");
  console.log("  [PASS] 5 of 6 Linux lessons completed: Docker remains locked");

  // 9. Complete Linux lesson 6 - Docker unlocks! Kubernetes remains locked
  res = createRes();
  await toggleProgress({ user: { _id: userId }, params: { pathwayId: "linux" }, body: { moduleId: "linux-06" } }, res);
  assert.strictEqual(res.statusCode, 200);
  status = await getPathwayLockStatus(userId);
  assert.strictEqual(status.linux.completedCount, 6);
  assert.strictEqual(status.linux.isCompleted, true);
  assert.strictEqual(status.docker.isLocked, false, "Docker MUST be unlocked when all Linux lessons are complete");
  assert.strictEqual(status.kubernetes.isLocked, true, "Kubernetes MUST remain locked until Docker is completed");
  console.log("  [PASS] All 6 Linux lessons completed: Docker unlocked, Kubernetes locked");

  // 10. Complete Docker modules 1 through 7 - Kubernetes unlocks!
  for (let i = 1; i <= 7; i++) {
    const moduleId = `docker-0${i}`;
    res = createRes();
    await toggleProgress({ user: { _id: userId }, params: { pathwayId: "docker" }, body: { moduleId } }, res);
    assert.strictEqual(res.statusCode, 200);
  }
  status = await getPathwayLockStatus(userId);
  assert.strictEqual(status.docker.completedCount, 7);
  assert.strictEqual(status.docker.isCompleted, true);
  assert.strictEqual(status.kubernetes.isLocked, false, "Kubernetes MUST unlock when all Docker modules are complete");
  console.log("  [PASS] All 7 Docker modules completed: Kubernetes unlocked");

  // 11. Cascading Relocking: Uncompleting git-07 relocks Linux, Docker, and Kubernetes
  console.log("  Testing Cascading Relocking when user uncompletes git-07...");
  res = createRes();
  await toggleProgress({ user: { _id: userId }, params: { pathwayId: "git" }, body: { moduleId: "git-07" } }, res);
  assert.strictEqual(res.statusCode, 200);

  status = await getPathwayLockStatus(userId);
  assert.strictEqual(status.git.isCompleted, false);
  assert.strictEqual(status.linux.isLocked, true, "Linux must dynamically re-lock when Git is incomplete");
  assert.strictEqual(status.docker.isLocked, true, "Docker must dynamically re-lock when Git is incomplete");
  assert.strictEqual(status.kubernetes.isLocked, true, "Kubernetes must dynamically re-lock when Git is incomplete");

  // Verify historical completions are intact
  assert.strictEqual(status.linux.completedCount, 6, "Historical Linux completions must be preserved");
  assert.strictEqual(status.docker.completedCount, 7, "Historical Docker completions must be preserved");
  console.log("  [PASS] Cascading relock succeeded and historical progress preserved!");

  // Requests to Linux, Docker, and Kubernetes now rejected with 403
  res = createRes();
  await getProgress({ user: { _id: userId }, params: { pathwayId: "linux" } }, res);
  assert.strictEqual(res.statusCode, 403);
  res = createRes();
  await getProgress({ user: { _id: userId }, params: { pathwayId: "docker" } }, res);
  assert.strictEqual(res.statusCode, 403);
  console.log("  [PASS] Linux, Docker, and Kubernetes requests return 403 while Git is incomplete");

  // 12. Restoring access when user re-completes git-07
  console.log("  Testing Restoring access when user re-completes git-07...");
  res = createRes();
  await toggleProgress({ user: { _id: userId }, params: { pathwayId: "git" }, body: { moduleId: "git-07" } }, res);
  assert.strictEqual(res.statusCode, 200);

  status = await getPathwayLockStatus(userId);
  assert.strictEqual(status.git.isCompleted, true);
  assert.strictEqual(status.linux.isLocked, false);
  assert.strictEqual(status.docker.isLocked, false);
  assert.strictEqual(status.kubernetes.isLocked, false);
  console.log("  [PASS] Re-completing Git restores Linux, Docker, and Kubernetes access with historical completions!");

  console.log("=== ALL PATHWAY LOCKING BACKEND TESTS PASSED SUCCESSFULLY! ===");
}

runTests().catch((err) => {
  console.error("Test failed:", err);
  process.exit(1);
});
