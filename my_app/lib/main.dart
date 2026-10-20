import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'state/app_state.dart';
import 'app/yevent_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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