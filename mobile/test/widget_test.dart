import 'package:flutter_test/flutter_test.dart';
import 'package:devops_learning_app/app.dart';

void main() {
  testWidgets(
    'Welcome screen renders minimal branding and navigation buttons',
    (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const DevOpsLearningApp());
      await tester.pumpAndSettle();

      // Verify minimal title and branding
      expect(find.text('DevOps Learning Platform'), findsOneWidget);
      expect(find.text('Master DevOps from code to cloud.'), findsOneWidget);

      // Verify clear primary actions
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    },
  );
}
