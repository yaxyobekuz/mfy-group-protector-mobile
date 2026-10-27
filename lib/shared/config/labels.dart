/// YORLIQLAR — YAGONA MANBA (mobil ilova).
///
/// ⚠️ YORLIQ WIDGET ICHIDA YOZILMAYDI — mini-ilovadagi
/// `shared/config/labels.ts` bilan AYNI qoida: holat nomi o'nlab
/// joyda ko'rinadi (ro'yxat, filtr, karta, bildirishnoma) va har
/// joyda qo'lda yozilsa, bir ekranda "Hal qilindi", boshqasida
/// "Yopildi" bo'lib qolardi.
///
/// ⚠️ MATN PANELDAGIDAN FARQ QILADI va bu ataylab. Panelda
/// `in_progress` — "Ko'rib chiqilmoqda" (xodim tili), ilovada
/// "Bajarilmoqda" (fuqaro tili).
library;

import 'package:flutter/material.dart';

import 'theme.dart';

class StatusLabel {
  const StatusLabel(this.label, this.color, this.background);
  final String label;
  final Color color;
  final Color background;
}

const Map<String, StatusLabel> appealStatus = <String, StatusLabel>{
  'new': StatusLabel(
    'Qabul qilindi',
    AppColors.accentForeground,
    AppColors.accent,
  ),
  'in_progress': StatusLabel('Bajarilmoqda', AppColors.warning, Color(0x26E19209)),
  'resolved': StatusLabel('Hal qilindi', AppColors.success, Color(0x261B9D4A)),
  'rejected': StatusLabel(
    'Rad etildi',
    AppColors.mutedForeground,
    AppColors.muted,
  ),
};

StatusLabel statusOf(String key) =>
    appealStatus[key] ?? appealStatus['new']!;

const Map<String, String> priorityLabels = <String, String>{
  'low': 'Past',
  'normal': 'O\'rta',
  'high': 'Yuqori',
  'urgent': 'Shoshilinch',
};

/// YO'NALISH BELGISI — serverdagi `icon` kalitidan Material belgisiga.
///
/// ⚠️ MINI-ILOVADAGI `icons.tsx` BILAN AYNI KALITLAR. Kalit yangi
/// qo'shilsa IKKALASIGA qo'shiladi, aks holda bir ilovada belgi,
/// ikkinchisida bo'sh kvadrat ko'rinardi.
///
/// ⚠️ NOMA'LUM KALIT YIQITMAYDI: server yangi toifa qo'shsa, ilova
/// eski versiyada ham ochilishi kerak.
const Map<String, IconData> categoryIcons = <String, IconData>{
  // ── Seed'dagi sakkizta yo'nalish (`issue_categories.icon`) ──────
  'water': Icons.water_drop_outlined,
  'road': Icons.add_road,
  'trash': Icons.delete_outline,
  'social': Icons.volunteer_activism_outlined,
  'shield': Icons.shield_outlined,
  'staff': Icons.badge_outlined,
  'document': Icons.description_outlined,
  'more': Icons.more_horiz,

  // ── Kelgusi yo'nalishlar uchun zaxira kalitlar ─────────────────
  'light': Icons.lightbulb_outline,
  'power': Icons.bolt_outlined,
  'gas': Icons.local_fire_department_outlined,
  'heat': Icons.thermostat_outlined,
  'building': Icons.apartment_outlined,
  'tree': Icons.park_outlined,
  'transport': Icons.directions_bus_outlined,
  'health': Icons.local_hospital_outlined,
  'school': Icons.school_outlined,
  'animal': Icons.pets_outlined,
  'noise': Icons.volume_up_outlined,
};

IconData iconOf(String? key) =>
    categoryIcons[key] ?? Icons.report_problem_outlined;

/// Toifa rangini `#RRGGBB` dan `Color` ga.
///
/// ⚠️ YARAROQSIZ QIYMAT YIQITMAYDI: panelda rang qo'lda kiritiladi
/// va "ko'k" deb yozib qo'yilishi mumkin.
Color colorOf(String? hex, [Color fallback = AppColors.primary]) {
  if (hex == null) return fallback;
  final clean = hex.replaceAll('#', '').trim();
  if (clean.length != 6) return fallback;
  final value = int.tryParse(clean, radix: 16);
  return value == null ? fallback : Color(0xFF000000 | value);
}

/// "12 ta murojaat" — paneldagi `plural` bilan ayni.
String plural(int count, String word) => '$count ta $word';

/// JAVOB MUDDATI — SOATDAN O'QILADIGAN MATNGA.
String slaText(int hours) {
  if (hours <= 0) return 'Muddat belgilanmagan';
  if (hours < 24) return '$hours soat ichida';
  final days = hours ~/ 24;
  return '$days kun ichida';
}

/// SEHRGAR QADAMLARI.
///
/// ⚠️ RO'YXAT TARTIBI = QADAMLAR TARTIBI va "1/5" sanoqchisi ham
/// shundan chiqadi. Sanoqni qo'lda yozish qadam qo'shilganda
/// beshta joyni tuzatishni talab qilardi va bittasi albatta
/// "3/5" bo'lib qolardi.
const List<({String key, String title, String hint})> wizardSteps = [
  (
    key: 'category',
    title: 'Muammo turini tanlang',
    hint: 'Eng mos turini tanlang. AI tizim uni avtomatik tasniflaydi.',
  ),
  (
    key: 'media',
    title: 'Foto qo\'shing',
    hint: 'Muammoni aniq ko\'rsatadigan surat yuboring.',
  ),
  (
    key: 'location',
    title: 'Manzilni belgilang',
    hint: 'Xaritada aniq joyni belgilang yoki manzilni qo\'lda kiriting.',
  ),
  (
    key: 'details',
    title: 'Batafsil ma\'lumot',
    hint: 'Muammoni qisqacha tasvirlang.',
  ),
  (
    key: 'review',
    title: 'AI tahlili',
    hint: 'Tizim ma\'lumotlaringizni tahlil qildi. To\'g\'ri bo\'lsa, tasdiqlang.',
  ),
];
