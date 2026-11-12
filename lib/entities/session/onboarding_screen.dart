/// BIRINCHI KIRISH — HUDUD VA TELEFON.
///
/// ⚠️ MAJBURIY VA O'TKAZIB BO'LMAYDI. Hududsiz murojaat qaysi MFY
/// ga tushishini tizim bilmaydi va u "egasiz" navbatda qolardi.
/// Keyin so'ralsa, fuqaro uni har safar o'tkazib yuborardi.
///
/// ⚠️ TELEFON HAM SHU YERDA, ALOHIDA EKRANDA EMAS: ketma-ket ikki
/// to'siq qo'yish fuqaroni ilovadan qaytarardi. Sabab esa AYNI —
/// telefonsiz murojaatda xodim odamga bog'lana olmaydi va murojaat
/// navbatda turib qoladi (server uni `create` da RAD ETADI).
///
/// ⚠️ TELEFON TALABI SERVERDAN KELADI (`profile.phoneNeeded`): u
/// sozlama (`Settings.requirePhone`) va panelda o'chirilishi mumkin.
/// Ilovada qotib qolsa, do'kondagi eski versiya baribir so'rab
/// turardi — do'kondagi versiyalar esa uzoq yashaydi.
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
  final TextEditingController _phone = TextEditingController();
  bool _saving = false;

  /// ⚠️ TALAB SESSIYADAN O'QILADI, ilovada HISOBLANMAYDI: u
  /// `Settings.requirePhone` sozlamasiga bog'liq.
  bool get _needsPhone =>
      SessionController.instance.profile?.phoneNeeded ?? false;

  /// ⚠️ ENG QO'POL FILTR — HAQIQIY TEKSHIRUV SERVERDA
  /// (`common/phone.ts`). Ikkinchi to'liq nusxa yozilsa, ikkisi
  /// albatta ajralib ketardi: ilova qabul qilgan raqam serverda rad
  /// etilib, fuqaro sababini bilmay qolardi.
  bool get _phoneOk =>
      !_needsPhone ||
      _phone.text.replaceAll(RegExp(r'[^0-9]'), '').length >= 9;

  @override
  void initState() {
    super.initState();

    // ⚠️ MAVJUD QIYMATLAR OLDINDAN QO'YILADI. Bu ekran endi FAQAT
    // hudud uchun emas: telefon qo'shilgach, hududi ALLAQACHON bor
    // fuqaro ham bu yerga tushadi. Maydonlar bo'sh qolsa, u tumanini
    // va MFY sini QAYTA tanlashga majbur bo'lardi — va "Davom etish"
    // tugmasi o'chiq turardi.
    final profile = SessionController.instance.profile;
    _districtId = profile?.districtId;
    _mahallaId = profile?.mahallaId;
    _phone.text = profile?.phone ?? '';

    _load();
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _load() {
    _future = ApiClient.get('/mobile/territory').then(
      (data) => Territory.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> _save() async {
    if (_districtId == null || _mahallaId == null || !_phoneOk) return;
    setState(() => _saving = true);

    try {
      await ApiClient.patch('/mobile/me', {
        'districtId': _districtId,
        'mahallaId': _mahallaId,
        // ⚠️ FAQAT YOZILGAN BO'LSA YUBORILADI: bo'sh satr serverda
        // "raqamni o'chirish" deb tushunilardi va telefon majburiy
        // bo'lganda butun so'rov rad etilardi.
        if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
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
                  Text(
                    _needsPhone
                        ? 'Murojaatingiz to\'g\'ri mahallaga yetib borishi '
                              'uchun hududingizni tanlang va telefon '
                              'raqamingizni kiriting.'
                        : 'Murojaatingiz to\'g\'ri mahallaga yetib borishi '
                              'uchun hududingizni tanlang.',
                    style: const TextStyle(
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

                  // ── TELEFON ─────────────────────────────────────
                  //
                  // ⚠️ FAQAT TALAB QILINGANDA KO'RSATILADI: raqami bor
                  // fuqaro hududini o'zgartirmoqchi bo'lganda ortiqcha
                  // maydon ko'rishi shart emas.
                  if (_needsPhone) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Telefon raqamingiz',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      autofillHints: const <String>[
                        AutofillHints.telephoneNumber,
                      ],
                      decoration: const InputDecoration(
                        hintText: '+998 90 123 45 67',
                      ),
                      // ⚠️ `setState` HAR HARFDA: tugmaning yoqilgan
                      // holati raqam uzunligiga bog'liq va usiz u
                      // o'chiq turardi.
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Murojaatingiz bo\'yicha xodim siz bilan shu raqam '
                      'orqali bog\'lanadi.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.mutedForeground,
                        height: 1.4,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed:
                        _saving ||
                            _districtId == null ||
                            _mahallaId == null ||
                            !_phoneOk
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
