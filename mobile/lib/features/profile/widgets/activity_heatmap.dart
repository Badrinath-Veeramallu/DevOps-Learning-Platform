import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/activity_model.dart';

/// Single cell representation for the 52-week activity calendar grid.
class HeatmapCellData {
  final String date;
  final String formattedDate;
  final int count;
  final int level; // 0 to 4
  final bool isFuture;
  final int dayOfWeek; // 0 = Sun, 6 = Sat
  final int dayOfMonth;
  final String monthShort;

  const HeatmapCellData({
    required this.date,
    required this.formattedDate,
    required this.count,
    required this.level,
    required this.isFuture,
    required this.dayOfWeek,
    required this.dayOfMonth,
    required this.monthShort,
  });
}

class MonthLabelData {
  final String label;
  final int weekIndex;

  const MonthLabelData({
    required this.label,
    required this.weekIndex,
  });
}

/// Interactive 52-week activity heatmap card matching Web's `ActivityHeatmap.jsx`.
///
/// Fetches aggregated activity data from `GET /api/activity?tz=...` and renders
/// a GitHub/LeetCode-style calendar grid with Burgundy color intensity.
class ActivityHeatmap extends StatefulWidget {
  final ApiClient? apiClient;
  final String? initialTimezone;

  const ActivityHeatmap({
    super.key,
    this.apiClient,
    this.initialTimezone,
  });

  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  ActivityHistoryModel? _activityData;
  bool _isLoading = true;
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _fetchActivity();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchActivity() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = widget.apiClient ??
          ApiClient(storageService: SecureStorageService());

      // Resolve timezone identifier or fallback safely to UTC
      final tz = widget.initialTimezone ??
          (DateTime.now().timeZoneName.isNotEmpty
              ? DateTime.now().timeZoneName
              : 'UTC');

      final res = await client.getActivity(tz: tz);
      final model = ActivityHistoryModel.fromJson(res);

