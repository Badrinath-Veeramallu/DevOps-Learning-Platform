/// Model representing a DevOps learning path track.
///
/// Matches the 6 core paths defined in Web's `Dashboard.jsx`.
class LearningPathTrack {
  final String id;
  final String title;
  final String level; // Foundational, Intermediate, Advanced
  final String modules;
  final String description;
  final bool hasPathway;

  const LearningPathTrack({
    required this.id,
    required this.title,
    required this.level,
    required this.modules,
    required this.description,
    this.hasPathway = false,
  });

  /// The 6 core learning tracks from `web/src/pages/Dashboard.jsx`.
  static const List<LearningPathTrack> defaultTracks = [
    LearningPathTrack(
      id: 'git',
      title: 'Git & Collaborative Workflows',
      level: 'Foundational',
      modules: '7 Modules · Interactive Pathway',
      description:
          'Version control strategies, GitOps branch patterns, interactive rebasing, merge conflict resolution, and commit workflows.',
      hasPathway: true,
    ),
    LearningPathTrack(
      id: 'linux',
      title: 'Linux Systems & Automation',
      level: 'Foundational',
      modules: '8 Modules',
      description:
          'Linux kernel fundamentals, process management, permissions, systemd services, and bash shell automation.',
      hasPathway: false,
    ),
    LearningPathTrack(
      id: 'docker',
      title: 'Docker & Container Engineering',
      level: 'Intermediate',
      modules: '8 Modules',
      description:
          'Container isolation, multi-stage Dockerfile architecture, layer caching, container networking, and security best practices.',
      hasPathway: false,
    ),
    LearningPathTrack(
      id: 'kubernetes',
      title: 'Kubernetes Cluster Architecture',
      level: 'Advanced',
      modules: '12 Modules',
      description:
          'Workload orchestration: Deployments, StatefulSets, Services, Ingress controllers, ConfigMaps, and Helm charts.',
      hasPathway: false,
    ),
    LearningPathTrack(
      id: 'cicd',
      title: 'CI/CD & GitOps Delivery',
      level: 'Intermediate',
      modules: '10 Modules',
      description:
          'Automated deployment pipelines using GitHub Actions, container registries, test automation, and GitOps synchronization.',
      hasPathway: false,
    ),
    LearningPathTrack(
      id: 'iac',
      title: 'Cloud Infrastructure & Terraform',
      level: 'Advanced',
      modules: '9 Modules',
      description:
          'Infrastructure as Code: declarative cloud provisioning, modular configurations, remote state management, and cloud networking.',
      hasPathway: false,
    ),
  ];
}

