/// Data models representing the DevOps Learning Platform Animation System.
///
/// Exactly mirrors the schema of Web's `git-animations.json` and `stepEngine.js`.
library;

class AnimationEdge {
  final String from;
  final String to;
  final String? label;
  final String style; // 'base', 'dash', 'ok', 'warn'

  const AnimationEdge({
    required this.from,
    required this.to,
    this.label,
    this.style = 'base',
  });

  factory AnimationEdge.fromList(List<dynamic> list) {
    return AnimationEdge(
      from: list.isNotEmpty ? list[0].toString() : '',
      to: list.length > 1 ? list[1].toString() : '',
      label: list.length > 2 && list[2] != null ? list[2].toString() : null,
      style: list.length > 3 && list[3] != null ? list[3].toString() : 'base',
    );
  }

  List<dynamic> toList() => [from, to, label, style];
}

class ActorModel {
  final String id;
  final String k; // 'box', 'file', 'pill', 'commit', 'zone', 'code', 'note'
  final double x;
  final double y;
  final double? w;
  final double? h;
  final String? text;
  final String? sub;
  final String? ic;
  final String? tone; // 'plain', 'soft', 'brand', 'warn', 'ok', 'bad', 'dim'
  final bool glow;
  final bool hide;
  final int delay;
  final double? bar;
  final String? title;
  final List<dynamic>? lines;

  const ActorModel({
    required this.id,
    required this.k,
    required this.x,
    required this.y,
    this.w,
    this.h,
    this.text,
    this.sub,
    this.ic,
    this.tone,
    this.glow = false,
    this.hide = false,
    this.delay = 0,
    this.bar,
    this.title,
    this.lines,
  });

  factory ActorModel.fromJson(String id, Map<String, dynamic> json) {
    return ActorModel(
      id: id,
      k: (json['k'] ?? 'box').toString(),
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      w: (json['w'] as num?)?.toDouble(),
      h: (json['h'] as num?)?.toDouble(),
      text: json['text']?.toString(),
      sub: json['sub']?.toString(),
      ic: json['ic']?.toString(),
      tone: json['tone']?.toString(),
      glow: json['glow'] == true,
      hide: json['hide'] == true,
      delay: (json['delay'] as num?)?.toInt() ?? 0,
      bar: (json['bar'] as num?)?.toDouble(),
      title: json['title']?.toString(),
      lines: json['lines'] as List<dynamic>?,
    );
  }

  ActorModel copyWithPatch(Map<String, dynamic> patch) {
    return ActorModel(
      id: id,
      k: patch['k']?.toString() ?? k,
      x: patch.containsKey('x')
          ? (patch['x'] as num).toDouble()
          : x,
      y: patch.containsKey('y')
          ? (patch['y'] as num).toDouble()
          : y,
      w: patch.containsKey('w')
          ? (patch['w'] as num?)?.toDouble()
          : w,
      h: patch.containsKey('h')
          ? (patch['h'] as num?)?.toDouble()
          : h,
      text: patch.containsKey('text') ? patch['text']?.toString() : text,
      sub: patch.containsKey('sub') ? patch['sub']?.toString() : sub,
      ic: patch.containsKey('ic') ? patch['ic']?.toString() : ic,
      tone: patch.containsKey('tone') ? patch['tone']?.toString() : tone,
      glow: patch.containsKey('glow') ? patch['glow'] == true : glow,
      hide: patch.containsKey('hide') ? patch['hide'] == true : false,
      delay: patch.containsKey('delay')
          ? (patch['delay'] as num?)?.toInt() ?? 0
          : 0,
      bar: patch.containsKey('bar')
          ? (patch['bar'] as num?)?.toDouble()
          : bar,
      title: patch.containsKey('title') ? patch['title']?.toString() : title,
      lines: patch.containsKey('lines')
          ? patch['lines'] as List<dynamic>?
          : lines,
    );
  }

  ActorModel copyWithHidden() {
    return ActorModel(
      id: id,
      k: k,
      x: x,
      y: y,
      w: w,
      h: h,
      text: text,
      sub: sub,
      ic: ic,
      tone: tone,
      glow: glow,
      hide: true,
      delay: 0,
      bar: bar,
      title: title,
      lines: lines,
    );
  }
}

class AnimationStep {
  final String? say;
  final Map<String, dynamic>? actors;
  final List<AnimationEdge>? edges;
  final List<String>? term;
  final bool clear;

  const AnimationStep({
    this.say,
    this.actors,
    this.edges,
    this.term,
    this.clear = false,
  });

  factory AnimationStep.fromJson(Map<String, dynamic> json) {
    List<AnimationEdge>? parsedEdges;
    if (json['edges'] is List) {
      parsedEdges = (json['edges'] as List)
          .whereType<List>()
          .map((e) => AnimationEdge.fromList(e))
          .toList();
    }

    List<String>? parsedTerm;
    if (json['term'] is List) {
      parsedTerm = (json['term'] as List).map((e) => e.toString()).toList();
    }

    return AnimationStep(
      say: json['say']?.toString(),
      actors: json['actors'] as Map<String, dynamic>?,
      edges: parsedEdges,
      term: parsedTerm,
      clear: json['clear'] == true,
    );
  }
}

class SubtopicAnimation {
  final String id; // e.g. "01.1"
  final String title;
  final List<AnimationStep> steps;
  final String? moduleId;
  final String? moduleTitle;

  const SubtopicAnimation({
    required this.id,
    required this.title,
    required this.steps,
    this.moduleId,
    this.moduleTitle,
  });

  factory SubtopicAnimation.fromJson(
    Map<String, dynamic> json, {
    String? moduleId,
    String? moduleTitle,
  }) {
    return SubtopicAnimation(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      steps: (json['steps'] as List? ?? [])
          .map((s) => AnimationStep.fromJson(s as Map<String, dynamic>))
          .toList(),
      moduleId: moduleId,
      moduleTitle: moduleTitle,
    );
  }
}

class AnimationModule {
  final String id; // e.g. "01"
  final String title;
  final List<SubtopicAnimation> subtopics;

  const AnimationModule({
    required this.id,
    required this.title,
    required this.subtopics,
  });

  factory AnimationModule.fromJson(Map<String, dynamic> json) {
    final modId = (json['id'] ?? '').toString();
    final modTitle = (json['title'] ?? '').toString();

    return AnimationModule(
      id: modId,
      title: modTitle,
      subtopics: (json['subtopics'] as List? ?? [])
          .map(
            (s) => SubtopicAnimation.fromJson(
              s as Map<String, dynamic>,
              moduleId: modId,
              moduleTitle: modTitle,
            ),
          )
          .toList(),
    );
  }
}

class AnimationFrame {
  final Map<String, ActorModel> actors;
  final List<AnimationEdge> edges;
  final List<String> term;
  final int termStart;
  final String? say;

  const AnimationFrame({
    required this.actors,
    required this.edges,
    required this.term,
    required this.termStart,
    this.say,
  });
}
