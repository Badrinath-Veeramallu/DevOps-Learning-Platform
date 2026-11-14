/**
 * DevOps Learning Platform — Final Quiz Question Bank
 * 20 questions per pathway.
 * Correct answers and explanations remain backend-only.
 */

const PATHWAY_PREREQUISITES = {
  git: ["git-01", "git-02", "git-03", "git-04", "git-05", "git-06", "git-07"],
  docker: ["docker-01", "docker-02", "docker-03", "docker-04", "docker-05", "docker-06", "docker-07"],
  linux: ["linux-01", "linux-02", "linux-03", "linux-04", "linux-05", "linux-06"],
  cicd: ["cicd-01", "cicd-02", "cicd-03", "cicd-04", "cicd-05", "cicd-06", "cicd-07"],
};

const PASSING_SCORE = 10;
const TOTAL_QUESTIONS_PER_QUIZ = 20;

const QUIZ_BANKS = {
  // ============================================================
  // GIT & GITHUB — 20 QUESTIONS
  // ============================================================
  git: [
    {
      id: "git-q01",
      moduleId: "git-01",
      question: "What is the primary purpose of Git?",
      options: [
        "To host websites",
        "To track changes in files and source code",
        "To manage databases",
        "To execute application code"
      ],
      correctOption: 1,
      explanation: "Git is a version control system that tracks changes in files and helps developers manage source code history."
    },
    {
      id: "git-q02",
      moduleId: "git-01",
      question: "What is the main difference between Git and GitHub?",
      options: [
        "Git is a programming language, while GitHub is an operating system",
        "Git and GitHub are exactly the same",
        "Git is a version control system, while GitHub hosts Git repositories online",
        "GitHub is used only for writing code"
      ],
      correctOption: 2,
      explanation: "Git manages version history locally, while GitHub provides an online platform for hosting and collaborating on Git repositories."
    },
    {
      id: "git-q03",
      moduleId: "git-02",
      question: "Which command initializes a new Git repository in the current directory?",
      options: [
        "git init",
        "git start",
        "git create",
        "git repository"
      ],
      correctOption: 0,
      explanation: "git init creates a new Git repository in the current directory."
    },
    {
      id: "git-q04",
      moduleId: "git-02",
      question: "What does the command git add file.txt do?",
      options: [
        "Uploads file.txt to GitHub",
        "Deletes file.txt from the repository",
        "Creates a commit immediately",
        "Stages file.txt for the next commit"
      ],
      correctOption: 3,
      explanation: "git add stages changes so they can be included in the next commit."
    },
    {
      id: "git-q05",
      moduleId: "git-02",
      question: "Which command displays changes that have not yet been staged?",
      options: [
        "git log",
        "git diff",
        "git push",
        "git clone"
      ],
      correctOption: 1,
      explanation: "git diff displays differences between the working directory and the staging area."
    },
    {
      id: "git-q06",
      moduleId: "git-02",
      question: "What is the purpose of git commit -m?",
      options: [
        "To download a repository",
        "To create a new branch",
        "To save staged changes as a commit with a message",
        "To upload changes to a remote repository"
      ],
      correctOption: 2,
      explanation: "git commit records staged changes in the repository history with a descriptive commit message."
    },
    {
      id: "git-q07",
      moduleId: "git-03",
      question: "What does the command git remote add origin URL do?",
      options: [
        "Connects the local repository to a remote repository named origin",
        "Creates a new local commit",
        "Deletes the current branch",
        "Downloads all repository files"
      ],
      correctOption: 0,
      explanation: "git remote add origin configures a remote repository and gives it the name origin."
    },
    {
      id: "git-q08",
      moduleId: "git-03",
      question: "Which command uploads the local main branch to origin and sets its upstream tracking branch?",
      options: [
        "git clone origin main",
        "git pull origin main",
        "git merge origin main",
        "git push -u origin main"
      ],
      correctOption: 3,
      explanation: "git push -u origin main uploads the main branch and establishes upstream tracking."
    },
    {
      id: "git-q09",
      moduleId: "git-03",
      question: "What does git pull generally do?",
      options: [
        "Deletes the remote repository",
        "Fetches remote changes and integrates them into the current branch",
        "Creates a new GitHub account",
        "Stages all local files"
      ],
      correctOption: 1,
      explanation: "git pull fetches changes from a remote repository and integrates them into the current branch."
    },
    {
      id: "git-q10",
      moduleId: "git-04",
      question: "Why do developers create feature branches?",
      options: [
        "To permanently replace the main branch",
        "To avoid using commits",
        "To work on changes independently without directly modifying the main branch",
        "To delete remote repositories"
      ],
      correctOption: 2,
      explanation: "Feature branches isolate development work and allow changes to be reviewed before merging."
    },
    {
      id: "git-q11",
      moduleId: "git-04",
      question: "Which command creates and switches to a new branch named feature-login?",
      options: [
        "git switch -c feature-login",
        "git branch delete feature-login",
        "git merge feature-login",
        "git push feature-login"
      ],
      correctOption: 0,
      explanation: "git switch -c creates a new branch and switches the working directory to it."
    },
    {
      id: "git-q12",
      moduleId: "git-04",
      question: "What do conflict markers such as <<<<<<< and ======= indicate?",
      options: [
        "A successful deployment",
        "A new remote repository",
        "A deleted Git branch",
        "Conflicting changes that require manual resolution"
      ],
      correctOption: 3,
      explanation: "Git uses conflict markers to identify sections where changes could not be automatically merged."
    },
    {
      id: "git-q13",
      moduleId: "git-05",
      question: "Which command displays the commit history in a compact, one-line format?",
      options: [
        "git status --short",
        "git log --oneline",
        "git diff --staged",
        "git remote -v"
      ],
      correctOption: 1,
      explanation: "git log --oneline displays each commit in a compact format."
    },
    {
      id: "git-q14",
      moduleId: "git-05",
      question: "Which command creates a new commit that reverses the changes introduced by an earlier commit?",
      options: [
        "git restore",
        "git amend",
        "git revert",
        "git clone"
      ],
      correctOption: 2,
      explanation: "git revert creates a new commit that reverses the changes from a specified earlier commit."
    },
    {
      id: "git-q15",
      moduleId: "git-05",
      question: "What does git restore --staged file.txt do?",
      options: [
        "Removes file.txt from the staging area while keeping its working-directory changes",
        "Deletes file.txt permanently",
        "Pushes file.txt to GitHub",
        "Creates a commit for file.txt"
      ],
      correctOption: 0,
      explanation: "git restore --staged unstages the file without discarding its working-directory modifications."
    },
    {
      id: "git-q16",
      moduleId: "git-06",
      question: "What is the main purpose of a Pull Request on GitHub?",
      options: [
        "To install Git",
        "To delete a repository",
        "To automatically publish an application",
        "To propose changes for review and merging into another branch"
      ],
      correctOption: 3,
      explanation: "A Pull Request allows collaborators to review, discuss, and approve proposed changes before merging."
    },
    {
      id: "git-q17",
      moduleId: "git-06",
      question: "What is the purpose of a .gitignore file?",
      options: [
        "To delete all existing commits",
        "To specify files and directories Git should ignore when untracked",
        "To configure GitHub account passwords",
        "To automatically merge branches"
      ],
      correctOption: 1,
      explanation: ".gitignore specifies intentionally untracked files and directories that Git should ignore."
    },
    {
      id: "git-q18",
      moduleId: "git-06",
      question: "A developer accidentally commits an API secret to a repository. What is the safest immediate response?",
      options: [
        "Rename the secret variable",
        "Add the secret to README.md",
        "Revoke or rotate the exposed secret and remove it from the repository as appropriate",
        "Ignore the issue because the repository is private"
      ],
      correctOption: 2,
      explanation: "An exposed credential should be considered compromised. Revoke or rotate it immediately; removing it from the latest commit alone does not invalidate it."
    },
    {
      id: "git-q19",
      moduleId: "git-07",
      question: "In a DevOps workflow, what commonly happens after a developer pushes code to a GitHub repository?",
      options: [
        "A configured CI workflow can automatically run builds and tests",
        "The operating system is automatically reinstalled",
        "Git deletes the source code",
        "The application is always deployed without any checks"
      ],
      correctOption: 0,
      explanation: "A configured CI pipeline can trigger automatically after a push to build the application and run automated tests."
    },
    {
      id: "git-q20",
      moduleId: "git-07",
      question: "What is the difference between Continuous Delivery and Continuous Deployment?",
      options: [
        "They both mean manually uploading source code",
        "Continuous Delivery does not use automated testing",
        "Continuous Deployment requires every developer to merge directly into main",
        "Continuous Delivery keeps software ready for release, while Continuous Deployment automatically releases qualifying changes to production"
      ],
      correctOption: 3,
      explanation: "Continuous Delivery prepares validated changes for release, while Continuous Deployment automatically deploys qualifying changes to production."
    }
  ],

  // ============================================================
  // DOCKER — 20 QUESTIONS
  // ============================================================
  docker: [
    {
      id: "docker-q01",
      moduleId: "docker-01",
      question: "What problem does containerization primarily help solve?",
      options: [
        "The need for version control",
        "Differences between development and deployment environments",
        "The need for network connectivity",
        "The need to write application code"
      ],
      correctOption: 1,
      explanation: "Containers package applications and their dependencies consistently, helping reduce environment-related differences."
    },
    {
      id: "docker-q02",
      moduleId: "docker-01",
      question: "How do containers generally differ from traditional virtual machines?",
      options: [
        "Every container requires a separate physical server",
        "Containers always include a complete guest operating system",
        "Containers generally share the host operating system kernel",
        "Virtual machines do not use operating systems"
      ],
      correctOption: 2,
      explanation: "Containers share the host kernel, while traditional virtual machines run separate guest operating systems."
    },
    {
      id: "docker-q03",
      moduleId: "docker-01",
      question: "Which command runs the Docker hello-world image?",
      options: [
        "docker run hello-world",
        "docker start hello-world",
        "docker create hello-world",
        "docker build hello-world"
      ],
      correctOption: 0,
      explanation: "docker run hello-world downloads the image if necessary and starts a container to verify Docker is working."
    },
    {
      id: "docker-q04",
      moduleId: "docker-02",
      question: "Which Docker component is responsible for managing containers, images, and other Docker objects?",
      options: [
        "Dockerfile",
        "Docker Hub",
        "Docker Compose YAML",
        "Docker daemon (dockerd)"
      ],
      correctOption: 3,
      explanation: "The Docker daemon, dockerd, manages Docker objects and handles Docker API requests."
    },
    {
      id: "docker-q05",
      moduleId: "docker-02",
      question: "What is the main difference between a Docker image and a Docker container?",
      options: [
        "An image is always running, while a container is a registry",
        "An image is a template used to create containers, while a container is an instance of an image",
        "An image stores only logs, while a container stores source code",
        "There is no difference"
      ],
      correctOption: 1,
      explanation: "An image is a packaged template, and a container is a created instance of that image."
    },
    {
      id: "docker-q06",
      moduleId: "docker-02",
      question: "What does docker run -d -p 8080:80 nginx do?",
      options: [
        "Deletes the nginx image",
        "Maps container port 8080 to host port 80",
        "Runs nginx in the background and maps host port 8080 to container port 80",
        "Builds a new nginx image"
      ],
      correctOption: 2,
      explanation: "-d runs the container in detached mode, and -p 8080:80 maps host port 8080 to container port 80."
    },
    {
      id: "docker-q07",
      moduleId: "docker-03",
      question: "Which Dockerfile instruction specifies the base image?",
      options: [
        "FROM",
        "COPY",
        "EXPOSE",
        "CMD"
      ],
      correctOption: 0,
      explanation: "FROM defines the base image on which the Docker image is built."
    },
    {
      id: "docker-q08",
      moduleId: "docker-03",
      question: "What does the COPY instruction do in a Dockerfile?",
      options: [
        "Starts a container",
        "Publishes an image to Docker Hub",
        "Deletes files from the host",
        "Copies files or directories from the build context into the image"
      ],
      correctOption: 3,
      explanation: "COPY transfers files from the build context into the image filesystem."
    },
    {
      id: "docker-q09",
      moduleId: "docker-03",
      question: "Which command builds a Docker image named my-node-app using the current directory as the build context?",
      options: [
        "docker run my-node-app",
        "docker build -t my-node-app .",
        "docker pull my-node-app",
        "docker images my-node-app ."
      ],
      correctOption: 1,
      explanation: "docker build -t assigns the image name, and the dot specifies the current directory as the build context."
    },
    {
      id: "docker-q10",
      moduleId: "docker-04",
      question: "What happens to data stored only in a container's writable layer when the container is removed?",
      options: [
        "It is automatically uploaded to Docker Hub",
        "It becomes a Docker image",
        "It is lost when the container is removed",
        "It is automatically copied to every other container"
      ],
      correctOption: 2,
      explanation: "The writable layer belongs to the container and is removed with it. Persistent storage should use volumes or bind mounts."
    },
    {
      id: "docker-q11",
      moduleId: "docker-04",
      question: "What is a Docker volume primarily used for?",
      options: [
        "Persisting data independently of a container's lifecycle",
        "Building Docker images",
        "Creating Dockerfiles",
        "Replacing the Docker daemon"
      ],
      correctOption: 0,
      explanation: "Volumes provide persistent storage that can exist independently of individual containers."
    },
    {
      id: "docker-q12",
      moduleId: "docker-04",
      question: "On a user-defined Docker bridge network, how can one container commonly reach another container?",
      options: [
        "Only by using its physical MAC address",
        "Only by using Docker Hub",
        "By restarting both containers",
        "By using the other container's name as its network hostname"
      ],
      correctOption: 3,
      explanation: "Containers on a user-defined bridge network can resolve one another by container name."
    },
    {
      id: "docker-q13",
      moduleId: "docker-05",
      question: "What is Docker Compose primarily designed for?",
      options: [
        "Managing Git commits",
        "Defining and running multi-container applications",
        "Replacing Linux package managers",
        "Editing source code"
      ],
      correctOption: 1,
      explanation: "Docker Compose uses a YAML configuration file to define and manage multi-container applications."
    },
    {
      id: "docker-q14",
      moduleId: "docker-05",
      question: "Which command starts the services defined in a Compose file in detached mode?",
      options: [
        "docker compose stop",
        "docker compose images",
        "docker compose up -d",
        "docker compose remove"
      ],
      correctOption: 2,
      explanation: "docker compose up -d creates and starts the configured services in the background."
    },
    {
      id: "docker-q15",
      moduleId: "docker-05",
      question: "In a Compose application, what hostname should an application commonly use to connect to a database service named db?",
      options: [
        "db",
        "localhost",
        "dockerhub",
        "127.0.0.1"
      ],
      correctOption: 0,
      explanation: "Compose services on the default network can discover each other using their service names."
    },
    {
      id: "docker-q16",
      moduleId: "docker-06",
      question: "What is Docker Hub?",
      options: [
        "A Linux text editor",
        "A Docker container runtime",
        "A Dockerfile instruction",
        "A registry service for storing and distributing container images"
      ],
      correctOption: 3,
      explanation: "Docker Hub is a registry where users can store, share, and retrieve container images."
    },
    {
      id: "docker-q17",
      moduleId: "docker-06",
      question: "Which command uploads a locally tagged image to a registry?",
      options: [
        "docker run",
        "docker push",
        "docker stop",
        "docker logs"
      ],
      correctOption: 1,
      explanation: "docker push uploads a locally available image to its configured registry repository."
    },
    {
      id: "docker-q18",
      moduleId: "docker-06",
      question: "Why should credentials not be written directly into a Dockerfile?",
      options: [
        "Dockerfiles cannot contain text",
        "Credentials automatically expire when an image is built",
        "They may become exposed through image layers, history, or shared source code",
        "Docker Hub does not support credentials"
      ],
      correctOption: 2,
      explanation: "Hardcoded credentials can be exposed through image metadata, layers, build history, or source repositories. Use appropriate secret-management mechanisms."
    },
    {
      id: "docker-q19",
      moduleId: "docker-07",
      question: "In a typical DevOps workflow, what role does a CI pipeline play after a code change?",
      options: [
        "It can automatically build the application and run tests",
        "It replaces the need for source control",
        "It permanently deletes old containers",
        "It automatically grants production access to every developer"
      ],
      correctOption: 0,
      explanation: "Continuous Integration automates tasks such as building and testing code changes."
    },
    {
      id: "docker-q20",
      moduleId: "docker-07",
      question: "What is an important reason to use multi-stage builds in Docker?",
      options: [
        "To make every image contain all development tools",
        "To avoid using a base image",
        "To store passwords in the final image",
        "To separate build tools from the final runtime image and reduce its size"
      ],
      correctOption: 3,
      explanation: "Multi-stage builds allow build dependencies and tools to be excluded from the final runtime image, helping reduce image size and attack surface."
    }
  ],

  // ============================================================
  // LINUX ESSENTIALS — 20 QUESTIONS
  // ============================================================
  linux: [
    {
      id: "linux-q01",
      moduleId: "linux-01",
      question: "Which Linux directory is the top-level directory of the filesystem hierarchy?",
      options: [
        "/home",
        "/root",
        "/",
        "/etc"
      ],
      correctOption: 2,
      explanation: "The root directory / is the top-level directory from which the Linux filesystem hierarchy begins."
    },
    {
      id: "linux-q02",
      moduleId: "linux-01",
      question: "Which command displays the current working directory?",
      options: [
        "pwd",
        "ls",
        "cd",
        "whoami"
      ],
      correctOption: 0,
      explanation: "pwd prints the absolute path of the current working directory."
    },
    {
      id: "linux-q03",
      moduleId: "linux-01",
      question: "What does the command ls -la display?",
      options: [
        "Only running processes",
        "Only directory names",
        "Only files larger than 1 MB",
        "Detailed directory contents, including hidden entries"
      ],
      correctOption: 3,
      explanation: "The -l option displays detailed information, while -a includes hidden entries."
    },
    {
      id: "linux-q04",
      moduleId: "linux-01",
      question: "Which command recursively searches for the word error inside files under the current directory?",
      options: [
        "pwd error",
        "grep -r error .",
        "touch error",
        "mkdir -p error"
      ],
      correctOption: 1,
      explanation: "grep -r searches recursively through files in the specified directory."
    },
    {
      id: "linux-q05",
      moduleId: "linux-02",
      question: "What do the Linux permission values 4, 2, and 1 represent?",
      options: [
        "Read, write, and execute respectively",
        "Write, execute, and read respectively",
        "Read, execute, and write respectively",
        "Owner, group, and others respectively"
      ],
      correctOption: 0,
      explanation: "In numeric permissions, read is 4, write is 2, and execute is 1."
    },
    {
      id: "linux-q06",
      moduleId: "linux-02",
      question: "What permissions does chmod 755 script.sh assign?",
      options: [
        "Everyone gets read and write permissions",
        "Only the owner can execute the file",
        "Owner gets read, write, and execute; group and others get read and execute",
        "Owner gets read only; everyone else gets write permission"
      ],
      correctOption: 2,
      explanation: "7 means read, write, and execute; 5 means read and execute. Therefore, 755 assigns 7 to the owner and 5 to group and others."
    },
    {
      id: "linux-q07",
      moduleId: "linux-02",
      question: "Which command changes the ownership of a file?",
      options: [
        "chmod",
        "chown",
        "whoami",
        "id"
      ],
      correctOption: 1,
      explanation: "chown changes the owner and optionally the group associated with a file or directory."
    },
    {
      id: "linux-q08",
      moduleId: "linux-03",
      question: "Which command displays running processes with detailed information?",
      options: [
        "systemctl start",
        "journalctl -f",
        "pwd",
        "ps aux"
      ],
      correctOption: 3,
      explanation: "ps aux displays a detailed snapshot of running processes."
    },
    {
      id: "linux-q09",
      moduleId: "linux-03",
      question: "What does PID represent in Linux process management?",
      options: [
        "Process Identifier",
        "Package Installation Directory",
        "Primary Internet Domain",
        "Permission Information Data"
      ],
      correctOption: 0,
      explanation: "PID is the unique Process Identifier assigned to a running process."
    },
    {
      id: "linux-q10",
      moduleId: "linux-03",
      question: "Which command follows a systemd service's logs in real time?",
      options: [
        "systemctl enable nginx",
        "ps aux",
        "journalctl -u nginx -f",
        "chmod 755 nginx"
      ],
      correctOption: 2,
      explanation: "journalctl -u filters logs for a particular unit, while -f follows new log entries."
    },
    {
      id: "linux-q11",
      moduleId: "linux-04",
      question: "Which port is commonly used by SSH?",
      options: [
        "80",
        "22",
        "443",
        "3306"
      ],
      correctOption: 1,
      explanation: "SSH commonly uses TCP port 22 for secure remote access."
    },
    {
      id: "linux-q12",
      moduleId: "linux-04",
      question: "What is the purpose of the command curl -I URL?",
      options: [
        "To delete a remote website",
        "To create an SSH key",
        "To display local IP addresses only",
        "To request and display HTTP response headers"
      ],
      correctOption: 3,
      explanation: "curl -I sends a request for response headers, allowing inspection of HTTP metadata."
    },
    {
      id: "linux-q13",
      moduleId: "linux-04",
      question: "Which command generates an Ed25519 SSH key pair?",
      options: [
        "ssh-keygen -t ed25519",
        "ssh-copy-id -t ed25519",
        "ping -c 4 ed25519",
        "curl -I ed25519"
      ],
      correctOption: 0,
      explanation: "ssh-keygen -t ed25519 generates an SSH key pair using the Ed25519 algorithm."
    },
    {
      id: "linux-q14",
      moduleId: "linux-05",
      question: "What does apt update do on a Debian-based Linux system?",
      options: [
        "Immediately upgrades every installed package",
        "Removes outdated packages",
        "Refreshes the local package index information",
        "Changes file ownership"
      ],
      correctOption: 2,
      explanation: "apt update refreshes package information from configured repositories. It does not itself upgrade installed packages."
    },
    {
      id: "linux-q15",
      moduleId: "linux-05",
      question: "In Nano, which keyboard shortcut saves the current file?",
      options: [
        "Ctrl + X",
        "Ctrl + O",
        "Ctrl + C",
        "Ctrl + Z"
      ],
      correctOption: 1,
      explanation: "Ctrl + O writes the current file in Nano. Ctrl + X exits the editor."
    },
    {
      id: "linux-q16",
      moduleId: "linux-05",
      question: "In Vim, what does the command :wq do?",
      options: [
        "Deletes the current file",
        "Enters insert mode",
        "Quits without saving",
        "Saves the file and quits"
      ],
      correctOption: 3,
      explanation: ":wq writes the changes to the file and then quits Vim."
    },
    {
      id: "linux-q17",
      moduleId: "linux-06",
      question: "What is the purpose of the shebang line #!/bin/bash at the beginning of a script?",
      options: [
        "It identifies the interpreter used to execute the script",
        "It grants root permissions automatically",
        "It installs Bash",
        "It creates a backup directory"
      ],
      correctOption: 0,
      explanation: "The shebang identifies the interpreter that should execute the script."
    },
    {
      id: "linux-q18",
      moduleId: "linux-06",
      question: "Which command makes hello.sh executable?",
      options: [
        "chown hello.sh",
        "mkdir hello.sh",
        "chmod +x hello.sh",
        "touch +x hello.sh"
      ],
      correctOption: 2,
      explanation: "chmod +x adds execute permission to the script."
    },
    {
      id: "linux-q19",
      moduleId: "linux-06",
      question: "Inside a Bash script, what does $1 represent?",
      options: [
        "The script's exit status",
        "The first positional command-line argument",
        "The current working directory",
        "The process identifier"
      ],
      correctOption: 1,
      explanation: "$1 refers to the first positional argument passed to a Bash script."
    },
    {
      id: "linux-q20",
      moduleId: "linux-06",
      question: "In a backup script, what is the purpose of the command cp -r source destination?",
      options: [
        "To rename the source directory",
        "To check whether a directory exists",
        "To display the current date",
        "To copy a directory and its contents recursively"
      ],
      correctOption: 3,
      explanation: "cp -r recursively copies a directory and its contents to the specified destination."
    }
  ],

  // ============================================================
  // CI/CD & GITOPS DELIVERY — 20 QUESTIONS
  // ============================================================
  cicd: [
    {
      id: "cicd-q01",
      moduleId: "cicd-01",
      question: "What is the primary goal of Continuous Integration (CI)?",
      options: [
        "Automating server hardware provisioning",
        "Frequently integrating and automatically verifying code changes into a shared repository",
        "Directly modifying production database schemas manually",
        "Eliminating the need for automated testing"
      ],
      correctOption: 1,
      explanation: "Continuous Integration focuses on frequently merging code changes into a central repository and automatically validating them with builds and tests."
    },
    {
      id: "cicd-q02",
      moduleId: "cicd-01",
      question: "What is the key difference between Continuous Delivery and Continuous Deployment?",
      options: [
        "Continuous Delivery requires manual approval before release to production, while Continuous Deployment releases automatically",
        "Continuous Delivery compiles code, while Continuous Deployment does not",
        "Continuous Delivery only supports Jenkins, while Continuous Deployment only supports GitHub Actions",
        "Continuous Deployment does not run automated tests"
      ],
      correctOption: 0,
      explanation: "Continuous Delivery keeps every release candidate production-ready but requires manual promotion to deploy to production. Continuous Deployment automatically deploys passing builds directly."
    },
    {
      id: "cicd-q03",
      moduleId: "cicd-01",
      question: "In a standard CI/CD pipeline, which stage typically precedes artifact packaging?",
      options: [
        "Production deployment",
        "Automated testing and quality verification",
        "Production traffic monitoring",
        "Domain DNS configuration"
      ],
      correctOption: 1,
      explanation: "Automated testing and code quality checks run before packaging to ensure only validated code is bundled into deployable artifacts or container images."
    },
    {
      id: "cicd-q04",
      moduleId: "cicd-02",
      question: "In Jenkins architecture, what is the primary role of an Agent node?",
      options: [
        "Managing user accounts and hosting the Web UI",
        "Executing the actual build, test, and deployment workloads dispatched by the controller",
        "Storing primary Git repository commit histories",
        "Monitoring cloud hosting invoices"
      ],
      correctOption: 1,
      explanation: "The Jenkins Controller manages jobs, UI, and scheduling, while Agent nodes execute the assigned pipeline stages and build steps."
    },
    {
      id: "cicd-q05",
      moduleId: "cicd-02",
      question: "Which top-level section is required in a Declarative Jenkinsfile to specify where jobs execute?",
      options: [
        "environment",
        "agent",
        "parameters",
        "triggers"
      ],
      correctOption: 1,
      explanation: "The 'agent' directive in Declarative Pipelines specifies where the pipeline or specific stage will execute (e.g. agent any, agent { docker ... })."
    },
    {
      id: "cicd-q06",
      moduleId: "cicd-02",
      question: "In a Declarative Jenkinsfile, what block contains the sequential stages of the pipeline?",
      options: [
        "stages",
        "steps",
        "post",
        "matrix"
      ],
      correctOption: 0,
      explanation: "The 'stages' block encloses individual 'stage' definitions, which in turn contain the executable 'steps'."
    },
    {
      id: "cicd-q07",
      moduleId: "cicd-03",
      question: "In GitHub Actions, in which directory must workflow YAML files be stored within a repository?",
      options: [
        "scripts/actions",
        ".github/workflows",
        ".ci/github",
        "config/pipelines"
      ],
      correctOption: 1,
      explanation: "GitHub Actions detects and executes workflow definitions located in the '.github/workflows' directory of the repository."
    },
    {
      id: "cicd-q08",
      moduleId: "cicd-03",
      question: "In a GitHub Actions workflow, which keyword specifies the triggers that run the workflow (such as push or pull_request)?",
      options: [
        "when",
        "on",
        "triggers",
        "listen"
      ],
      correctOption: 1,
      explanation: "The 'on' keyword specifies which repository events (e.g., push, pull_request, workflow_dispatch) trigger workflow execution."
    },
    {
      id: "cicd-q09",
      moduleId: "cicd-03",
      question: "How should sensitive credentials (such as API keys and Docker tokens) be accessed inside GitHub Actions?",
      options: [
        "Hardcoded directly in the YAML file",
        "Committed into Git in a plain text secrets.env file",
        "Referenced using the ${{ secrets.SECRET_NAME }} context from GitHub Repository Secrets",
        "Passed as public repository query parameters"
      ],
      correctOption: 2,
      explanation: "GitHub Actions provides encrypted repository secrets accessible securely via the ${{ secrets.SECRET_NAME }} expression."
    },
    {
      id: "cicd-q10",
      moduleId: "cicd-04",
      question: "According to the Test Pyramid, which type of tests should form the largest and fastest base of your test suite?",
      options: [
        "End-to-End (E2E) browser UI tests",
        "Unit tests",
        "Manual exploratory regression tests",
        "Stress load tests"
      ],
      correctOption: 1,
      explanation: "Unit tests are isolated, fast, and lightweight, providing the broadest foundation and quickest feedback in the testing pyramid."
    },
    {
      id: "cicd-q11",
      moduleId: "cicd-04",
      question: "What is the purpose of a Quality Gate in tools like SonarQube during a CI pipeline?",
      options: [
        "To format HTML and CSS stylesheets",
        "To block the pipeline and fail the build if code fails required thresholds for coverage, security vulnerabilities, or code smells",
        "To reboot the CI runner whenever a commit arrives",
        "To assign Jira tickets to developers"
      ],
      correctOption: 1,
      explanation: "Quality Gates enforce measurable thresholds (such as minimum code coverage and zero critical vulnerabilities); failing stops pipeline progression."
    },
    {
      id: "cicd-q12",
      moduleId: "cicd-04",
      question: "What is Static Application Security Testing (SAST) in a CI/CD pipeline?",
      options: [
        "Analyzing source code or compiled binaries for known security vulnerabilities without executing the program",
        "Simulating a live penetration attack against an active production server",
        "Verifying network firewall port configurations",
        "Tracking application memory usage under continuous user traffic"
      ],
      correctOption: 0,
      explanation: "SAST scans non-running source code early in the pipeline to detect vulnerabilities, security anti-patterns, and insecure dependencies."
    },
    {
      id: "cicd-q13",
      moduleId: "cicd-05",
      question: "Why is using specific Git commit SHA or semantic version tags preferred over using the ':latest' tag for container images in production pipelines?",
      options: [
        "':latest' takes longer to download from the container registry",
        "Immutable, unique tags guarantee reproducibility, traceability, and safe rollbacks",
        "Docker engines refuse to pull images tagged with ':latest'",
        "Git repositories do not support tags"
      ],
      correctOption: 1,
      explanation: "Commit SHAs and SemVer tags provide immutable versions, ensuring deployments can be traced back to exact source revisions and reliably rolled back."
    },
    {
      id: "cicd-q14",
      moduleId: "cicd-05",
      question: "Which deployment strategy maintains two identical production environments and shifts all live traffic instantly using a router or load balancer?",
      options: [
        "Recreate deployment",
        "Blue/Green deployment",
        "Shadow mirroring deployment",
        "In-place deployment"
      ],
      correctOption: 1,
      explanation: "Blue/Green deployment maintains current (Blue) and new (Green) versions in parallel, switching traffic instantly with near-zero downtime."
    },
    {
      id: "cicd-q15",
      moduleId: "cicd-05",
      question: "How does a Canary deployment reduce release risk?",
      options: [
        "By testing the code only on a local developer laptop",
        "By releasing the update to a small subset of real users first and observing metrics before expanding to the rest of the fleet",
        "By shutting down the entire infrastructure before deploying",
        "By skipping unit and integration tests"
      ],
      correctOption: 1,
      explanation: "Canary releases route a small fraction of live traffic to the new version to verify stability and metrics before full rollout."
    },
    {
      id: "cicd-q16",
      moduleId: "cicd-06",
      question: "What is the core philosophy of GitOps?",
      options: [
        "Deploying applications manually using SSH connections",
        "Using Git repositories as the single source of truth for declarative infrastructure and application state",
        "Replacing Git with container registries",
        "Running builds without source control"
      ],
      correctOption: 1,
      explanation: "GitOps uses Git repositories as the authoritative single source of truth for declarative system specifications and deployment configs."
    },
    {
      id: "cicd-q17",
      moduleId: "cicd-06",
      question: "What is the role of an automated reconciliation loop in GitOps controllers like Argo CD?",
      options: [
        "Periodically comparing the desired state in Git with the live cluster state and automatically synchronizing or alerting on drift",
        "Sending daily email newsletters to customers",
        "Compiling Java bytecode into native machine code",
        "Purging all Docker containers every hour"
      ],
      correctOption: 0,
      explanation: "Argo CD continuously monitors live Kubernetes clusters against target Git manifests, correcting configuration drift to maintain the desired state."
    },
    {
      id: "cicd-q18",
      moduleId: "cicd-06",
      question: "Why does GitOps enhance security compared to traditional CI-driven push deployments?",
      options: [
        "It removes the need to encrypt database passwords",
        "The deployment agent runs inside the cluster pulling from Git, avoiding the need to expose cluster API credentials to external CI runners",
        "It disables HTTPS encryption",
        "It executes code without user permissions"
      ],
      correctOption: 1,
      explanation: "A pull-based GitOps operator lives inside the cluster and pulls manifests from Git, so external CI runners do not require administrative cluster access."
    },
    {
      id: "cicd-q19",
      moduleId: "cicd-07",
      question: "In an end-to-end production GitOps pipeline, what action completes the CI phase and triggers deployment?",
      options: [
        "Manually running kubectl apply on a production bastion host",
        "Building and pushing the versioned container image, then updating the image tag in the GitOps deployment repository",
        "Deleting old Docker images from the local machine",
        "Rebooting the cluster master node"
      ],
      correctOption: 1,
      explanation: "CI builds and tests the app, publishes a tagged container image, and commits the updated tag to the GitOps config repository, triggering Argo CD's sync."
    },
    {
      id: "cicd-q20",
      moduleId: "cicd-07",
      question: "In a production CI/CD setup, how is an instant rollback achieved when an issue is detected after a GitOps deployment?",
      options: [
        "Reverting the commit in the GitOps repository or selecting the previous healthy release in Argo CD",
        "Stopping all server power supplies",
        "Re-writing the source code from scratch",
        "Reinstalling the Kubernetes operating system"
      ],
      correctOption: 0,
      explanation: "Because Git holds the complete history of declarative manifests, rolling back is as fast and safe as reverting the Git commit or rolling back to the prior revision in Argo CD."
    }
  ]
};

