const assert = require('assert');

// Test curriculum definitions
const PATHWAY_CURRICULA = {
  git: [
    'git-01',
    'git-02',
    'git-03',
    'git-04',
    'git-05',
    'git-06',
    'git-07',
  ],
  docker: [
    'docker-01',
    'docker-02',
    'docker-03',
    'docker-04',
    'docker-05',
    'docker-06',
    'docker-07',
  ],
  linux: [
    'linux-01',
    'linux-02',
    'linux-03',
    'linux-04',
    'linux-05',
    'linux-06',
  ],
};

function calculateProgress(completedModules, totalModules) {
  const unique = [...new Set(completedModules)];
  return totalModules > 0 ? Math.round((unique.length / totalModules) * 100) : 0;
}

// In-memory mock DB for testing the controller logic
let db = {};

const mockProgressModel = {
  findOne: async ({ userId, pathwayId }) => {
    const key = `${userId}_${pathwayId}`;
    return db[key] ? { ...db[key] } : null;
  },
  create: async ({ userId, pathwayId, completedModules }) => {
    const key = `${userId}_${pathwayId}`;
    db[key] = { userId, pathwayId, completedModules: [...completedModules] };
    return { ...db[key] };
  },
};

// Re-create the controller handlers with injected mocks
async function getProgress(req, res) {
  try {
    const pathwayId = req.params.pathwayId || "git";
    const userId = req.user._id;

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
      return res.status(400).json({
        success: false,
        message: "moduleId is required",
      });
    }

    const pathwayModules = PATHWAY_CURRICULA[pathwayId];
    if (!pathwayModules) {
      return res.status(400).json({
        success: false,
        message: `Unknown pathway: "${pathwayId}"`,
      });
    }

    const moduleIndex = pathwayModules.indexOf(moduleId);
    if (moduleIndex === -1) {
      return res.status(400).json({
        success: false,
        message: `Invalid moduleId "${moduleId}" for pathway "${pathwayId}"`,
      });
    }

    let progress = await mockProgressModel.findOne({ userId, pathwayId });
    if (!progress) {
      progress = {
        userId,
        pathwayId,
        completedModules: [],
      };
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
            message: `Cannot complete module "${moduleId}" out of sequence. Preceding module "${precedingModuleId}" must be completed first.`,
          });
        }
      }

      progress.completedModules = [...new Set([...currentModules, moduleId])];
      isNowCompleted = true;
    }

    // Save to db
    db[`${userId}_${pathwayId}`] = { ...progress };

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

function mockRes() {
  const res = {
    statusCode: 200,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(data) {
      this.body = data;
      return this;
    },
  };
  return res;
}

