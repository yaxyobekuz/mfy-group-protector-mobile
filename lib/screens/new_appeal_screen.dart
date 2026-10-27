/// YANGI MUROJAAT — BESH QADAMLI SEHRGAR.
///
/// ⚠️ QADAMLAR RO'YXATI `labels.dart` DAN (`wizardSteps`): sanoqchi
/// ("2/5") ham shundan chiqadi. Qo'lda yozilsa, qadam qo'shilganda
/// beshta joyni tuzatish kerak bo'lardi va bittasi albatta
/// eskiligicha qolardi.
///
/// ⚠️ AI FAQAT TAKLIF QILADI, QAROR QILMAYDI: beshinchi qadamda
/// fuqaroning O'ZI tasdiqlaydi. Avtomatik yuborilsa, "signal —
/// muammo emas" doktrinasi buzilardi.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../entities/session/session.dart';
import '../shared/api/client.dart';
import '../shared/api/models.dart';
import '../shared/config/labels.dart';
import '../shared/config/theme.dart';
import '../shared/ui/widgets.dart';

/// Server cheklovi (`mobile.dto.ts` dagi `BODY_MIN`/`BODY_MAX`).
///
/// ⚠️ IKKI JOYDA — SERVER VA ILOVADA. Faqat serverda bo'lsa,
/// fuqaro uzun matnni yozib bo'lib, yuborishda rad javobini
/// olardi.
const int bodyMin = 10;
const int bodyMax = 2000;
const int maxPhotos = 5;

class NewAppealScreen extends StatefulWidget {
  const NewAppealScreen({super.key});

  @override
  State<NewAppealScreen> createState() => _NewAppealScreenState();
}

class _NewAppealScreenState extends State<NewAppealScreen> {
  int _step = 0;

  late Future<List<Category>> _categories;

  String? _categoryId;
  final List<UploadedFile> _uploads = <UploadedFile>[];
  final List<File> _localPhotos = <File>[];
  bool _uploading = false;

  LatLng? _point;
  final TextEditingController _address = TextEditingController();
  final TextEditingController _body = TextEditingController();

  bool _isHazard = false;
  bool _isLongStanding = false;
  bool _isRepeatAppeal = false;

