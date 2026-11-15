/// Model representing user learning streak data matching Web's `streak` object.
class StreakModel {
  final int currentStreak;
  final int longestStreak;
  final bool isActiveToday;
  final bool hasActivityYesterday;

  const StreakModel({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.isActiveToday = false,
    this.hasActivityYesterday = false,
  });

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    return StreakModel(
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      isActiveToday: json['isActiveToday'] == true,
      hasActivityYesterday: json['hasActivityYesterday'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'isActiveToday': isActiveToday,
      'hasActivityYesterday': hasActivityYesterday,
    };
  }
}
