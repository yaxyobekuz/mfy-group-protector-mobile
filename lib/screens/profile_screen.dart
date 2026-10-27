/// PROFIL.
///
/// ⚠️ ISM/RASM TAHRIRLANMAYDI: ular Google hisobidan keladi va har
/// kirishda qaytadan yoziladi — ilovada o'zgartirilgani keyingi
/// kirishda jimgina yo'qolardi.
///
/// ⚠️ TELEFON IXTIYORIY: majburiy qilinsa, raqamini bermoqchi
/// bo'lmagan fuqaro murojaat yubora olmasdi. U faqat ma'muriyat
/// qayta aloqa qilishi uchun.
library;

import 'package:flutter/material.dart';

import '../entities/session/session.dart';
import '../shared/api/client.dart';
import '../shared/api/models.dart';
import '../shared/config/theme.dart';
import '../shared/util/date_uz.dart';
import '../shared/ui/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _phone = TextEditingController();
  bool _saving = false;
  bool _filled = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _savePhone() async {
    setState(() => _saving = true);
    try {
      await ApiClient.patch('/mobile/me', {'phone': _phone.text.trim()});
      await SessionController.instance.refresh();
      if (mounted) showToast(context, 'Saqlandi');
    } on ApiException catch (error) {
      if (mounted) showToast(context, error.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hisobdan chiqish'),
        content: const Text(
          'Chiqqaningizdan keyin murojaatlaringizni ko\'rish uchun '
          'qaytadan kirishingiz kerak bo\'ladi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
              minimumSize: const Size(100, 44),
            ),
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );

    if (ok == true) await SessionController.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionController.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: AnimatedBuilder(
        animation: session,
        builder: (context, _) {
          final CitizenProfile? profile = session.profile;
          if (profile == null) return const LoadingBlock();

          // ⚠️ BIR MARTA TO'LDIRILADI: har qayta chizilganda
          // yozilsa, fuqaro yozayotgan matn ustiga yozib ketardi.
          if (!_filled) {
            _phone.text = profile.phone ?? '';
            _filled = true;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              AppCard(
                child: Row(
                  children: [
                    Avatar(
                      url: profile.photoUrl,
                      name: profile.firstName,
                      size: 60,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (profile.email != null)
                            Text(
                              profile.email!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            '${formatDateUz(profile.createdAt)} dan beri',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Tile(
                      value: '${profile.stats.total}',
                      label: 'Murojaat',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Tile(
                      value: '${profile.stats.resolved}',
                      label: 'Hal qilindi',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Tile(value: '${profile.points}', label: 'Ball'),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _Row(
                      icon: Icons.place_outlined,
                      label: 'Tuman',
                      value: profile.districtName ?? '—',
                    ),
                    const Divider(height: 1, indent: 52),
                    _Row(
                      icon: Icons.place_outlined,
                      label: 'MFY',
                      value: profile.mahallaName ?? '—',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Telefon raqami',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '+998 __ ___ __ __',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ixtiyoriy — ma\'muriyat qayta aloqa qilishi uchun',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    if (_phone.text.trim() != (profile.phone ?? '')) ...[
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _saving ? null : _savePhone,
                        child: Text(_saving ? 'Saqlanmoqda…' : 'Saqlash'),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _confirmSignOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.destructive,
                  side: const BorderSide(color: AppColors.border),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Hisobdan chiqish'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.mutedForeground),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
