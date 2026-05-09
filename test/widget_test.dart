import 'package:flutter_test/flutter_test.dart';

import 'package:relief_net/relief_net_app.dart';

void main() {
  testWidgets('Homepage renders ReliefNet headline', (WidgetTester tester) async {
    await tester.pumpWidget(const ReliefNetApp());

    expect(find.text('ReliefNet'), findsWidgets);
    expect(find.textContaining('Stay connected when networks fail'), findsOneWidget);
  });
}
