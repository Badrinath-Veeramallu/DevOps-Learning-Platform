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
  docker: [
    "docker-01",
    "docker-02",
    "docker-03",
    "docker-04",
    "docker-05",
    "docker-06",
    "docker-07",
  ],
  linux: [
    "linux-01",
    "linux-02",
    "linux-03",
    "linux-04",
    "linux-05",
    "linux-06",
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

async function getPathwayLockStatus(userId) {
  const gitModules = PATHWAY_CURRICULA.git;
  const dockerModules = PATHWAY_CURRICULA.docker;
  const linuxModules = PATHWAY_CURRICULA.linux;

  const [gitDoc, dockerDoc, linuxDoc] = await Promise.all([
    mockProgressModel.findOne({ userId, pathwayId: "git" }),
    mockProgressModel.findOne({ userId, pathwayId: "docker" }),
    mockProgressModel.findOne({ userId, pathwayId: "linux" }),
  ]);

  const cleanGitCompleted = [...new Set(gitDoc?.completedModules || [])].filter((id) =>
    gitModules.includes(id)
  );
  const cleanDockerCompleted = [...new Set(dockerDoc?.completedModules || [])].filter((id) =>
    dockerModules.includes(id)
  );
  const cleanLinuxCompleted = [...new Set(linuxDoc?.completedModules || [])].filter((id) =>
    linuxModules.includes(id)
  );

  const isGitComplete =
    gitModules.length > 0 &&
    gitModules.every((id) => cleanGitCompleted.includes(id));

  const isDockerComplete =
    isGitComplete &&
    dockerModules.length > 0 &&
    dockerModules.every((id) => cleanDockerCompleted.includes(id));

  const isLinuxComplete =
    isDockerComplete &&
    linuxModules.length > 0 &&
    linuxModules.every((id) => cleanLinuxCompleted.includes(id));

  return {
    git: {
      isLocked: false,
      isCompleted: isGitComplete,
      totalModules: gitModules.length,
      completedCount: cleanGitCompleted.length,
      completedModules: cleanGitCompleted,
      lockReason: null,
    },
    docker: {
      isLocked: !isGitComplete,
      isCompleted: isDockerComplete,
      totalModules: dockerModules.length,
      completedCount: cleanDockerCompleted.length,
      completedModules: cleanDockerCompleted,
      lockReason: !isGitComplete
        ? "Docker pathway is locked. Complete all Git modules to unlock."
        : null,
    },
    linux: {
      isLocked: !isDockerComplete,
      isCompleted: isLinuxComplete,
      totalModules: linuxModules.length,
      completedCount: cleanLinuxCompleted.length,
      completedModules: cleanLinuxCompleted,
      lockReason: !isGitComplete
        ? "Linux pathway is locked. Complete all Git modules first."
        : !isDockerComplete
          ? "Linux pathway is locked. Complete all Docker modules to unlock."
          : null,
    },
  };
}

async function getProgress(req, res) {
  try {
    const pathwayId = req.params.pathwayId || "git";
    const userId = req.user._id;

    if (pathwayId === "docker" || pathwayId === "linux") {
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

    if (pathwayId === "docker" || pathwayId === "linux") {
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

    if (pathwayId === "docker" || pathwayId === "linux") {
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

  // 1. Initial State: Git unlocked, Docker locked, Linux locked
  let status = await getPathwayLockStatus(userId);
  assert.strictEqual(status.git.isLocked, false, "Git must be unlocked initially");
  assert.strictEqual(status.docker.isLocked, true, "Docker must be locked initially");
  assert.strictEqual(status.linux.isLocked, true, "Linux must be locked initially");
  console.log("  [PASS] Initial state: Git unlocked, Docker locked, Linux locked");

  // 2. Reject GET /api/progress/docker when locked
  let res = createRes();
  await getProgress({ user: { _id: userId }, params: { pathwayId: "docker" } }, res);
  assert.strictEqual(res.statusCode, 403, "GET Docker must return 403 when locked");
  assert.strictEqual(res.data.isLocked, true);
  console.log("  [PASS] Direct GET /api/progress/docker rejected with 403");

  // 3. Reject POST /api/progress/docker/toggle when locked
  res = createRes();
  await toggleProgress(
    { user: { _id: userId }, params: { pathwayId: "docker" }, body: { moduleId: "docker-01" } },
    res
  );
  assert.strictEqual(res.statusCode, 403, "Toggle Docker must return 403 when locked");
  console.log("  [PASS] Toggle /api/progress/docker/toggle rejected with 403");

  // 4. Reject activity log for Docker when locked
  res = createRes();
  await logClientActivity(
    { user: { _id: userId }, body: { type: "lesson_viewed", pathwayId: "docker", stopSlug: "docker-01" } },
    res
  );
  assert.strictEqual(res.statusCode, 403, "Activity log for locked Docker must return 403");
  console.log("  [PASS] Activity log rejected with 403 for locked pathway");

  // 5. Complete Git modules 1 to 6 - Docker and Linux should remain locked
  for (let i = 1; i <= 6; i++) {
    const moduleId = `git-0${i}`;
    res = createRes();
    await toggleProgress({ user: { _id: userId }, params: { pathwayId: "git" }, body: { moduleId } }, res);
    assert.strictEqual(res.statusCode, 200);
  }
  status = await getPathwayLockStatus(userId);
  assert.strictEqual(status.git.completedCount, 6);
  assert.strictEqual(status.git.isCompleted, false);
  assert.strictEqual(status.docker.isLocked, true, "Docker must remain locked with only 6 Git modules complete");
  assert.strictEqual(status.linux.isLocked, true, "Linux must remain locked");
  console.log("  [PASS] 6 of 7 Git completed: Docker & Linux remain locked");

  // 6. Complete Module 7 in Git - Docker unlocks! Linux remains locked
  res = createRes();
  await toggleProgress({ user: { _id: userId }, params: { pathwayId: "git" }, body: { moduleId: "git-07" } }, res);
  assert.strictEqual(res.statusCode, 200);
  status = await getPathwayLockStatus(userId);
  assert.strictEqual(status.git.completedCount, 7);
  assert.strictEqual(status.git.isCompleted, true);
  assert.strictEqual(status.docker.isLocked, false, "Docker MUST be unlocked when all Git modules are complete");
  assert.strictEqual(status.linux.isLocked, true, "Linux MUST remain locked until Docker is completed");
  console.log("  [PASS] All 7 Git modules completed: Docker unlocked, Linux locked");

  // 7. Access Docker now succeeds
  res = createRes();
  await getProgress({ user: { _id: userId }, params: { pathwayId: "docker" } }, res);
  assert.strictEqual(res.statusCode, 200);
  console.log("  [PASS] GET /api/progress/docker now succeeds with 200");

  // 8. Complete Docker modules 1 through 6 - Linux remains locked
  for (let i = 1; i <= 6; i++) {
    const moduleId = `docker-0${i}`;
    res = createRes();
    await toggleProgress({ user: { _id: userId }, params: { pathwayId: "docker" }, body: { moduleId } }, res);
    assert.strictEqual(res.statusCode, 200);
  }
  status = await getPathwayLockStatus(userId);
  assert.strictEqual(status.docker.completedCount, 6);
  assert.strictEqual(status.docker.isCompleted, false);
  assert.strictEqual(status.linux.isLocked, true, "Linux must remain locked with only 6 Docker modules complete");
  console.log("  [PASS] 6 of 7 Docker modules completed: Linux remains locked");

  // 9. Complete Docker module 7 - Linux unlocks!
  res = createRes();
  await toggleProgress({ user: { _id: userId }, params: { pathwayId: "docker" }, body: { moduleId: "docker-07" } }, res);
  assert.strictEqual(res.statusCode, 200);
  status = await getPathwayLockStatus(userId);
  assert.strictEqual(status.docker.completedCount, 7);
  assert.strictEqual(status.docker.isCompleted, true);
  assert.strictEqual(status.linux.isLocked, false, "Linux MUST be unlocked when all Docker modules are complete");
  console.log("  [PASS] All 7 Docker modules completed: Linux unlocked");

  // 10. Complete Linux module 1 through 3
  for (let i = 1; i <= 3; i++) {
    const moduleId = `linux-0${i}`;
    res = createRes();
    await toggleProgress({ user: { _id: userId }, params: { pathwayId: "linux" }, body: { moduleId } }, res);
    assert.strictEqual(res.statusCode, 200);
  }
  status = await getPathwayLockStatus(userId);
  assert.strictEqual(status.linux.completedCount, 3);
  console.log("  [PASS] Linux modules 1-3 completed successfully");

  // 11. Cascading Relocking: User uncompletes git-07!
  console.log("  Testing Cascading Relocking when user uncompletes git-07...");
  res = createRes();
  await toggleProgress({ user: { _id: userId }, params: { pathwayId: "git" }, body: { moduleId: "git-07" } }, res);
  assert.strictEqual(res.statusCode, 200);
  assert.strictEqual(res.data.isCompleted, false);

  status = await getPathwayLockStatus(userId);
  assert.strictEqual(status.git.completedCount, 6);
  assert.strictEqual(status.git.isCompleted, false);
  assert.strictEqual(status.docker.isLocked, true, "Docker MUST immediately relock when Git is no longer complete");
  assert.strictEqual(status.linux.isLocked, true, "Linux MUST immediately relock when Git is no longer complete");

  // Verify historical progress in Docker & Linux was NOT erased!
  assert.strictEqual(status.docker.completedCount, 7, "Docker historical completion records must NOT be deleted");
  assert.strictEqual(status.linux.completedCount, 3, "Linux historical completion records must NOT be deleted");
  console.log("  [PASS] Cascading relock succeeded and historical progress preserved!");

  // Attempting to access Docker or Linux now returns 403 Forbidden
  res = createRes();
  await getProgress({ user: { _id: userId }, params: { pathwayId: "docker" } }, res);
  assert.strictEqual(res.statusCode, 403);
  res = createRes();
  await getProgress({ user: { _id: userId }, params: { pathwayId: "linux" } }, res);
  assert.strictEqual(res.statusCode, 403);
  console.log("  [PASS] Docker and Linux requests return 403 while Git is incomplete");

  // 12. Re-completing git-07: Docker and Linux should unlock again and restore access!
  console.log("  Testing Restoring access when user re-completes git-07...");
  res = createRes();
  await toggleProgress({ user: { _id: userId }, params: { pathwayId: "git" }, body: { moduleId: "git-07" } }, res);
  assert.strictEqual(res.statusCode, 200);

  status = await getPathwayLockStatus(userId);
  assert.strictEqual(status.git.isCompleted, true);
  assert.strictEqual(status.docker.isLocked, false, "Docker must be unlocked again");
  assert.strictEqual(status.docker.isCompleted, true, "Docker is completed again because 7 modules were preserved");
  assert.strictEqual(status.linux.isLocked, false, "Linux must be unlocked again!");
  assert.strictEqual(status.linux.completedCount, 3, "Linux historical 3 modules immediately restored!");
  console.log("  [PASS] Re-completing Git restores Docker and Linux access with historical completions!");

  console.log("=== ALL PATHWAY LOCKING BACKEND TESTS PASSED SUCCESSFULLY! ===");
}

runTests().catch((err) => {
  console.error("Test failed:", err);
  process.exit(1);
});
