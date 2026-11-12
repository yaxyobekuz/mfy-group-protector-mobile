/// SERVER JAVOBLARINING TURLARI.
///
/// ⚠️ QO'LDA YOZILGAN va serverdagi turlar bilan QO'LDA sinxron —
/// mini-ilovadagi `shared/api/types.ts` ning ko'zgusi. Kod
/// generatsiyasi (`openapi`) qurilish bosqichida server ishga
/// tushishini talab qilardi.
///
/// ⚠️ TO'G'RIDAN-TO'G'RI `as double` QILINMAYDI: JSON'da butun son
/// `int` bo'lib keladi va `as double` ish vaqtida yiqilardi. Shuning
/// uchun quyidagi yordamchilar.
library;

import '../config/env.dart';

String? _str(Object? v) => v is String && v.isNotEmpty ? v : null;
int _int(Object? v) => v is num ? v.toInt() : 0;
double? _dbl(Object? v) => v is num ? v.toDouble() : null;
bool _bool(Object? v) => v == true;

/// Nisbiy `/uploads/...` manzilini to'liq havolaga aylantiradi.
///
/// ⚠️ ALLAQACHON TO'LIQ BO'LSA TEGILMAYDI: server ba'zi joyda
/// to'liq havola qaytaradi va oldiga yana domen qo'shilsa, manzil
/// buzilardi.
String fileUrl(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final suffix = path.startsWith('/') ? path : '/$path';
  return '${Env.filesBase}$suffix';
}

class Ref {
  const Ref({required this.id, required this.name});
  final String id;
  final String name;

  factory Ref.fromJson(Map<String, dynamic> j) =>
      Ref(id: j['id'] as String, name: j['name'] as String? ?? '');
}

class MahallaRef extends Ref {
  const MahallaRef({
    required super.id,
    required super.name,
    required this.districtId,
  });
  final String districtId;

  factory MahallaRef.fromJson(Map<String, dynamic> j) => MahallaRef(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    districtId: j['districtId'] as String? ?? '',
  );
}

class Territory {
  const Territory({required this.districts, required this.mahallas});
  final List<Ref> districts;
  final List<MahallaRef> mahallas;

