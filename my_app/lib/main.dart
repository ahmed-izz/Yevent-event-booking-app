import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'state/app_state.dart';
import 'app/yevent_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final appState = AppState(prefs);
  await appState.init();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const YeventApp(),
    ),
  );
}