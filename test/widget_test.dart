import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/main.dart';

void main() {
  testWidgets('WhyIBuyApp smoke test and renders title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WhyIBuyApp());

    // Verify that the Design System Preview screen loads
    expect(find.text('Why I Buy – Design System'), findsOneWidget);
  });
}
