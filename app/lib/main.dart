import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await StorageService.init();
  final state = AppState();
  await state.boot();
  runApp(ChangeNotifierProvider.value(value: state, child: const QadamApp()));
}