  factory Territory.fromJson(Map<String, dynamic> j) => Territory(
    districts: (j['districts'] as List<dynamic>? ?? [])
        .map((e) => Ref.fromJson(e as Map<String, dynamic>))
        .toList(),
    mahallas: (j['mahallas'] as List<dynamic>? ?? [])
        .map((e) => MahallaRef.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class CitizenStats {
  const CitizenStats({
    required this.total,
    required this.open,
    required this.resolved,
  });
  final int total;
  final int open;
  final int resolved;

  factory CitizenStats.fromJson(Map<String, dynamic>? j) => CitizenStats(
    total: _int(j?['total']),
    open: _int(j?['open']),
    resolved: _int(j?['resolved']),
  );
}

class CitizenProfile {
  const CitizenProfile({
    required this.id,
    required this.firstName,
    this.lastName,
    this.username,
    this.email,
    this.phone,
    this.photoUrl,
    this.districtId,
    this.districtName,
    this.mahallaId,
    this.mahallaName,
    required this.points,
    this.createdAt,
    required this.stats,
    this.requirePhone = true,
    this.phoneNeeded = false,
  });

  final String id;
  final String firstName;
  final String? lastName;
  final String? username;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String? districtId;
  final String? districtName;
  final String? mahallaId;
  final String? mahallaName;
  final int points;
  final String? createdAt;
  final CitizenStats stats;

  /// ── TELEFON MAJBURIYMI ───────────────────────────────
  ///
  /// ⚠️ QIYMAT SERVERDAN KELADI (`Settings.requirePhone`), ilovada
  /// QOTIB QOLMAYDI: sozlama panelda o'zgarsa, do'kondagi ilovani
  /// yangilash kerak bo'lmasligi kerak — va eski versiyalar
  /// do'konda uzoq turadi.
  ///
  /// ⚠️ STANDART `true`: maydon javobda bo'lmasa (eski server),
  /// talab O'CHIB qolmasligi kerak.
  final bool requirePhone;

  /// ⚠️ Tayyor javob: "hozir, shu fuqarodan raqam so'rash
  /// kerakmi". Ilovada hisoblanmaydi — server aytadi.
  final bool phoneNeeded;

  /// ⚠️ TUMAN VA MFY IKKALASI HAM KERAK — murojaat aniq MFY ga
  /// yo'nalishi uchun. Bittasi bo'lsa onboarding yopilmaydi.
  bool get hasTerritory => districtId != null && mahallaId != null;

  /// ⚠️ ONBOARDING SHARTI: hudud VA telefon. Ikkisi bitta
  /// ekranda so'raladi — ketma-ket ikki to'siq qo'yish fuqaroni
  /// ilovadan qaytarardi.
  bool get needsOnboarding => !hasTerritory || phoneNeeded;

  String get fullName => lastName == null ? firstName : '$firstName $lastName';

  factory CitizenProfile.fromJson(Map<String, dynamic> j) => CitizenProfile(
    id: j['id'] as String,
    firstName: j['firstName'] as String? ?? 'Fuqaro',
    lastName: _str(j['lastName']),
    username: _str(j['username']),
    email: _str(j['email']),
    phone: _str(j['phone']),
    photoUrl: _str(j['photoUrl']),
    districtId: _str(j['districtId']),
    districtName: _str(j['districtName']),
    mahallaId: _str(j['mahallaId']),
    mahallaName: _str(j['mahallaName']),
    points: _int(j['points']),
    createdAt: _str(j['createdAt']),
    stats: CitizenStats.fromJson(j['stats'] as Map<String, dynamic>?),
    // ⚠️ MAYDON YO'Q BO'LSA `true`: eski server bilan ishlaganda
    // talab jimgina o'chib qolmasligi kerak.
    requirePhone: j['requirePhone'] == null || j['requirePhone'] == true,
    phoneNeeded: _bool(j['phoneNeeded']),
  );
}

class Category {
  const Category({
    required this.id,
    required this.name,
    this.color,
    this.description,
    this.icon,
    required this.slaHours,
    this.orgName,
    this.parentId,
    this.hasChildren = false,
    this.selectable = true,
  });

  final String id;
  final String name;
  final String? color;
  final String? description;
  final String? icon;
  final int slaHours;
  final String? orgName;

  /// ── IKKI DARAJALI RO'YXAT ────────────────────────────────────────
  ///
  /// ⚠️ `parentId` — ASOSIY yo'nalish id'si (`null` — o'zi asosiy).
  /// Daraxt serverda qurilmaydi: mijozlar uni turlicha ko'rsatadi
  /// (bot — ikki qadamli tugma, ilova — guruhlangan to'r).
  final String? parentId;

  /// ⚠️ Ichida kichik yo'nalishlari bor — SARLAVHA, tanlov emas.
  final bool hasChildren;

  /// ⚠️ `false` — YAKUNIY TANLOV BO'LA OLMAYDI (server rad etadi).
  ///
  /// ⚠️ STANDART `true`: maydon javobda bo'lmasa (eski server),
  /// ro'yxat bo'shab qolmasligi kerak — do'kondagi ilova eski
  /// server bilan ham ishlashi mumkin.
  final bool selectable;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    color: _str(j['color']),
    description: _str(j['description']),
    icon: _str(j['icon']),
    slaHours: _int(j['slaHours']),
    orgName: _str(j['orgName']),
    parentId: _str(j['parentId']),
    hasChildren: _bool(j['hasChildren']),
    selectable: j['selectable'] == null || j['selectable'] == true,
  );
}

class HomeStats {
  const HomeStats({
    required this.total,
    required this.resolved,
    required this.last30,
  });
  final int total;
  final int resolved;
  final int last30;

  factory HomeStats.fromJson(Map<String, dynamic> j) => HomeStats(
    total: _int(j['total']),
    resolved: _int(j['resolved']),
    last30: _int(j['last30']),
  );
}

class TimelineStep {
  const TimelineStep({
    required this.key,
    required this.label,
    required this.done,
  });
  final String key;
  final String label;
  final bool done;

  factory TimelineStep.fromJson(Map<String, dynamic> j) => TimelineStep(
    key: j['key'] as String? ?? '',
    label: j['label'] as String? ?? '',
    done: _bool(j['done']),
  );
}

class CategoryBrief {
  const CategoryBrief({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    this.orgName,
  });
  final String id;
  final String name;
  final String? color;
  final String? icon;
  final String? orgName;

  factory CategoryBrief.fromJson(Map<String, dynamic>? j) => CategoryBrief(
    id: j?['id'] as String? ?? '',
    name: j?['name'] as String? ?? '',
    color: _str(j?['color']),
    icon: _str(j?['icon']),
    orgName: _str(j?['orgName']),
  );
}

class AppealListItem {
  const AppealListItem({
    required this.id,
    required this.publicNo,
    required this.title,
    required this.status,
    this.address,
    required this.createdAt,
    this.resolvedAt,
    this.dueAt,
    required this.category,
    required this.photos,
    required this.commentCount,
    required this.timeline,
  });

  final String id;
  final String publicNo;
  final String title;
  final String status;
  final String? address;
  final String createdAt;
  final String? resolvedAt;
  final String? dueAt;
  final CategoryBrief category;
  final List<String> photos;
  final int commentCount;
  final List<TimelineStep> timeline;

  factory AppealListItem.fromJson(Map<String, dynamic> j) => AppealListItem(
    id: j['id'] as String,
    publicNo: j['publicNo'] as String? ?? '',
    title: j['title'] as String? ?? '',
    status: j['status'] as String? ?? 'new',
    address: _str(j['address']),
    createdAt: j['createdAt'] as String? ?? '',
    resolvedAt: _str(j['resolvedAt']),
    dueAt: _str(j['dueAt']),
    category: CategoryBrief.fromJson(j['category'] as Map<String, dynamic>?),
    photos: (j['photos'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
    commentCount: _int(j['commentCount']),
    timeline: (j['timeline'] as List<dynamic>? ?? [])
        .map((e) => TimelineStep.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class AppealListResponse {
  const AppealListResponse({
    required this.items,
    required this.total,
    required this.hasMore,
    required this.counts,
  });
  final List<AppealListItem> items;
  final int total;
  final bool hasMore;
  final Map<String, int> counts;

  factory AppealListResponse.fromJson(Map<String, dynamic> j) =>
      AppealListResponse(
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => AppealListItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: _int(j['total']),
        hasMore: _bool(j['hasMore']),
        counts: ((j['counts'] as Map<String, dynamic>?) ?? {}).map(
          (k, v) => MapEntry(k, _int(v)),
        ),
      );
}

class AppealComment {
  const AppealComment({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.mine,
    required this.author,
  });
  final String id;
  final String body;
  final String createdAt;
  final bool mine;
  final String author;

  factory AppealComment.fromJson(Map<String, dynamic> j) => AppealComment(
    id: j['id'] as String,
    body: j['body'] as String? ?? '',
    createdAt: j['createdAt'] as String? ?? '',
    mine: _bool(j['mine']),
    author: j['author'] as String? ?? '',
  );
}

class Attachment {
  const Attachment({
    required this.id,
    required this.kind,
    required this.url,
    required this.mimeType,
  });
  final String id;
  final String kind;
  final String url;
  final String mimeType;

  factory Attachment.fromJson(Map<String, dynamic> j) => Attachment(
    id: j['id'] as String,
    kind: j['kind'] as String? ?? 'photo',
    url: j['url'] as String? ?? '',
    mimeType: j['mimeType'] as String? ?? '',
  );
}

class AppealDetail {
  const AppealDetail({
    required this.id,
    required this.publicNo,
    required this.title,
    required this.body,
    required this.status,
    this.address,
    this.lat,
    this.lng,
    required this.isHazard,
    required this.isLongStanding,
    required this.isRepeatAppeal,
    required this.createdAt,
    this.dueAt,
    this.resolvedAt,
    this.resolution,
    required this.category,
    this.mahallaName,
    this.districtName,
    required this.attachments,
    required this.comments,
    required this.timeline,
  });

  final String id;
  final String publicNo;
  final String title;
  final String body;
  final String status;
  final String? address;
  final double? lat;
  final double? lng;
  final bool isHazard;
  final bool isLongStanding;
  final bool isRepeatAppeal;
  final String createdAt;
  final String? dueAt;
  final String? resolvedAt;
  final String? resolution;
  final CategoryBrief category;
  final String? mahallaName;
  final String? districtName;
  final List<Attachment> attachments;
  final List<AppealComment> comments;
  final List<TimelineStep> timeline;

  factory AppealDetail.fromJson(Map<String, dynamic> j) => AppealDetail(
    id: j['id'] as String,
    publicNo: j['publicNo'] as String? ?? '',
    title: j['title'] as String? ?? '',
    body: j['body'] as String? ?? '',
    status: j['status'] as String? ?? 'new',
    address: _str(j['address']),
    lat: _dbl(j['lat']),
    lng: _dbl(j['lng']),
    isHazard: _bool(j['isHazard']),
    isLongStanding: _bool(j['isLongStanding']),
    isRepeatAppeal: _bool(j['isRepeatAppeal']),
    createdAt: j['createdAt'] as String? ?? '',
    dueAt: _str(j['dueAt']),
    resolvedAt: _str(j['resolvedAt']),
    resolution: _str(j['resolution']),
    category: CategoryBrief.fromJson(j['category'] as Map<String, dynamic>?),
    mahallaName: _str(j['mahallaName']),
    districtName: _str(j['districtName']),
    attachments: (j['attachments'] as List<dynamic>? ?? [])
        .map((e) => Attachment.fromJson(e as Map<String, dynamic>))
        .toList(),
    comments: (j['comments'] as List<dynamic>? ?? [])
        .map((e) => AppealComment.fromJson(e as Map<String, dynamic>))
        .toList(),
    timeline: (j['timeline'] as List<dynamic>? ?? [])
        .map((e) => TimelineStep.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class CreatedAppeal {
  const CreatedAppeal({
    required this.id,
    required this.publicNo,
    this.dueAt,
    required this.categoryName,
    this.orgName,
    required this.slaHours,
  });
  final String id;
  final String publicNo;
  final String? dueAt;
  final String categoryName;
  final String? orgName;
  final int slaHours;

  factory CreatedAppeal.fromJson(Map<String, dynamic> j) => CreatedAppeal(
    id: j['id'] as String,
    publicNo: j['publicNo'] as String? ?? '',
    dueAt: _str(j['dueAt']),
    categoryName: j['categoryName'] as String? ?? '',
    orgName: _str(j['orgName']),
    slaHours: _int(j['slaHours']),
  );
}

class UploadedFile {
  const UploadedFile({
    required this.token,
    required this.kind,
    required this.url,
    required this.size,
  });

  /// ⚠️ IMZOLANGAN HAVOLA — murojaat yaratishda SHU qaytariladi,
  /// `url` emas: mijoz aytgan yo'lga ishonilsa, boshqa fuqaroning
  /// fayli biriktirib yuborilishi mumkin bo'lardi.
  final String token;
  final String kind;
  final String url;
  final int size;

  factory UploadedFile.fromJson(Map<String, dynamic> j) => UploadedFile(
    token: j['token'] as String? ?? '',
    kind: j['kind'] as String? ?? 'photo',
    url: j['url'] as String? ?? '',
    size: _int(j['size']),
  );
}

class AiSuggestion {
  const AiSuggestion({
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    required this.confidence,
    required this.priority,
    required this.slaHours,
    this.orgName,
    this.parentName,
    this.urgencyLabel,
  });

  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final double confidence;
  final String priority;
  final int slaHours;
  final String? orgName;

  /// ⚠️ ASOSIY YO'NALISH NOMI — "Kommunal xizmatlar → Ichimlik suvi".
  /// Yakka "Ichimlik suvi" degan taklif kontekstsiz qolardi.
  final String? parentName;

  /// ⚠️ AI MATNDAN CHIQARGAN SHOSHILINCHLIK BAHOSI — KO'RSATILADI,
  /// LEKIN MUDDATNI BELGILAMAYDI: muddat yo'nalish SLA'si yoki MFY
  /// qoidasidan chiqadi va tavsifni panelda XODIM qo'llaydi.
  final String? urgencyLabel;

  /// Ko'rsatish uchun to'liq nom.
  String get fullName =>
      parentName == null ? categoryName : '$parentName → $categoryName';

  factory AiSuggestion.fromJson(Map<String, dynamic> j) => AiSuggestion(
    categoryId: j['categoryId'] as String? ?? '',
    categoryName: j['categoryName'] as String? ?? '',
    categoryIcon: _str(j['categoryIcon']),
    confidence: _dbl(j['confidence']) ?? 0,
    priority: j['priority'] as String? ?? 'normal',
    slaHours: _int(j['slaHours']),
    orgName: _str(j['orgName']),
    parentName: _str(j['parentName']),
    urgencyLabel: _str(j['urgencyLabel']),
  );
}

class AnalysisResponse {
  const AnalysisResponse({this.suggestion, this.token});
  final AiSuggestion? suggestion;

  /// ⚠️ SERVER IMZOSI — `POST /mobile/appeals` ga SHUNDAYLIGICHA
  /// uzatiladi. Qiymatni mijoz yozsa, panelda "AI 94% ishonch bilan
  /// shuni aytgan" degan soxta dalil paydo bo'lardi.
  final String? token;

  factory AnalysisResponse.fromJson(Map<String, dynamic> j) => AnalysisResponse(
    suggestion: j['suggestion'] == null
        ? null
        : AiSuggestion.fromJson(j['suggestion'] as Map<String, dynamic>),
    token: _str(j['token']),
  );
}

class MapPoint {
  const MapPoint({
    required this.id,
    this.lat,
    this.lng,
    required this.status,
    required this.category,
  });
  final String id;
  final double? lat;
  final double? lng;
  final String status;
  final CategoryBrief category;

  factory MapPoint.fromJson(Map<String, dynamic> j) => MapPoint(
    id: j['id'] as String,
    lat: _dbl(j['lat']),
    lng: _dbl(j['lng']),
    status: j['status'] as String? ?? 'new',
    category: CategoryBrief.fromJson(j['category'] as Map<String, dynamic>?),
  );
}

/// E'LONGA QO'SHILGAN FAYL.
///
/// ⚠️ `Attachment` QAYTA ISHLATILMADI: unda `id` MAJBURIY
/// (`j['id'] as String`) va fuqaroga beriladigan e'lon javobida
/// u YO'Q — ya'ni `Attachment.fromJson` tip xatosi bilan
/// yiqilardi. Dalil fayllarida `id` kerak (izohda havola
/// qilinadi), e'lon suratida esa kerak emas.
///
/// ⚠️ `coverUrl` NING O'RNINI BOSMAYDI: muqova — ro'yxatdagi
/// BITTA surat, media esa e'lon ICHIDAGI galereya.
class NewsMedia {
  const NewsMedia({required this.kind, required this.url, required this.mimeType});

  final String kind;
  final String url;
  final String mimeType;

  factory NewsMedia.fromJson(Map<String, dynamic> j) => NewsMedia(
    kind: j['kind'] as String? ?? 'photo',
    url: j['url'] as String? ?? '',
    mimeType: j['mimeType'] as String? ?? '',
  );
}

class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.body,
    this.coverUrl,
    required this.isPinned,
    this.publishedAt,
    required this.viewCount,
    this.districtName,
    this.media = const [],
  });

  final String id;
  final String title;
  final String body;
  final String? coverUrl;
  final bool isPinned;
  final String? publishedAt;
  final int viewCount;
  final String? districtName;

  /// ⚠️ STANDART — BO'SH RO'YXAT, `null` EMAS: do'kondagi eski
  /// ilova yangi server bilan ishlaganda maydon kelmasligi
  /// mumkin va `null` tekshiruvi har joyda takrorlanardi.
  final List<NewsMedia> media;

  factory NewsItem.fromJson(Map<String, dynamic> j) => NewsItem(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    body: j['body'] as String? ?? '',
    coverUrl: _str(j['coverUrl']),
    isPinned: _bool(j['isPinned']),
    publishedAt: _str(j['publishedAt']),
    viewCount: _int(j['viewCount']),
    districtName: _str(j['districtName']),
    // ⚠️ MAYDON KELMASA BO'SH RO'YXAT: eski e'lonlarda u yo'q
    // va `as List` to'g'ridan-to'g'ri yozilsa, ilova ochilishida
    // yiqilardi.
    media: (j['media'] as List<dynamic>? ?? [])
        .map((e) => NewsMedia.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class RatingRow {
  const RatingRow({
    required this.rank,
    required this.id,
    required this.name,
    this.photoUrl,
    required this.points,
    required this.appeals,
    this.districtName,
  });

  final int rank;
  final String id;
  final String name;
  final String? photoUrl;
  final int points;
  final int appeals;
  final String? districtName;

  factory RatingRow.fromJson(Map<String, dynamic> j) => RatingRow(
    rank: _int(j['rank']),
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    photoUrl: _str(j['photoUrl']),
    points: _int(j['points']),
    appeals: _int(j['appeals']),
    districtName: _str(j['districtName']),
  );
}
