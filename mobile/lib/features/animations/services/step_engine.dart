import 'dart:math' as math;
import '../../../models/animation_model.dart';

class EdgeGeometry {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double mx;
  final double my;

  const EdgeGeometry({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.mx,
    required this.my,
  });
}

/// Pure calculation engine for Git subtopic animations.
///
/// Converts a sequence of JSON animation steps into renderable frames
/// and solves directed vector geometries between actors.
class StepEngine {
  StepEngine._();

  static const double stageWidth = 1000.0;
  static const double stageHeight = 400.0;

  static const Map<String, double> defaultW = {
    'file': 10.0,
    'commit': 6.0,
    'pill': 0.0,
    'box': 16.0,
    'code': 30.0,
    'note': 0.0,
    'zone': 30.0,
    'vol': 12.0,
    'layer': 24.0,
  };

  static const Map<String, double> defaultWMobile = {
    'file': 22.0,
    'commit': 13.0,
    'pill': 0.0,
    'box': 36.0,
    'code': 94.0,
    'note': 0.0,
    'zone': 30.0,
    'vol': 26.0,
    'layer': 60.0,
  };

  static const Map<String, double> halfH = {
    'file': 28.0,
    'commit': 26.0,
    'pill': 13.0,
    'box': 26.0,
    'note': 10.0,
    'vol': 32.0,
    'layer': 15.0,
  };

  /// Turns a list of steps into renderable frames matching Web `stepEngine.js`.
  static List<AnimationFrame> buildFrames(List<AnimationStep> steps) {
    final Map<String, Map<String, dynamic>> first = {};
    for (final s in steps) {
      if (s.actors != null) {
        s.actors!.forEach((id, p) {
          if (p != null &&
              !first.containsKey(id) &&
              p is Map<String, dynamic>) {
            first[id] = p;
          }
        });
      }
    }

    Map<String, ActorModel> cur = {};
    List<AnimationEdge> edges = [];
    List<String> term = [];

    final List<AnimationFrame> frames = [];

    for (final s in steps) {
      final patch = s.actors ?? {};
      final Map<String, ActorModel> next = {};

      for (final id in first.keys) {
        final prev = cur[id];
        final p = patch[id];

        if (!patch.containsKey(id)) {
          // undefined: preserve previous state or initialize hidden
          if (prev != null) {
            next[id] = prev;
          } else {
            final initialActor = ActorModel.fromJson(id, first[id]!);
            next[id] = initialActor.copyWithHidden();
          }
        } else if (p == null) {
          // null: hide actor
          final base = prev ?? ActorModel.fromJson(id, first[id]!);
          next[id] = base.copyWithHidden();
        } else if (p is Map<String, dynamic>) {
          // patch: update properties
          final base = prev ?? ActorModel.fromJson(id, first[id]!);
          next[id] = base.copyWithPatch(p);
        }
      }

      cur = next;
      if (s.edges != null) {
        edges = s.edges!;
      }
      if (s.clear) {
        term = [];
      }
      final added = s.term ?? const [];
      final termStart = term.length;
      term = [...term, ...added];

      frames.add(
        AnimationFrame(
          actors: next,
          edges: edges,
          term: term,
          termStart: termStart,
          say: s.say,
        ),
      );
    }

    return frames;
  }

  static ({double w, double h}) halfSize(
    ActorModel a, {
    double stageWidth = stageWidth,
    double stageHeight = stageHeight,
  }) {
    final mobile = stageWidth < 600.0;
    if (mobile) {
      final defaultWidth = defaultWMobile[a.k] ?? 16.0;
      final wp = ((a.w ?? defaultWidth) * stageWidth) / 100.0;
      if (a.k == 'pill' || a.k == 'note') {
        final textLen = (a.text ?? '').length;
        final full = textLen * 6.2 + 24.0;
        final w = a.w != null ? wp : math.min(full, stageWidth * 0.9);
        final denom = math.max(20.0, w - 24.0);
        final n = math.max(1, ((textLen * 6.2) / denom).ceil());
        return (w: w / 2.0, h: (n * 13.0 + 10.0) / 2.0);
      }
      if (a.k == 'code') {
        final linesCount = (a.lines ?? const []).length;
        return (w: wp / 2.0, h: ((linesCount * 14.0 + 40.0) / 2.0));
      }
      if (a.k == 'commit') {
        return (w: wp / 2.0, h: wp / 2.0);
      }
      final double hVal = switch (a.k) {
        'file' => 24.0,
        'layer' => 12.0,
        'vol' => 30.0,
        _ => 27.0,
      };
      return (w: wp / 2.0, h: hVal);
    }

    final w = a.w ?? defaultW[a.k] ?? 16.0;
    if (a.k == 'pill' || a.k == 'note') {
      final textLen = (a.text ?? '').length;
      return (w: (textLen * 7.2 + 30.0) / 2.0, h: halfH['pill'] ?? 13.0);
    }
    if (a.k == 'code') {
      final linesCount = (a.lines ?? const []).length;
      return (w: w * 5.0, h: ((linesCount * 5.0 + 12.0) * 2.0));
    }
    return (w: w * 5.0, h: halfH[a.k] ?? 26.0);
  }

  /// Line between two actors, trimmed so arrows stop at actor borders (viewBox units).
  static EdgeGeometry? edgeGeometry(
    ActorModel a,
    ActorModel b, {
    double stageWidth = stageWidth,
    double stageHeight = stageHeight,
  }) {
    final sx = stageWidth / 100.0;
    final sy = stageHeight / 100.0;
    final ax = a.x * sx;
    final ay = a.y * sy;
    final bx = b.x * sx;
    final by = b.y * sy;
    final dx = bx - ax;
    final dy = by - ay;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0.0) return null;

    double t(double hw, double hh) {
      final tx = dx != 0.0 ? hw / dx.abs() : double.infinity;
      final ty = dy != 0.0 ? hh / dy.abs() : double.infinity;
      return math.min(tx, ty);
    }

    final sizeA = halfSize(a, stageWidth: stageWidth, stageHeight: stageHeight);
    final sizeB = halfSize(b, stageWidth: stageWidth, stageHeight: stageHeight);
    final ta = t(sizeA.w, sizeA.h);
    final tb = t(sizeB.w, sizeB.h);

    if (ta + tb >= 0.98) return null; // actors touch: no room for line

    final ux = dx / len;
    final uy = dy / len;
    final gap = stageWidth < 600.0 ? 3.0 : 5.0;

    return EdgeGeometry(
      x1: ax + dx * ta + ux * gap,
      y1: ay + dy * ta + uy * gap,
      x2: bx - dx * tb - ux * gap,
      y2: by - dy * tb - uy * gap,
      mx: (ax + bx) / 2.0,
      my: (ay + by) / 2.0,
    );
  }
}
