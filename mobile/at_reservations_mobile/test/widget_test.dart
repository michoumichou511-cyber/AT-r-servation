import 'package:flutter_test/flutter_test.dart';
import 'package:at_reservations_mobile/main.dart';
import 'package:at_reservations_mobile/services/app_preferences.dart';
import 'package:at_reservations_mobile/services/offline_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final prefs = AppPreferences();
    final offline = OfflineService();
    await tester.pumpWidget(ATReservationsApp(prefs: prefs, offline: offline));
    expect(find.byType(ATReservationsApp), findsOneWidget);
  });
}
