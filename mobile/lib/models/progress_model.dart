/// Data model representing learning pathway progress state.
///
/// Tracks user-scoped completed modules and active learning tracks with sync state.
class ProgressModel {
  final String pathway;
  final Set<String> completedModules;
  final String activeTrack;
  final String? lastAccessedModule;
  final DateTime? updatedAt;
  final bool isSynced;

  const ProgressModel({
    this.pathway = 'git',
    this.completedModules = const {},
    this.activeTrack = 'git',
    this.lastAccessedModule,
    this.updatedAt,
    this.isSynced = false,
  });

  bool isCompleted(String moduleId) => completedModules.contains(moduleId);

  ProgressModel copyWith({
    String? pathway,
    Set<String>? completedModules,
    String? activeTrack,
    String? lastAccessedModule,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return ProgressModel(
      pathway: pathway ?? this.pathway,
      completedModules: completedModules ?? this.completedModules,
      activeTrack: activeTrack ?? this.activeTrack,
      lastAccessedModule: lastAccessedModule ?? this.lastAccessedModule,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    final rawModules = json['completedModules'];
    final Set<String> modules = rawModules is List
        ? rawModules.map((e) => e.toString()).toSet()
        : {};

    return ProgressModel(
      pathway: (json['pathway'] ?? 'git').toString(),
      completedModules: modules,
      activeTrack: (json['activeTrack'] ?? 'git').toString(),
      lastAccessedModule: json['lastAccessedModule']?.toString(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      isSynced: json['isSynced'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pathway': pathway,
      'completedModules': completedModules.toList(),
      'activeTrack': activeTrack,
      if (lastAccessedModule != null) 'lastAccessedModule': lastAccessedModule,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'isSynced': isSynced,
    };
  }
}