  AnalysisResponse? _analysis;
  bool _analyzing = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _categories = ApiClient.get('/mobile/categories').then(
      (d) => (d as List<dynamic>)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  void dispose() {
    _address.dispose();
    _body.dispose();
    super.dispose();
  }

  // ── QADAM ALMASHTIRISH ────────────────────────────────────────────

  bool get _canGoNext {
    switch (_step) {
      case 0:
        return _categoryId != null;
      case 1:
        // ⚠️ SURAT MAJBURIY EMAS: ba'zi muammoni suratga olib
        // bo'lmaydi (hid, shovqin) va majburiy qilinsa, fuqaro
        // tasodifiy rasm qo'yardi.
        return !_uploading;
      case 2:
        return true;
      case 3:
        return _body.text.trim().length >= bodyMin;
      default:
        return true;
    }
  }

  Future<void> _next() async {
    if (!_canGoNext) return;

    // Oxirgi qadamdan oldin AI tahlili so'raladi.
    if (_step == 3) {
      await _analyze();
    }

    if (_step < wizardSteps.length - 1) {
      setState(() => _step += 1);
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() => _step -= 1);
  }

  // ── SURAT ─────────────────────────────────────────────────────────

  Future<void> _pick(ImageSource source) async {
    if (_uploads.length >= maxPhotos) return;

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      // ⚠️ SIFAT PASAYTIRILADI: zamonaviy telefon surati 5-10 MB
      // va mobil internetda yuklanishi daqiqalar olardi.
      imageQuality: 70,
      maxWidth: 1920,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final file = File(picked.path);
      final data =
          await ApiClient.upload('/mobile/uploads', file)
              as Map<String, dynamic>;

      setState(() {
        _uploads.add(UploadedFile.fromJson(data));
        _localPhotos.add(file);
      });
    } on ApiException catch (error) {
      if (mounted) showToast(context, error.message, error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ── JOY ───────────────────────────────────────────────────────────

  Future<void> _useMyLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          showToast(
            context,
            'Joylashuvga ruxsat berilmadi. Xaritada qo\'lda belgilang.',
            error: true,
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() => _point = LatLng(position.latitude, position.longitude));
    } on Exception {
      if (mounted) {
        showToast(
          context,
          'Joylashuv aniqlanmadi. Xaritada qo\'lda belgilang.',
          error: true,
        );
      }
    }
  }

  // ── AI ────────────────────────────────────────────────────────────

  Future<void> _analyze() async {
    setState(() {
      _analyzing = true;
      _analysis = null;
    });

    try {
      final data =
          await ApiClient.post('/mobile/appeals/analyze', {
                'body': _body.text.trim(),
              })
              as Map<String, dynamic>;
      setState(() => _analysis = AnalysisResponse.fromJson(data));
    } on ApiException {
      // ⚠️ AI YIQILSA MUROJAAT TO'XTAMAYDI: taklif qo'shimcha
      // qulaylik, majburiy bosqich emas. Aks holda model
      // ishlamaganda hech kim murojaat yubora olmasdi.
      setState(() => _analysis = null);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  // ── YUBORISH ──────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final profile = SessionController.instance.profile;

    try {
      final data =
          await ApiClient.post('/mobile/appeals', <String, dynamic>{
                'categoryId': _categoryId,
                'body': _body.text.trim(),
                'districtId': profile?.districtId,
                'mahallaId': profile?.mahallaId,
                if (_point != null) 'lat': _point!.latitude,
                if (_point != null) 'lng': _point!.longitude,
                if (_address.text.trim().isNotEmpty)
                  'address': _address.text.trim(),
                'isHazard': _isHazard,
                'isLongStanding': _isLongStanding,
                'isRepeatAppeal': _isRepeatAppeal,
                if (_uploads.isNotEmpty)
                  'attachments': _uploads.map((u) => u.token).toList(),
                if (_analysis?.token != null)
                  'analysisToken': _analysis!.token,
              })
              as Map<String, dynamic>;

      final created = CreatedAppeal.fromJson(data);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _SuccessDialog(appeal: created),
      );

      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) showToast(context, error.message, error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── KO'RINISH ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final step = wizardSteps[_step];

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _back,
          ),
          title: Text('${_step + 1}/${wizardSteps.length}'),
        ),
        body: Column(
          children: [
            // Qadam ko'rsatkichi.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (var i = 0; i < wizardSteps.length; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _step
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.hint,
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _body_()),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _step == wizardSteps.length - 1
                    ? FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: Text(
                          _submitting ? 'Yuborilmoqda…' : 'Murojaatni yuborish',
                        ),
                      )
                    : FilledButton(
                        onPressed: _canGoNext ? _next : null,
                        child: const Text('Davom etish'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body_() {
    switch (_step) {
      case 0:
        return _CategoryStep(
          future: _categories,
          selected: _categoryId,
          onSelect: (id) => setState(() => _categoryId = id),
        );
      case 1:
        return _MediaStep(
          photos: _localPhotos,
          uploading: _uploading,
          onPick: _pick,
          onRemove: (index) => setState(() {
            _uploads.removeAt(index);
            _localPhotos.removeAt(index);
          }),
        );
      case 2:
        return _LocationStep(
          point: _point,
          address: _address,
          onPoint: (value) => setState(() => _point = value),
          onLocate: _useMyLocation,
        );
      case 3:
        return _DetailsStep(
          body: _body,
          isHazard: _isHazard,
          isLongStanding: _isLongStanding,
          isRepeatAppeal: _isRepeatAppeal,
          onChanged: (hazard, long, repeat) => setState(() {
            _isHazard = hazard;
            _isLongStanding = long;
            _isRepeatAppeal = repeat;
          }),
          onText: () => setState(() {}),
        );
      default:
        return _ReviewStep(
          analyzing: _analyzing,
          analysis: _analysis,
          body: _body.text.trim(),
          photos: _localPhotos.length,
          hasPoint: _point != null,
        );
    }
  }
}

// ══════════════════════════════════════════════════════════════════
//  1 — TOIFA
// ══════════════════════════════════════════════════════════════════

class _CategoryStep extends StatelessWidget {
  const _CategoryStep({
    required this.future,
    required this.selected,
    required this.onSelect,
  });

  final Future<List<Category>> future;
  final String? selected;
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context) => AsyncView<List<Category>>(
    future: future,
    loadingLabel: 'Yo\'nalishlar yuklanmoqda…',
    builder: (context, categories) => GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final active = category.id == selected;
        final color = colorOf(category.color);

        return GestureDetector(
          onTap: () => onSelect(category.id),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
                width: active ? 2 : 1,
              ),
              boxShadow: active ? cardShadow : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(iconOf(category.icon), color: color, size: 26),
                const Spacer(),
                Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  slaText(category.slaHours),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// ══════════════════════════════════════════════════════════════════
//  2 — SURAT
// ══════════════════════════════════════════════════════════════════

class _MediaStep extends StatelessWidget {
  const _MediaStep({
    required this.photos,
    required this.uploading,
    required this.onPick,
    required this.onRemove,
  });

  final List<File> photos;
  final bool uploading;
  final Future<void> Function(ImageSource source) onPick;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
    children: [
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: uploading || photos.length >= maxPhotos
                  ? null
                  : () => onPick(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Kamera'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: uploading || photos.length >= maxPhotos
                  ? null
                  : () => onPick(ImageSource.gallery),
              icon: const Icon(Icons.image_outlined),
              label: const Text('Galereya'),
            ),
          ),
        ],
      ),
      if (uploading) ...[
        const SizedBox(height: 18),
        const LoadingBlock(label: 'Surat yuklanmoqda…'),
      ],
      const SizedBox(height: 18),
      if (photos.isEmpty && !uploading)
        const MessageBlock(
          icon: Icons.add_a_photo_outlined,
          title: 'Surat qo\'shilmagan',
          message: 'Surat majburiy emas, lekin u bilan muammo '
              'tezroq hal qilinadi.',
        )
      else
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) => Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(photos[index], fit: BoxFit.cover),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => onRemove(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

// ══════════════════════════════════════════════════════════════════
//  3 — JOY
// ══════════════════════════════════════════════════════════════════

/// ⚠️ KO'RINAYOTGAN NARSA = SAQLANADIGAN QIYMAT.
///
/// Xarita ochilishi bilan markazdagi nuqta DARHOL yoziladi. Faqat
/// surilganda yozilsa, nuqtani to'g'ri joyda deb topgan odam hech
/// narsa surmay davom etardi — murojaat esa JOYSIZ ketardi, ekranda
/// esa nuqta turgan bo'lardi.
class _LocationStep extends StatefulWidget {
  const _LocationStep({
    required this.point,
    required this.address,
    required this.onPoint,
    required this.onLocate,
  });

  final LatLng? point;
  final TextEditingController address;
  final void Function(LatLng point) onPoint;
  final Future<void> Function() onLocate;

  @override
  State<_LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<_LocationStep> {
  static const LatLng _fallback = LatLng(40.7821, 72.3442);
  final MapController _controller = MapController();

  @override
  void initState() {
    super.initState();
    // ⚠️ DARHOL YOZILADI (yuqoridagi izoh).
    if (widget.point == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onPoint(_fallback);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.point ?? _fallback;

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              FlutterMap(
                mapController: _controller,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 15,
                  // ⚠️ MARKAZ O'ZGARGANDA YOZILADI: nuqta ekran
                  // markazida turadi, ya'ni ko'rinayotgan joy
                  // saqlanadigan joy bilan AYNI.
                  onPositionChanged: (position, _) =>
                      widget.onPoint(position.center),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'uz.mysrv.nazoratchi',
                    maxZoom: 19,
                  ),
                ],
              ),
              // Markazdagi qadalgan nuqta.
              const Padding(
                padding: EdgeInsets.only(bottom: 28),
                child: Icon(
                  Icons.location_on,
                  size: 44,
                  color: AppColors.destructive,
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(
                  heroTag: 'locate',
                  backgroundColor: AppColors.card,
                  foregroundColor: AppColors.primary,
                  onPressed: () async {
                    await widget.onLocate();
                    if (widget.point != null) {
                      _controller.move(widget.point!, 16);
                    }
                  },
                  child: const Icon(Icons.my_location),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: widget.address,
            maxLength: 300,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.place_outlined),
              hintText: 'Manzil (ko\'cha, uy) — ixtiyoriy',
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  4 — TAFSILOT
// ══════════════════════════════════════════════════════════════════

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.body,
    required this.isHazard,
    required this.isLongStanding,
    required this.isRepeatAppeal,
    required this.onChanged,
    required this.onText,
  });

  final TextEditingController body;
  final bool isHazard;
  final bool isLongStanding;
  final bool isRepeatAppeal;
  final void Function(bool hazard, bool long, bool repeat) onChanged;
  final VoidCallback onText;

  @override
  Widget build(BuildContext context) {
    final length = body.text.trim().length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        TextField(
          controller: body,
          maxLines: 7,
          maxLength: bodyMax,
          onChanged: (_) => onText(),
          decoration: InputDecoration(
            hintText: 'Muammoni qisqacha tasvirlang…',
            helperText: length < bodyMin
                ? 'Kamida $bodyMin belgi (hozir $length)'
                : null,
            helperStyle: const TextStyle(color: AppColors.warning),
          ),
        ),
        const SizedBox(height: 10),

        // ⚠️ BAYROQLAR USTUVORLIKNI O'ZGARTIRMAYDI — ular TAXMIN va
        // panelda faqat ko'rsatiladi. Aks holda "shoshilinch"
        // tugmasini har kim bosib, navbat ma'nosini yo'qotardi.
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                value: isHazard,
                onChanged: (v) => onChanged(v, isLongStanding, isRepeatAppeal),
                title: const Text('Xavfli holat'),
                subtitle: const Text('Odamlar salomatligiga xavf bor'),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: isLongStanding,
                onChanged: (v) => onChanged(isHazard, v, isRepeatAppeal),
                title: const Text('Uzoq vaqtdan beri'),
                subtitle: const Text('Muammo uzoq vaqt hal qilinmagan'),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: isRepeatAppeal,
                onChanged: (v) => onChanged(isHazard, isLongStanding, v),
                title: const Text('Takroriy murojaat'),
                subtitle: const Text('Bu haqda avval ham yozganman'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  5 — AI TAHLILI
// ══════════════════════════════════════════════════════════════════

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.analyzing,
    required this.analysis,
    required this.body,
    required this.photos,
    required this.hasPoint,
  });

  final bool analyzing;
  final AnalysisResponse? analysis;
  final String body;
  final int photos;
  final bool hasPoint;

  @override
  Widget build(BuildContext context) {
    if (analyzing) {
      return const LoadingBlock(label: 'AI tahlil qilmoqda…');
    }

    final suggestion = analysis?.suggestion;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        if (suggestion != null)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'AI taklifi',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${(suggestion.confidence * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      iconOf(suggestion.categoryIcon),
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.categoryName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (suggestion.orgName != null)
                            Text(
                              suggestion.orgName!,
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
                const SizedBox(height: 10),
                Text(
                  'Javob muddati: ${slaText(suggestion.slaHours)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 10),
                // ⚠️ TAKLIF — QAROR EMAS: oxirgi so'z fuqaroniki.
                const Text(
                  'Bu — tizim taklifi. Yuborganingizdan keyin mutaxassis '
                  'tekshiradi.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                    height: 1.45,
                  ),
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
                'Murojaat matni',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(body, style: const TextStyle(height: 1.55)),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Chip(
                    icon: Icons.image_outlined,
                    label: photos == 0 ? 'Surat yo\'q' : '$photos ta surat',
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    icon: Icons.place_outlined,
                    label: hasPoint ? 'Joy belgilangan' : 'Joy yo\'q',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.muted,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.mutedForeground),
        const SizedBox(width: 5),
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

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({required this.appeal});
  final CreatedAppeal appeal;

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Icon(
      Icons.check_circle_outline,
      size: 48,
      color: AppColors.success,
    ),
    title: const Text('Murojaat qabul qilindi'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          appeal.publicNo,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          '${appeal.categoryName}\n'
          '${appeal.orgName ?? "Mas'ul tashkilot belgilanadi"}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.mutedForeground,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Javob muddati: ${slaText(appeal.slaHours)}',
          style: const TextStyle(fontSize: 13),
        ),
      ],
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Yopish'),
      ),
    ],
  );
}
