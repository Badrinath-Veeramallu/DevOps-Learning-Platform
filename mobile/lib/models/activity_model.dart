/// Single day activity entry from `GET /api/activity?tz=...`.
class ActivityDay {
  final String date; // Format: YYYY-MM-DD
  final int count;

  const ActivityDay({
    required this.date,
    required this.count,
  });

  factory ActivityDay.fromJson(Map<String, dynamic> json) {
    return ActivityDay(
      date: (json['date'] ?? '').toString(),
      count: (json['count'] is num) ? (json['count'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'count': count,
    };
  }
}

/// 365-day aggregated activity history.
class ActivityHistoryModel {
  final int total;
  final List<ActivityDay> days;

  const ActivityHistoryModel({
    required this.total,
    required this.days,
  });

  factory ActivityHistoryModel.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    final List<ActivityDay> parsedDays = (rawDays is List)
        ? rawDays
            .whereType<Map<String, dynamic>>()
            .map((e) => ActivityDay.fromJson(e))
            .toList()
        : [];

    final int parsedTotal = (json['total'] is num)
        ? (json['total'] as num).toInt()
        : parsedDays.fold(0, (sum, d) => sum + d.count);

    return ActivityHistoryModel(
      total: parsedTotal,
      days: parsedDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'days': days.map((d) => d.toJson()).toList(),
    };
  }

  /// Helper map: { "YYYY-MM-DD": count } for fast lookups.
  Map<String, int> toCountsMap() {
    final map = <String, int>{};
    for (final day in days) {
      if (day.date.isNotEmpty) {
        map[day.date] = day.count;
      }
    }
    return map;
  }
}
