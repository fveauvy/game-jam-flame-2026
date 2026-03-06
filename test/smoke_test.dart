import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/app/game_app.dart';

void main() {
  testWidgets('app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const GameJamApp());
    await tester.pump();

    expect(find.byType(GameJamApp), findsOneWidget);
  });
}
