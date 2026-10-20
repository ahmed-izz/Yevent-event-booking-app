import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_app/app/yevent_app.dart';
import 'package:my_app/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App starts (smoke test)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final appState = AppState(prefs);
    await appState.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: appState, child: const YeventApp()),
    );

    // First frame should show Splash with "Yevent"
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Yevent'), findsWidgets);
  });
}
