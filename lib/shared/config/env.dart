/// MUHIT SOZLAMALARI — BITTA JOYDA.
///
/// ⚠️ QIYMATLAR `--dart-define` ORQALI BERILADI, koddan
/// o'zgartirilmaydi: ishlab chiqish (emulyator) va ishlab chiqarish
/// uchun ikki xil manzil kerak va uni har safar faylda tuzatish
/// "localhost bilan qurilgan ilova do'konga ketdi" degan xato
/// bilan tugardi.
///
/// Misol:
///   flutter run --dart-define=API_URL=http://10.0.2.2:4000/api
library;

class Env {
  const Env._();

  /// Backend manzili (`/api` bilan birga).
  ///
  /// ⚠️ EMULYATORDA `localhost` ISHLAMAYDI: u emulyatorning O'ZINI
  /// bildiradi. Kompyuterdagi server — `10.0.2.2`.
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://nazoratchi-ai-api.mysrv.uz/api',
  );

  /// Fayl manzillari uchun asos (`/uploads/...` nisbiy keladi).
  ///
  /// ⚠️ `apiUrl` DAN HOSIL QILINADI: alohida sozlama bo'lsa, biri
  /// o'zgartirilib ikkinchisi unutilardi va suratlar jimgina
  /// ko'rinmay qolardi.
  static String get filesBase {
    final value = apiUrl.endsWith('/api')
        ? apiUrl.substring(0, apiUrl.length - 4)
        : apiUrl;
    return value;
  }

  /// GOOGLE — WEB turidagi mijoz id'si (`serverClientId`).
  ///
  /// ⚠️ ANDROID MIJOZ ID'SI EMAS. `google_sign_in` ga `serverClientId`
  /// sifatida aynan WEB id beriladi va `id_token` ning `aud` maydoni
  /// SHU qiymatga teng bo'ladi — server ham shuni kutadi
  /// (`GOOGLE_CLIENT_ID`). Android id yozilsa, imzo to'g'ri bo'lsa
  /// ham server `aud` mos kelmagani uchun rad etardi.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// ⚠️ FAQAT ISHLAB CHIQISH: Google sozlanmaguncha ilovani to'liq
  /// sinash uchun. Server `NODE_ENV=production` da bu yo'lni O'ZI
  /// rad etadi (`/mobile/auth/dev`), ya'ni yoqib qo'yilsa ham
  /// ishlab chiqarishda ishlamaydi.
  static const bool devLoginEnabled = bool.fromEnvironment(
    'DEV_LOGIN',
    defaultValue: false,
  );

  static const String devTelegramId = String.fromEnvironment(
    'DEV_TELEGRAM_ID',
    defaultValue: '900000001',
  );
}
