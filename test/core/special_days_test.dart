import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_kupler/core/special_days.dart';
import 'package:lifeos_kupler/l10n/strings.dart';

void main() {
  test('the national days, the bayrams and 10 Kasım fall on their dates', () {
    expect(SpecialDay.of(DateTime(2027, 1, 1, 10)), SpecialDay.yilbasi);
    expect(SpecialDay.of(DateTime(2027, 4, 23, 10)), SpecialDay.cocuk);
    expect(SpecialDay.of(DateTime(2027, 5, 1, 10)), SpecialDay.emek);
    expect(SpecialDay.of(DateTime(2027, 7, 15, 10)), SpecialDay.demokrasi);
    expect(SpecialDay.of(DateTime(2027, 8, 30, 10)), SpecialDay.zafer);
    expect(SpecialDay.of(DateTime(2026, 11, 10, 9, 5)), SpecialDay.ataturk);
    // Cumhuriyet Bayramı starts at one in the afternoon on the 28th.
    expect(SpecialDay.of(DateTime(2026, 10, 28, 12, 59)), isNull);
    expect(SpecialDay.of(DateTime(2026, 10, 28, 13)), SpecialDay.cumhuriyet);
    expect(SpecialDay.of(DateTime(2026, 10, 29, 23)), SpecialDay.cumhuriyet);
    // Ramazan Bayramı 9–11 March 2027, Kurban Bayramı 16–19 May 2027; its
    // fourth day is 19 Mayıs, and the national day comes first.
    expect(SpecialDay.of(DateTime(2027, 3, 8, 20)), isNull);
    expect(SpecialDay.of(DateTime(2027, 3, 11, 20)), SpecialDay.ramazan);
    expect(SpecialDay.of(DateTime(2027, 5, 16, 8)), SpecialDay.kurban);
    expect(SpecialDay.of(DateTime(2027, 5, 19, 8)), SpecialDay.genclik);
    expect(SpecialDay.of(DateTime(2027, 5, 20, 8)), isNull);
    expect(SpecialDay.of(DateTime(2027, 5, 6, 8)), SpecialDay.hidirellez);
    expect(SpecialDay.of(DateTime(2026, 10, 19)), isNull);
  });

  test('10 Kasım and 15 Temmuz are days of remembrance; Lokum mourns on 10 Kasım', () {
    expect(SpecialDay.ataturk.solemn, isTrue);
    expect(SpecialDay.demokrasi.solemn, isTrue);
    expect(SpecialDay.cumhuriyet.solemn, isFalse);
    expect(SpecialDay.ataturk.props, [LokumProp.ribbon]);
    expect(SpecialDay.cumhuriyet.props, contains(LokumProp.flag));
    final words = AppStrings.tr.specialDay(SpecialDay.ataturk, 103);
    expect(words.line, contains('Atatürk'));
    expect(AppStrings.tr.specialDay(SpecialDay.cumhuriyet, 2026 - 1923).line, 'Cumhuriyetimizin 103. yılı kutlu olsun!');
  });
}
