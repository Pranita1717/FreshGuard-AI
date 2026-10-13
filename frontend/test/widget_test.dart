import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/session.dart';

void main() {
  testWidgets('App smoke test - verifies FreshGuard landing', (WidgetTester tester) async {
    final session = Session();
    await tester.pumpWidget(FreshGuardApp(initialSession: session));

    expect(find.text('FRESHGUARD'), findsWidgets);
    expect(find.text('Zero Food Waste.\nTotal Shelf Accountability.'), findsOneWidget);
  });
}
