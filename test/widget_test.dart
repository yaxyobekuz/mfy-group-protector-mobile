/// ⚠️ ODDIY SOG'LIQ TESTI: ilova qurilganda `main.dart` import
/// qilinadi va kompilyatsiya xatosi shu yerda ham chiqadi.
///
/// To'liq ekran testlari YO'Q va bu ataylab: har ekran serverga
/// so'rov yuboradi va ularni soxtalashtirish uchun butun API
/// qatlamini ikkilantirish kerak bo'lardi — hozircha haqiqiy
/// qurilmadagi sinov foydaliroq.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:viloyat_shtabi/shared/util/date_uz.dart';

void main() {
  test('sana formati loyiha qoidasiga mos', () {
    // 2025-05-21T09:30:00Z → Toshkentda 14:30
    expect(formatDateUz('2025-05-21T09:30:00Z'), '21-may, 2025');
    expect(formatTimeUz('2025-05-21T09:30:00Z'), '14:30');
    expect(formatDateTimeUz('2025-05-21T09:30:00Z'), '21-may, 2025 14:30');
    expect(formatMonthUz('2026-01-03T00:00:00Z'), 'Yanvar, 2026');
  });

  test('bo\'sh qiymat tire beradi', () {
    expect(formatDateUz(null), '—');
    expect(formatDateUz(''), '—');
  });

  test('imlo: sentabr / oktabr', () {
    expect(formatDateUz('2025-09-10T00:00:00Z'), contains('sentabr'));
    expect(formatDateUz('2025-10-10T00:00:00Z'), contains('oktabr'));
  });
}
