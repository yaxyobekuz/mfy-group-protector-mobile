/// KIRISH EKRANI — FAQAT GOOGLE.
///
/// ⚠️ BITTA TUGMA — ATAYLAB. Ikkinchi yo'l (telefon/parol/Telegram)
/// qo'shilsa, bitta odam ikki hisob ochib, murojaatlari ikkiga
/// bo'linib ketardi: biri "Mening murojaatlarim" da ko'rinib,
/// ikkinchisi yo'qolgandek bo'lardi.
library;

import 'package:flutter/material.dart';

import '../../shared/config/env.dart';
import '../../shared/config/theme.dart';
import 'session.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionController.instance;

    return Scaffold(
      body: AnimatedBuilder(
        animation: session,
        builder: (context, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'Viloyat shtabi',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Hududingizdagi muammolarni fotosurat bilan yuboring. '
                  'Biz ularni hal qilishga yordam beramiz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),

                // ⚠️ XATO SABABI KO'RSATILADI: "kirib bo'lmadi" degan
                // quruq xabar fuqaroga nima qilishni aytmasdi.
                if (session.authError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x14DC2828),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      session.authError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.destructive),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                _GoogleButton(
                  busy: session.busy,
                  onPressed: session.signInWithGoogle,
                ),

                // ⚠️ FAQAT ISHLAB CHIQISHDA KO'RINADI
                // (`--dart-define=DEV_LOGIN=true`). Server bu yo'lni
                // `production` da O'ZI rad etadi.
                if (Env.devLoginEnabled) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: session.busy ? null : session.signInDev,
                    icon: const Icon(Icons.bug_report_outlined, size: 18),
                    label: const Text('Sinov kirishi (dev)'),
                  ),
                ],

                const SizedBox(height: 20),
                const Text(
                  'Kirish uchun Google hisobingiz kerak. Ma\'lumotlaringiz '
                  'faqat murojaatingizni ko\'rib chiqish uchun ishlatiladi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// GOOGLE TUGMASI.
///
/// ⚠️ BELGI INLINE CHIZILADI, RASM FAYLI EMAS: internetsiz
/// ochilganda ham ko'rinishi kerak va bitta PNG uchun aktiv
/// papkasini ochish ortiqcha.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.foreground,
        side: const BorderSide(color: AppColors.border),
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _GoogleMark(),
                SizedBox(width: 12),
                Text(
                  'Google orqali kirish',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
    ),
  );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(20, 20), painter: _GooglePainter());
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final stroke = size.width * 0.22;
    final inner = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Google rasmiy ranglari — to'rt yoy.
    const double q = 1.5707963; // pi / 2
    final arcs = <(double, Color)>[
      (-q * 0.25, const Color(0xFFEA4335)), // qizil — yuqori o'ng
      (q * 0.75, const Color(0xFF4285F4)), // ko'k — pastki o'ng
      (q * 1.75, const Color(0xFF34A853)), // yashil — pastki chap
      (q * 2.75, const Color(0xFFFBBC05)), // sariq — yuqori chap
    ];

    for (final (start, color) in arcs) {
      canvas.drawArc(inner, start, q, false, paint..color = color);
    }

    // "G" ning gorizontal chizig'i.
    final bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.5,
        size.height * 0.4,
        size.width * 0.5,
        stroke,
      ),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
