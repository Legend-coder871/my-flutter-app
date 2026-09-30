import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('shows the app title', (WidgetTester tester) async {
    await tester.pumpWidget(const StudentMarketplaceApp());

    expect(find.text('Student Marketplace'), findsOneWidget);
  });
}
