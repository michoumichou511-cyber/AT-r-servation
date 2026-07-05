import 'package:flutter_test/flutter_test.dart';
import 'package:at_reservations_mobile/utils/date_utils.dart';

void main() {
  group('parseBackendDate', () {
    test('parse ISO 8601 UTC', () {
      final d = parseBackendDate('2026-07-20T10:30:00.000000Z');
      expect(d, isNotNull);
      expect(d!.toUtc().hour, 10);
    });

    test('parse format français date seule', () {
      final d = parseBackendDate('20/07/2026');
      expect(d, DateTime(2026, 7, 20));
    });

    test('parse format français date + heure', () {
      final d = parseBackendDate('02/07/2026 20:03:16');
      expect(d, DateTime(2026, 7, 2, 20, 3, 16));
    });

    test('null, vide et invalide → null', () {
      expect(parseBackendDate(null), isNull);
      expect(parseBackendDate(''), isNull);
      expect(parseBackendDate('n/a'), isNull);
    });
  });
}
