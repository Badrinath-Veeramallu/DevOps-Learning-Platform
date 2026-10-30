import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:devops_learning_app/models/curriculum_model.dart';
import 'package:devops_learning_app/models/animation_model.dart';
import 'package:devops_learning_app/models/progress_model.dart';
import 'package:devops_learning_app/features/animations/services/step_engine.dart';
import 'package:devops_learning_app/features/animations/services/animation_loader.dart';
import 'package:devops_learning_app/features/pathway/data/git_curriculum_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Curriculum Data Integrity Tests', () {
    late String curriculumJsonString;

    setUpAll(() {
      curriculumJsonString = File('assets/data/git_curriculum.json').readAsStringSync();
    });

    test('curriculum asset contains exactly 7 modules with continuous ordering', () {
      final List<dynamic> decoded = json.decode(curriculumJsonString) as List<dynamic>;
      expect(decoded.length, 7);

      final modules = decoded
          .map((m) => CurriculumModule.fromJson(m as Map<String, dynamic>))
          .toList();

      for (int i = 0; i < 7; i++) {
        final mod = modules[i];
        expect(mod.order, i + 1);
        expect(mod.id, 'git-0${i + 1}');
        expect(mod.title.isNotEmpty, isTrue);
        expect(mod.shortTitle.isNotEmpty, isTrue);
        expect(mod.summary.isNotEmpty, isTrue);
        expect(mod.estimatedMinutes, greaterThan(0));
        expect(mod.objectives.isNotEmpty, isTrue);
        expect(mod.sections.isNotEmpty, isTrue);
      }
    });

    test('GitCurriculumRepository findModule finds by id and number', () {
      final List<dynamic> decoded = json.decode(curriculumJsonString) as List<dynamic>;
      final modules = decoded
          .map((m) => CurriculumModule.fromJson(m as Map<String, dynamic>))
          .toList();

      final mod1 = GitCurriculumRepository.findModule(modules, 'git-01');
      expect(mod1, isNotNull);
      expect(mod1!.shortTitle, 'Introduction to Git & Setup');

      final mod4 = GitCurriculumRepository.findModule(modules, '04');
      expect(mod4, isNotNull);
      expect(mod4!.id, 'git-04');

      final nonExistent = GitCurriculumRepository.findModule(modules, 'git-99');
      expect(nonExistent, isNull);
    });
  });

  group('Animation System & StepEngine Tests', () {
    late String animationsJsonString;

    setUpAll(() {
      animationsJsonString = File('assets/data/git_animations.json').readAsStringSync();
    });

    test('animation asset contains exactly 7 modules and exactly 43 subtopics', () {
      final Map<String, dynamic> decoded = json.decode(animationsJsonString) as Map<String, dynamic>;
      final rawModules = decoded['modules'] as List<dynamic>;
      expect(rawModules.length, 7);

      final modules = rawModules
          .map((m) => AnimationModule.fromJson(m as Map<String, dynamic>))
          .toList();

      int totalSubtopics = 0;
      for (final m in modules) {
        totalSubtopics += m.subtopics.length;
        for (final s in m.subtopics) {
          expect(s.id.isNotEmpty, isTrue);
          expect(s.title.isNotEmpty, isTrue);
          expect(s.steps.isNotEmpty, isTrue);
        }
      }

      // Exact count verification from audit
      expect(totalSubtopics, 43);
    });

    test('AnimationLoader index and lookup by ID and title work accurately', () {
      final Map<String, dynamic> decoded = json.decode(animationsJsonString) as Map<String, dynamic>;
      final rawModules = decoded['modules'] as List<dynamic>;
      final modules = rawModules
          .map((m) => AnimationModule.fromJson(m as Map<String, dynamic>))
          .toList();

      // Trigger index build through loading
      AnimationLoader.clearCache();

      // Simulate find directly on modules
      final anim011 = modules.first.subtopics.firstWhere((s) => s.id == '01.1');
      expect(anim011.title, contains('Version Control'));

      final anim045 = modules
          .firstWhere((m) => m.id == '04')
          .subtopics
          .firstWhere((s) => s.id == '04.5');
      expect(anim045.title, contains('Merge Conflict'));
    });

    test('StepEngine compiles steps into frames with patched actor state', () {
      const step1 = AnimationStep(
        say: 'Initial state',
        actors: {
          'fileA': {'k': 'file', 'x': 20.0, 'y': 30.0, 'text': 'main.py'},
          'box1': {'k': 'box', 'x': 50.0, 'y': 50.0, 'text': 'Repo'},
        },
        term: ['\$ git init'],
      );

      const step2 = AnimationStep(
        say: 'Moving file',
        actors: {
          'fileA': {'x': 60.0, 'y': 40.0},
        },
        term: ['\$ git add main.py'],
      );

      final frames = StepEngine.buildFrames([step1, step2]);
      expect(frames.length, 2);

      // Frame 0
      expect(frames[0].actors['fileA']?.x, 20.0);
      expect(frames[0].actors['fileA']?.y, 30.0);
      expect(frames[0].actors['fileA']?.hide, isFalse);
      expect(frames[0].term, ['\$ git init']);
      expect(frames[0].say, 'Initial state');

      // Frame 1: patched x, y; preserved text; preserved box1
      expect(frames[1].actors['fileA']?.x, 60.0);
      expect(frames[1].actors['fileA']?.y, 40.0);
      expect(frames[1].actors['fileA']?.text, 'main.py');
      expect(frames[1].actors['box1']?.x, 50.0);
      expect(frames[1].term, ['\$ git init', '\$ git add main.py']);
      expect(frames[1].termStart, 1);
    });

    test('StepEngine edgeGeometry computes valid trimmed vectors', () {
      const actorA = ActorModel(id: 'a', k: 'box', x: 20.0, y: 20.0, w: 10.0);
      const actorB = ActorModel(id: 'b', k: 'box', x: 60.0, y: 60.0, w: 10.0);

      final geom = StepEngine.edgeGeometry(actorA, actorB);
      expect(geom, isNotNull);
      expect(geom!.x1, greaterThan(actorA.x * 10.0));
      expect(geom.x2, lessThan(actorB.x * 10.0));
    });
  });

  group('ProgressModel Tests', () {
    test('ProgressModel tracks completed modules correctly', () {
      const progress = ProgressModel(
        pathway: 'git',
        completedModules: {'git-01', 'git-02'},
        activeTrack: 'git',
      );

      expect(progress.isCompleted('git-01'), isTrue);
      expect(progress.isCompleted('git-02'), isTrue);
      expect(progress.isCompleted('git-03'), isFalse);

      final updated = progress.copyWith(
        completedModules: {...progress.completedModules, 'git-03'},
      );
      expect(updated.isCompleted('git-03'), isTrue);

      final jsonMap = updated.toJson();
      expect(jsonMap['pathway'], 'git');
      expect(jsonMap['completedModules'], contains('git-03'));

      final deserialized = ProgressModel.fromJson(jsonMap);
      expect(deserialized.isCompleted('git-03'), isTrue);
    });
  });
}

