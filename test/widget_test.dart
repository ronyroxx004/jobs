import 'package:flutter_test/flutter_test.dart';
import 'package:jobs/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JobsApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byType(JobsApp), findsOneWidget);
  });
}
