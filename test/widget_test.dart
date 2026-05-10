import 'package:flutter_test/flutter_test.dart';

import 'package:relief_net/relief_net_app.dart';
import 'package:relief_net/services/session_controller.dart';

void main() {
  testWidgets('Homepage renders AlertU headline', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await SessionController.instance.bootstrap();
    await tester.pumpWidget(const ReliefNetApp());

    expect(find.text('AlertU'), findsWidgets);
    expect(find.textContaining('Stay connected when networks fail'), findsOneWidget);
  });
}
