/// Centralized route path and name constants.
class RouteNames {
  RouteNames._();

  static const String splash = '/splash';
  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String dashboard = '/dashboard';
  static const String learningPaths = '/learning-paths';
  static const String gitPathway = '/pathways/git';
  static const String gitModule = '/pathways/git/:moduleId';
  static const String dockerPathway = '/pathways/docker';
  static const String dockerModule = '/pathways/docker/:moduleId';
  static const String linuxPathway = '/pathways/linux';
  static const String linuxModule = '/pathways/linux/:moduleId';
  static const String pathwayQuiz = '/pathways/:pathwayId/quiz';
  static const String profile = '/profile';
}
