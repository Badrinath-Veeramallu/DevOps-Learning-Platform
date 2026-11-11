/**
 * DevOps Learning Platform — Linux Essentials Curriculum
 * Single Source of Truth based on provided final curriculum.
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
        title: "1. Introduction to Linux",
        paragraphs: [
          "Linux is an open-source operating system widely used in servers, cloud infrastructure, and development environments. Many DevOps tools, including Docker and Kubernetes, commonly run on Linux.",
          "The terminal allows developers to interact directly with the operating system, manage files, configure applications, and automate tasks. This makes Linux an essential skill when working with remote servers and deployment environments.",
        ],
      },
      {
        number: 2,
        title: "2. Understanding the File System",
        paragraphs: [
          "Linux uses a hierarchical file system that begins at the root directory `/`. Important directories include `/home` for user files, `/etc` for configuration, `/var` for logs and application data, and `/tmp` for temporary files.",
          "Paths can be absolute, starting from `/`, or relative to the current directory.",
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
        number: 3,
        title: "3. Managing Files and Directories",
        paragraphs: [
          "Developers regularly create directories, organize project files, and maintain backups. Linux provides commands for these operations:",
        ],
        codeSnippet: {
          code: "mkdir -p projects/linux\ntouch notes.txt\n\ncp notes.txt backup.txt\nmv notes.txt projects/\nrm backup.txt\nrm -r projects",
          language: "bash",
        },
        postSnippetParagraphs: [
          "`mkdir` creates directories, `touch` creates files, `cp` copies, `mv` moves or renames, and `rm` removes files or directories. Use `rm` carefully because deletion generally cannot be undone.",
        ],
      },
      {
        number: 4,
        title: "4. Reading and Searching Files",
        paragraphs: [
          "Commands such as `cat` and `less` help inspect file contents, while `head` and `tail` display selected portions.",
        ],
        codeSnippet: {
          code: "cat notes.txt\nless application.log\nhead -n 5 application.log\ntail -f application.log",
          language: "bash",
        },
        middleParagraphs: [
          "When troubleshooting applications, developers often need to locate specific messages in large log files. The `grep` command makes this easier:",
        ],
        secondSnippet: {
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
        title: "1. Users, Groups, and Permissions",
        paragraphs: [
          "Linux supports multiple users, each with an identity and specific access rights. Files and directories have an owner, an associated group, and permissions that determine who can access or modify them.",
          "The `whoami`, `id`, and `ls -l` commands help inspect user information and file permissions.",
        ],
        codeSnippet: {
          code: "whoami\nid\nls -l",
          language: "bash",
        },
        postSnippetParagraphs: ["A permission entry such as:"],
        secondSnippet: {
          code: "-rwxr-xr--",
          language: "text",
        },
        middleParagraphs: [
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
        closingParagraphs: [
          "These permissions can also be represented numerically: read = 4, write = 2, and execute = 1. For example, `755` represents `rwxr-xr-x`, while `644` represents `rw-r--r--`.",
        ],
      },
      {
        number: 2,
        title: "2. Managing Permissions and Ownership",
        paragraphs: [
          "The `chmod` command changes permissions, while `chown` changes file ownership.",
        ],
        codeSnippet: {
          code: "chmod u+x deploy.sh\nchmod 755 deploy.sh\nchmod 644 notes.txt\n\nsudo chown student:developers notes.txt",
          language: "bash",
        },
        postSnippetParagraphs: [
          "The symbolic method uses letters such as `u`, `g`, and `o` for owner, group, and others. Numeric permissions provide a shorter way to assign access.",
        ],
      },
      {
        number: 3,
        title: "3. sudo and Root Access",
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
          "If a process becomes unresponsive, it can be stopped using its PID:",
        ],
        secondSnippet: {
          code: "kill 2450",
          language: "bash",
        },
        closingParagraphs: [
          "By default, `kill` requests graceful termination. The `kill -9` command forces termination and should only be used when necessary.",
        ],
      },
      {
        number: 2,
        title: "2. Managing Services",
        paragraphs: [
          "Services are background programs that provide functionality such as web hosting, database access, and remote connections.",
          "On Linux systems using `systemd`, services are managed through `systemctl`.",
        ],
        codeSnippet: {
          code: "systemctl status nginx\nsudo systemctl start nginx\nsudo systemctl stop nginx\nsudo systemctl restart nginx\nsudo systemctl enable nginx",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Starting a service affects its current state, while enabling it configures automatic startup during system boot.",
        ],
      },
      {
        number: 3,
        title: "3. Viewing Logs",
        paragraphs: [
          "When a service fails, its logs can help identify the cause. The `journalctl` command displays logs collected by `systemd`.",
        ],
        codeSnippet: {
          code: "journalctl -u nginx\njournalctl -u nginx -n 20\njournalctl -u nginx -f",
          language: "bash",
        },
        postSnippetParagraphs: [
          "These commands display service logs, show recent entries, and continuously follow new messages.",
          "Checking service status and logs together is a useful starting point when troubleshooting application failures.",
        ],
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
        title: "1. Basic Networking",
        paragraphs: [
          "Applications communicate across networks using IP addresses and ports. An IP address identifies a device or network interface, while a port identifies a particular communication endpoint.",
          "For example, SSH commonly uses port `22`, HTTP uses `80`, and HTTPS uses `443`. DNS translates domain names into IP addresses.",
        ],
      },
      {
        number: 2,
        title: "2. Testing Connections",
        paragraphs: [
          "The `ping` command checks whether a host responds to network requests:",
        ],
        codeSnippet: {
          code: "ping -c 4 google.com",
          language: "bash",
        },
        postSnippetParagraphs: [
          "The `curl` command is useful for testing websites, backend applications, and APIs:",
        ],
        secondSnippet: {
          code: "curl https://example.com\ncurl -I https://example.com\ncurl http://localhost:3000",
          language: "bash",
        },
        middleParagraphs: [
          "To inspect listening network ports, use:",
        ],
        thirdSnippet: {
          code: "ss -tuln\nsudo ss -tulpn",
          language: "bash",
        },
        closingParagraphs: [
          "These commands help identify whether an application is listening on its expected port.",
        ],
      },
      {
        number: 3,
        title: "3. Remote Access Using SSH",
        paragraphs: [
          "Secure Shell (SSH) provides an encrypted connection to remote Linux machines. Developers commonly use it to access cloud servers.",
        ],
        codeSnippet: {
          code: "ssh student@192.168.1.50",
          language: "bash",
        },
        postSnippetParagraphs: [
          "SSH also supports key-based authentication. Generate a key pair using:",
        ],
        secondSnippet: {
          code: 'ssh-keygen -t ed25519 -C "student@example.com"',
          language: "bash",
        },
        middleParagraphs: [
          "The public key can be installed on the remote server using `ssh-copy-id`:",
        ],
        thirdSnippet: {
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
        title: "1. Installing and Managing Software",
        paragraphs: [
          "Linux package managers simplify software installation, updates, dependency management, and removal.",
          "Ubuntu and Debian commonly use `apt`, while Red Hat-based distributions use `dnf` or, on older systems, `yum`.",
          "On Ubuntu, software can be managed using:",
        ],
        codeSnippet: {
          code: "sudo apt update\nsudo apt install nginx\nsudo apt upgrade\nsudo apt remove nginx",
          language: "bash",
        },
        postSnippetParagraphs: [
          "On systems using DNF:",
        ],
        secondSnippet: {
          code: "sudo dnf install nginx\nsudo dnf update\nsudo dnf remove nginx",
          language: "bash",
        },
        middleParagraphs: [
          "The available package manager depends on the distribution. Its details can be checked using:",
        ],
        thirdSnippet: {
          code: "cat /etc/os-release",
          language: "bash",
        },
      },
      {
        number: 2,
        title: "2. Editing Files in the Terminal",
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
        title: "1. Introduction to Shell Scripting",
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
        title: "2. Variables, Conditions, and Loops",
        paragraphs: [
          "Variables store values that can be reused within a script.",
        ],
        codeSnippet: {
          code: 'name="Student"\necho "Welcome, $name"',
          language: "bash",
        },
        postSnippetParagraphs: [
          "Scripts can also accept command-line arguments such as `$1` and `$2`, allowing users to provide different inputs when executing them.",
          "Conditional statements help scripts make decisions:",
        ],
        secondSnippet: {
          code: 'if [ -f "config.txt" ]; then\n    echo "Configuration file found"\nelse\n    echo "Configuration file is missing"\nfi',
          language: "bash",
        },
        middleParagraphs: [
          "Loops repeat operations for multiple values or while a condition remains true:",
        ],
        thirdSnippet: {
          code: "for item in Git Linux Docker\ndo\n    echo \"Learning: $item\"\ndone",
          language: "bash",
        },
        closingParagraphs: [
          "These features allow scripts to handle different situations without requiring users to execute every command manually.",
        ],
      },
      {
        number: 3,
        title: "3. Mini Project: Automated Project Backup",
        paragraphs: [
          "Create a script named `backup.sh` that accepts a project directory, checks whether it exists, and copies it into a timestamped backup folder.",
        ],
        codeSnippet: {
          code: '#!/bin/bash\n\nSOURCE_DIR="$1"\nBACKUP_ROOT="$HOME/backups"\n\nif [ -z "$SOURCE_DIR" ] || [ ! -d "$SOURCE_DIR" ]; then\n    echo "Usage: ./backup.sh <existing-directory>"\n    exit 1\nfi\n\nmkdir -p "$BACKUP_ROOT"\n\nTIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")\nBACKUP_DIR="$BACKUP_ROOT/backup_$TIMESTAMP"\n\nif cp -r "$SOURCE_DIR" "$BACKUP_DIR"; then\n    echo "Backup completed successfully."\n    echo "Location: $BACKUP_DIR"\nelse\n    echo "Backup failed."\n    exit 1\nfi',
          language: "bash",
        },
        postSnippetParagraphs: [
          "Make the script executable:",
        ],
        secondSnippet: {
          code: "chmod +x backup.sh",
          language: "bash",
        },
        middleParagraphs: [
          "Create a sample project and run the script:",
        ],
        thirdSnippet: {
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

