/// BIRINCHI KIRISH — HUDUD TANLASH.
///
/// ⚠️ MAJBURIY VA O'TKAZIB BO'LMAYDI. Hududsiz murojaat qaysi MFY
/// ga tushishini tizim bilmaydi va u "egasiz" navbatda qolardi.
/// Keyin so'ralsa, fuqaro uni har safar o'tkazib yuborardi.
///
/// ⚠️ IKKALASI HAM TALAB QILINADI (tuman VA MFY): `AuthGate`
/// shartidan chiqish aynan shunda.
library;

import 'package:flutter/material.dart';

import '../../shared/api/client.dart';
import '../../shared/api/models.dart';
import '../../shared/config/theme.dart';
import '../../shared/ui/widgets.dart';
import 'session.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late Future<Territory> _future;
  String? _districtId;
  String? _mahallaId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ApiClient.get('/mobile/territory').then(
      (data) => Territory.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> _save() async {
    if (_districtId == null || _mahallaId == null) return;
    setState(() => _saving = true);

    try {
      await ApiClient.patch('/mobile/me', {
        'districtId': _districtId,
        'mahallaId': _mahallaId,
      });
      // ⚠️ SESSIYA QAYTA O'QILADI: `AuthGate` shu ma'lumotga qarab
      // ekranni almashtiradi. Mahalliy holatni o'zgartirish bilan
      // kifoyalansa, server bilan ekran ajralib ketardi.
      await SessionController.instance.refresh();
    } on ApiException catch (error) {
      if (mounted) showToast(context, error.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = SessionController.instance.profile;

    return Scaffold(
      body: SafeArea(
        child: AsyncView<Territory>(
          future: _future,
          loadingLabel: 'Hududlar yuklanmoqda…',
          onRetry: () => setState(_load),
          builder: (context, territory) {
            final mahallas = territory.mahallas
                .where((m) => m.districtId == _districtId)
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Assalomu alaykum, ${profile?.firstName ?? "fuqaro"}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Murojaatingiz to\'g\'ri mahallaga yetib borishi uchun '
                    'hududingizni tanlang.',
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Tuman',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _districtId,
                    isExpanded: true,
                    hint: const Text('Tumanni tanlang'),
                    items: territory.districts
                        .map(
                          (d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _districtId = value;
                      // ⚠️ MFY TOZALANADI: tuman o'zgarganda eski MFY
                      // boshqa tumanniki bo'lib qolardi va murojaat
                      // noto'g'ri joyga ketardi.
                      _mahallaId = null;
                    }),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Mahalla (MFY)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _mahallaId,
                    isExpanded: true,
                    hint: Text(
                      _districtId == null
                          ? 'Avval tumanni tanlang'
                          : 'Mahallani tanlang',
                    ),
                    items: mahallas
                        .map(
                          (m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(m.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: _districtId == null
                        ? null
                        : (value) => setState(() => _mahallaId = value),
                  ),

                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed:
                        _saving || _districtId == null || _mahallaId == null
                        ? null
                        : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Davom etish'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: SessionController.instance.signOut,
                    child: const Text(
                      'Boshqa hisob bilan kirish',
                      style: TextStyle(color: AppColors.mutedForeground),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
