/// KIRISH DARVOZASI — qaysi ekran ko'rsatilishini hal qiladi.
///
/// ⚠️ TEKSHIRUV BITTA JOYDA. Har ekranda "kirganmi?" deb qo'lda
/// tekshirilsa, bittasida unutilib, kirmagan fuqaro ro'yxatni
/// ochib qo'yardi (va server 401 bergani uchun bo'sh ekran
/// ko'rardi — sababsiz).
///
/// ⚠️ HUDUD TANLASH HAM SHU YERDA: tuman YOKI MFY bo'sh bo'lsa,
/// ilovaga o'tkazilmaydi. Shu tufayli murojaat yaratish ekrani
/// "hudud yo'q" holatini umuman bilmaydi.
library;

import 'package:flutter/material.dart';

import '../../screens/home_shell.dart';
import '../../shared/ui/widgets.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'session.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final SessionController _session = SessionController.instance;

  @override
  void initState() {
    super.initState();
    // ⚠️ `addPostFrameCallback` EMAS: `bootstrap` tarmoqqa chiqadi
    // va birinchi kadrni kutib o'tirishi shart emas.
    _session.bootstrap();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _session,
    builder: (context, _) {
      switch (_session.status) {
        case SessionStatus.loading:
          return const Scaffold(
            body: LoadingBlock(label: 'Ilova ochilmoqda…'),
          );

        case SessionStatus.signedOut:
          return const LoginScreen();

        case SessionStatus.needsTerritory:
          return const OnboardingScreen();

        case SessionStatus.ready:
          return const HomeShell();
      }
    },
  );
}
