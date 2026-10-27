/// VILOYAT SHTABI — FUQARO MUROJAATI (mobil ilova).
///
/// ⚠️ BU MINI-ILOVANING NUSXASI EMAS, IKKINCHI ESHIGI. Mini-ilova
/// (`mini-app/`) Telegram ichida ishlaydi va u yerda kirish
/// avtomatik (`initData`). Bu ilova do'kondan o'rnatiladi va
/// Google bilan kiriladi. Ekranlar va server AYNI — farq faqat
/// kirishda.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'entities/session/auth_gate.dart';
import 'shared/config/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚠️ FAQAT TIK HOLAT: ekranlar (sehrgar, xarita) tik uchun
  // chizilgan va yon holatda tugmalar ekrandan chiqib ketardi.
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  runApp(const ViloyatShtabiApp());
}

class ViloyatShtabiApp extends StatelessWidget {
  const ViloyatShtabiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Viloyat shtabi',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    // ⚠️ MATN O'LCHAMI CHEGARALANADI: tizimda "juda katta shrift"
    // tanlangan qurilmada kartalar bir-birining ustiga chiqib
    // ketardi.
    builder: (context, child) {
      final scale = MediaQuery.textScalerOf(context).clamp(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.3,
      );
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: scale),
        child: child!,
      );
    },
    home: const AuthGate(),
  );
}