      if (mounted) {
        setState(() {
          _activityData = model;
          _isLoading = false;
        });

        // Auto-scroll to the latest week on the far right
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load learning activity.';
          _isLoading = false;
        });
      }
    }
  }

  /// Resolves the 5-level color for a given activity intensity level (0 to 4).
  Color _resolveCellColor(int level, {bool isFuture = false}) {
    if (isFuture) {
      return Colors.transparent;
    }
    switch (level) {
      case 1:
        return const Color(0xFF60343D);
      case 2:
        return const Color(0xFF82535D);
      case 3:
        return const Color(0xFFB88A91);
      case 4:
        return const Color(0xFFE7D4D7);
      case 0:
      default:
        return const Color(0xFF141926);
    }
  }

  Color _resolveCellBorderColor(int level, {bool isFuture = false}) {
    if (isFuture) {
      return Colors.transparent;
    }
    switch (level) {
      case 1:
        return const Color(0xFF723D48);
      case 2:
        return const Color(0xFF9D626D);
      case 3:
        return const Color(0xFFC79CA3);
      case 4:
        return const Color(0xFFF3EFF0);
      case 0:
      default:
        return const Color(0xFF1E293B);
    }
  }

  String _formatDateString(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  ({List<List<HeatmapCellData>> weeks, List<MonthLabelData> monthLabels})
      _buildGrid(Map<String, int> countsMap) {
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day, 12);
    final todayStr = _formatDateString(now);

    // 365 days window: startDate is 364 days before today
    final startDateUtc = todayUtc.subtract(const Duration(days: 364));
    // In Dart weekday is 1=Mon, 7=Sun. Sunday in 0-indexed is `weekday % 7`.
    final startDayOfWeek = startDateUtc.weekday % 7;
    final gridStartUtc =
        startDateUtc.subtract(Duration(days: startDayOfWeek));

    final List<List<HeatmapCellData>> generatedWeeks = [];
    var cur = gridStartUtc;
    var currentWeek = <HeatmapCellData>[];

    while (cur.isBefore(todayUtc) ||
        cur.isAtSameMomentAs(todayUtc) ||
        currentWeek.isNotEmpty) {
      final dateStr = _formatDateString(cur);
      final isFuture = dateStr.compareTo(todayStr) > 0;
      final count = countsMap[dateStr] ?? 0;

      int level = 0;
      if (!isFuture) {
        if (count >= 7) {
          level = 4;
        } else if (count >= 4) {
          level = 3;
        } else if (count >= 2) {
          level = 2;
        } else if (count >= 1) {
          level = 1;
        }
      }

      final monthName = _monthNames[cur.month - 1];
      final formattedDate = '$monthName ${cur.day}, ${cur.year}';

      currentWeek.add(
        HeatmapCellData(
          date: dateStr,
          formattedDate: formattedDate,
          count: count,
          level: level,
          isFuture: isFuture,
          dayOfWeek: cur.weekday % 7,
          dayOfMonth: cur.day,
          monthShort: monthName,
        ),
      );

      if (currentWeek.length == 7) {
        generatedWeeks.add(currentWeek);
        currentWeek = [];
        if (cur.isAfter(todayUtc) || cur.isAtSameMomentAs(todayUtc)) {
          break;
        }
      }

      cur = cur.add(const Duration(days: 1));
    }

    // Extract month labels with collision avoidance (>=3 columns apart)
    final List<MonthLabelData> rawMonthLabels = [];
    for (int wIdx = 0; wIdx < generatedWeeks.length; wIdx++) {
      final week = generatedWeeks[wIdx];
      final firstOfMonth =
          week.where((d) => d.dayOfMonth == 1 && !d.isFuture).firstOrNull;

      if (firstOfMonth != null) {
        rawMonthLabels.add(
          MonthLabelData(label: firstOfMonth.monthShort, weekIndex: wIdx),
        );
      } else if (wIdx == 0 && week.isNotEmpty) {
        rawMonthLabels.add(
          MonthLabelData(label: week[0].monthShort, weekIndex: 0),
        );
      }
    }

    final List<MonthLabelData> filteredMonthLabels = [];
    for (int i = 0; i < rawMonthLabels.length; i++) {
      final current = rawMonthLabels[i];
      final prev =
          filteredMonthLabels.isNotEmpty ? filteredMonthLabels.last : null;
      if (prev != null && (current.weekIndex - prev.weekIndex < 3)) {
        continue;
      }
      filteredMonthLabels.add(current);
    }

    return (weeks: generatedWeeks, monthLabels: filteredMonthLabels);
  }

  void _showCellTooltip(HeatmapCellData cell) {
    if (cell.isFuture) return;
    final String msg = cell.count == 0
        ? 'No activity on ${cell.formattedDate}'
        : '${cell.count} ${cell.count == 1 ? "activity" : "activities"} on ${cell.formattedDate}';

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.surfaceElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final countsMap = _activityData?.toCountsMap() ?? {};
    final grid = _buildGrid(countsMap);
    final totalActivities = _activityData?.total ?? 0;

    const double cellSize = 11.0;
    const double cellSpacing = 3.0;
    const double columnWidth = cellSize + cellSpacing;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learning Activity',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your learning activity over the past year.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _isLoading && _activityData == null
                        ? '—'
                        : '$totalActivities',
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.lightAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    'activities in the last year',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSubtle,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Loading / Error / Grid View
          if (_isLoading && _activityData == null)
            const SizedBox(
              height: 140,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.lightAccent,
                ),
              ),
            )
          else if (_errorMessage != null && _activityData == null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(
                    _errorMessage!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _fetchActivity,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          else ...[
            // Main Heatmap Grid with Weekdays and Horizontal Scroll
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weekday Labels Column (Mon, Wed, Fri matching rows 1, 3, 5)
                Padding(
                  padding: const EdgeInsets.only(top: 20, right: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWeekdayLabel(''),
                      _buildWeekdayLabel('Mon'),
                      _buildWeekdayLabel(''),
                      _buildWeekdayLabel('Wed'),
                      _buildWeekdayLabel(''),
                      _buildWeekdayLabel('Fri'),
                      _buildWeekdayLabel(''),
                    ],
                  ),
                ),

                // Scrollable 52-Week Columns + Month Labels
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month Labels Header Row
                        SizedBox(
                          height: 16,
                          width: grid.weeks.length * columnWidth,
                          child: Stack(
                            children: grid.monthLabels.map((m) {
                              return Positioned(
                                left: m.weekIndex * columnWidth,
                                child: Text(
                                  m.label,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSubtle,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Week Columns
                        Row(
                          children: grid.weeks.map((week) {
                            return Padding(
                              padding: const EdgeInsets.only(right: cellSpacing),
                              child: Column(
                                children: week.map((cell) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: cellSpacing),
                                    child: InkWell(
                                      onTap: cell.isFuture
                                          ? null
                                          : () => _showCellTooltip(cell),
                                      borderRadius:
                                          BorderRadius.circular(2.5),
                                      child: Container(
                                        width: cellSize,
                                        height: cellSize,
                                        decoration: BoxDecoration(
                                          color: _resolveCellColor(
                                            cell.level,
                                            isFuture: cell.isFuture,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(2.5),
                                          border: Border.all(
                                            color: _resolveCellBorderColor(
                                              cell.level,
                                              isFuture: cell.isFuture,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. Footer Legend Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Less',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSubtle,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 5),
                ...List.generate(5, (lvl) {
                  return Container(
                    width: cellSize,
                    height: cellSize,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: _resolveCellColor(lvl),
                      borderRadius: BorderRadius.circular(2.5),
                      border: Border.all(
                        color: _resolveCellBorderColor(lvl),
                        width: 1,
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 5),
                Text(
                  'More',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSubtle,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekdayLabel(String label) {
    return SizedBox(
      height: 14,
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSubtle,
          fontSize: 9,
          height: 1.1,
        ),
      ),
    );
  }
}
