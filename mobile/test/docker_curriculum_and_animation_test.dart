import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devops_learning_app/features/animations/services/animation_loader.dart';
import 'package:devops_learning_app/features/animations/services/step_engine.dart';
import 'package:devops_learning_app/features/animations/widgets/actor_widget.dart';
import 'package:devops_learning_app/features/animations/widgets/stage_canvas.dart';
import 'package:devops_learning_app/features/pathway/data/curriculum_repository.dart';
import 'package:devops_learning_app/features/pathway/data/docker_curriculum_repository.dart';
import 'package:devops_learning_app/features/pathway/data/git_curriculum_repository.dart';
import 'package:devops_learning_app/models/animation_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Docker Curriculum Integration Tests', () {
    setUp(() {
      CurriculumRepository.clearCache();
    });

    test('1. Loads all 7 Docker modules from JSON asset with full fidelity',
        () async {
      final modules = await DockerCurriculumRepository.loadCurriculum();

      expect(modules.length, 7);
      expect(modules[0].id, 'docker-01');
      expect(modules[0].number, '01');
      expect(modules[0].title, contains('Docker & Containerization'));
      expect(modules[0].shortTitle, 'Introduction to Docker & Containerization');

      expect(modules[6].id, 'docker-07');
      expect(modules[6].number, '07');
      expect(modules[6].title, contains('DevOps Workflow'));

      // Verify total sections across all 7 modules equals 34
      final totalSections =
          modules.fold<int>(0, (sum, m) => sum + m.sections.length);
      expect(totalSections, 34);

      // Verify all sections have required fields
      for (final mod in modules) {
        expect(mod.objectives.isNotEmpty, isTrue);
        expect(mod.summary.isNotEmpty, isTrue);
        for (final sec in mod.sections) {
          expect(sec.number, greaterThan(0));
          expect(sec.title.isNotEmpty, isTrue);
          expect(sec.paragraphs.isNotEmpty, isTrue);
        }
      }
    });

    test('2. Finds module by id and order number', () async {
      final modules = await DockerCurriculumRepository.loadCurriculum();

      final byId = DockerCurriculumRepository.findModule(modules, 'docker-03');
      expect(byId, isNotNull);
      expect(byId!.number, '03');
      expect(byId.shortTitle, 'Dockerfile & Building Custom Images');

      final byNumber = DockerCurriculumRepository.findModule(modules, '05');
      expect(byNumber, isNotNull);
      expect(byNumber!.id, 'docker-05');
      expect(
        byNumber.shortTitle,
        'Docker Compose & Multi-Container Applications',
      );

      final notFound =
          DockerCurriculumRepository.findModule(modules, 'unknown-99');
      expect(notFound, isNull);
    });

    test('3. Docker and Git curriculum repositories maintain isolated caches',
        () async {
      final gitModules = await GitCurriculumRepository.loadCurriculum();
      final dockerModules = await DockerCurriculumRepository.loadCurriculum();

      expect(gitModules.length, 7);
      expect(dockerModules.length, 7);

      expect(gitModules[0].id, 'git-01');
      expect(dockerModules[0].id, 'docker-01');

      expect(GitCurriculumRepository.cachedModules?[0].id, 'git-01');
      expect(DockerCurriculumRepository.cachedModules?[0].id, 'docker-01');

      // Clearing Git cache leaves Docker cache intact
      GitCurriculumRepository.clearCache();
      expect(GitCurriculumRepository.cachedModules, isNull);
      expect(DockerCurriculumRepository.cachedModules, isNotNull);
      expect(DockerCurriculumRepository.cachedModules?[0].id, 'docker-01');
    });
  });

  group('Docker Animation System & Engine Tests', () {
    setUp(() {
      AnimationLoader.clearCache();
    });

    test('1. Loads all 7 modules, 34 subtopics, and 139 steps from JSON asset',
        () async {
      final modules =
          await AnimationLoader.loadAnimations(pathway: 'docker');

      expect(modules.length, 7);

      final totalSubtopics =
          modules.fold<int>(0, (sum, m) => sum + m.subtopics.length);
      expect(totalSubtopics, 34);

      final totalSteps = modules.fold<int>(
        0,
        (sum, m) =>
            sum +
            m.subtopics.fold<int>(0, (sSum, s) => sSum + s.steps.length),
      );
      expect(totalSteps, 139);
    });

    test('2. Subtopics correctly parse mobile portrait stage dimensions',
        () async {
      final modules =
          await AnimationLoader.loadAnimations(pathway: 'docker');

      final firstSubtopic = modules[0].subtopics[0];
      expect(firstSubtopic.stageWidth, 360.0);
      expect(firstSubtopic.stageHeight, 640.0);

      // Verify all subtopics have valid mobile portrait dimensions
      for (final mod in modules) {
        for (final sub in mod.subtopics) {
          expect(sub.stageWidth, 360.0);
          expect(sub.stageHeight, anyOf(600.0, 640.0, 720.0));
        }
      }
    });

    test('3. AnimationLoader isolates Git and Docker lookups', () async {
      await AnimationLoader.loadAnimations(pathway: 'git');
      await AnimationLoader.loadAnimations(pathway: 'docker');

      final gitAnim = AnimationLoader.findAnimation('01.1', pathway: 'git');
      final dockerAnim =
          AnimationLoader.findAnimation('01.1', pathway: 'docker');

      expect(gitAnim, isNotNull);
      expect(dockerAnim, isNotNull);

      expect(gitAnim!.title, contains('Why Do We Need Version Control?'));
      expect(dockerAnim!.title, contains('Why Do We Need Containerization?'));

      // Check stage mobile portrait dimensions
      expect(gitAnim.stageWidth, 360.0);
      expect(gitAnim.stageHeight, 640.0);
      expect(dockerAnim.stageWidth, 360.0);
      expect(dockerAnim.stageHeight, 640.0);
    });

    test('4. StepEngine correctly computes halfSize and geometry on portrait stage',
        () {
      const volActor = ActorModel(
        id: 'db-vol',
        k: 'vol',
        x: 50,
        y: 60,
        text: '/var/lib/mysql',
        sub: 'named volume',
      );

      const layerActor = ActorModel(
        id: 'img-layer',
        k: 'layer',
        x: 50,
        y: 30,
        text: 'RUN apt-get update',
      );

      // On portrait mobile stage (360 x 640)
      final volSize = StepEngine.halfSize(
        volActor,
        stageWidth: 360.0,
        stageHeight: 640.0,
      );
      expect(volSize.w, greaterThan(0));
      expect(volSize.h, 30.0); // web halfH for vol on mobile

      final layerSize = StepEngine.halfSize(
        layerActor,
        stageWidth: 360.0,
        stageHeight: 640.0,
      );
      expect(layerSize.w, greaterThan(0));
      expect(layerSize.h, 12.0); // web halfH for layer on mobile

      // Directed edge between them
      final edgeGeom = StepEngine.edgeGeometry(
        layerActor,
        volActor,
        stageWidth: 360.0,
        stageHeight: 640.0,
      );
      expect(edgeGeom, isNotNull);
      expect(edgeGeom!.x1.isFinite, isTrue);
      expect(edgeGeom.y1.isFinite, isTrue);
      expect(edgeGeom.x2.isFinite, isTrue);
      expect(edgeGeom.y2.isFinite, isTrue);
    });

    testWidgets('5. ActorWidget renders vol and layer shapes properly',
        (tester) async {
      const volActor = ActorModel(
        id: 'vol-1',
        k: 'vol',
        x: 50,
        y: 50,
        text: 'data_volume',
        sub: '10 GB',
        ic: '💾',
      );

      const layerActor = ActorModel(
        id: 'layer-1',
        k: 'layer',
        x: 50,
        y: 20,
        text: 'COPY . /app',
        bar: 75,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: Stack(
                children: const [
                  ActorWidget(
                    actor: volActor,
                    stageWidth: 360,
                    stageHeight: 640,
                  ),
                  ActorWidget(
                    actor: layerActor,
                    stageWidth: 360,
                    stageHeight: 640,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('data_volume'), findsOneWidget);
      expect(find.text('10 GB'), findsOneWidget);
      expect(find.text('💾'), findsOneWidget);
      expect(find.text('COPY . /app'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('6. StageCanvas scales portrait stages without overflow',
        (tester) async {
      final frame = AnimationFrame(
        actors: {
          'host': const ActorModel(
            id: 'host',
            k: 'box',
            x: 50,
            y: 80,
            text: 'Host OS',
          ),
          'container': const ActorModel(
            id: 'container',
            k: 'vol',
            x: 50,
            y: 30,
            text: 'Nginx Container',
          ),
        },
        edges: const [
          AnimationEdge(from: 'host', to: 'container', label: '80:80'),
        ],
        term: const ['docker run -d -p 80:80 nginx'],
        termStart: 0,
        say: 'Host port 80 is forwarded to container port 80.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: StageCanvas(
                frame: frame,
                stageWidth: 360,
                stageHeight: 640,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Host OS'), findsOneWidget);
      expect(find.text('Nginx Container'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
