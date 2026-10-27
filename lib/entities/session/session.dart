/// SESSIYA — "KIM KIRDI".
///
/// ── NIMA UCHUN GOOGLE ──────────────────────────────────────────────
///
/// ⚠️ BU MINI-ILOVA EMAS. Mini-ilova (`mini-app/`) Telegram ichida
/// ochiladi va u yerda `initData` BOR — kirish avtomatik, ekran ham
/// ko'rinmaydi. Bu esa do'kondan o'rnatiladigan mustaqil ilova:
/// `initData` YO'Q va fuqaro o'zini tanishtirishi kerak.
///
/// ⚠️ TELEGRAM LOGIN OLIB TASHLANDI. U brauzer → HTTPS qaytish
/// sahifasi → `vshtabi://` deep link → ilova degan to'rt bo'g'inli
/// oqim edi va har bo'g'in jimgina uzilardi. Google esa tizim
/// darajasida: hisob qurilmada allaqachon bor va natija
/// to'g'ridan-to'g'ri ilovaga qaytadi.
///
/// ⚠️ BITTA KIRISH YO'LI — ATAYLAB. Ikkinchi yo'l (telefon, parol)
/// qo'shilsa, bitta odam ikki hisob ochib, murojaatlari ikkiga
/// bo'linib ketardi.
library;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../shared/api/client.dart';
import '../../shared/api/models.dart';
import '../../shared/config/env.dart';

enum SessionStatus {
  /// Ilova endi ochildi — token bor-yo'qligi tekshirilmoqda.
  loading,

  /// Kirish ekrani ko'rsatiladi.
  signedOut,

  /// Hudud tanlanmagan — onboarding.
  needsTerritory,

  /// Hammasi joyida.
  ready,
}

class SessionController extends ChangeNotifier {
  SessionController._();

  /// ⚠️ YAGONA NUSXA: ikkita bo'lsa, biri kirgan, ikkinchisi
  /// chiqqan holatda qolib, ekranlar bir-biriga zid ma'lumot
  /// ko'rsatardi.
  static final SessionController instance = SessionController._();

  SessionStatus status = SessionStatus.loading;
  CitizenProfile? profile;

  /// Kirish paytidagi xato — kirish ekranida ko'rsatiladi.
  String? authError;

  bool _googleReady = false;
  bool busy = false;

  /// ⚠️ GOOGLE BIR MARTA TAYYORLANADI: `initialize()` ni har
  /// bosishda chaqirish Android'da ogohlantirish beradi va ortiqcha
  /// ish qiladi.
  Future<void> _ensureGoogle() async {
    if (_googleReady) return;

    await GoogleSignIn.instance.initialize(
      // ⚠️ WEB mijoz id'si (`serverClientId`), Android niki EMAS —
      // `env.dart` dagi izohga qarang.
      serverClientId: Env.googleServerClientId.isEmpty
          ? null
          : Env.googleServerClientId,
    );
    _googleReady = true;
  }

  /// ILOVA OCHILGANDA: token bo'lsa — profilni oladi.
  Future<void> bootstrap() async {
    final token = await TokenStore.read();
    if (token == null) {
      _set(SessionStatus.signedOut);
      return;
    }

    try {
      await refresh();
    } on ApiException catch (error) {
      // ⚠️ 401/403 DA TOKEN TOZALANADI: eskirgan token bilan har
      // ekran xato ko'rsatib, fuqaroda chiqish yo'li qolmasdi.
      if (error.isUnauthorized || error.statusCode == 403) {
        await TokenStore.clear();
        authError = error.statusCode == 403 ? error.message : null;
        _set(SessionStatus.signedOut);
      } else {
        // Tarmoq xatosi — token saqlanadi, fuqaro qayta urinadi.
        authError = error.message;
        _set(SessionStatus.signedOut);
      }
    }
  }

  /// PROFILNI SERVERDAN QAYTA O'QIYDI.
  Future<void> refresh() async {
    final data = await ApiClient.get('/mobile/me') as Map<String, dynamic>;
    profile = CitizenProfile.fromJson(data);
    _set(
      profile!.hasTerritory
          ? SessionStatus.ready
          : SessionStatus.needsTerritory,
    );
  }

  /// GOOGLE BILAN KIRISH.
  Future<void> signInWithGoogle() async {
    if (busy) return;
    busy = true;
    authError = null;
    notifyListeners();

    try {
      await _ensureGoogle();

      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;

      /// ⚠️ `idToken` BO'SH BO'LISHI MUMKIN: `serverClientId`
      /// berilmagan yoki Google konsolida mijoz noto'g'ri
      /// sozlangan bo'lsa, Google hisobni qaytaradi, lekin TOKEN
      /// bermaydi. Bu eng chalg'ituvchi holat — "kirdim, lekin
      /// kirmadim" — shuning uchun sabab aniq aytiladi.
      if (idToken == null || idToken.isEmpty) {
        throw ApiException(
          0,
          'Google tokeni olinmadi. Ilova sozlamasi to\'liq emas '
          '(serverClientId).',
        );
      }

      final data =
          await ApiClient.post('/mobile/auth/google', {'idToken': idToken})
              as Map<String, dynamic>;

      await TokenStore.write(data['token'] as String);
      await refresh();
    } on GoogleSignInException catch (error) {
      // ⚠️ BEKOR QILISH XATO EMAS: fuqaro oynani yopgan bo'lsa,
      // qizil xato ko'rsatish uni qo'rqitardi.
      if (error.code != GoogleSignInExceptionCode.canceled) {
        authError = 'Google hisobiga kirib bo\'lmadi: ${error.code.name}';
      }
    } on ApiException catch (error) {
      authError = error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// ⚠️ FAQAT ISHLAB CHIQISH. Server `production` da bu yo'lni O'ZI
  /// rad etadi — ya'ni yoqib qo'yilgan ilova ham ishlab chiqarishda
  /// kira olmaydi.
  Future<void> signInDev() async {
    if (busy || !Env.devLoginEnabled) return;
    busy = true;
    authError = null;
    notifyListeners();

    try {
      final data =
          await ApiClient.post('/mobile/auth/dev', {
                'telegramId': Env.devTelegramId,
                'firstName': 'Sinov',
              })
              as Map<String, dynamic>;

      await TokenStore.write(data['token'] as String);
      await refresh();
    } on ApiException catch (error) {
      authError = error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// CHIQISH.
  ///
  /// ⚠️ GOOGLE'DAN HAM CHIQILADI: faqat token o'chirilsa, keyingi
  /// "Kirish" bosilganda Google hisob tanlashni so'ramay, AYNI
  /// hisobga qaytadi — boshqa hisob bilan kirmoqchi bo'lgan odam
  /// buni "ilova sinmagan" deb tushunmasdi.
  Future<void> signOut() async {
    await TokenStore.clear();
    try {
      if (_googleReady) await GoogleSignIn.instance.signOut();
    } on Exception {
      // Jim: chiqish baribir amalga oshdi (token yo'q).
    }
    profile = null;
    authError = null;
    _set(SessionStatus.signedOut);
  }

  void _set(SessionStatus value) {
    status = value;
    notifyListeners();
  }
}
