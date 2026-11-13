import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/curriculum_model.dart';
import 'milestone_monument.dart';
import 'pathway_stop_node.dart';
import 'pathway_track_painter.dart';

/// Interactive curved learning pathway map for Linux Essentials.
///
/// Renders a continuous cubic-Bézier pale-blush winding road in a background
/// [CustomPaint] layer with responsive alternating left/right cards and
/// completion nodes in the foreground [Stack] layer for Linux's 6 stops.
class LinuxPathwayMap extends StatefulWidget {
  final List<CurriculumModule> modules;
  final Set<String> completedModuleIds;
  final ValueChanged<String> onSelectModule;
  final VoidCallback? onFinishTap;
  final String finishText;

  const LinuxPathwayMap({
    super.key,
    required this.modules,
    required this.completedModuleIds,
    required this.onSelectModule,
    this.onFinishTap,
    this.finishText = 'Linux System Administration Mastered!',
  });

  @override
  State<LinuxPathwayMap> createState() => _LinuxPathwayMapState();
}

class _LinuxPathwayMapState extends State<LinuxPathwayMap> {
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _startMonumentKey = GlobalKey();
  final GlobalKey _finishMonumentKey = GlobalKey();
  List<GlobalKey> _nodeKeys = [];

  List<Offset> _measuredPoints = const [];
  double _lastMeasuredWidth = -1;
  bool _measurementScheduled = false;

  @override
  void initState() {
    super.initState();
    _syncNodeKeys();
  }

  @override
  void didUpdateWidget(covariant LinuxPathwayMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final modulesChanged = oldWidget.modules.length != widget.modules.length;
    final completionChanged =
        oldWidget.completedModuleIds.length != widget.completedModuleIds.length;
    if (modulesChanged) {
      _syncNodeKeys();
      _measuredPoints = const [];
      _lastMeasuredWidth = -1;
    } else if (completionChanged) {
      _lastMeasuredWidth = -1;
    }
  }

  void _syncNodeKeys() {
    _nodeKeys = List<GlobalKey>.generate(
      widget.modules.length,
      (_) => GlobalKey(),
    );
  }

