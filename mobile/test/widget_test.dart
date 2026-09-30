import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('connection screen offers a Retry after the check',
      (WidgetTester tester) async {
    await tester.pumpWidget(const StudentMarketplaceApp());
    await tester.pumpAndSettle();

    // Tests have no network, so the health check fails and Retry appears.
    expect(find.text('Retry'), findsOneWidget);
  });
}
