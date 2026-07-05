import 'package:flutter_test/flutter_test.dart';
import 'package:at_reservations_mobile/main.dart';
import 'package:at_reservations_mobile/services/app_preferences.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final prefs = AppPreferences();
    await tester.pumpWidget(ATReservationsApp(prefs: prefs));
    expect(find.byType(ATReservationsApp), findsOneWidget);
  });
}