async function runTests() {
  console.log('--- Starting Progress Sequential & Percentage Verification Suite ---\n');

  // Test 1: Percentage calculations
  console.log('Test 1: Mathematical Accuracy of Progress Percentage Calculation');
  assert.strictEqual(calculateProgress([], 7), 0, '0 of 7 must be 0%');
  assert.strictEqual(calculateProgress(['git-01'], 7), 14, '1 of 7 must be 14%');
  assert.strictEqual(calculateProgress(['git-01', 'git-02', 'git-03'], 7), 43, '3 of 7 must be 43%');
  assert.strictEqual(calculateProgress(['git-01', 'git-02', 'git-03', 'git-04'], 7), 57, '4 of 7 must be 57%');
  assert.strictEqual(
    calculateProgress(['git-01', 'git-02', 'git-03', 'git-04', 'git-05', 'git-06', 'git-07'], 7),
    100,
    '7 of 7 must be 100%'
  );

  // Linux (6 modules)
  assert.strictEqual(calculateProgress([], 6), 0, '0 of 6 must be 0%');
  assert.strictEqual(calculateProgress(['linux-01'], 6), 17, '1 of 6 must be 17%');
  assert.strictEqual(calculateProgress(['linux-01', 'linux-02', 'linux-03'], 6), 50, '3 of 6 must be 50%');
  assert.strictEqual(
    calculateProgress(['linux-01', 'linux-02', 'linux-03', 'linux-04', 'linux-05', 'linux-06'], 6),
    100,
    '6 of 6 must be 100%'
  );

  // Deduplication check
  assert.strictEqual(
    calculateProgress(['git-01', 'git-01', 'git-02', 'git-02', 'git-03'], 7),
    43,
    'Duplicate module IDs must not be counted more than once (3 of 7 = 43%)'
  );
  console.log('  ✓ Percentage tests passed!\n');

  // Test 2: Initial state allows completing Stop 1
  console.log('Test 2: Sequential Unlocking - Stop 1 is accessible by default');
  db = {};
  const req1 = { user: { _id: 'user_1' }, params: { pathwayId: 'git' }, body: { moduleId: 'git-01' } };
  const res1 = mockRes();
  await toggleProgress(req1, res1);
  assert.strictEqual(res1.statusCode, 200);
  assert.strictEqual(res1.body.isCompleted, true);
  assert.deepStrictEqual(res1.body.completedModules, ['git-01']);
  console.log('  ✓ Stop 1 marked completed successfully');

  // Test 3: Stop 3 cannot be completed before Stop 2
  console.log('Test 3: Out-of-Sequence Completion is rejected with HTTP 400');
  const req3 = { user: { _id: 'user_1' }, params: { pathwayId: 'git' }, body: { moduleId: 'git-03' } };
  const res3 = mockRes();
  await toggleProgress(req3, res3);
  assert.strictEqual(res3.statusCode, 400);
  assert.strictEqual(res3.body.success, false);
  assert(res3.body.message.includes('out of sequence'));
  console.log('  ✓ Direct API attempt to complete Stop 3 rejected with HTTP 400');

  // Test 4: Stop 2 can be completed after Stop 1
  console.log('Test 4: Stop 2 can be completed after Stop 1 is completed');
  const req2 = { user: { _id: 'user_1' }, params: { pathwayId: 'git' }, body: { moduleId: 'git-02' } };
  const res2 = mockRes();
  await toggleProgress(req2, res2);
  assert.strictEqual(res2.statusCode, 200);
  assert.strictEqual(res2.body.isCompleted, true);
  assert.deepStrictEqual(res2.body.completedModules, ['git-01', 'git-02']);
  console.log('  ✓ Stop 2 completed successfully');

  // Test 5: Stop 3 can now be completed
  console.log('Test 5: Stop 3 can now be completed');
  const res3_retry = mockRes();
  await toggleProgress(req3, res3_retry);
  assert.strictEqual(res3_retry.statusCode, 200);
  assert.strictEqual(res3_retry.body.isCompleted, true);
  assert.deepStrictEqual(res3_retry.body.completedModules, ['git-01', 'git-02', 'git-03']);
  console.log('  ✓ Stop 3 completed successfully (3 of 7 completed = 43%)');

  // Test 6: Uncompleting Stop 2 cascades to uncomplete Stop 3
  console.log('Test 6: Cascading Un-completion Preserves Chain Integrity');
  const req2_uncomplete = { user: { _id: 'user_1' }, params: { pathwayId: 'git' }, body: { moduleId: 'git-02' } };
  const res2_uncomplete = mockRes();
  await toggleProgress(req2_uncomplete, res2_uncomplete);
  assert.strictEqual(res2_uncomplete.statusCode, 200);
  assert.strictEqual(res2_uncomplete.body.isCompleted, false);
  assert.deepStrictEqual(res2_uncomplete.body.completedModules, ['git-01']);
  console.log('  ✓ Uncompleting Stop 2 cascaded to remove Stop 3; completedModules is now [git-01]');

  // Test 7: Linux pathway sequential validation (6 modules)
  console.log('Test 7: Linux Pathway Sequential Validation');
  const reqLinux2 = { user: { _id: 'user_linux' }, params: { pathwayId: 'linux' }, body: { moduleId: 'linux-02' } };
  const resLinux2 = mockRes();
  await toggleProgress(reqLinux2, resLinux2);
  assert.strictEqual(resLinux2.statusCode, 400, 'Cannot complete linux-02 before linux-01');

  const reqLinux1 = { user: { _id: 'user_linux' }, params: { pathwayId: 'linux' }, body: { moduleId: 'linux-01' } };
  const resLinux1 = mockRes();
  await toggleProgress(reqLinux1, resLinux1);
  assert.strictEqual(resLinux1.statusCode, 200);
  assert.deepStrictEqual(resLinux1.body.completedModules, ['linux-01']);

  const resLinux2_ok = mockRes();
  await toggleProgress(reqLinux2, resLinux2_ok);
  assert.strictEqual(resLinux2_ok.statusCode, 200);
  assert.deepStrictEqual(resLinux2_ok.body.completedModules, ['linux-01', 'linux-02']);
  console.log('  ✓ Linux pathway sequential validation passed');

  // Test 8: Unknown pathway or invalid module ID
  console.log('Test 8: Unknown Pathway & Invalid Module Handling');
  const reqBadPathway = { user: { _id: 'user_1' }, params: { pathwayId: 'kubernetes' }, body: { moduleId: 'k8s-01' } };
  const resBadPathway = mockRes();
  await toggleProgress(reqBadPathway, resBadPathway);
  assert.strictEqual(resBadPathway.statusCode, 400);

  const reqBadMod = { user: { _id: 'user_1' }, params: { pathwayId: 'git' }, body: { moduleId: 'invalid-mod' } };
  const resBadMod = mockRes();
  await toggleProgress(reqBadMod, resBadMod);
  assert.strictEqual(resBadMod.statusCode, 400);
  console.log('  ✓ Invalid pathway and module ID tests passed');

  console.log('\n--- ALL BACKEND PROGRESS & SEQUENTIAL TESTS PASSED! ---');
}

runTests().catch((err) => {
  console.error('Test Suite Failed:', err);
  process.exit(1);
});
