/**
 * DevOps Learning Platform — Docker & Container Engineering Curriculum
 * Single Source of Truth based on provided final curriculum.
 * Exact content, objectives, commands, and code examples preserved.
 */

export const dockerCurriculum = [
  {
    id: "docker-01",
    order: 1,
    number: "01",
    title: "01. Introduction to Docker & Containerization",
    shortTitle: "Introduction to Docker & Containerization",
    summary:
      "Understand containerization and why it is used, identify common problems Docker solves, differentiate between virtual machines and containers, and install Docker.",
    estimatedMinutes: 20,
    objectives: [
      "Understand containerization and why it is used.",
      "Identify common problems Docker solves.",
      "Differentiate between virtual machines and containers.",
      "Understand the role of Docker in modern development.",
      "Install Docker and verify the setup.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Why Do We Need Containerization?",
        paragraphs: [
          "You've developed a web application using React and Node.js. Everything works correctly on your computer, but when another developer clones the project, they encounter errors because their Node.js version, dependencies, or system configuration is different.",
          "The same problem can occur when moving an application from development to production. An application that works on one machine may behave differently on another.",
          "This is commonly known as the it works on my machine problem.",
          "Containerization provides a solution by packaging an application along with its required dependencies into an isolated environment called a container. This allows the application to run consistently across different environments.",
        ],
      },
      {
        number: 2,
        title: "2. What is Docker?",
        paragraphs: [
          "Docker is an open-source platform used to build, package, distribute, and run applications inside containers.",
          "A Docker container includes the application and the dependencies required to run it. Developers can package an application once and use the same environment during development, testing, and production.",
          "Docker also provides tools to manage images, containers, networks, and storage.",
        ],
      },
      {
        number: 3,
        title: "3. Virtual Machines vs Containers",
        paragraphs: [
          "Virtual machines provide isolated environments by running separate guest operating systems on top of physical hardware through a hypervisor.",
          "Containers work differently. They isolate applications and their dependencies while sharing the host operating system's kernel.",
          "As a result, containers generally require fewer resources and start faster than virtual machines.",
          "Virtual machines are useful when separate operating systems are required, while containers are particularly useful for portable applications and efficient resource utilization.",
        ],
      },
      {
        number: 4,
        title: "4. Installing and Verifying Docker",
        paragraphs: [
          "Download Docker Desktop from the official website:",
        ],
        link: {
          url: "https://www.docker.com/products/docker-desktop/",
          text: "https://www.docker.com/products/docker-desktop/",
        },
        afterLinkParagraphs: [
          "Install the version suitable for your operating system and start Docker Desktop.",
          "Open the terminal and verify the installation:",
        ],
        codeSnippet: {
          code: "docker --version\ndocker info",
          language: "bash",
        },
        postSnippetParagraphs: [
          "To confirm that Docker can run containers, execute:",
        ],
        secondSnippet: {
          code: "docker run hello-world",
          language: "bash",
        },
        closingParagraphs: [
          "Docker downloads the test image if necessary, creates a container, and displays a confirmation message when successful.",
        ],
      },
    ],
  },
  {
    id: "docker-02",
    order: 2,
    number: "02",
    title: "02. Docker Architecture, Images & Containers",
    shortTitle: "Docker Architecture, Images & Containers",
    summary:
      "Understand Docker's client-server architecture, client vs daemon, image templates, container instances, pulling images, and managing container lifecycles.",
    estimatedMinutes: 25,
    objectives: [
      "Understand Docker's client-server architecture.",
      "Identify the responsibilities of Docker Client and Docker Daemon.",
      "Understand Docker Images and Containers.",
      "Learn how Docker retrieves images from registries.",
      "Create and manage containers using Docker commands.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Understand Docker Architecture",
        paragraphs: [
          "Docker follows a client-server architecture consisting of several components.",
          "The Docker Client is the interface through which developers execute commands. It communicates with the Docker Daemon (dockerd), which runs in the background and manages images, containers, networks, and volumes.",
          "The Docker Host is the machine where the Docker Daemon manages these resources. A Docker Registry stores and distributes images, with Docker Hub being one of the commonly used registries.",
          "For example, when you execute:",
        ],
        codeSnippet: {
          code: "docker run nginx",
          language: "bash",
        },
        postSnippetParagraphs: [
          "The Docker Client sends a request to the Daemon. The Daemon checks whether the Nginx image exists locally. If it does not, Docker downloads it from a registry and creates a container.",
        ],
      },
      {
        number: 2,
        title: "2. Understand Docker Images",
        paragraphs: [
          "A Docker Image is a read-only template used to create containers.",
          "It contains the application code, runtime, libraries, and dependencies required to run an application.",
          "Images are built using multiple layers, allowing Docker to reuse existing layers and avoid repeating unnecessary work during image builds.",
          "For example, developers can use an existing Node.js image instead of manually installing Node.js every time they create an application environment.",
        ],
      },
      {
        number: 3,
        title: "3. Understand Docker Containers",
        paragraphs: [
          "A Docker Container is an instance created from a Docker Image.",
          "While an image acts as the template, a container is the environment in which the application actually runs.",
          "Multiple containers can be created from the same image, and each container operates independently with its own writable layer.",
          "Containers can be started, stopped, restarted, and removed without modifying the original image.",
        ],
      },
      {
        number: 4,
        title: "4. Download Images and Run Containers",
        paragraphs: ["To download an Nginx image:"],
        codeSnippet: {
          code: "docker pull nginx",
          language: "bash",
        },
        postSnippetParagraphs: ["To view locally available images:"],
        secondSnippet: {
          code: "docker images",
          language: "bash",
        },
        middleParagraphs: ["Create and run an Nginx container:"],
        thirdSnippet: {
          code: "docker run -d -p 8080:80 --name my-nginx nginx",
          language: "bash",
        },
        closingParagraphs: [
          "Here, -d runs the container in the background, while -p maps host port 8080 to container port 80.",
          "Open http://localhost:8080 in your browser to access the Nginx welcome page.",
        ],
      },
      {
        number: 5,
        title: "5. Manage Docker Containers",
        paragraphs: [
          "Docker provides commands to monitor and manage containers:",
        ],
        codeSnippet: {
          code: "# View running containers\ndocker ps\n\n# View all containers\ndocker ps -a\n\n# Stop a container\ndocker stop my-nginx\n\n# Start a container\ndocker start my-nginx\n\n# View container logs\ndocker logs my-nginx\n\n# Remove a stopped container\ndocker rm my-nginx",
          language: "bash",
        },
        closingParagraphs: [
          "These commands help developers monitor application execution and manage containers throughout development.",
        ],
      },
    ],
  },
  {
    id: "docker-03",
    order: 3,
    number: "03",
    title: "03. Dockerfile & Building Custom Images",
    shortTitle: "Dockerfile & Building Custom Images",
    summary:
      "Master Dockerfile instructions, define a Node.js image environment, build and run custom images, and leverage layer caching and version tags.",
    estimatedMinutes: 25,
    objectives: [
      "Understand the purpose of a Dockerfile.",
      "Learn commonly used Dockerfile instructions.",
      "Create a Dockerfile for a Node.js application.",
      "Build and run custom Docker Images.",
      "Understand image layers and build caching.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Why Do We Need a Dockerfile?",
        paragraphs: [
          "A Node.js application requires a particular runtime version, dependencies, and configuration before it can run.",
          "Manually preparing this environment every time the application needs to be deployed can be repetitive and difficult to maintain.",
          "A Dockerfile solves this problem by defining the application environment and image-building instructions in a single text file.",
          "Docker uses these instructions to build an image that can be reused across different environments.",
        ],
      },
      {
        number: 2,
        title: "2. Understand Common Dockerfile Instructions",
        paragraphs: [
          "A Dockerfile contains instructions that describe how an image should be created.",
          "Some commonly used instructions include:",
        ],
        listItems: [
          "FROM: Specifies the base image.",
          "WORKDIR: Sets the working directory inside the image.",
          "COPY: Copies application files into the image.",
          "RUN: Executes commands during image building.",
          "EXPOSE: Documents the port used by the application.",
          "ENV: Defines environment variables.",
          "CMD: Specifies the default command executed when a container starts.",
        ],
        closingParagraphs: [
          "These instructions help developers define the environment required to run their applications.",
        ],
      },
      {
        number: 3,
        title: "3. Create a Dockerfile for a Node.js Application",
        paragraphs: [
          "Consider a project with the following structure:",
        ],
        codeSnippet: {
          code: "node-app/\n├── server.js\n├── package.json\n├── package-lock.json\n└── Dockerfile",
          language: "text",
        },
        postSnippetParagraphs: ["Create a file named Dockerfile:"],
        secondSnippet: {
          code: "FROM node:20\n\nWORKDIR /app\n\nCOPY package*.json ./\n\nRUN npm install\n\nCOPY . .\n\nEXPOSE 3000\n\nCMD [\"npm\", \"start\"]",
          language: "dockerfile",
        },
        closingParagraphs: [
          "Docker uses Node.js as the base image, creates a working directory, installs dependencies, and copies the application files.",
          "The final instruction defines the command used to start the application.",
        ],
      },
      {
        number: 4,
        title: "4. Build and Run a Custom Image",
        paragraphs: [
          "Open the terminal in the project directory and execute:",
        ],
        codeSnippet: {
          code: "docker build -t my-node-app .",
          language: "bash",
        },
        postSnippetParagraphs: [
          "The -t option assigns a name to the image, while . specifies the current directory as the build context.",
          "To run a container using the newly created image:",
        ],
        secondSnippet: {
          code: "docker run -d -p 3000:3000 --name my-app my-node-app",
          language: "bash",
        },
        closingParagraphs: [
          "If the application listens on port 3000, it can now be accessed through http://localhost:3000.",
        ],
      },
      {
        number: 5,
        title: "5. Understand Image Layers and Build Caching",
        paragraphs: [
          "Docker builds images using layers generated by Dockerfile instructions.",
          "When an instruction and its dependencies have not changed, Docker can reuse the previously generated layer. This is known as build caching.",
          "For this reason, copying package files and installing dependencies before copying frequently changing source files can improve build performance.",
          "Docker images can also use tags to identify different versions:",
        ],
        codeSnippet: {
          code: "docker build -t my-node-app:v1 .\ndocker build -t my-node-app:v2 .",
          language: "bash",
        },
        closingParagraphs: [
          "Version tags help developers manage and identify different application releases.",
        ],
      },
    ],
  },
  {
    id: "docker-04",
    order: 4,
    number: "04",
    title: "04. Docker Storage, Volumes & Networking",
    shortTitle: "Docker Storage, Volumes & Networking",
    summary:
      "Understand persistent storage, Docker-managed volumes, host bind mounts, networking drivers, and inter-container communication.",
    estimatedMinutes: 25,
    objectives: [
      "Understand how Docker handles container data.",
      "Learn about persistent storage.",
      "Differentiate between volumes and bind mounts.",
      "Understand Docker networking.",
      "Create networks and connect containers.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Why Do We Need Persistent Storage?",
        paragraphs: [
          "Containers are designed to be replaceable. Data stored only in a container's writable layer is lost when that container is removed.",
          "For example, a database running inside a container may store important user records. Removing the container without preserving its data can result in data loss.",
          "Docker provides volumes and bind mounts to store data outside the container's writable layer.",
        ],
      },
      {
        number: 2,
        title: "2. Understand Docker Volumes",
        paragraphs: [
          "A Docker Volume is a storage mechanism managed by Docker. It allows application data to remain available independently of a container's lifecycle.",
          "Create a volume:",
        ],
        codeSnippet: {
          code: "docker volume create mydata",
          language: "bash",
        },
        postSnippetParagraphs: ["View available volumes:"],
        secondSnippet: {
          code: "docker volume ls",
          language: "bash",
        },
        middleParagraphs: ["Use the volume with a MySQL container:"],
        thirdSnippet: {
          code: "docker run -d \\\n  --name my-database \\\n  -v mydata:/var/lib/mysql \\\n  -e MYSQL_ROOT_PASSWORD=example \\\n  mysql:8",
          language: "bash",
        },
        closingParagraphs: [
          "Here, mydata is mounted at /var/lib/mysql, where MySQL stores its database files.",
          "The volume remains available even after the container is removed, unless the volume itself is deleted.",
        ],
      },
      {
        number: 3,
        title: "3. Understand Bind Mounts",
        paragraphs: [
          "A Bind Mount connects a directory or file on the host machine to a location inside a container.",
          "For example, developers can connect their local project directory to a Node.js container:",
        ],
        codeSnippet: {
          code: "docker run -d \\\n  --name node-dev \\\n  -p 3000:3000 \\\n  -v \"$(pwd):/app\" \\\n  node:20",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Here, the current directory is mounted inside the container at /app.",
          "This is particularly useful during development because changes made to local files can be accessed from inside the container.",
        ],
      },
      {
        number: 4,
        title: "4. Understand Docker Networking",
        paragraphs: [
          "Applications often consist of multiple services, such as a frontend, backend, and database. When these services run in separate containers, they need a way to communicate.",
          "Docker Networking provides this connectivity.",
          "Common network drivers include:",
        ],
        listItems: [
          "Bridge: Connects containers on the same Docker host.",
          "Host: Allows a container to share the host's network namespace.",
          "None: Disables normal container networking.",
          "Overlay: Connects containers across multiple Docker hosts.",
        ],
      },
      {
        number: 5,
        title: "5. Create and Connect Docker Networks",
        paragraphs: ["Create a custom bridge network:"],
        codeSnippet: {
          code: "docker network create my-network",
          language: "bash",
        },
        postSnippetParagraphs: ["Run two containers on the same network:"],
        secondSnippet: {
          code: "docker run -d --name backend --network my-network nginx\n\ndocker run -d --name frontend --network my-network nginx",
          language: "bash",
        },
        closingParagraphs: [
          "Containers connected to the same user-defined bridge network can communicate using their container names.",
          "This makes it easier to connect application services without exposing every service directly to the outside world.",
        ],
      },
    ],
  },
  {
    id: "docker-05",
    order: 5,
    number: "05",
    title: "05. Docker Compose & Multi-Container Applications",
    shortTitle: "Docker Compose & Multi-Container Applications",
    summary:
      "Define and manage multi-container applications with Docker Compose, services, ports, environment variables, networks, and persistent volumes.",
    estimatedMinutes: 25,
    objectives: [
      "Understand the challenges of managing multiple containers.",
      "Learn what Docker Compose is.",
      "Understand the structure of Compose YAML files.",
      "Define services, networks, and volumes.",
      "Start and manage multi-container applications.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Why Do We Need Docker Compose?",
        paragraphs: [
          "A typical web application may contain a frontend, backend, and database, each running in a separate container.",
          "Managing these containers individually requires multiple commands and separate configurations.",
          "Docker Compose simplifies this process by allowing developers to define all application services in a single YAML file and manage them together.",
        ],
      },
      {
        number: 2,
        title: "2. Understand Docker Compose",
        paragraphs: [
          "Docker Compose is a tool used to define and run multi-container Docker applications.",
          "It uses a configuration file commonly named compose.yaml to describe services, ports, environment variables, networks, and volumes.",
          "Instead of starting every container separately, developers can use a single command to start the entire application.",
        ],
      },
      {
        number: 3,
        title: "3. Create a Compose File",
        paragraphs: [
          "Consider an application containing an Nginx web server and a MySQL database.",
          "Create a file named compose.yaml:",
        ],
        codeSnippet: {
          code: "services:\n  web:\n    image: nginx\n    ports:\n      - \"8080:80\"\n\n  db:\n    image: mysql:8\n    environment:\n      MYSQL_ROOT_PASSWORD: example\n    volumes:\n      - db-data:/var/lib/mysql\n\nvolumes:\n  db-data:",
          language: "yaml",
        },
        closingParagraphs: [
          "The web service runs Nginx, while the db service runs MySQL.",
          "The named volume db-data ensures that database files are stored independently of the container's writable layer.",
          "Compose also creates a default network, allowing services to communicate with one another.",
        ],
      },
      {
        number: 4,
        title: "4. Run and Manage Services",
        paragraphs: ["To start all services:"],
        codeSnippet: {
          code: "docker compose up -d",
          language: "bash",
        },
        postSnippetParagraphs: ["To view running services:"],
        secondSnippet: {
          code: "docker compose ps",
          language: "bash",
        },
        middleParagraphs: ["To view application logs:"],
        thirdSnippet: {
          code: "docker compose logs",
          language: "bash",
        },
        afterThirdParagraphs: [
          "To stop and remove the containers and network:",
        ],
        fourthSnippet: {
          code: "docker compose down",
          language: "bash",
        },
        closingParagraphs: [
          "Named volumes are retained by default when running docker compose down, helping preserve application data.",
        ],
      },
      {
        number: 5,
        title: "5. Understand Service Dependencies and Configuration",
        paragraphs: [
          "Compose allows developers to configure service dependencies using depends_on.",
          "Environment variables can also be used to provide configuration values such as database hostnames and connection details.",
          "For example, a backend service can connect to a database using its Compose service name:",
        ],
        codeSnippet: {
          code: "environment:\n  DB_HOST: db\n  DB_PORT: 3306",
          language: "yaml",
        },
        closingParagraphs: [
          "When both services share a network, the database can be reached using db as its hostname.",
          "This makes Docker Compose useful for developing and testing applications that depend on multiple services.",
        ],
      },
    ],
  },
  {
    id: "docker-06",
    order: 6,
    number: "06",
    title: "06. Docker Hub, Image Distribution & Best Practices",
    shortTitle: "Docker Hub, Image Distribution & Best Practices",
    summary:
      "Explore Docker Hub container registries, repositories, image tagging, publishing and downloading images, and production security best practices.",
    estimatedMinutes: 25,
    objectives: [
      "Understand the purpose of Docker Hub.",
      "Learn how to create and manage repositories.",
      "Tag and publish Docker Images.",
      "Download images from registries.",
      "Understand image versioning.",
      "Learn Docker security and optimization practices.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Why Do We Need Docker Hub?",
        paragraphs: [
          "After creating a Docker Image, developers may need to share it with teammates or deploy it on another server.",
          "Rebuilding the image separately on every machine can introduce unnecessary work.",
          "A container registry provides a centralized location to store and distribute Docker Images.",
          "Docker Hub is a popular registry where developers can upload their own images and download images published by others.",
        ],
      },
      {
        number: 2,
        title: "2. Understand Docker Hub",
        paragraphs: [
          "Docker Hub provides repositories for storing Docker Images.",
          "Some important concepts include:",
        ],
        listItems: [
          "Repository: A collection of related images.",
          "Tag: Identifies an image version or variant.",
          "Push: Uploads an image to a registry.",
          "Pull: Downloads an image from a registry.",
          "Public repository: Allows public access.",
          "Private repository: Restricts access to authorized users.",
        ],
      },
      {
        number: 3,
        title: "3. Upload an Image to Docker Hub",
        paragraphs: [
          "Visit https://hub.docker.com/ and create an account.",
          "Create a repository named my-node-app.",
          "Authenticate with Docker Hub:",
        ],
        codeSnippet: {
          code: "docker login",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Tag your local image using your Docker Hub username:",
        ],
        secondSnippet: {
          code: "docker tag my-node-app:latest YOUR-USERNAME/my-node-app:v1",
          language: "bash",
        },
        middleParagraphs: ["Upload the image:"],
        thirdSnippet: {
          code: "docker push YOUR-USERNAME/my-node-app:v1",
          language: "bash",
        },
        closingParagraphs: [
          "The image is now available in the registry for users with the required permissions.",
        ],
      },
      {
        number: 4,
        title: "4. Download and Run a Published Image",
        paragraphs: [
          "Another developer or deployment server can retrieve the image using:",
        ],
        codeSnippet: {
          code: "docker pull YOUR-USERNAME/my-node-app:v1",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Create a container from the downloaded image:",
        ],
        secondSnippet: {
          code: "docker run -d -p 3000:3000 YOUR-USERNAME/my-node-app:v1",
          language: "bash",
        },
        closingParagraphs: [
          "This allows the same packaged application to run on another machine without manually configuring its environment.",
        ],
      },
      {
        number: 5,
        title: "5. Follow Docker Best Practices",
        paragraphs: [
          "Building an image that works correctly is only one part of container development. Images should also be secure, efficient, and easy to maintain.",
          "Developers should use trusted and appropriately versioned base images, avoid storing credentials inside Dockerfiles, and use non-root users whenever possible.",
          "A .dockerignore file should be used to exclude unnecessary files such as local dependencies, Git history, logs, and environment files from the build context.",
          "For example:",
        ],
        codeSnippet: {
          code: "node_modules\n.git\n.env\n*.log",
          language: "text",
        },
        closingParagraphs: [
          "Multi-stage builds can also reduce final image size by separating the build environment from the runtime environment.",
          "These practices help improve image security, reduce unnecessary dependencies, and simplify deployments.",
        ],
      },
    ],
  },
  {
    id: "docker-07",
    order: 7,
    number: "07",
    title: "07. Docker in a Real DevOps Workflow",
    shortTitle: "Docker in a Real DevOps Workflow",
    summary:
      "Integrate Git, GitHub, Docker, and CI/CD with GitHub Actions into a unified, automated container build and deployment workflow.",
    estimatedMinutes: 25,
    objectives: [
      "Understand Docker's role in the DevOps lifecycle.",
      "Connect version control with containerization.",
      "Understand Docker image creation and distribution.",
      "Learn how Docker integrates with CI/CD.",
      "Understand the role of GitHub Actions.",
      "Follow the process of deploying a containerized application.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Connect Docker to the DevOps Lifecycle",
        paragraphs: [
          "Git helps developers manage source code, while GitHub provides a platform for collaboration and version control.",
          "Docker builds on this process by packaging the application and its dependencies into images that can run consistently across different environments.",
          "Automation tools can then test the application, build Docker Images, publish them to a registry, and deploy them to servers.",
          "A typical workflow includes code development, Git commits, GitHub collaboration, automated testing, image building, image publishing, and deployment.",
        ],
      },
      {
        number: 2,
        title: "2. Build and Test the Application",
        paragraphs: [
          "Consider a developer working on a Node.js application.",
          "After making changes, the developer stages and commits the code:",
        ],
        codeSnippet: {
          code: "git add .\ngit commit -m \"Add user authentication\"\ngit push origin main",
          language: "bash",
        },
        postSnippetParagraphs: [
          "The application can then be packaged using its Dockerfile:",
        ],
        secondSnippet: {
          code: "docker build -t my-node-app:v1 .",
          language: "bash",
        },
        middleParagraphs: ["Run a container to verify the application:"],
        thirdSnippet: {
          code: "docker run -d -p 3000:3000 my-node-app:v1",
          language: "bash",
        },
        closingParagraphs: [
          "This helps confirm that the application runs using the environment defined in the Dockerfile.",
        ],
      },
      {
        number: 3,
        title: "3. Understand CI/CD Integration with Docker",
        paragraphs: [
          "Continuous Integration (CI) automates the process of checking application changes through activities such as building and running tests.",
          "Continuous Delivery and Continuous Deployment extend this process by preparing or automatically releasing tested changes.",
          "GitHub Actions can automate Docker-related tasks whenever code is pushed or a pull request is created.",
          "A typical workflow can:",
        ],
        listItems: [
          "Check out the repository.",
          "Install application dependencies.",
          "Run automated tests.",
          "Build a Docker Image.",
          "Authenticate with a container registry.",
          "Push the image to Docker Hub.",
        ],
        closingParagraphs: [
          "Registry credentials should be stored securely using GitHub Actions secrets rather than hardcoded in workflow files.",
        ],
      },
      {
        number: 4,
        title: "4. Deploy a Containerized Application",
        paragraphs: [
          "Once the image is published, a deployment server can retrieve it from Docker Hub.",
          "Download the image:",
        ],
        codeSnippet: {
          code: "docker pull YOUR-USERNAME/my-node-app:v1",
          language: "bash",
        },
        postSnippetParagraphs: ["Run the application:"],
        secondSnippet: {
          code: "docker run -d \\\n  --name production-app \\\n  -p 3000:3000 \\\n  YOUR-USERNAME/my-node-app:v1",
          language: "bash",
        },
        closingParagraphs: [
          "The application now runs inside a container on the deployment server.",
          "Production environments may also require persistent storage, environment variables, monitoring, health checks, and additional security configurations.",
        ],
      },
      {
        number: 5,
        title: "5. Follow the Complete DevOps Workflow",
        paragraphs: [
          "Consider a team developing a task management application.",
          "A developer adds a feature and pushes the changes to GitHub. GitHub Actions automatically runs tests and builds a Docker Image.",
          "After the changes pass the required checks, the image is published to Docker Hub.",
          "The deployment server then retrieves the image and starts a container using the required configuration.",
          "The updated application becomes available to users.",
          "This workflow connects Git, GitHub, Docker, Docker Hub, and CI/CD into a single application delivery process.",
          "Docker makes it easier to package, distribute, and execute applications consistently, making it an important part of modern DevOps workflows.",
        ],
      },
    ],
  },
];

