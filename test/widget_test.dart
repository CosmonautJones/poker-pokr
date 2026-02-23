import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PokerTrainerApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Poker Trainer'), findsOneWidget);
  });
}