/**
 * Returns sanitized questions for client consumption.
 * Correct answers and explanations are never exposed here.
 */
function getSanitizedQuestions(pathwayId) {
  const norm = (pathwayId || "").toLowerCase();
  const bank = QUIZ_BANKS[norm];

  if (!bank) return null;

  return bank.map((q) => ({
    id: q.id,
    question: q.question,
    options: [...q.options],
  }));
}

/**
 * Evaluates submitted answers against the secure backend question bank.
 *
 * userAnswers format:
 * {
 *   "git-q01": 1,
 *   "git-q02": 2
 * }
 */
function evaluateQuiz(pathwayId, userAnswers = {}) {
  const norm = (pathwayId || "").toLowerCase();
  const bank = QUIZ_BANKS[norm];

  if (!bank) {
    throw new Error(`Unsupported pathway: ${pathwayId}`);
  }

  let score = 0;

  const review = bank.map((q) => {
    const selected = userAnswers[q.id];

    const hasSelected =
      typeof selected === "number" &&
      Number.isInteger(selected) &&
      selected >= 0 &&
      selected < q.options.length;

    const isCorrect = hasSelected && selected === q.correctOption;

    if (isCorrect) {
      score += 1;
    }

    return {
      id: q.id,
      question: q.question,
      options: [...q.options],
      selectedOption: hasSelected ? selected : null,
      correctOption: q.correctOption,
      isCorrect,
      isAttempted: hasSelected,
      explanation: q.explanation,
    };
  });

  const totalQuestions = bank.length;
  const percentage = Math.round((score / totalQuestions) * 100);
  const passed = score >= PASSING_SCORE;

  return {
    score,
    totalQuestions,
    percentage,
    passed,
    passingScore: PASSING_SCORE,
    review,
  };
}

module.exports = {
  PATHWAY_PREREQUISITES,
  PASSING_SCORE,
  TOTAL_QUESTIONS_PER_QUIZ,
  QUIZ_BANKS,
  getSanitizedQuestions,
  evaluateQuiz,
};
