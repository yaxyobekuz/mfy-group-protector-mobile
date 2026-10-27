/// RANG VA USLUB — YAGONA MANBA.
///
/// ⚠️ QIYMATLAR MINI-ILOVADAN KO'CHIRILGAN (`globals.css` dagi HSL
/// tokenlar). Ikki ilova bitta tizimning ikki eshigi: fuqaro
/// Telegram'da ko'k ilovani, do'kondan o'rnatganda esa boshqa
/// rangdagisini ko'rsa, bu bir xil xizmat ekaniga ishonmasdi.
///
/// ⚠️ HOLAT RANGLARI BREND RANGIDAN ALOHIDA (`success`, `warning`,
/// `destructive`): ko'k — brend, yashil/sariq/qizil esa MA'NO.
/// Aralashsa, "hal qilindi" yorlig'i brend rangiga kirib ketib,
/// ko'zga tashlanmay qolardi.
///
/// ⚠️ `Colors.blue` KABI TAYYOR RANGLAR ISHLATILMAYDI: ular
/// Material palitrasi bo'yicha biroz boshqacha va ekranlar
/// bir-biridan sezilmas darajada farq qilib ketardi.
library;

import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color background = Color(0xFFF2F4F8);
  static const Color foreground = Color(0xFF0F1729);
  static const Color card = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF2463EB);
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFEFF2F5);
  static const Color mutedForeground = Color(0xFF65758B);
  static const Color accent = Color(0xFFE6F1FE);
  static const Color accentForeground = Color(0xFF1147BB);
  static const Color success = Color(0xFF1B9D4A);
  static const Color warning = Color(0xFFE19209);
  static const Color destructive = Color(0xFFDC2828);
  static const Color border = Color(0xFFDCE2EA);
}

/// Kartalar uchun yumshoq soya — mini-ilovadagi "suzuvchi karta".
const List<BoxShadow> cardShadow = <BoxShadow>[
  BoxShadow(color: Color(0x0F0F1729), blurRadius: 18, offset: Offset(0, 6)),
];

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      surface: AppColors.card,
      onSurface: AppColors.foreground,
      error: AppColors.destructive,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.foreground,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.foreground,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.foreground,
      displayColor: AppColors.foreground,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.foreground,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.foreground,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );
}
