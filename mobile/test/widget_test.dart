import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('shows the shell with four tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const StudentMarketplaceApp());
    await tester.pumpAndSettle();

    expect(find.text('Services'), findsWidgets);
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('guest profile shows Login and Register',
      (WidgetTester tester) async {
    await tester.pumpWidget(const StudentMarketplaceApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });

  testWidgets('guest bookings tab asks to log in',
      (WidgetTester tester) async {
    await tester.pumpWidget(const StudentMarketplaceApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();

    expect(find.text('Please log in'), findsOneWidget);
  });
}
