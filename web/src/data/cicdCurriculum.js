/**
 * DevOps Learning Platform — CI/CD & GitOps Delivery Curriculum
 * Single Source of Truth based on provided final curriculum.
 * Exact content, objectives, commands, and code examples preserved.
 */

export const cicdCurriculum = [
  // ============================================================
  // LESSON 1: CI/CD Fundamentals
  // ============================================================
  {
    id: "cicd-01",
    order: 1,
    number: "01",
    title: "01. CI/CD Fundamentals",
    shortTitle: "CI/CD Fundamentals",
    summary:
      "Understand CI/CD and its importance in DevOps, differentiate between Continuous Integration, Delivery, and Deployment, understand pipeline stages, and explore automated workflows.",
    estimatedMinutes: 20,
    objectives: [
      "Understand CI/CD and its importance in DevOps.",
      "Differentiate between Continuous Integration, Delivery, and Deployment.",
      "Understand the stages of a CI/CD pipeline.",
      "Learn how automated build, test, and deployment workflows work.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Why Do We Need CI/CD?",
        animationId: "cicd-fundamentals-why-cicd-animation",
        paragraphs: [
          "Imagine a team working on an application where multiple developers regularly push code changes. Every update needs to be tested, built, and deployed.",
          "Performing these tasks manually takes time and can introduce errors.",
          "CI/CD automates these activities, helping teams detect problems early and deliver software more reliably.",
        ],
      },
      {
        number: 2,
        title: "2. Understand Continuous Integration (CI)",
        animationId: "cicd-fundamentals-continuous-integration-animation",
        paragraphs: [
          "Continuous Integration is the practice of frequently integrating code changes into a shared repository and automatically validating them.",
          "Whenever a developer pushes code, automated workflows can install dependencies, run tests, and build the application.",
          "This helps identify problems before changes are merged into the main branch.",
        ],
      },
      {
        number: 3,
        title: "3. Continuous Delivery vs Continuous Deployment",
        animationId: "cicd-fundamentals-delivery-vs-deployment-animation",
        paragraphs: [
          "Both practices extend Continuous Integration.",
          "Continuous Delivery keeps the application ready for release, but production deployment may require manual approval.",
          "Continuous Deployment automatically releases changes to production after all configured checks pass.",
          "The choice depends on the application's requirements and release policies.",
        ],
      },
      {
        number: 4,
        title: "4. Understand CI/CD Pipeline Stages",
        animationId: "cicd-fundamentals-pipeline-stages-animation",
        paragraphs: [
          "A typical pipeline contains these stages:",
        ],
        listItems: [
          "1. Source: Developers push code to Git.",
          "2. Build: The application is compiled or packaged.",
          "3. Test: Automated tests verify functionality.",
          "4. Quality Checks: Code quality and security are analyzed.",
          "5. Package: A deployable artifact or Docker image is created.",
          "6. Deploy: The application is released.",
          "7. Monitor: Application health and performance are checked.",
        ],
      },
      {
        number: 5,
        title: "5. Understand Build, Test and Deployment Workflows",
        animationId: "cicd-fundamentals-build-test-deploy-animation",
        paragraphs: [
          "Consider a Node.js application:",
        ],
        codeSnippet: {
          code: "npm install\nnpm test\nnpm run build",
          language: "bash",
        },
        postSnippetParagraphs: [
          "These commands install dependencies, run tests, and build the application.",
          "A CI/CD pipeline automates these steps so they execute consistently whenever required.",
        ],
      },
    ],
  },

  // ============================================================
  // LESSON 2: Jenkins & Pipeline Automation
  // ============================================================
  {
    id: "cicd-02",
    order: 2,
    number: "02",
    title: "02. Jenkins & Pipeline Automation",
    shortTitle: "Jenkins & Pipeline Automation",
    summary:
      "Understand Jenkins and its architecture, install and configure Jenkins, master jobs and build triggers, and create declarative pipelines using Jenkinsfiles.",
    estimatedMinutes: 25,
    objectives: [
      "Understand Jenkins and its architecture.",
      "Install and configure Jenkins.",
      "Learn Jenkins jobs and build triggers.",
      "Create Jenkins pipelines.",
      "Understand Jenkinsfiles and declarative pipelines.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Introduction to Jenkins",
        animationId: "jenkins-introduction-animation",
        paragraphs: [
          "Jenkins is an open-source automation server used to automate software development tasks such as building, testing, and deploying applications.",
          "It integrates with tools like Git, Docker, Kubernetes, and SonarQube through plugins.",
        ],
      },
      {
        number: 2,
        title: "2. Understand Jenkins Architecture",
        animationId: "jenkins-architecture-animation",
        paragraphs: [
          "Jenkins follows a controller-agent architecture.",
        ],
        listItems: [
          "Controller: Manages jobs, configuration, and pipeline execution.",
          "Agent: Executes assigned build and testing tasks.",
          "Job: Defines an automation task.",
          "Build: An execution of a job.",
          "Plugin: Adds additional functionality.",
        ],
        closingParagraphs: [
          "This architecture allows teams to distribute pipeline workloads across different machines.",
        ],
      },
      {
        number: 3,
        title: "3. Install and Configure Jenkins",
        animationId: "jenkins-installation-animation",
        paragraphs: [
          "Jenkins can be installed on Linux, Windows, macOS, or through Docker.",
          "Check Java:",
        ],
        codeSnippet: {
          code: "java -version",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Start Jenkins using Docker:",
        ],
        secondSnippet: {
          code: "docker run -d \\\n  --name jenkins \\\n  -p 8080:8080 \\\n  -p 50000:50000 \\\n  -v jenkins_home:/var/jenkins_home \\\n  jenkins/jenkins:lts",
          language: "bash",
        },
        middleParagraphs: [
          "Open:",
        ],
        thirdSnippet: {
          code: "http://localhost:8080",
          language: "text",
        },
        afterThirdParagraphs: [
          "Complete the initial setup using the administrator password and installation wizard.",
        ],
      },
      {
        number: 4,
        title: "4. Understand Jenkins Jobs and Build Triggers",
        animationId: "jenkins-jobs-triggers-animation",
        paragraphs: [
          "A Jenkins job defines tasks such as retrieving code, running tests, and building applications.",
          "Common triggers include:",
        ],
        listItems: [
          "Manual: Started by a developer.",
          "Poll SCM: Periodically checks repository changes.",
          "Webhook: Triggered by GitHub events.",
          "Scheduled: Runs at configured times.",
        ],
        closingParagraphs: [
          "Webhooks are commonly used to start Jenkins jobs whenever developers push code.",
        ],
      },
      {
        number: 5,
        title: "5. Create Your First Jenkins Pipeline",
        animationId: "jenkins-first-pipeline-animation",
        paragraphs: [
          "A pipeline defines the stages of an automated workflow.",
          "Create a file named Jenkinsfile:",
        ],
        codeSnippet: {
          code: `pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install') {
            steps {
                sh 'npm install'
            }
        }

        stage('Test') {
            steps {
                sh 'npm test'
            }
        }

        stage('Build') {
            steps {
                sh 'npm run build'
            }
        }
    }
}`,
          language: "groovy",
        },
        postSnippetParagraphs: [
          "Jenkins executes these stages in sequence. A failed stage normally prevents later stages from running.",
        ],
      },
      {
        number: 6,
        title: "6. Understand Declarative Pipelines",
        animationId: "jenkins-declarative-pipeline-animation",
        paragraphs: [
          "A Jenkinsfile stores pipeline configuration as code inside the repository.",
          "Important elements include:",
        ],
        listItems: [
          "pipeline: Defines the pipeline.",
          "agent: Specifies the execution environment.",
          "stages: Contains pipeline stages.",
          "stage: Defines an individual stage.",
          "steps: Contains commands.",
          "environment: Defines environment variables.",
          "post: Defines actions after execution.",
        ],
        closingParagraphs: [
          "Keeping the Jenkinsfile in Git makes pipeline changes easier to review and maintain.",
        ],
      },
    ],
  },

  // ============================================================
  // LESSON 3: GitHub Actions
  // ============================================================
  {
    id: "cicd-03",
    order: 3,
    number: "03",
    title: "03. GitHub Actions",
    shortTitle: "GitHub Actions",
    summary:
      "Understand GitHub Actions, workflows, events, jobs, steps, runners, YAML syntax, and manage secrets, environment variables, and build artifacts.",
    estimatedMinutes: 25,
    objectives: [
      "Understand GitHub Actions and its role in CI/CD.",
      "Learn workflows, events, jobs, steps, and runners.",
      "Understand GitHub Actions YAML syntax.",
      "Create automated workflows.",
      "Use secrets, environment variables, and artifacts.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Introduction to GitHub Actions",
        animationId: "github-actions-introduction-animation",
        paragraphs: [
          "GitHub Actions is an automation platform integrated into GitHub.",
          "It allows developers to automate testing, building, security checks, and deployment whenever repository events occur.",
          "Unlike Jenkins, it does not require teams to maintain a separate automation server for its hosted runners.",
        ],
      },
      {
        number: 2,
        title: "2. Understand Workflows, Events and Triggers",
        animationId: "github-actions-workflows-triggers-animation",
        paragraphs: [
          "A workflow is an automated process defined in a YAML file.",
          "Workflows are stored inside:",
        ],
        codeSnippet: {
          code: ".github/workflows/",
          language: "text",
        },
        postSnippetParagraphs: [
          "Common triggers include:",
        ],
        listItems: [
          "push: Runs when code is pushed.",
          "pull_request: Runs for pull request events.",
          "workflow_dispatch: Allows manual execution.",
          "schedule: Runs at configured intervals.",
        ],
        secondSnippet: {
          code: `name: Basic CI

on:
  push:
    branches: [main]

  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - name: Display Message
        run: echo "CI started"`,
          language: "yaml",
        },
      },
      {
        number: 3,
        title: "3. Understand Jobs, Steps and Runners",
        animationId: "github-actions-jobs-steps-runners-animation",
        paragraphs: [
          "A workflow contains jobs, and each job contains steps.",
        ],
        listItems: [
          "Workflow: Complete automation process.",
          "Job: Group of related tasks.",
          "Step: Individual command or action.",
          "Runner: Machine that executes a job.",
          "Action: Reusable automation component.",
        ],
        closingParagraphs: [
          "Independent jobs can run in parallel, while dependencies can be configured using needs.",
        ],
      },
      {
        number: 4,
        title: "4. Understand GitHub Actions YAML Syntax",
        animationId: "github-actions-yaml-animation",
        paragraphs: [
          "Consider a Node.js CI workflow:",
        ],
        codeSnippet: {
          code: `name: Node.js CI

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 22

      - name: Install Dependencies
        run: npm ci

      - name: Run Tests
        run: npm test

      - name: Build
        run: npm run build`,
          language: "yaml",
        },
        postSnippetParagraphs: [
          "The uses property runs reusable actions, while run executes shell commands.",
        ],
      },
      {
        number: 5,
        title: "5. Understand Secrets and Environment Variables",
        animationId: "github-actions-secrets-environment-animation",
        paragraphs: [
          "Environment variables store configuration values used by workflows.",
          "Sensitive information such as API keys and deployment tokens should be stored using GitHub Secrets.",
          "Example:",
        ],
        codeSnippet: {
          code: `steps:
  - name: Deploy Application
    run: ./deploy.sh
    env:
      DEPLOY_TOKEN: \${{ secrets.DEPLOY_TOKEN }}`,
          language: "yaml",
        },
        postSnippetParagraphs: [
          "Never hardcode passwords or access tokens in workflow files.",
        ],
      },
      {
        number: 6,
        title: "6. Understand Artifacts and Workflow Execution",
        animationId: "github-actions-artifacts-animation",
        paragraphs: [
          "Artifacts are files generated during workflow execution that can be stored and accessed later.",
          "For example, upload a React build:",
        ],
        codeSnippet: {
          code: `- name: Upload Build
  uses: actions/upload-artifact@v4
  with:
    name: frontend-build
    path: dist/`,
          language: "yaml",
        },
        postSnippetParagraphs: [
          "Workflow execution can be inspected through the repository's Actions tab, where developers can review job results and error logs.",
        ],
      },
    ],
  },

  // ============================================================
  // LESSON 4: Automated Testing & Code Quality
  // ============================================================
  {
    id: "cicd-04",
    order: 4,
    number: "04",
    title: "04. Automated Testing & Code Quality",
    shortTitle: "Automated Testing & Code Quality",
    summary:
      "Understand automated testing in CI/CD, differentiate unit, integration, and E2E tests, configure code coverage and quality gates, explore SonarQube, and scan dependencies for vulnerabilities.",
    estimatedMinutes: 25,
    objectives: [
      "Understand automated testing in CI/CD.",
      "Differentiate between unit, integration, and end-to-end testing.",
      "Understand code coverage and quality gates.",
      "Learn SonarQube and static code analysis.",
      "Understand dependency and vulnerability scanning.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Why Is Automated Testing Important?",
        animationId: "testing-importance-animation",
        paragraphs: [
          "A developer may update one feature and accidentally break another.",
          "Automated testing executes predefined checks whenever code changes, helping identify problems before deployment.",
          "This reduces manual testing effort and improves application reliability.",
        ],
      },
      {
        number: 2,
        title: "2. Understand Unit Testing",
        animationId: "unit-testing-animation",
        paragraphs: [
          "Unit testing verifies individual functions or components.",
          "Example:",
        ],
        codeSnippet: {
          code: `function calculateTotal(price, quantity) {
    return price * quantity;
}

module.exports = calculateTotal;`,
          language: "javascript",
        },
        postSnippetParagraphs: [
          "A Jest test:",
        ],
        secondSnippet: {
          code: `const calculateTotal = require('./calculateTotal');

test('calculates total', () => {
    expect(calculateTotal(100, 3)).toBe(300);
});`,
          language: "javascript",
        },
        closingParagraphs: [
          "Unit tests help detect errors in individual pieces of code.",
        ],
      },
      {
        number: 3,
        title: "3. Understand Integration and End-to-End Testing",
        animationId: "integration-e2e-testing-animation",
        paragraphs: [
          "Integration testing verifies that multiple components work together, such as an API controller communicating with a database.",
          "End-to-end testing checks complete user workflows.",
          "For example:",
        ],
        listItems: [
          "1. Open a registration page.",
          "2. Enter user details.",
          "3. Submit the form.",
          "4. Verify successful registration.",
          "5. Log in using the new account.",
        ],
        closingParagraphs: [
          "Tools such as Playwright and Cypress support browser-based testing.",
        ],
      },
      {
        number: 4,
        title: "4. Understand Code Coverage and Quality Gates",
        animationId: "code-coverage-quality-gates-animation",
        paragraphs: [
          "Code coverage measures how much application code is executed by tests.",
          "Common measurements include:",
        ],
        listItems: [
          "Line coverage.",
          "Statement coverage.",
          "Branch coverage.",
          "Function coverage.",
        ],
        closingParagraphs: [
          "A quality gate defines conditions that must pass before code progresses through a pipeline.",
          "These conditions may include passing tests, minimum coverage, and the absence of critical security issues.",
        ],
      },
      {
        number: 5,
        title: "5. Introduction to SonarQube",
        animationId: "sonarqube-animation",
        paragraphs: [
          "SonarQube is a code quality and security analysis platform.",
          "It identifies issues such as:",
        ],
        listItems: [
          "Bugs.",
          "Code smells.",
          "Security vulnerabilities.",
          "Duplicated code.",
          "Maintainability problems.",
        ],
        closingParagraphs: [
          "It can integrate with Jenkins and GitHub Actions to analyze code automatically.",
        ],
      },
      {
        number: 6,
        title: "6. Dependency and Vulnerability Scanning",
        animationId: "dependency-vulnerability-scanning-animation",
        paragraphs: [
          "Applications use external packages that may contain known security vulnerabilities.",
          "For npm projects, run:",
        ],
        codeSnippet: {
          code: "npm audit",
          language: "bash",
        },
        postSnippetParagraphs: [
          "To apply available fixes:",
        ],
        secondSnippet: {
          code: "npm audit fix",
          language: "bash",
        },
        closingParagraphs: [
          "Review dependency updates before accepting them because they can introduce compatibility problems.",
          "GitHub also provides Dependabot alerts for supported repositories.",
        ],
      },
      {
        number: 7,
        title: "7. Integrate Quality Checks into CI/CD",
        animationId: "ci-quality-checks-animation",
        paragraphs: [
          "Example GitHub Actions workflow:",
        ],
        codeSnippet: {
          code: `name: Quality Check

on:
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 22

      - run: npm ci
      - run: npm test
      - run: npm audit --audit-level=high
      - run: npm run build`,
          language: "yaml",
        },
        postSnippetParagraphs: [
          "The pipeline stops when a required command fails.",
        ],
      },
    ],
  },

  // ============================================================
  // LESSON 5: Deployment Strategies & Release Management
  // ============================================================
  {
    id: "cicd-05",
    order: 5,
    number: "05",
    title: "05. Deployment Strategies & Release Management",
    shortTitle: "Deployment Strategies & Release Management",
    summary:
      "Understand development, staging, and production environments, compare rolling, blue-green, and canary deployments, and execute rollbacks and release management.",
    estimatedMinutes: 25,
    objectives: [
      "Understand development, staging, and production environments.",
      "Learn rolling, blue-green, and canary deployments.",
      "Understand rollback procedures.",
      "Learn release management practices.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Understand Deployment Environments",
        animationId: "deployment-environments-animation",
        paragraphs: [
          "Applications commonly use three environments:",
        ],
        listItems: [
          "Development: Used for implementing and testing features.",
          "Staging: Used to validate changes before release.",
          "Production: Used by actual application users.",
        ],
        closingParagraphs: [
          "Keeping environments separate reduces the risk of unfinished changes affecting production.",
        ],
      },
      {
        number: 2,
        title: "2. Understand Rolling Deployments",
        animationId: "rolling-deployment-animation",
        paragraphs: [
          "A rolling deployment gradually replaces old application instances with new ones.",
          "For example, an application running three instances can update them one at a time rather than stopping the entire application.",
          "In Kubernetes:",
        ],
        codeSnippet: {
          code: "kubectl set image deployment/web \\\n  web=example/web:v2",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Check the rollout:",
        ],
        secondSnippet: {
          code: "kubectl rollout status deployment/web",
          language: "bash",
        },
      },
      {
        number: 3,
        title: "3. Understand Blue-Green Deployments",
        animationId: "blue-green-deployment-animation",
        paragraphs: [
          "Blue-Green deployment uses two environments.",
        ],
        listItems: [
          "Blue: Current production version.",
          "Green: New application version.",
        ],
        closingParagraphs: [
          "The new version is deployed and tested in Green before traffic is switched from Blue.",
          "If problems occur, traffic can be redirected to Blue, provided the old version remains compatible.",
        ],
      },
      {
        number: 4,
        title: "4. Understand Canary Releases",
        animationId: "canary-release-animation",
        paragraphs: [
          "A canary release gradually introduces a new version to a small percentage of users.",
          "For example:",
        ],
        codeSnippet: {
          code: "95% traffic → Version 1\n5% traffic  → Version 2",
          language: "text",
        },
        postSnippetParagraphs: [
          "If the new version performs well, traffic is gradually increased. Otherwise, the release can be stopped or rolled back.",
        ],
      },
      {
        number: 5,
        title: "5. Understand Rollbacks and Release Management",
        animationId: "rollback-release-management-animation",
        paragraphs: [
          "A rollback restores a previously working application version.",
          "In Kubernetes:",
        ],
        codeSnippet: {
          code: "kubectl rollout undo deployment/web",
          language: "bash",
        },
        postSnippetParagraphs: [
          "View deployment history:",
        ],
        secondSnippet: {
          code: "kubectl rollout history deployment/web",
          language: "bash",
        },
        closingParagraphs: [
          "Release management also includes versioning, release notes, approvals, deployment scheduling, and rollback planning.",
          "Database changes and external dependencies must also be considered when rolling back an application.",
        ],
      },
      {
        number: 6,
        title: "6. Compare Deployment Strategies",
        animationId: "deployment-strategy-comparison-animation",
        paragraphs: [
          "Summary comparison of deployment strategies:",
        ],
        listItems: [
          "Rolling: Replaces instances gradually without downtime.",
          "Blue-Green: Switches traffic instantaneously between two distinct environments.",
          "Canary: Gradually exposes the new version to a fraction of users.",
        ],
        closingParagraphs: [
          "The appropriate strategy depends on infrastructure, application architecture, and acceptable deployment risk.",
        ],
      },
    ],
  },

  // ============================================================
  // LESSON 6: GitOps & Argo CD
  // ============================================================
  {
    id: "cicd-06",
    order: 6,
    number: "06",
    title: "06. GitOps & Argo CD",
    shortTitle: "GitOps & Argo CD",
    summary:
      "Understand GitOps and its principles, declarative configuration, Argo CD architecture, cluster installation, repository connection, drift detection, and rollbacks.",
    estimatedMinutes: 30,
    objectives: [
      "Understand GitOps and its principles.",
      "Learn declarative configuration and desired state.",
      "Understand Argo CD architecture.",
      "Deploy Kubernetes applications using Argo CD.",
      "Understand synchronization, drift detection, and rollbacks.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Introduction to GitOps",
        animationId: "gitops-introduction-animation",
        paragraphs: [
          "GitOps uses Git as the source of truth for application and infrastructure configuration.",
          "Instead of manually changing Kubernetes resources, teams store the desired configuration in Git and use automation to synchronize it with the cluster.",
          "This improves consistency, traceability, and collaboration.",
        ],
      },
      {
        number: 2,
        title: "2. Understand GitOps Principles and Architecture",
        animationId: "gitops-architecture-animation",
        paragraphs: [
          "GitOps follows four main principles:",
        ],
        listItems: [
          "Declarative configuration.",
          "Version-controlled configuration.",
          "Automated synchronization.",
          "Continuous monitoring.",
        ],
        secondSnippet: {
          code: `Developer
    |
    v
Git Repository
    |
    v
GitOps Controller
    |
    v
Kubernetes Cluster
    |
    v
Running Application`,
          language: "text",
        },
      },
      {
        number: 3,
        title: "3. Understand Declarative Configuration and Desired State",
        animationId: "declarative-configuration-animation",
        paragraphs: [
          "Declarative configuration describes the desired system state.",
          "Example Kubernetes Deployment:",
        ],
        codeSnippet: {
          code: `apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app

spec:
  replicas: 3

  selector:
    matchLabels:
      app: web-app

  template:
    metadata:
      labels:
        app: web-app

    spec:
      containers:
        - name: web
          image: nginx:latest
          ports:
            - containerPort: 80`,
          language: "yaml",
        },
        postSnippetParagraphs: [
          "This configuration declares that three replicas should run.",
          "Kubernetes works to maintain that desired state.",
        ],
      },
      {
        number: 4,
        title: "4. Introduction to Argo CD",
        animationId: "argocd-introduction-animation",
        paragraphs: [
          "Argo CD is a GitOps continuous delivery tool for Kubernetes.",
          "It monitors Git repositories and synchronizes application configuration with Kubernetes clusters.",
          "Important components include:",
        ],
        listItems: [
          "API Server: Provides the interface and API.",
          "Repository Server: Retrieves and processes Git configuration.",
          "Application Controller: Compares desired and actual states.",
          "User Interface: Allows application monitoring and management.",
        ],
        closingParagraphs: [
          "Argo CD supports Kubernetes manifests, Helm, and Kustomize.",
        ],
      },
      {
        number: 5,
        title: "5. Install Argo CD on Kubernetes",
        animationId: "argocd-installation-animation",
        paragraphs: [
          "Create a namespace:",
        ],
        codeSnippet: {
          code: "kubectl create namespace argocd",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Install Argo CD:",
        ],
        secondSnippet: {
          code: "kubectl apply -n argocd \\\n  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml",
          language: "bash",
        },
        middleParagraphs: [
          "Check the Pods:",
        ],
        thirdSnippet: {
          code: "kubectl get pods -n argocd",
          language: "bash",
        },
        afterThirdParagraphs: [
          "Access the API server locally:",
        ],
        fourthSnippet: {
          code: "kubectl port-forward svc/argocd-server \\\n  -n argocd 8080:443",
          language: "bash",
        },
        closingParagraphs: [
          "Open https://localhost:8080 to access the interface.",
        ],
      },
      {
        number: 6,
        title: "6. Connect a Git Repository to Argo CD",
        animationId: "argocd-repository-connection-animation",
        paragraphs: [
          "An Argo CD application can be configured using:",
        ],
        codeSnippet: {
          code: `argocd app create web-app \\
  --repo https://github.com/example/devops-manifests.git \\
  --path kubernetes/web \\
  --dest-server https://kubernetes.default.svc \\
  --dest-namespace default`,
          language: "bash",
        },
        postSnippetParagraphs: [
          "This connects a Git repository and identifies where the application should be deployed.",
        ],
      },
      {
        number: 7,
        title: "7. Understand Synchronization and Drift Detection",
        animationId: "argocd-sync-drift-animation",
        paragraphs: [
          "Argo CD compares Git configuration with the actual Kubernetes state.",
          "Common application states include:",
        ],
        listItems: [
          "Synced: Actual state matches Git.",
          "OutOfSync: Actual state differs from Git.",
          "Unknown: Synchronization state cannot be determined.",
        ],
        closingParagraphs: [
          "For example, if Git specifies three replicas but someone manually changes the cluster to five, Argo CD detects the difference.",
          "This is called configuration drift.",
        ],
      },
      {
        number: 8,
        title: "8. Understand Rollbacks in GitOps",
        animationId: "gitops-rollback-animation",
        paragraphs: [
          "GitOps makes deployments traceable through Git history.",
          "If a new configuration causes problems, revert the commit:",
        ],
        codeSnippet: {
          code: "git revert COMMIT_HASH\ngit push origin main",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Argo CD can then synchronize the cluster with the restored configuration.",
        ],
      },
    ],
  },

  // ============================================================
  // LESSON 7: Production CI/CD Pipeline Project
  // ============================================================
  {
    id: "cicd-07",
    order: 7,
    number: "07",
    title: "07. Production CI/CD Pipeline Project",
    shortTitle: "Production CI/CD Pipeline Project",
    summary:
      "Design an end-to-end CI/CD pipeline, integrate GitHub Actions with Docker, automate testing and image builds, publish to a registry, deploy to Kubernetes with GitOps, and troubleshoot pipeline failures.",
    estimatedMinutes: 35,
    objectives: [
      "Design an end-to-end CI/CD pipeline.",
      "Integrate GitHub Actions or Jenkins with Docker.",
      "Automate testing and image building.",
      "Publish images to a container registry.",
      "Deploy applications to Kubernetes.",
      "Integrate Argo CD and GitOps.",
      "Monitor and troubleshoot pipeline failures.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Design an End-to-End CI/CD Pipeline",
        animationId: "production-pipeline-architecture-animation",
        paragraphs: [
          "Consider a project containing a React frontend, Node.js backend, and MongoDB database.",
          "The objective is to automate testing, building, and deployment.",
          "A typical workflow:",
        ],
        codeSnippet: {
          code: `Developer
    |
    v
GitHub Repository
    |
    v
GitHub Actions / Jenkins
    |
    v
Automated Tests
    |
    v
Docker Image Build
    |
    v
Container Registry
    |
    v
GitOps Repository
    |
    v
Argo CD
    |
    v
Kubernetes Cluster`,
          language: "text",
        },
      },
      {
        number: 2,
        title: "2. Integrate GitHub Actions with Docker",
        animationId: "github-actions-docker-animation",
        paragraphs: [
          "A Dockerfile defines how an application image is built.",
          "Example Node.js Dockerfile:",
        ],
        codeSnippet: {
          code: `FROM node:22-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

EXPOSE 5000

CMD ["npm", "start"]`,
          language: "dockerfile",
        },
        postSnippetParagraphs: [
          "Build the image:",
        ],
        secondSnippet: {
          code: "docker build -t devops-backend:v1 .",
          language: "bash",
        },
        middleParagraphs: [
          "Run the container:",
        ],
        thirdSnippet: {
          code: "docker run -d \\\n  --name backend \\\n  -p 5000:5000 \\\n  devops-backend:v1",
          language: "bash",
        },
      },
      {
        number: 3,
        title: "3. Push Docker Images to a Container Registry",
        animationId: "container-registry-animation",
        paragraphs: [
          "A container registry stores and distributes Docker images.",
          "Common registries include Docker Hub, GitHub Container Registry, and Amazon ECR.",
          "Tag an image:",
        ],
        codeSnippet: {
          code: "docker tag devops-backend:v1 \\\n  username/devops-backend:v1",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Push it:",
        ],
        secondSnippet: {
          code: "docker push username/devops-backend:v1",
          language: "bash",
        },
        closingParagraphs: [
          "Production workflows should use securely configured credentials and unique image tags.",
        ],
      },
      {
        number: 4,
        title: "4. Automate Testing and Image Building",
        animationId: "automated-testing-image-build-animation",
        paragraphs: [
          "GitHub Actions can run tests before building an image.",
        ],
        codeSnippet: {
          code: `name: Application CI

on:
  push:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 22

      - run: npm ci
      - run: npm test
      - run: npm run build

      - name: Build Docker Image
        run: docker build -t backend:\${{ github.sha }} .`,
          language: "yaml",
        },
        postSnippetParagraphs: [
          "If testing fails, the pipeline stops before the image build.",
        ],
      },
      {
        number: 5,
        title: "5. Understand Kubernetes Deployment Integration",
        animationId: "kubernetes-deployment-integration-animation",
        paragraphs: [
          "Kubernetes uses Deployment manifests to manage application containers.",
          "Example:",
        ],
        codeSnippet: {
          code: `apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend

spec:
  replicas: 2

  selector:
    matchLabels:
      app: backend

  template:
    metadata:
      labels:
        app: backend

    spec:
      containers:
        - name: backend
          image: username/devops-backend:v1
          ports:
            - containerPort: 5000`,
          language: "yaml",
        },
        postSnippetParagraphs: [
          "Apply the configuration:",
        ],
        secondSnippet: {
          code: "kubectl apply -f deployment.yaml",
          language: "bash",
        },
        middleParagraphs: [
          "Verify the deployment:",
        ],
        thirdSnippet: {
          code: "kubectl get pods\nkubectl get deployments\nkubectl rollout status deployment/backend",
          language: "bash",
        },
      },
      {
        number: 6,
        title: "6. Integrate Kubernetes Deployment with GitOps",
        animationId: "kubernetes-gitops-integration-animation",
        paragraphs: [
          "After building and publishing an image, the pipeline can update the image reference in a GitOps repository.",
          "For example:",
        ],
        codeSnippet: {
          code: "image: username/devops-backend:v2",
          language: "yaml",
        },
        postSnippetParagraphs: [
          "The updated manifest is committed to Git.",
          "Argo CD detects the change and synchronizes the Kubernetes cluster.",
          "Responsibilities are separated:",
        ],
        listItems: [
          "GitHub Actions: Tests and builds images.",
          "Container Registry: Stores images.",
          "Git: Stores desired deployment configuration.",
          "Argo CD: Synchronizes configuration.",
          "Kubernetes: Runs the application.",
        ],
      },
      {
        number: 7,
        title: "7. Monitor and Troubleshoot Pipeline Failures",
        animationId: "pipeline-troubleshooting-animation",
        paragraphs: [
          "Common problems include failed tests, Docker build errors, registry authentication issues, and Kubernetes deployment failures.",
          "Useful commands:",
        ],
        codeSnippet: {
          code: `docker ps -a
docker images
kubectl get pods
kubectl get deployments
kubectl describe pod POD_NAME
kubectl logs POD_NAME
kubectl rollout status deployment/backend`,
          language: "bash",
        },
        postSnippetParagraphs: [
          "These commands help identify container, deployment, and application errors.",
        ],
      },
      {
        number: 8,
        title: "8. Complete the Production CI/CD Project",
        animationId: "production-cicd-final-project-animation",
        paragraphs: [
          "Build an end-to-end workflow demonstrating:",
        ],
        listItems: [
          "1. Source code hosted on GitHub.",
          "2. Automated testing using GitHub Actions or Jenkins.",
          "3. Docker image building and publishing.",
          "4. Kubernetes deployment configuration.",
          "5. GitOps integration using Argo CD.",
          "6. Application health and deployment verification.",
        ],
        closingParagraphs: [
          "The final objective is to understand how version control, automation, containers, testing, Kubernetes, and GitOps work together to deliver software reliably.",
        ],
      },
    ],
  },
];