  void _scheduleMeasurement(double width) {
    if (_measurementScheduled) return;
    _measurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementScheduled = false;
      if (!mounted) return;
      _measurePoints(width);
    });
  }

  void _measurePoints(double width) {
    final stackBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || !stackBox.hasSize) return;

    final startCenter = _resolveCenter(
      _startMonumentKey,
      stackBox,
      // Monument emblem is a 52x52 circle anchored at the top center of the monument.
      localAnchor: (size) => Offset(size.width / 2, 26.0),
    );
    final finishCenter = _resolveCenter(
      _finishMonumentKey,
      stackBox,
      localAnchor: (size) => Offset(size.width / 2, 26.0),
    );

    if (startCenter == null || finishCenter == null) return;

    final nextPoints = <Offset>[startCenter];
    for (final key in _nodeKeys) {
      final nodeCenter = _resolveCenter(
        key,
        stackBox,
        localAnchor: (size) => Offset(size.width / 2, size.height / 2),
      );
      if (nodeCenter == null) return;
      nextPoints.add(nodeCenter);
    }
    nextPoints.add(finishCenter);

    final widthChanged = (width - _lastMeasuredWidth).abs() > 0.5;
    if (widthChanged || _pointsDiffer(_measuredPoints, nextPoints)) {
      setState(() {
        _measuredPoints = nextPoints;
        _lastMeasuredWidth = width;
      });
    }
  }

  Offset? _resolveCenter(
    GlobalKey key,
    RenderBox ancestor, {
    required Offset Function(Size size) localAnchor,
  }) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final global = box.localToGlobal(localAnchor(box.size));
    return ancestor.globalToLocal(global);
  }

  bool _pointsDiffer(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).distance > 0.5) return true;
    }
    return false;
  }

  List<Offset> _estimateFallbackPoints(_PathwayMetrics metrics) {
    final width = metrics.maxWidth;
    final xLeft = metrics.edgeMargin + metrics.nodeSize / 2;
    final xRight = width - metrics.edgeMargin - metrics.nodeSize / 2;
    final xCenter = width / 2;

    const double startY = 48.0;
    const double estimatedCardHeight = 200.0;
    final double stepStride = estimatedCardHeight + metrics.stopSpacing;

    final points = <Offset>[Offset(xCenter, startY)];
    double currentY = startY + 26.0 + metrics.stopSpacing + (estimatedCardHeight / 2);
    for (int i = 0; i < widget.modules.length; i++) {
      final isLeft = i % 2 == 0;
      points.add(Offset(isLeft ? xLeft : xRight, currentY));
      currentY += stepStride;
    }

    final finishY =
        currentY - (estimatedCardHeight / 2) + 26.0;
    points.add(Offset(xCenter, finishY));
    return points;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.modules.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final isAllCompleted = widget.modules.isNotEmpty &&
        widget.completedModuleIds.length >= widget.modules.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final metrics = _PathwayMetrics.fromWidth(maxWidth);

        if ((maxWidth - _lastMeasuredWidth).abs() > 0.5 ||
            _measuredPoints.length != widget.modules.length + 2) {
          _scheduleMeasurement(maxWidth);
        }

        final effectivePoints =
            _measuredPoints.length == widget.modules.length + 2 &&
                    (maxWidth - _lastMeasuredWidth).abs() <= 0.5
                ? _measuredPoints
                : _estimateFallbackPoints(metrics);

        return NotificationListener<SizeChangedLayoutNotification>(
          onNotification: (_) {
            _scheduleMeasurement(maxWidth);
            return false;
          },
          child: SizeChangedLayoutNotifier(
            child: Stack(
              key: _stackKey,
              clipBehavior: Clip.none,
              children: [
                // Background Layer: Continuous Pale-Blush + Muted-Burgundy Road
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: const Key('pathway_road_painter'),
                      painter: PathwayTrackPainter(
                        points: effectivePoints,
                        cushionWidth: metrics.roadCushionWidth,
                        roadWidth: metrics.roadBaseWidth,
                        dashWidth: metrics.roadDashWidth,
                        dashLength: metrics.roadDashLength,
                        dashSpace: metrics.roadDashSpace,
                      ),
                    ),
                  ),
                ),

                // Foreground Layer: START Monument, Alternating Stop Cards/Nodes, FINISH Monument
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // START Monument Section
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Journey Kickoff',
                            style: TextStyle(
                              color: AppColors.textSubtle,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          MilestoneMonument(
                            key: _startMonumentKey,
                            type: MilestoneMonumentType.start,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: metrics.stopSpacing),

                    // Stop Rows (Alternating Left/Right Nodes & Cards)
                    ...List.generate(widget.modules.length, (idx) {
                      final module = widget.modules[idx];
                      final isCompleted =
                          widget.completedModuleIds.contains(module.id);
                      final isPrecedingCompleted =
                          idx == 0 || widget.completedModuleIds.contains(widget.modules[idx - 1].id);
                      final isCurrent = !isCompleted && isPrecedingCompleted;
                      final status = isCompleted
                          ? StopStatus.completed
                          : (isCurrent
                              ? StopStatus.current
                              : StopStatus.locked);
                      final isLeft = idx % 2 == 0;

                      final nodeWidget = KeyedSubtree(
                        key: _nodeKeys[idx],
                        child: PathwayStopNode(
                          module: module,
                          status: status,
                          onSelectModule: widget.onSelectModule,
                          isNodeOnly: true,
                          totalStops: widget.modules.length,
                          nodeSize: metrics.nodeSize,
                        ),
                      );

                      final cardWidget = Expanded(
                        child: PathwayStopNode(
                          module: module,
                          status: status,
                          onSelectModule: widget.onSelectModule,
                          totalStops: widget.modules.length,
                          nodeSize: metrics.nodeSize,
                        ).buildStopCard(context),
                      );

                      return Padding(
                        padding: EdgeInsets.only(bottom: metrics.stopSpacing),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: isLeft
                              ? [
                                  SizedBox(width: metrics.edgeMargin),
                                  nodeWidget,
                                  SizedBox(width: metrics.nodeCardGap),
                                  cardWidget,
                                  SizedBox(width: metrics.cardOppositeIndent),
                                ]
                              : [
                                  SizedBox(width: metrics.cardOppositeIndent),
                                  cardWidget,
                                  SizedBox(width: metrics.nodeCardGap),
                                  nodeWidget,
                                  SizedBox(width: metrics.edgeMargin),
                                ],
                        ),
                      );
                    }),

                    // FINISH Monument Section
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MilestoneMonument(
                            key: _finishMonumentKey,
                            type: MilestoneMonumentType.finish,
                            isAllCompleted: isAllCompleted,
                            label: isAllCompleted && widget.onFinishTap != null
                                ? 'FINAL QUIZ'
                                : 'FINISH',
                            onTap: isAllCompleted ? widget.onFinishTap : null,
                          ),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: (maxWidth - 24).clamp(160.0, 420.0),
                            ),
                            child: Text(
                              isAllCompleted
                                  ? widget.finishText
                                  : 'Pathway Milestone Finish',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isAllCompleted
                                    ? AppColors.success
                                    : AppColors.textSubtle,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PathwayMetrics {
  final double maxWidth;
  final double nodeSize;
  final double edgeMargin;
  final double nodeCardGap;
  final double cardOppositeIndent;
  final double stopSpacing;
  final double roadCushionWidth;
  final double roadBaseWidth;
  final double roadDashWidth;
  final double roadDashLength;
  final double roadDashSpace;

  const _PathwayMetrics({
    required this.maxWidth,
    required this.nodeSize,
    required this.edgeMargin,
    required this.nodeCardGap,
    required this.cardOppositeIndent,
    required this.stopSpacing,
    required this.roadCushionWidth,
    required this.roadBaseWidth,
    required this.roadDashWidth,
    required this.roadDashLength,
    required this.roadDashSpace,
  });

  factory _PathwayMetrics.fromWidth(double maxWidth) {
    final bool isTablet = maxWidth >= 680;
    final bool isNarrow = maxWidth < 345; // 360px/375px screens minus 40px page padding

    final double nodeSize = isTablet ? 48.0 : (isNarrow ? 42.0 : 44.0);
    final double edgeMargin = isTablet ? 28.0 : (isNarrow ? 4.0 : 6.0);
    final double nodeCardGap = isTablet ? 24.0 : (isNarrow ? 10.0 : 12.0);
    final double cardOppositeIndent = isTablet
        ? (maxWidth * 0.22).clamp(80.0, 240.0)
        : (maxWidth >= 380 ? 18.0 : (maxWidth >= 345 ? 12.0 : 8.0));

    return _PathwayMetrics(
      maxWidth: maxWidth,
      nodeSize: nodeSize,
      edgeMargin: edgeMargin,
      nodeCardGap: nodeCardGap,
      cardOppositeIndent: cardOppositeIndent,
      stopSpacing: isTablet ? 48.0 : 38.0,
      roadCushionWidth: isTablet ? 46.0 : 34.0,
      roadBaseWidth: isTablet ? 34.0 : 24.0,
      roadDashWidth: isTablet ? 3.2 : 2.6,
      roadDashLength: isTablet ? 12.0 : 10.0,
      roadDashSpace: isTablet ? 12.0 : 10.0,
    );
  }
}
