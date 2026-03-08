import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/app/game_app.dart';
import 'package:game_jam/core/constants/ui_timing.dart';

void main() {
  testWidgets('app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const GameJamApp());
    await tester.pump(UiTiming.splashScreenDuration);

    expect(find.byType(GameJamApp), findsOneWidget);
  });
}
