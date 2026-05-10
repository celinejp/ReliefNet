import 'package:flutter/material.dart';

import 'relief_net_app.dart';
import 'services/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionController.instance.bootstrap();
  runApp(const ReliefNetApp());
}
