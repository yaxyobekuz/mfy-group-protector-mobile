/// TAKRORLANADIGAN KO'RINISHLAR.
///
/// ⚠️ "YUKLANMOQDA / XATO / BO'SH" UCHALASI BITTA JOYDA
/// (`AsyncView`): har ekranda qo'lda yozilsa, bittasida xato
/// holati umuman ko'rsatilmay, ekran abadiy aylanuvchi doira
/// bo'lib qolardi — aynan shu eng ko'p uchraydigan xato.
library;

import 'package:flutter/material.dart';

import '../api/client.dart';
import '../config/labels.dart';
import '../config/theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: cardShadow,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: content,
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final label = statusOf(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: label.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.label,
        style: TextStyle(
          color: label.color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class LoadingBlock extends StatelessWidget {
  const LoadingBlock({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(strokeWidth: 2.4),
        if (label != null) ...[
          const SizedBox(height: 14),
          Text(
            label!,
            style: const TextStyle(color: AppColors.mutedForeground),
          ),
        ],
      ],
    ),
  );
}

class MessageBlock extends StatelessWidget {
  const MessageBlock({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel = 'Qaytadan urinish',
  });

  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.mutedForeground),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedForeground),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: 220,
              child: FilledButton(onPressed: onRetry, child: Text(retryLabel)),
            ),
          ],
        ],
      ),
    ),
  );
}

/// SO'ROV HOLATLARINI BITTA JOYDA KO'RSATADI.
///
/// ⚠️ XATO MATNI SERVERDAN OLINADI (`ApiException.message`): u
/// o'zbekcha va aniq sabab aytadi. Umumiy "Xatolik" fuqaroga nima
/// qilishni aytmasdi.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.future,
    required this.builder,
    this.loadingLabel,
    this.onRetry,
    this.emptyWhen,
    this.emptyTitle = 'Hozircha bo\'sh',
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
  });

  final Future<T>? future;
  final Widget Function(BuildContext context, T data) builder;
  final String? loadingLabel;
  final VoidCallback? onRetry;
  final bool Function(T data)? emptyWhen;
  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return LoadingBlock(label: loadingLabel);
      }

      if (snapshot.hasError) {
        final error = snapshot.error;
        return MessageBlock(
          icon: Icons.cloud_off_outlined,
          title: 'Ma\'lumot olinmadi',
          message: error is ApiException
              ? error.message
              : 'Serverga ulanib bo\'lmadi.',
          onRetry: onRetry,
        );
      }

      final data = snapshot.data as T;
      if (emptyWhen != null && emptyWhen!(data)) {
        return MessageBlock(
          icon: emptyIcon,
          title: emptyTitle,
          message: emptyMessage,
        );
      }

      return builder(context, data);
    },
  );
}

/// Sarlavha + "hammasi" havolasi.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              action!,
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
      ],
    ),
  );
}

/// Yumaloq rasm — surat bo'lmasa bosh harf.
class Avatar extends StatelessWidget {
  const Avatar({super.key, this.url, required this.name, this.size = 48});
  final String? url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: AppColors.accent,
        child: url == null
            ? Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentForeground,
                  ),
                ),
              )
            // ⚠️ XATO USHLANADI: Telegram/Google surat havolasi
            // muddati o'tgan bo'lishi mumkin va `Image.network`
            // bunda qizil xato kvadratini chizardi.
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentForeground,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Xabarni bir xil ko'rinishda ko'rsatadi.
void showToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.destructive : AppColors.foreground,
      ),
    );
}

/// ILOVA BELGISI — qalqon + joy nuqtasi.
///
/// ⚠️ LAUNCHER BELGISI BILAN AYNI SHAKL (`tool/make_icons.py`).
/// Avval bu yerda `Icons.campaign` (karnay) turardi va ilova
/// ichidagi belgi telefon ekranidagi belgidan butunlay boshqacha
/// edi — foydalanuvchi uchun bu "boshqa ilova" degan taassurot
/// qoldirardi.
///
/// ⚠️ RASM EMAS, CHIZMA: PNG qo'shilsa, u yana bir nusxa bo'lardi
/// va belgi o'zgarganda ikkisidan biri eskirib qolardi. Bu yerda
/// shakl KOD bilan chiziladi — har doim bir xil.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 56, this.color});

  final double size;

  /// Qalqon rangi (standart — brend ko'ki).
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _LogoPainter(color ?? AppColors.primary)),
  );
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final paint = Paint()..color = color..isAntiAlias = true;

    // ── Qalqon ──────────────────────────────────────────────
    final path = Path();
    final left = w * 0.14, right = w * 0.86;
    final top = w * 0.10, bottom = w * 0.93;
    final shoulder = top + (bottom - top) * 0.50;

    path.moveTo(left, top);
    path.lineTo(right, top);
    path.lineTo(right, shoulder);
    // Pastki egri qirralar — belgi "uy" ga o'xshab qolmasligi uchun.
    path.quadraticBezierTo(right, bottom - w * 0.06, w / 2, bottom);
    path.quadraticBezierTo(left, bottom - w * 0.06, left, shoulder);
    path.close();
    canvas.drawPath(path, paint);

    // ── Joy nuqtasi (oq, qalqon ichida) ─────────────────────
    final hole = Paint()..color = Colors.white..isAntiAlias = true;
    final pr = w * 0.155;
    final pcy = top + (bottom - top) * 0.36;
    canvas.drawCircle(Offset(w / 2, pcy), pr, hole);

    final tip = Path()
      ..moveTo(w / 2 - pr * 0.72, pcy + pr * 0.62)
      ..lineTo(w / 2 + pr * 0.72, pcy + pr * 0.62)
      ..lineTo(w / 2, pcy + pr * 2.25)
      ..close();
    canvas.drawPath(tip, hole);

    // Halqa teshigi — qalqon rangida.
    canvas.drawCircle(Offset(w / 2, pcy), pr * 0.38, paint);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.color != color;
}
