import 'package:flutter_test/flutter_test.dart';
import 'package:goal/main.dart';

void main() {
  testWidgets('Smoke test app load', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GameApp());
    expect(find.byType(GameApp), findsOneWidget);
  });
}
