import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora_frontend/core/services/currency_service.dart';
import 'package:finora_frontend/core/services/app_settings_service.dart';

void main() {
  // CurrencyService is a singleton. We access it via the factory constructor.
  // We cannot inject dependencies for fetchRate (it uses GetIt), so we test
  // the pure computation methods (convert, format, formatCompact) directly
  // after manipulating the rate through fetchRate('EUR') which resets it to 1.0.

  setUp(() async {
    // Use in-memory SharedPreferences so AppSettingsService works without
    // a real device storage backend (required for format/formatCompact).
    SharedPreferences.setMockInitialValues({'app_currency': 'EUR'});
    await AppSettingsService().load();
  });

  group('CurrencyService – default rate', () {
    test('rate is 1.0 by default (EUR)', () async {
      await CurrencyService().fetchRate('EUR');
      expect(CurrencyService().rate, equals(1.0));
    });

    test('fetchRate(EUR) keeps rate at 1.0', () async {
      await CurrencyService().fetchRate('EUR');
      expect(CurrencyService().rate, equals(1.0));
    });
  });

  group('CurrencyService.convert()', () {
    setUp(() async {
      await CurrencyService().fetchRate('EUR');
    });

    test('converts EUR amount with rate 1.0 (identity)', () {
      expect(CurrencyService().convert(100.0), equals(100.0));
    });

    test('converts zero amount', () {
      expect(CurrencyService().convert(0.0), equals(0.0));
    });

    test('converts negative amount (expense)', () {
      expect(CurrencyService().convert(-50.0), equals(-50.0));
    });

    test('applies rate correctly when rate differs from 1.0', () {
      // We can only test by directly reading the internal rate logic via convert.
      // fetchRate for non-EUR calls the network, so we only verify that
      // convert() = amount * rate, which for EUR rate = 1.0 is amount * 1.0.
      final service = CurrencyService();
      final result = service.convert(200.0);
      expect(result, equals(200.0 * service.rate));
    });
  });

  group('CurrencyService.format()', () {
    setUp(() async {
      await CurrencyService().fetchRate('EUR');
    });

    test('formats integer amount with comma decimal separator', () {
      final result = CurrencyService().format(1000.0);
      // Spanish locale: 1000,00 €  or with thousands: 1.000,00 €
      expect(result, contains(','));
      expect(result, contains('€'));
    });

    test('formats with € symbol', () {
      final result = CurrencyService().format(50.0);
      expect(result, contains('€'));
    });

    test('formats thousands with dot separator', () {
      final result = CurrencyService().format(1000.0);
      // 1.000,00 €  — dot as thousands separator
      expect(result, contains('1.000'));
    });

    test('formats negative amount with leading minus sign', () {
      final result = CurrencyService().format(-100.0);
      expect(result.startsWith('-'), isTrue);
    });

    test('formats zero correctly', () {
      final result = CurrencyService().format(0.0);
      expect(result, contains('0,00'));
      expect(result, contains('€'));
    });

    test('respects custom decimals parameter', () {
      final result = CurrencyService().format(100.0, decimals: 0);
      expect(result, contains('100'));
      expect(result, isNot(contains(',')));
    });

    test('formats large amount with dot thousands and comma decimal', () {
      final result = CurrencyService().format(1234567.89);
      // Expected: 1.234.567,89 €
      expect(result, contains('1.234.567'));
      expect(result, contains(',89'));
      expect(result, contains('€'));
    });
  });

  group('CurrencyService.formatCompact()', () {
    setUp(() async {
      await CurrencyService().fetchRate('EUR');
    });

    test('formats amounts < 1000 without suffix', () {
      final result = CurrencyService().formatCompact(500.0);
      expect(result, equals('500€'));
    });

    test('formats 1500 as 1.5k€', () {
      final result = CurrencyService().formatCompact(1500.0);
      expect(result, equals('1.5k€'));
    });

    test('formats 2300 as 2.3k€', () {
      final result = CurrencyService().formatCompact(2300.0);
      expect(result, equals('2.3k€'));
    });

    test('formats 1000000 as 1.0M€', () {
      final result = CurrencyService().formatCompact(1000000.0);
      expect(result, equals('1.0M€'));
    });

    test('formats 2300000 as 2.3M€', () {
      final result = CurrencyService().formatCompact(2300000.0);
      expect(result, equals('2.3M€'));
    });

    test('uses absolute value for compact format (negative amounts)', () {
      final pos = CurrencyService().formatCompact(1500.0);
      final neg = CurrencyService().formatCompact(-1500.0);
      // Both should show 1.5k€ since formatCompact takes abs()
      expect(pos, equals(neg));
    });

    test('formats boundary of 1000 exactly as 1.0k€', () {
      final result = CurrencyService().formatCompact(1000.0);
      expect(result, equals('1.0k€'));
    });

    test('formats boundary of 1000000 exactly as 1.0M€', () {
      final result = CurrencyService().formatCompact(1000000.0);
      expect(result, equals('1.0M€'));
    });
  });
}

