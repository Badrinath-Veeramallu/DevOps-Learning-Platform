/**
 * DevOps Learning Platform — Git & GitHub Curriculum
 * Single Source of Truth based on provided final curriculum.
 * Exact content, objectives, commands, and code examples preserved.
 */

export const gitCurriculum = [
  {
    id: "git-01",
    order: 1,
    number: "01",
    title: "01. Introduction to Git & Setup",
    shortTitle: "Introduction to Git & Setup",
    summary:
      "Understand version control principles, the difference between Git and GitHub, installation, identity configuration, and your working environment.",
    estimatedMinutes: 20,
    objectives: [
      "Understand what version control is and why developers use it.",
      "Differentiate between Git and GitHub.",
      "Install Git and verify that it works.",
      "Configure a Git username and email address.",
      "Understand how Git fits into everyday software development.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Why Do We Need Version Control?",
        paragraphs: [
          "You've spent several days building a web application. The frontend is complete, the backend is connected to the database, and users can log in successfully. You decide to improve the authentication system, but the changes introduce a bug that breaks the application.",
          "Now you need to figure out what went wrong. Which files did you modify? Which changes caused the issue? Was the previous implementation working correctly?",
          "Without version control, answering these questions can be frustrating. Developers sometimes resort to creating multiple copies of their projects with names such as final-project, final-project-new, and final-project-fixed. As the project grows, managing these copies becomes increasingly difficult.",
          "Version control provides a better solution. It maintains a history of changes, allowing you to inspect previous versions, understand how the code evolved, and recover from mistakes.",
          "Git is a distributed version control system. It tracks changes to files and stores project history in a repository. Developers can maintain this history locally, work on separate branches, and share their changes with others.",
          "Git records how your project develops over time; it is more than a tool for storing files.",
        ],
      },
      {
        number: 2,
        title: "2. Git vs GitHub",
        paragraphs: [
          "Git and GitHub are closely related, but they serve different purposes.",
          "Git is the version control tool that tracks changes to your project. It runs on your computer and manages your repository's history.",
          "GitHub is an online platform that hosts Git repositories. It provides tools for sharing code, reviewing changes, managing tasks, and collaborating with other developers.",
          "A task management application built with React and Node.js can use Git to record changes to the frontend and backend on your computer. Once the code is ready to share, you push the repository to GitHub so that teammates can access it and review your work.",
          "Git manages the history of your code. GitHub makes that code easier to share and work on as a team.",
          "You can use Git without GitHub, but GitHub adds useful collaboration and remote-hosting capabilities.",
        ],
      },
      {
        number: 3,
        title: "3. Install Git",
        paragraphs: [
          "Before tracking your first project, you need Git installed on your computer.",
          "Download it from the official website:",
        ],
        link: {
          url: "https://git-scm.com/install/",
          text: "https://git-scm.com/install/",
        },
        afterLinkParagraphs: [
          "Select the instructions for your operating system and complete the installation.",
          "Open your terminal or the integrated terminal in VS Code and run:",
        ],
        codeSnippet: {
          code: "git --version",
          language: "bash",
        },
        postSnippetParagraphs: [
          "If the installation is successful, Git displays its version number.",
          "If the command is not recognized, check whether Git was installed correctly and whether its executable is available through your system's PATH. Restarting the terminal may also help.",
        ],
      },
      {
        number: 4,
        title: "4. Configure Your Git Identity",
        paragraphs: [
          "Every commit records author information, including a name and email address. This information helps developers identify who made a change.",
          "Configure your identity using:",
        ],
        codeSnippet: {
          code: 'git config --global user.name "Your Name"\ngit config --global user.email "you@example.com"',
          language: "bash",
        },
        postSnippetParagraphs: [
          "Replace the sample values with your own details. If you want your commits associated with your GitHub account, use an email configured for that account or an appropriate GitHub-provided private email address.",
          "The --global option applies this configuration to your repositories by default. A particular repository can override these settings if necessary.",
          "To verify the configuration, run:",
        ],
        secondSnippet: {
          code: "git config --global --list",
          language: "bash",
        },
        closingParagraphs: [
          "Git is now ready to record your changes under the configured identity.",
        ],
      },
      {
        number: 5,
        title: "5. Understand Your Working Environment",
        paragraphs: [
          "Before running Git commands, make sure your terminal is inside the correct project directory. Otherwise, you may initialize or modify a repository in the wrong location.",
          "To enter a project directory:",
        ],
        codeSnippet: {
          code: "cd my-project",
          language: "bash",
        },
        postSnippetParagraphs: ["To view its files:"],
        secondSnippet: {
          code: "ls",
          language: "bash",
        },
        closingParagraphs: [
          "On Windows Command Prompt, use dir. PowerShell also supports ls.",
          "Once you understand where your project is located and have configured Git, you're ready to start tracking changes.",
        ],
      },
    ],
  },
  {
    id: "git-02",
    order: 2,
    number: "02",
    title: "02. Git Basics & Tracking Changes",
    shortTitle: "Git Basics & Tracking Changes",
    summary:
      "Initialize repositories, inspect status, stage files with precision, review diffs, and create meaningful checkpoint commits.",
    estimatedMinutes: 25,
    objectives: [
      "Initialize a Git repository.",
      "Understand untracked, modified, and staged files.",
      "Stage files and create commits.",
      "Inspect changes before committing.",
      "Understand the working directory, staging area, and repository history.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Start Tracking an Existing Project",
        paragraphs: [
          "Your website is already running locally, and you're ready to begin adding new features. Before making further changes, you want Git to maintain a history of the project.",
          "Open the terminal in the project's root directory and run:",
        ],
        codeSnippet: {
          code: "git init",
          language: "bash",
        },
        postSnippetParagraphs: [
          "This initializes a Git repository in the current directory. Git creates the internal repository structure needed to maintain its history.",
          "However, initialization does not automatically record your existing files in a commit. You still need to select the changes you want Git to record.",
          "If the project is already a Git repository, you do not need to initialize it again.",
        ],
      },
      {
        number: 2,
        title: "2. Check the Repository Status",
        paragraphs: [
          "Run:",
        ],
        codeSnippet: {
          code: "git status",
          language: "bash",
        },
        postSnippetParagraphs: [
          "This command shows the state of your working directory and staging area.",
          "Three file states are particularly important:",
        ],
        listItems: [
          "Untracked: Git sees a file but has not started tracking it.",
          "Modified: A tracked file has changes that differ from the recorded version.",
          "Staged: Changes have been selected for inclusion in the next commit.",
        ],
        closingParagraphs: [
          "These states determine what Git will include when you create a commit. A modified file, for example, is not automatically included merely because you committed another file in the same project.",
          "Checking the status regularly helps you understand exactly what Git sees before you make a decision.",
        ],
      },
      {
        number: 3,
        title: "3. Stage Your Changes",
        paragraphs: [
          "You've created a new homepage and updated the project's README. Before recording these changes, you need to select which files should be included in the next commit.",
          "To stage a specific file:",
        ],
        codeSnippet: {
          code: "git add README.md",
          language: "bash",
        },
        postSnippetParagraphs: [
          "To stage eligible changes under the current directory:",
        ],
        secondSnippet: {
          code: "git add .",
          language: "bash",
        },
        closingParagraphs: [
          "The dot refers to the current directory. This is convenient when several files have changed, but it can also stage unrelated work if you're not careful.",
          "For example, you might be working on a login feature while also experimenting with a dashboard design. If you want to commit only the login feature, staging its relevant files individually gives you more control.",
          "Staging creates a boundary between everything you've changed and the changes you intend to record together.",
        ],
      },
      {
        number: 4,
        title: "4. Review Changes Before Committing",
        paragraphs: [
          "Before creating a commit, inspect the changes you've made.",
          "Run:",
        ],
        codeSnippet: {
          code: "git diff",
          language: "bash",
        },
        postSnippetParagraphs: [
          "This displays unstaged changes to tracked files.",
          "After staging your changes, use:",
        ],
        secondSnippet: {
          code: "git diff --staged",
          language: "bash",
        },
        closingParagraphs: [
          "This displays the changes selected for the next commit.",
          "Reviewing the staged changes can help you catch accidental edits, temporary debugging statements, or unrelated modifications. It's a simple habit that prevents many avoidable mistakes.",
        ],
      },
      {
        number: 5,
        title: "5. Create a Commit",
        paragraphs: [
          "Once you've staged and reviewed the intended changes, record them in the repository's history:",
        ],
        codeSnippet: {
          code: 'git commit -m "Add homepage layout"',
          language: "bash",
        },
        postSnippetParagraphs: [
          "A commit records a snapshot of the staged changes, along with information such as the author, timestamp, and commit message.",
          "Commit messages should describe the purpose of the change. For example, Add login validation or Fix dashboard loading state communicates more than a message such as changes or update.",
          "A commit acts as a meaningful checkpoint. Smaller, focused commits generally make it easier to understand the history and investigate problems later.",
        ],
      },
      {
        number: 6,
        title: "6. Verify Your Commit",
        paragraphs: [
          "After committing, check the repository:",
        ],
        codeSnippet: {
          code: "git status\ngit log -1 --oneline",
          language: "bash",
        },
        postSnippetParagraphs: [
          "The first command shows whether any changes remain. The second displays the most recent commit.",
          "Keep these three operations distinct:",
        ],
        listItems: [
          "git add stages changes.",
          "git commit records staged changes in local history.",
          "git push publishes commits to a remote repository.",
        ],
        closingParagraphs: [
          "A commit is stored locally. It does not automatically upload your code to GitHub.",
        ],
      },
    ],
  },
  {
    id: "git-03",
    order: 3,
    number: "03",
    title: "03. GitHub & Remote Repositories",
    shortTitle: "GitHub & Remote Repositories",
    summary:
      "Connect local repositories to GitHub remotes, push code, clone shared projects, and pull collaborative team changes.",
    estimatedMinutes: 30,
    objectives: [
      "Create a remote repository on GitHub.",
      "Connect a local repository to a remote.",
      "Push commits to GitHub.",
      "Clone existing repositories.",
      "Pull remote changes into a local repository.",
      "Understand remote names and branch tracking.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Why Do We Need a Remote Repository?",
        paragraphs: [
          "Your application now has a local Git history, but that history exists on your computer. If you want teammates to access the code or need to work on the project from another machine, you'll need a way to share the repository.",
          "A remote repository stores a Git repository outside your local working environment. It allows developers to exchange commits and collaborate on a shared codebase.",
          "GitHub is one of the most widely used platforms for hosting remote Git repositories. Connecting your local repository to GitHub lets you publish changes, retrieve updates, and work with other developers.",
        ],
      },
      {
        number: 2,
        title: "2. Create a GitHub Repository",
        paragraphs: [
          "Open:",
        ],
        link: {
          url: "https://github.com/",
          text: "https://github.com/",
        },
        afterLinkParagraphs: [
          "Create a new repository and choose a name, such as task-manager.",
          "If your project already exists locally and contains commits, creating an empty remote repository is usually the simplest approach. Avoid initializing the GitHub repository with a separate README or other files when you intend to push an existing local history, unless you are prepared to reconcile the two histories.",
          "Once the repository is created, copy its URL. You'll use this URL to connect your local repository to GitHub.",
        ],
      },
      {
        number: 3,
        title: "3. Connect Your Local Repository",
        paragraphs: [
          "Inside your project's root directory, run:",
        ],
        codeSnippet: {
          code: "git remote add origin https://github.com/YOUR-USERNAME/task-manager.git",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Replace the example URL with the actual URL of your GitHub repository.",
          "The name origin is a conventional alias for the remote repository. It is not a special command, and another name can be used if needed.",
          "To verify the configuration, run:",
        ],
        secondSnippet: {
          code: "git remote -v",
          language: "bash",
        },
        closingParagraphs: [
          "Git displays the configured remote URLs.",
          "If a remote named origin already exists, inspect its URL rather than trying to add it again.",
        ],
      },
      {
        number: 4,
        title: "4. Push Your Code to GitHub",
        paragraphs: [
          "Before pushing, check the name of your current branch:",
        ],
        codeSnippet: {
          code: "git branch --show-current",
          language: "bash",
        },
        postSnippetParagraphs: [
          "For this example, assume the branch is named main.",
          "To publish that branch to GitHub, run:",
        ],
        secondSnippet: {
          code: "git push -u origin main",
          language: "bash",
        },
        closingParagraphs: [
          "The -u option establishes an upstream relationship between your local branch and the remote branch. This makes subsequent pushes and pulls more convenient.",
          "If your branch has another name, substitute the correct name in the command.",
          "GitHub may require authentication before allowing you to push. Use its supported sign-in or credential configuration, and never put passwords, access tokens, or private keys directly into your source code.",
          "Once the push succeeds, your committed changes are available in the remote repository.",
        ],
      },
      {
        number: 5,
        title: "5. Clone an Existing Repository",
        paragraphs: [
          "Working on an existing project is just as common as starting a new one. A teammate might share a repository with you, or you might want to contribute to an open-source project.",
          "To download a repository, run:",
        ],
        codeSnippet: {
          code: "git clone https://github.com/TEAM-NAME/task-manager.git",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Git downloads the repository and creates a local working directory containing its files and available history.",
          "Enter the new directory:",
        ],
        secondSnippet: {
          code: "cd task-manager",
          language: "bash",
        },
        closingParagraphs: [
          "You can now inspect the code, create branches, make changes, and commit your work.",
          "The difference between git init and git clone is straightforward: git init initializes a repository in the current directory, while git clone retrieves an existing repository and sets up a local copy.",
        ],
      },
      {
        number: 6,
        title: "6. Pull Remote Changes",
        paragraphs: [
          "Shared repositories change as teammates push new commits. Before continuing work on a branch, you may need to integrate the latest changes from GitHub.",
          "For example, a teammate has updated a backend route on the remote main branch. If you're ready to update your local main branch, run:",
        ],
        codeSnippet: {
          code: "git switch main\ngit pull",
          language: "bash",
        },
        postSnippetParagraphs: [
          "This assumes your local main branch is configured to track the correct remote branch.",
          "The git pull command fetches remote changes and integrates them into your current branch according to the configured pull behavior. If the changes cannot be reconciled automatically, Git may require you to resolve conflicts.",
          "A common collaborative workflow is to update the relevant branch, create a feature branch, implement the change, commit it, and push that branch for review.",
        ],
      },
    ],
  },
  {
    id: "git-04",
    order: 4,
    number: "04",
    title: "04. Branching, Merging & Conflict Resolution",
    shortTitle: "Branching, Merging & Conflict Resolution",
    summary:
      "Isolate feature development on branches, integrate code with merges, recognize conflict markers, and safely resolve competing edits.",
    estimatedMinutes: 35,
    objectives: [
      "Understand why branches are useful.",
      "Create and switch between branches.",
      "Develop features independently.",
      "Merge branches into a destination branch.",
      "Identify and resolve merge conflicts.",
      "Verify changes after a merge.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Why Do Developers Use Branches?",
        paragraphs: [
          "A working application often needs several features developed at the same time. One developer might be improving authentication while another is building a dashboard. Making all these changes directly on the main branch can make the code harder to review and the working version harder to maintain.",
          "Branches provide separate lines of development within the same repository. Developers can implement features, create commits, and test changes without immediately integrating them into the main branch.",
          "This makes development more organized and gives the team greater control over when changes become part of the shared codebase.",
        ],
      },
      {
        number: 2,
        title: "2. Create a Feature Branch",
        paragraphs: [
          "Let's use Google sign-in as an example of a new feature.",
          "Before starting, make sure you're on the correct base branch and have incorporated the latest shared changes if your workflow requires it.",
          "Create a branch and switch to it:",
        ],
        codeSnippet: {
          code: "git switch -c feature/google-login",
          language: "bash",
        },
        postSnippetParagraphs: [
          "This creates the branch and switches your working directory to it.",
          "To verify the current branch, run:",
        ],
        secondSnippet: {
          code: "git branch --show-current",
          language: "bash",
        },
        closingParagraphs: [
          "You can now implement Google sign-in and commit the changes on the feature branch.",
          "The main branch remains separate from your feature's new commits until you integrate them.",
        ],
      },
      {
        number: 3,
        title: "3. Commit Your Feature",
        paragraphs: [
          "After implementing and testing the feature, inspect the changes:",
        ],
        codeSnippet: {
          code: "git status\ngit diff",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Stage and commit the relevant files:",
        ],
        secondSnippet: {
          code: 'git add .\ngit commit -m "Add Google login support"',
          language: "bash",
        },
        closingParagraphs: [
          "Review the staged files before committing, particularly if the project contains local configuration files or generated files that should not be included.",
          "The feature now has its own commit history on the branch.",
        ],
      },
      {
        number: 4,
        title: "4. Merge the Feature into Main",
        paragraphs: [
          "Once the feature is ready, its changes need to be integrated into the destination branch.",
          "Switch to the main branch:",
        ],
        codeSnippet: {
          code: "git switch main",
          language: "bash",
        },
        postSnippetParagraphs: [
          "If required, update it before merging. Then run:",
        ],
        secondSnippet: {
          code: "git merge feature/google-login",
          language: "bash",
        },
        closingParagraphs: [
          "Git integrates the feature branch's changes into main. Depending on the commit history and merge strategy, this may create a merge commit or move the branch pointer forward.",
          "In many team environments, developers open a GitHub pull request instead of merging directly. This allows the team to review and test the changes before integration.",
        ],
      },
      {
        number: 5,
        title: "5. Understand Merge Conflicts",
        paragraphs: [
          "Git can merge many changes automatically, but it cannot always determine how competing edits should be combined.",
          "For example, two developers may modify the same lines in a backend authentication file. One changes the error response, while the other changes the validation logic. When the branches are integrated, Git may identify a conflict because it cannot safely choose between the competing versions.",
          "A conflicted file may contain markers such as:",
        ],
        codeSnippet: {
          code: `<<<<<<< HEAD\nreturn res.status(401).json({ message: "Invalid credentials" });\n=======\nreturn res.status(400).json({ message: "Check your login details" });\n>>>>>>> feature/login-validation`,
          language: "diff",
        },
        postSnippetParagraphs: [
          "The section above ======= represents the current branch's version, while the section below represents the incoming changes. The exact labels can vary depending on the operation.",
          "These markers indicate that the developer needs to decide how the final code should behave.",
        ],
      },
      {
        number: 6,
        title: "6. Resolve a Conflict",
        paragraphs: [
          "Open the conflicted file and inspect both versions. Determine the intended behavior, then edit the code to preserve the correct logic.",
          "You might keep one version, combine both changes, or write a new implementation that incorporates the required behavior.",
          "Remove all conflict markers, save the file, and test the result.",
          "Stage the resolved file:",
        ],
        codeSnippet: {
          code: "git add server/routes/auth.js",
          language: "bash",
        },
        postSnippetParagraphs: [
          "If Git is waiting for a merge commit, complete the merge:",
        ],
        secondSnippet: {
          code: "git commit",
          language: "bash",
        },
        closingParagraphs: [
          "Finally, inspect the repository status and test the affected functionality.",
          "The important point is that resolving a conflict is not just about removing markers. The final code must preserve the intended behavior of the application.",
        ],
      },
    ],
  },
  {
    id: "git-05",
    order: 5,
    number: "05",
    title: "05. Git History & Undoing Mistakes",
    shortTitle: "Git History & Undoing Mistakes",
    summary:
      "Inspect logs, compare commits, restore unstaged files, unstage accidental additions, amend recent commits, and safely revert shared history.",
    estimatedMinutes: 30,
    objectives: [
      "Inspect repository history.",
      "Understand and compare commit changes.",
      "Discard unwanted unstaged changes.",
      "Unstage accidentally selected files.",
      "Correct the most recent local commit.",
      "Safely reverse a commit that has already been shared.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Inspect Your Commit History",
        paragraphs: [
          "A feature worked yesterday, but after several changes, it no longer behaves as expected. Before rewriting the code, inspect the repository's history to understand what has changed.",
          "Run:",
        ],
        codeSnippet: {
          code: "git log",
          language: "bash",
        },
        postSnippetParagraphs: [
          "For a shorter view:",
        ],
        secondSnippet: {
          code: "git log --oneline",
          language: "bash",
        },
        closingParagraphs: [
          "Each entry represents a commit and includes its identifier and message. This history helps you identify when a feature was introduced, which changes came before it, and where a potential regression may have started.",
        ],
      },
      {
        number: 2,
        title: "2. Inspect a Specific Commit",
        paragraphs: [
          "Once you've identified a relevant commit, examine its details:",
        ],
        codeSnippet: {
          code: "git show COMMIT_HASH",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Replace COMMIT_HASH with an actual identifier from your repository.",
          "This displays the commit's metadata and the changes it introduced.",
          "You can also compare staged and unstaged work:",
        ],
        secondSnippet: {
          code: "git diff\ngit diff --staged",
          language: "bash",
        },
        closingParagraphs: [
          "The first command helps you inspect unstaged changes. The second shows what you've selected for the next commit.",
          "These comparisons make it easier to separate your current work from previously recorded changes.",
        ],
      },
      {
        number: 3,
        title: "3. Discard Unstaged Changes",
        paragraphs: [
          "You've experimented with a component and decided that the edits are no longer useful. If you want to discard its unstaged modifications and restore the version recorded in the index, run:",
        ],
        codeSnippet: {
          code: "git restore src/App.jsx",
          language: "bash",
        },
        postSnippetParagraphs: [
          "This discards unstaged changes to the specified file.",
          "Be careful with this command. Changes that have not been saved elsewhere may be difficult or impossible to recover afterward.",
          "Before discarding work, make sure the file doesn't contain changes you still need.",
        ],
      },
      {
        number: 4,
        title: "4. Unstage a File",
        paragraphs: [
          "Sometimes a file is added to the staging area accidentally. For example, you may have staged a local configuration file alongside your intended code changes.",
          "To unstage it, run:",
        ],
        codeSnippet: {
          code: "git restore --staged .env",
          language: "bash",
        },
        postSnippetParagraphs: [
          "This removes the file from the staging area without deleting it or discarding its contents.",
          "If the file contains credentials, remember that unstaging it does not remove it from an earlier commit. If a secret has already been exposed, revoke or rotate it and follow the appropriate repository cleanup procedure.",
        ],
      },
      {
        number: 5,
        title: "5. Correct Your Most Recent Commit",
        paragraphs: [
          "A common mistake is forgetting to include a related file in a commit. If the commit is local and hasn't been shared, you can amend it.",
          "Stage the missing file:",
        ],
        codeSnippet: {
          code: "git add README.md",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Then amend the previous commit:",
        ],
        secondSnippet: {
          code: "git commit --amend",
          language: "bash",
        },
        closingParagraphs: [
          "Git replaces the previous commit with a new one containing the updated snapshot and commit message as configured.",
          "Amending changes the commit identifier. Avoid rewriting commits that teammates are already relying on unless your team has explicitly agreed to that workflow.",
        ],
      },
      {
        number: 6,
        title: "6. Revert a Shared Commit",
        paragraphs: [
          "A different approach is needed when an incorrect commit has already been pushed to a shared branch.",
          "Rather than rewriting shared history, you can create a new commit that reverses the earlier change:",
        ],
        codeSnippet: {
          code: "git revert COMMIT_HASH",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Replace the placeholder with the actual commit identifier.",
          "Git creates a new commit that reverses the selected commit's changes. You may need to resolve conflicts if the affected files have changed since the original commit.",
          "This is generally safer for shared branches than resetting the branch and force-pushing a rewritten history.",
          "Before choosing a recovery command, identify the state of the change: is it unstaged, staged, committed locally, or already shared? The correct solution depends on that distinction.",
        ],
      },
    ],
  },
  {
    id: "git-06",
    order: 6,
    number: "06",
    title: "06. Team Collaboration & Repository Management",
    shortTitle: "Team Collaboration & Repository Management",
    summary:
      "Collaborate with feature branches, open comprehensive pull requests, manage issues, configure .gitignore, and write clear READMEs.",
    estimatedMinutes: 35,
    objectives: [
      "Understand forks and pull requests.",
      "Contribute changes using feature branches.",
      "Review and discuss code changes.",
      "Track tasks and bugs using GitHub Issues.",
      "Write useful README documentation.",
      "Configure .gitignore and protect sensitive information.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Understand the Team Workflow",
        paragraphs: [
          "A development team might have several people working on the same task management application. One developer is adding password reset functionality, another is improving the dashboard, and a third is fixing a backend bug.",
          "Each developer can work independently on a feature branch. When a change is ready, the developer publishes the branch and opens a pull request for review.",
          "This workflow helps keep the main branch organized and gives the team an opportunity to discuss the implementation, identify problems, and verify changes before they are integrated.",
        ],
      },
      {
        number: 2,
        title: "2. Push a Feature Branch",
        paragraphs: [
          "Start from the latest appropriate base branch:",
        ],
        codeSnippet: {
          code: "git switch main\ngit pull",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Create a branch for the new feature:",
        ],
        secondSnippet: {
          code: "git switch -c feature/password-reset",
          language: "bash",
        },
        middleParagraphs: [
          "Implement and test the feature, then commit the changes:",
        ],
        thirdSnippet: {
          code: 'git add .\ngit commit -m "Add password reset flow"',
          language: "bash",
        },
        afterThirdParagraphs: [
          "Publish the branch to GitHub:",
        ],
        fourthSnippet: {
          code: "git push -u origin feature/password-reset",
          language: "bash",
        },
        closingParagraphs: [
          "The branch is now available for teammates to review.",
        ],
      },
      {
        number: 3,
        title: "3. Create a Pull Request",
        paragraphs: [
          "Open the repository on GitHub and create a pull request from feature/password-reset into main.",
          "A good pull request explains what changed, why the change was necessary, and how it was tested.",
          "For example, the description might explain that a new password reset endpoint has been added, that expired reset tokens are rejected, and that automated tests cover the main success and failure cases.",
          "Your teammates can inspect the diff, comment on specific lines, request changes, and approve the implementation. Once the repository's review and status-check requirements are satisfied, the change can be merged.",
          "A pull request is more than a request to merge code. It provides a place to discuss the implementation and make sure the change meets the team's expectations.",
        ],
      },
      {
        number: 4,
        title: "4. Understand Forks",
        paragraphs: [
          "Contributing to a project you don't own often requires a different workflow. You may not have permission to create branches directly in the original repository.",
          "A fork creates a copy of a repository under another GitHub account. You can make changes in your fork and submit a pull request back to the original project.",
          "Forks are common in open-source development because they let contributors propose changes without needing direct write access to the original repository.",
        ],
      },
      {
        number: 5,
        title: "5. Manage Tasks with GitHub Issues",
        paragraphs: [
          "Code is only one part of maintaining an application. Teams also need a reliable way to track bugs, feature requests, and planned improvements.",
          "When a user reports that the dashboard crashes when there are no tasks, create a GitHub Issue describing the problem, including reproduction steps and the expected behavior.",
          "A developer can investigate the issue, implement a fix on a feature branch, and link the resulting pull request to the issue.",
          "This creates a record connecting the original problem to the implementation and its resolution.",
        ],
      },
      {
        number: 6,
        title: "6. Write a Useful README",
        paragraphs: [
          "A repository should help another developer understand the project without requiring a long conversation with its creator.",
          "A README typically explains what the application does, what is required to run it, how to install dependencies, how to configure the environment, and how to start the services.",
          "For a frontend and backend application, a simple starting structure could be:",
        ],
        codeSnippet: {
          code: `# Task Manager\n\nA task management application with a frontend\nand a backend API.\n\n## Getting Started\n\n1. Clone the repository.\n2. Install the frontend dependencies.\n3. Install the backend dependencies.\n4. Configure the required environment variables.\n5. Start both services.\n\n## Configuration\n\nSee the environment configuration documentation\nfor required local settings.`,
          language: "markdown",
        },
        closingParagraphs: [
          "Adapt these instructions to the actual project. Documentation that contains incorrect setup commands can be more frustrating than having no instructions at all.",
        ],
      },
      {
        number: 7,
        title: "7. Use .gitignore",
        paragraphs: [
          "Projects frequently contain files that should not be committed, including installed dependencies, generated output, local environment files, and logs.",
          "A Node.js project's .gitignore might include:",
        ],
        codeSnippet: {
          code: `node_modules/\n.env\n.env.*\n!.env.example\ndist/\nbuild/\n*.log`,
          language: "gitignore",
        },
        closingParagraphs: [
          "Adjust these rules to match the project. The example excludes local environment files while allowing a deliberately prepared .env.example template.",
          "One important detail: .gitignore does not automatically stop tracking a file that has already been committed. If a tracked file should no longer be tracked, remove it from Git's index and commit that change.",
          "Never commit passwords, API keys, private keys, or other sensitive credentials. Ignoring a file is useful, but it is not a replacement for proper secrets management.",
        ],
      },
    ],
  },
  {
    id: "git-07",
    order: 7,
    number: "07",
    title: "07. Git in a Real DevOps Workflow",
    shortTitle: "Git in a Real DevOps Workflow",
    summary:
      "Connect version control to the CI/CD lifecycle, GitHub Actions automation, continuous delivery, and deployment pipelines.",
    estimatedMinutes: 30,
    objectives: [
      "Understand the role of Git in the DevOps lifecycle.",
      "Follow code changes from local development to GitHub.",
      "Explain the purpose of pull requests and code reviews.",
      "Understand Continuous Integration and Continuous Delivery or Deployment.",
      "Recognize the role of GitHub Actions.",
      "Distinguish between pushing code and deploying an application.",
    ],
    sections: [
      {
        number: 1,
        title: "1. Connect Git to the DevOps Lifecycle",
        paragraphs: [
          "The application is working locally, the source code is hosted on GitHub, and the team is ready to release updates. The next challenge is delivering those updates reliably without manually repeating every testing and deployment step.",
          "This is where Git becomes part of a broader DevOps workflow.",
          "Git records code changes. GitHub hosts the repository and coordinates collaboration. Automation tools can then validate changes, build the application, and help release it to the intended environment.",
          "A typical workflow includes development, committing, pushing, code review, automated testing, building, and deployment.",
        ],
      },
      {
        number: 2,
        title: "2. Develop and Commit Changes",
        paragraphs: [
          "After implementing and testing a new task filtering feature locally, inspect the changes:",
        ],
        codeSnippet: {
          code: "git status\ngit diff",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Stage and commit the relevant files:",
        ],
        secondSnippet: {
          code: 'git add .\ngit commit -m "Add task filtering"',
          language: "bash",
        },
        closingParagraphs: [
          "This records the change in the repository's history.",
          "Review staged files before committing, particularly when the project contains unrelated modifications, generated files, or sensitive configuration.",
        ],
      },
      {
        number: 3,
        title: "3. Push Changes to GitHub",
        paragraphs: [
          "Publish the feature branch:",
        ],
        codeSnippet: {
          code: "git push -u origin feature/task-filtering",
          language: "bash",
        },
        postSnippetParagraphs: [
          "Your teammates can now access the branch on GitHub.",
          "Open a pull request to propose integrating the feature into the main branch. The team can inspect the changes, discuss the implementation, and verify that the required checks have passed.",
          "This review stage helps identify issues before the code becomes part of the shared application.",
        ],
      },
      {
        number: 4,
        title: "4. Understand Continuous Integration",
        paragraphs: [
          "Continuous Integration, or CI, is the practice of regularly integrating code changes and automatically checking that the software remains in a working state.",
          "For example, a GitHub Actions workflow can run when a pull request is opened. It might install dependencies, execute automated tests, and build the frontend and backend.",
          "If a test fails, the team can investigate the problem before merging the changes. This is particularly useful when a project has several developers, because a change that works on one developer's machine may still break an existing feature.",
          "The exact checks depend on the application. A React frontend, Node.js API, and containerized service may each need different validation steps.",
        ],
      },
      {
        number: 5,
        title: "5. Understand Continuous Delivery and Deployment",
        paragraphs: [
          "After the required checks pass, the next stage is preparing or releasing the application.",
          "Continuous Delivery keeps the application in a releasable state. Production deployment may still require an explicit approval or release action.",
          "Continuous Deployment goes further by automatically releasing qualifying changes to production when the configured conditions are satisfied.",
          "The right approach depends on the project's testing coverage, operational requirements, and tolerance for risk. Both approaches aim to make software releases more consistent and less dependent on manual work.",
        ],
      },
      {
        number: 6,
        title: "6. Explore GitHub Actions",
        paragraphs: [
          "GitHub Actions allows developers to define automated workflows in YAML files stored in the repository, commonly under .github/workflows/.",
          "A workflow can run in response to events such as a pull request, a push to a branch, or a manual trigger.",
          "For example, one workflow might run tests whenever a pull request is opened. Another might build and deploy the application after changes are merged into the configured deployment branch.",
          "Deployment requires more than a workflow file. The hosting environment, permissions, credentials, build commands, and deployment steps must also be configured correctly.",
          "Simply pushing code to GitHub does not guarantee that the application will be deployed.",
        ],
      },
      {
        number: 7,
        title: "7. Follow a Change from Development to Deployment",
        paragraphs: [
          "For a change to the application's login page, the developer implements the feature locally, tests it, commits the changes, and pushes a feature branch to GitHub. A pull request is opened, allowing teammates to review the code while automated checks run.",
          "After the change is approved and merged, the configured deployment workflow may build the application and publish it to the hosting platform.",
          "The team can then trace the release back to the original code changes, review, and automated checks.",
          "This is the larger purpose of learning Git and GitHub in a DevOps course. The commands matter, but the real skill is understanding how version control, collaboration, testing, and deployment fit together to deliver reliable software.",
        ],
      },
    ],
  },
];
