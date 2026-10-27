import 'package:flutter_test/flutter_test.dart';
import 'package:herb_app/main.dart';

void main() {
  testWidgets('HerbApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HerbApp());
    expect(find.text('herb'), findsWidgets);
  });
}
