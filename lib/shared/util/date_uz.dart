/// SANA FORMATI — YAGONA MANBA (mobil ilova, Flutter).
///
/// ⚠️ BU FAYLDAN BOSHQA JOYDA SANA MATNI YIG'ILMAYDI. Serverdagi
/// `common/date.util.ts`, paneldagi `shared/lib/date.ts` va
/// mini-ilovadagi `shared/lib/date.ts` ning KO'ZGUSI: bitta murojaat
/// panelda "21-may, 2025 14:30", ilovada esa "21.05.2025" bo'lib
/// ko'rinsa, fuqaro bilan xodim bir xil yozuv haqida
/// gaplashayotganiga ishonch qolmasdi.
///
///   kun         →  21-may, 2025
///   kun + vaqt  →  21-may, 2025 14:30
///   oy          →  Yanvar, 2026
///   vaqt        →  14:30
///
/// ── TAQIQLANGAN ────────────────────────────────────────────────────
///
/// ⚠️ `intl` PAKETI (`DateFormat`) VA `toLocal()` ISHLATILMAYDI.
/// Natija kod YOZILGAN joyga emas, qurilma sozlamasiga bog'liq
/// bo'lardi: foydalanuvchi telefonining zonasi yoki tili
/// o'zgarganda bir ekran "21-may", boshqasi "May 21" bo'lib
/// qolardi.
library;

const List<String> _monthsUz = <String>[
  'yanvar',
  'fevral',
  'mart',
  'aprel',
  'may',
  'iyun',
  'iyul',
  'avgust',
  // ⚠️ IMLO QAT'IY: "sentabr"/"oktabr" — "sentyabr"/"oktyabr" EMAS.
  'sentabr',
  'oktabr',
  'noyabr',
  'dekabr',
];

/// Bo'sh yoki yaroqsiz qiymat — "Invalid Date" yoki bo'sh satr EMAS.
const String _empty = '—';

/// Toshkent (+5), DST yo'q.
const Duration _tashkentOffset = Duration(hours: 5);

DateTime? _toDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  if (value is String) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
  return null;
}

/// TOSHKENT DEVOR-SOATI.
///
/// ⚠️ `toLocal()` ISHLATILMAYDI: u QURILMANING zonasini beradi.
/// Tizim esa Asia/Tashkent bo'yicha ishlaydi va hisobot ham shunga
/// qarab quriladi — ya'ni ko'rinish ham shunday bo'lishi kerak.
DateTime _toTashkent(DateTime date) => date.toUtc().add(_tashkentOffset);

String _pad(int value) => value.toString().padLeft(2, '0');

String _cap(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

/// "21-may, 2025"
String formatDateUz(Object? value) {
  final date = _toDate(value);
  if (date == null) return _empty;

  final tz = _toTashkent(date);
  // ⚠️ Kun raqami NOLDAN BOSHLANMAYDI: "3-yanvar", "03-yanvar" emas.
  return '${tz.day}-${_monthsUz[tz.month - 1]}, ${tz.year}';
}

/// "14:30"
String formatTimeUz(Object? value) {
  final date = _toDate(value);
  if (date == null) return _empty;

  final tz = _toTashkent(date);
  return '${_pad(tz.hour)}:${_pad(tz.minute)}';
}

/// "21-may, 2025 14:30"
String formatDateTimeUz(Object? value) {
  final date = _toDate(value);
  if (date == null) return _empty;

  return '${formatDateUz(date)} ${formatTimeUz(date)}';
}

/// "Yanvar, 2026"
String formatMonthUz(Object? value) {
  final date = _toDate(value);
  if (date == null) return _empty;

  final tz = _toTashkent(date);
  return '${_cap(_monthsUz[tz.month - 1])}, ${tz.year}';
}

/// NISBIY VAQT — "5 daqiqa oldin".
///
/// ⚠️ FAQAT YAQIN O'TMISH UCHUN. Bir kundan oshsa to'liq sanaga
/// o'tadi: "23 kun oldin" degan yorliq odamga hech narsa bermaydi va
/// u baribir aniq sanani izlardi.
String formatRelativeUz(Object? value) {
  final date = _toDate(value);
  if (date == null) return _empty;

  final diff = DateTime.now().toUtc().difference(date.toUtc());

  // Kelajakdagi sana (muddat) — nisbiy ko'rsatilmaydi.
  if (diff.isNegative) return formatDateTimeUz(date);

  if (diff.inMinutes < 1) return 'hozir';
  if (diff.inMinutes < 60) return '${diff.inMinutes} daqiqa oldin';
  if (diff.inHours < 24) return '${diff.inHours} soat oldin';

  return formatDateTimeUz(date);
}

/// JAVOB MUDDATIGACHA QOLGAN VAQT — "2 kun qoldi" / "muddati o'tdi".
///
/// ⚠️ O'TIB KETGANI ALOHIDA AYTILADI: "-3 kun" degan manfiy son
/// fuqaroga hech narsa aytmasdi.
String formatDueUz(Object? value) {
  final date = _toDate(value);
  if (date == null) return _empty;

  final diff = date.toUtc().difference(DateTime.now().toUtc());
  if (diff.isNegative) return 'muddati o\'tdi';

  if (diff.inHours < 24) return '${diff.inHours} soat qoldi';
  return '${diff.inDays} kun qoldi';
}
