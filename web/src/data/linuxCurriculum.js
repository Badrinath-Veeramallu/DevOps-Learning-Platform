/**
 * DevOps Learning Platform — Linux Essentials Curriculum
 * Single Source of Truth based on provided final curriculum and animation package.
 * Exact content, objectives, commands, tables, and code examples preserved.
 */

export const linuxCurriculum = [
  {
    id: "linux-01",
    order: 1,
    number: "01",
    title: "01. Linux Fundamentals & File System Navigation",
    shortTitle: "Linux Fundamentals & File System Navigation",
    summary:
      "Understand the role of Linux in software development and DevOps, navigate the file system hierarchy, manage files and directories, and read and search file contents.",
    estimatedMinutes: 20,
    objectives: [
      "Understand the role of Linux in software development and DevOps.",
      "Navigate the Linux file system.",
      "Manage files and directories using terminal commands.",
      "Read and search file contents.",
    ],
    sections: [
      {
        number: 1,
        subtopicId: "01.1",
        title: "1. Why Linux Matters for DevOps",
        paragraphs: [
          "Linux is an open-source operating system widely used in servers, cloud infrastructure, and development environments. Many DevOps tools, including Docker and Kubernetes, commonly run on Linux.",
        ],
      },
      {
        number: 2,
        subtopicId: "01.2",
        title: "2. The Terminal and the Shell",
        paragraphs: [
          "The terminal allows developers to interact directly with the operating system, manage files, configure applications, and automate tasks. This makes Linux an essential skill when working with remote servers and deployment environments.",
        ],
      },
      {
        number: 3,
        subtopicId: "01.3",
        title: "3. The Linux File System Tree",
        paragraphs: [
          "Linux uses a hierarchical file system that begins at the root directory `/`. Important directories include `/home` for user files, `/etc` for configuration, `/var` for logs and application data, and `/tmp` for temporary files.",
        ],
      },
      {
        number: 4,
        subtopicId: "01.4",
        title: "4. Absolute vs Relative Paths",
        paragraphs: [
          "Paths can be absolute, starting from `/`, or relative to the current directory.",
        ],
      },
      {
        number: 5,
        subtopicId: "01.5",
        title: "5. Navigate with pwd, ls and cd",
        paragraphs: [
          "The following commands are commonly used for navigation:",
        ],
        codeSnippet: {
          code: "pwd\nls -la\ncd projects\ncd ..\ncd ~",
          language: "bash",
        },
        postSnippetParagraphs: [
          "`pwd` displays the current location, `ls` lists directory contents, and `cd` changes directories.",
        ],
      },
      {
        number: 6,
        subtopicId: "01.6",
        title: "6. Create Directories and Files",
        paragraphs: [
          "Developers regularly create directories, organize project files, and maintain backups. Linux provides commands for these operations:",
        ],
        codeSnippet: {
          code: "mkdir -p projects/linux\ntouch notes.txt",
          language: "bash",
        },
        postSnippetParagraphs: [
          "`mkdir` creates directories and `touch` creates files.",
        ],
      },
      {
        number: 7,
        subtopicId: "01.7",
        title: "7. Copy, Move and Rename Files",
        paragraphs: [
          "Linux provides commands to copy or move files between directories:",
        ],
        codeSnippet: {
          code: "cp notes.txt backup.txt\nmv notes.txt projects/",
          language: "bash",
        },
        postSnippetParagraphs: [
          "`cp` copies, and `mv` moves or renames files.",
        ],
      },
      {
        number: 8,
        subtopicId: "01.8",
        title: "8. Remove Files Carefully",
        paragraphs: [
          "To remove files and directories when they are no longer needed:",
        ],
        codeSnippet: {
          code: "rm backup.txt\nrm -r projects",
          language: "bash",
        },
        postSnippetParagraphs: [
          "`rm` removes files or directories. Use `rm` carefully because deletion generally cannot be undone.",
        ],
      },
      {
        number: 9,
        subtopicId: "01.9",
        title: "9. Read Files: cat, less, head and tail",
        paragraphs: [
          "Commands such as `cat` and `less` help inspect file contents, while `head` and `tail` display selected portions.",
        ],
        codeSnippet: {
          code: "cat notes.txt\nless application.log\nhead -n 5 application.log\ntail -f application.log",
          language: "bash",
        },
      },
      {
        number: 10,
        subtopicId: "01.10",
        title: "10. Search Logs with grep",
        paragraphs: [
          "When troubleshooting applications, developers often need to locate specific messages in large log files. The `grep` command makes this easier:",
        ],
        codeSnippet: {
          code: 'grep -i "error" application.log\ngrep -r "database" ./logs',
          language: "bash",
        },
        closingParagraphs: [
          "These commands provide a practical foundation for navigating and managing files through the Linux terminal.",
        ],
      },
    ],
  },
  {
    id: "linux-02",
    order: 2,
    number: "02",
    title: "02. Linux Permissions & User Management",
    shortTitle: "Linux Permissions & User Management",
    summary:
      "Understand Linux users, groups, and ownership, interpret read, write, and execute permissions, modify access with chmod and chown, and use sudo for root administration.",
    estimatedMinutes: 20,
    objectives: [
      "Understand Linux users, groups, and ownership.",
      "Interpret read, write, and execute permissions.",
      "Modify permissions and ownership.",
      "Understand sudo and the root user.",
    ],
    sections: [
      {
        number: 1,
        subtopicId: "02.1",
        title: "1. Users, Groups and Ownership",
        paragraphs: [
          "Linux supports multiple users, each with an identity and specific access rights. Files and directories have an owner, an associated group, and permissions that determine who can access or modify them.",
          "The `whoami`, `id`, and `ls -l` commands help inspect user information and file permissions.",
        ],
        codeSnippet: {
          code: "whoami\nid\nls -l",
          language: "bash",
        },
      },
      {
        number: 2,
        subtopicId: "02.2",
        title: "2. Read the Permission String",
        paragraphs: ["A permission entry such as:"],
        codeSnippet: {
          code: "-rwxr-xr--",
          language: "text",
        },
        postSnippetParagraphs: [
          "is divided into three groups: owner, group, and others.",
          "Linux uses three basic permissions:",
        ],
        table: {
          headers: ["Permission", "Meaning"],
          rows: [
            ["`r`", "Read"],
            ["`w`", "Write"],
            ["`x`", "Execute"],
          ],
        },
      },
      {
        number: 3,
        subtopicId: "02.3",
        title: "3. Numeric Permissions",
        paragraphs: [
          "These permissions can also be represented numerically: read = 4, write = 2, and execute = 1. For example, `755` represents `rwxr-xr-x`, while `644` represents `rw-r--r--`.",
        ],
      },
      {
        number: 4,
        subtopicId: "02.4",
        title: "4. Change Permissions with chmod",
        paragraphs: [
          "The `chmod` command changes permissions.",
        ],
        codeSnippet: {
          code: "chmod u+x deploy.sh\nchmod 755 deploy.sh\nchmod 644 notes.txt",
          language: "bash",
        },
        postSnippetParagraphs: [
          "The symbolic method uses letters such as `u`, `g`, and `o` for owner, group, and others. Numeric permissions provide a shorter way to assign access.",
        ],
      },
      {
        number: 5,
        subtopicId: "02.5",
        title: "5. Change Ownership with chown",
        paragraphs: [
          "The `chown` command changes file ownership.",
        ],
        codeSnippet: {
          code: "sudo chown student:developers notes.txt",
          language: "bash",
        },
      },
      {
        number: 6,
        subtopicId: "02.6",
        title: "6. sudo and the Root User",
        paragraphs: [
          "The root user has extensive administrative privileges. Regular users can perform authorized administrative operations using `sudo`.",
        ],
        codeSnippet: {
          code: "sudo apt update\nsudo systemctl restart nginx",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Using elevated privileges requires care because administrative commands can modify or delete protected system files. Always verify commands and paths before executing them.",
        ],
      },
    ],
  },
  {
    id: "linux-03",
    order: 3,
    number: "03",
    title: "03. Processes, Services & System Logs",
    shortTitle: "Processes, Services & System Logs",
    summary:
      "Monitor running processes with ps and top, manage process termination, control systemd services with systemctl, and inspect system logs with journalctl.",
    estimatedMinutes: 20,
    objectives: [
      "Monitor running processes.",
      "Stop unresponsive processes.",
      "Manage background services.",
      "Inspect logs for troubleshooting.",
    ],
    sections: [
      {
        number: 1,
        subtopicId: "03.1",
        title: "1. Processes and Resource Monitoring",
        paragraphs: [
          "Whenever a program runs, Linux creates a process and assigns it a unique Process ID (PID). Developers can inspect running processes and their resource usage using:",
        ],
        codeSnippet: {
          code: "ps aux\ntop",
          language: "bash",
        },
        postSnippetParagraphs: [
          "`ps aux` provides a snapshot of processes, while `top` continuously displays CPU and memory usage.",
        ],
      },
      {
        number: 2,
        subtopicId: "03.2",
        title: "2. Stop an Unresponsive Process",
        paragraphs: [
          "If a process becomes unresponsive, it can be stopped using its PID:",
        ],
        codeSnippet: {
          code: "kill 2450",
          language: "bash",
        },
        postSnippetParagraphs: [
          "By default, `kill` requests graceful termination. The `kill -9` command forces termination and should only be used when necessary.",
        ],
      },
      {
        number: 3,
        subtopicId: "03.3",
        title: "3. Services and systemd",
        paragraphs: [
          "Services are background programs that provide functionality such as web hosting, database access, and remote connections.",
          "On Linux systems using `systemd`, services are managed through `systemctl`.",
        ],
      },
      {
        number: 4,
        subtopicId: "03.4",
        title: "4. Start, Stop and Restart a Service",
        paragraphs: [
          "Manage the runtime state of a service with basic `systemctl` commands:",
        ],
        codeSnippet: {
          code: "systemctl status nginx\nsudo systemctl start nginx\nsudo systemctl stop nginx\nsudo systemctl restart nginx",
          language: "bash",
        },
      },
      {
        number: 5,
        subtopicId: "03.5",
        title: "5. Start Now vs Start at Boot",
        paragraphs: [
          "Starting a service affects its current state, while enabling it configures automatic startup during system boot.",
        ],
        codeSnippet: {
          code: "sudo systemctl enable nginx",
          language: "bash",
        },
      },
      {
        number: 6,
        subtopicId: "03.6",
        title: "6. Read Service Logs with journalctl",
        paragraphs: [
          "When a service fails, its logs can help identify the cause. The `journalctl` command displays logs collected by `systemd`.",
        ],
        codeSnippet: {
          code: "journalctl -u nginx\njournalctl -u nginx -n 20\njournalctl -u nginx -f",
          language: "bash",
        },
        postSnippetParagraphs: [
          "These commands display service logs, show recent entries, and continuously follow new messages.",
        ],
      },
      {
        number: 7,
        subtopicId: "03.7",
        title: "7. Troubleshoot a Failing Service",
        paragraphs: [
          "Checking service status and logs together is a useful starting point when troubleshooting application failures.",
        ],
        codeSnippet: {
          code: "systemctl status nginx\njournalctl -u nginx -n 20",
          language: "bash",
        },
      },
    ],
  },
  {
    id: "linux-04",
    order: 4,
    number: "04",
    title: "04. Networking & Remote Access",
    shortTitle: "Networking & Remote Access",
    summary:
      "Understand IP addresses, ports, and DNS, test network connectivity with ping and curl, inspect listening ports with ss, and connect remotely using SSH and key pairs.",
    estimatedMinutes: 20,
    objectives: [
      "Understand IP addresses, ports, and DNS.",
      "Test connectivity and make HTTP requests.",
      "Inspect listening ports.",
      "Connect to remote machines using SSH and SSH keys.",
    ],
    sections: [
      {
        number: 1,
        subtopicId: "04.1",
        title: "1. IP Addresses, Ports and DNS",
        paragraphs: [
          "Applications communicate across networks using IP addresses and ports. An IP address identifies a device or network interface, while a port identifies a particular communication endpoint.",
          "For example, SSH commonly uses port `22`, HTTP uses `80`, and HTTPS uses `443`. DNS translates domain names into IP addresses.",
        ],
      },
      {
        number: 2,
        subtopicId: "04.2",
        title: "2. Test Connectivity with ping",
        paragraphs: [
          "The `ping` command checks whether a host responds to network requests:",
        ],
        codeSnippet: {
          code: "ping -c 4 google.com",
          language: "bash",
        },
      },
      {
        number: 3,
        subtopicId: "04.3",
        title: "3. Make HTTP Requests with curl",
        paragraphs: [
          "The `curl` command is useful for testing websites, backend applications, and APIs:",
        ],
        codeSnippet: {
          code: "curl https://example.com\ncurl -I https://example.com\ncurl http://localhost:3000",
          language: "bash",
        },
      },
      {
        number: 4,
        subtopicId: "04.4",
        title: "4. Inspect Listening Ports with ss",
        paragraphs: [
          "To inspect listening network ports, use:",
        ],
        codeSnippet: {
          code: "ss -tuln\nsudo ss -tulpn",
          language: "bash",
        },
        postSnippetParagraphs: [
          "These commands help identify whether an application is listening on its expected port.",
        ],
      },
      {
        number: 5,
        subtopicId: "04.5",
        title: "5. Connect to a Server with SSH",
        paragraphs: [
          "Secure Shell (SSH) provides an encrypted connection to remote Linux machines. Developers commonly use it to access cloud servers.",
        ],
        codeSnippet: {
          code: "ssh student@192.168.1.50",
          language: "bash",
        },
      },
      {
        number: 6,
        subtopicId: "04.6",
        title: "6. SSH Key Authentication",
        paragraphs: [
          "SSH also supports key-based authentication. Generate a key pair using:",
        ],
        codeSnippet: {
          code: 'ssh-keygen -t ed25519 -C "student@example.com"',
          language: "bash",
        },
        middleParagraphs: [
          "The public key can be installed on the remote server using `ssh-copy-id`:",
        ],
        secondSnippet: {
          code: "ssh-copy-id student@192.168.1.50",
          language: "bash",
        },
        closingParagraphs: [
          "After installation, the matching private key can authenticate the connection. The private key must remain secret and should never be committed to GitHub.",
        ],
      },
    ],
  },
  {
    id: "linux-05",
    order: 5,
    number: "05",
    title: "05. Package Management & Text Editing",
    shortTitle: "Package Management & Text Editing",
    summary:
      "Understand Linux package managers like apt and dnf, install and manage software packages, and edit configuration files using Nano and Vim.",
    estimatedMinutes: 20,
    objectives: [
      "Understand Linux package managers.",
      "Install, update, and remove software.",
      "Use Nano and Vim for terminal-based editing.",
    ],
    sections: [
      {
        number: 1,
        subtopicId: "05.1",
        title: "1. Package Managers: apt and dnf",
        paragraphs: [
          "Linux package managers simplify software installation, updates, dependency management, and removal.",
          "Ubuntu and Debian commonly use `apt`, while Red Hat-based distributions use `dnf` or, on older systems, `yum`.",
          "The available package manager depends on the distribution. Its details can be checked using:",
        ],
        codeSnippet: {
          code: "cat /etc/os-release",
          language: "bash",
        },
      },
      {
        number: 2,
        subtopicId: "05.2",
        title: "2. Install, Update and Remove with apt",
        paragraphs: [
          "On Ubuntu and Debian systems, software can be managed using `apt`:",
        ],
        codeSnippet: {
          code: "sudo apt update\nsudo apt install nginx\nsudo apt upgrade\nsudo apt remove nginx",
          language: "bash",
        },
      },
      {
        number: 3,
        subtopicId: "05.3",
        title: "3. apt vs dnf: Same Idea, Different Command",
        paragraphs: [
          "On Red Hat-based systems using DNF, package operations follow a similar workflow:",
        ],
        codeSnippet: {
          code: "sudo dnf install nginx\nsudo dnf update\nsudo dnf remove nginx",
          language: "bash",
        },
      },
      {
        number: 4,
        subtopicId: "05.4",
        title: "4. Edit Files with Nano",
        paragraphs: [
          "When working on remote servers, developers often need to edit configuration files without a graphical editor.",
          "Nano provides a simple editing experience:",
        ],
        codeSnippet: {
          code: "nano app.conf",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Useful shortcuts include `Ctrl + O` to save and `Ctrl + X` to exit.",
        ],
      },
      {
        number: 5,
        subtopicId: "05.5",
        title: "5. Edit Files with Vim",
        paragraphs: [
          "Vim provides more advanced editing through different modes. Press `i` to enter Insert mode and `Esc` to return to Normal mode.",
          "Common Vim commands include:",
        ],
        table: {
          headers: ["Command", "Action"],
          rows: [
            ["`:w`", "Save"],
            ["`:q`", "Quit"],
            ["`:wq`", "Save and quit"],
            ["`:q!`", "Quit without saving"],
          ],
        },
        closingParagraphs: [
          "Both editors are useful when modifying application settings and system configuration files.",
        ],
      },
    ],
  },
  {
    id: "linux-06",
    order: 6,
    number: "06",
    title: "06. Shell Scripting & Automation",
    shortTitle: "Shell Scripting & Automation",
    summary:
      "Create and execute Bash scripts, work with variables, arguments, conditions, and loops, and build an automated project backup script.",
    estimatedMinutes: 25,
    objectives: [
      "Create and execute Bash scripts.",
      "Use variables and command-line arguments.",
      "Apply conditions and loops.",
      "Automate a basic file-management task.",
    ],
    sections: [
      {
        number: 1,
        subtopicId: "06.1",
        title: "1. Your First Bash Script",
        paragraphs: [
          "Shell scripting allows multiple Linux commands to be combined into a single file and executed together. It is commonly used to automate repetitive tasks such as creating directories, managing files, and preparing application environments.",
          "A basic Bash script begins with a shebang:",
        ],
        codeSnippet: {
          code: '#!/bin/bash\n\necho "Welcome to Linux Shell Scripting"',
          language: "bash",
        },
        postSnippetParagraphs: [
          "Save it as `hello.sh`, make it executable, and run it:",
        ],
        secondSnippet: {
          code: "chmod +x hello.sh\n./hello.sh",
          language: "bash",
        },
      },
      {
        number: 2,
        subtopicId: "06.2",
        title: "2. Variables and Arguments",
        paragraphs: [
          "Variables store values that can be reused within a script.",
        ],
        codeSnippet: {
          code: 'name="Student"\necho "Welcome, $name"',
          language: "bash",
        },
        postSnippetParagraphs: [
          "Scripts can also accept command-line arguments such as `$1` and `$2`, allowing users to provide different inputs when executing them.",
        ],
      },
      {
        number: 3,
        subtopicId: "06.3",
        title: "3. Conditions: if and else",
        paragraphs: [
          "Conditional statements help scripts make decisions:",
        ],
        codeSnippet: {
          code: 'if [ -f "config.txt" ]; then\n    echo "Configuration file found"\nelse\n    echo "Configuration file is missing"\nfi',
          language: "bash",
        },
      },
      {
        number: 4,
        subtopicId: "06.4",
        title: "4. Loops: Repeat Work with for",
        paragraphs: [
          "Loops repeat operations for multiple values or while a condition remains true:",
        ],
        codeSnippet: {
          code: 'for item in Git Linux Docker\ndo\n    echo "Learning: $item"\ndone',
          language: "bash",
        },
        postSnippetParagraphs: [
          "These features allow scripts to handle different situations without requiring users to execute every command manually.",
        ],
      },
      {
        number: 5,
        subtopicId: "06.5",
        title: "5. Mini Project: Backup Script Walkthrough",
        paragraphs: [
          "Create a script named `backup.sh` that accepts a project directory, checks whether it exists, and copies it into a timestamped backup folder.",
        ],
        codeSnippet: {
          code: '#!/bin/bash\n\nSOURCE_DIR="$1"\nBACKUP_ROOT="$HOME/backups"\n\nif [ -z "$SOURCE_DIR" ] || [ ! -d "$SOURCE_DIR" ]; then\n    echo "Usage: ./backup.sh <existing-directory>"\n    exit 1\nfi\n\nmkdir -p "$BACKUP_ROOT"\n\nTIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")\nBACKUP_DIR="$BACKUP_ROOT/backup_$TIMESTAMP"\n\nif cp -r "$SOURCE_DIR" "$BACKUP_DIR"; then\n    echo "Backup completed successfully."\n    echo "Location: $BACKUP_DIR"\nelse\n    echo "Backup failed."\n    exit 1\nfi',
          language: "bash",
        },
      },
      {
        number: 6,
        subtopicId: "06.6",
        title: "6. Mini Project: Run and Verify the Backup",
        paragraphs: [
          "Make the script executable:",
        ],
        codeSnippet: {
          code: "chmod +x backup.sh",
          language: "bash",
        },
        middleParagraphs: [
          "Create a sample project and run the script:",
        ],
        secondSnippet: {
          code: "mkdir -p my-project\ntouch my-project/README.txt\n\n./backup.sh my-project",
          language: "bash",
        },
        closingParagraphs: [
          "The script checks the input directory, creates a backup location, and copies the project into a timestamped folder. Each execution creates a separate backup.",
          "This mini project combines variables, conditions, file operations, and command execution to demonstrate how shell scripting can automate everyday tasks.",
        ],
      },
    ],
    moduleCompletion: {
      title: "Module Completion",
      paragraphs: [
        "After completing Linux Essentials, learners should be able to navigate Linux systems, manage files and permissions, monitor processes and services, inspect logs, work with networks and remote servers, install software, edit configuration files, and write basic automation scripts.",
        "These skills provide the foundation for working with Docker, CI/CD pipelines, and cloud infrastructure.",
      ],
    },
  },
];
