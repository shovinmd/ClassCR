import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('ClassCR smoke test loads splash and onboarding setup', (WidgetTester tester) async {
    await tester.pumpWidget(const ClassCRApp());
    expect(find.text('ClassCR'), findsWidgets);

    // Advance past splash delay
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Verify first-time Setup Screen appears
    expect(find.text('Welcome to ClassCR'), findsOneWidget);
    expect(find.text('Select Class & Section'), findsOneWidget);
    expect(find.text('Select Your Role'), findsOneWidget);
  });
}
