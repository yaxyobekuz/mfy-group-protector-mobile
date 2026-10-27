# Viloyat shtabi — mobil ilova (Flutter)

Fuqaro murojaatlari uchun **do'kon ilovasi** (Android / iOS).
Kirish — **faqat Google**.

> ⚠️ Bu `mini-app/` ning nusxasi emas, **ikkinchi eshigi**. Mini-ilova
> Telegram ichida ishlaydi va u yerda kirish avtomatik (`initData`).
> Ekranlar va server **ayni** — farq faqat kirishda. Ildizdagi
> `CLAUDE.md` dagi "Ikki ilova — ikki kirish yo'li" bo'limiga qarang.

---

## Nima kerak

| | Versiya | Qayerda |
|---|---|---|
| Flutter | 3.47+ | `C:\Users\i7\dev\flutter` |
| JDK | **21** | `C:\Users\i7\dev\jdk\jdk-21.0.12.1+1` |
| Android SDK | API 36 | `%LOCALAPPDATA%\Android\Sdk` |
| NDK | **28.2.13676358** | `…\Sdk\ndk\28.2.13676358` |

⚠️ **JDK 25 ISHLAMAYDI.** Tizimdagi yagona JDK — Android Studio'niki
(25) va Gradle uni tushunmaydi (`Unsupported class file major version
69`). Shuning uchun Flutter'ga alohida JDK 21 ko'rsatilgan:

```bash
flutter config --jdk-dir "C:\Users\i7\dev\jdk\jdk-21.0.12.1+1"
```

⚠️ **NDK QO'LDA O'RNATILADI.** `path_provider_android` → `jni` paketi
native kod bilan keladi. Bu mashinadagi `cmdline-tools` da
`sdkmanager` **yo'q** (yangi `android` CLI uni almashtirgan) va u `ndk`
paketini topa olmaydi — xato "Android sdkmanager did not install NDK"
deb chiqadi, nima qilish kerakligini aytmaydi. Yechim:

```
dl.google.com/android/repository/android-ndk-r28c-windows.zip
→ %LOCALAPPDATA%\Android\Sdk\ndk\28.2.13676358\
```

---

## Google kirishini sozlash

⚠️ **Busiz kirish ishlamaydi.** `GOOGLE_CLIENT_ID` bo'lmasa server
endpoint'i `503` beradi va ilovada "Google orqali kirish hozircha
sozlanmagan" chiqadi (`401` emas — fuqaro aybni o'zidan qidirmasligi
uchun).

Google Cloud Console → **APIs & Services → Credentials**:

**1. OAuth consent screen** — External, ilova nomi "Viloyat shtabi".

**2. Android mijozi** (qurilmada kirish oynasi ochilishi uchun):

| Maydon | Qiymat |
|---|---|
| Package name | `uz.mysrv.nazoratchi` |
| SHA-1 (debug) | `56:84:EB:12:17:0E:46:4E:C7:A4:C6:FC:F9:F2:97:3B:A4:79:B5:32` |

⚠️ Release imzosi uchun **alohida** SHA-1 qo'shiladi, aks holda
do'kondan o'rnatilgan ilovada kirish ishlamaydi:

```bash
keytool -list -v -keystore <release.jks> -alias <alias>
```

**3. Web mijozi** — `id_token` ning `aud` i uchun. Hech qayerga
yo'naltirish kerak emas, faqat id olinadi.

⚠️ **ANDROID ID EMAS, WEB ID.** `serverClientId` ga Android id
yozilsa, Google hisobni qaytaradi, lekin `id_token` **bermaydi** —
eng chalg'ituvchi holat ("kirdim, lekin kirmadim"). Ilova buni
alohida aytadi.

Olingan qiymatlar:

```bash
# server/.env
GOOGLE_CLIENT_ID="<web mijoz id>"

# ilovani qurishda
--dart-define=GOOGLE_SERVER_CLIENT_ID=<web mijoz id>
```

---

## Ishga tushirish

**Emulyatorda, kompyuterdagi server bilan:**

```bash
flutter run --dart-define=API_URL=http://10.0.2.2:4000/api --dart-define=DEV_LOGIN=true
```

⚠️ `localhost` emas, **`10.0.2.2`** — emulyator host'ga shu manzil
orqali chiqadi.

⚠️ `DEV_LOGIN=true` — Google sozlanmaguncha ilovani to'liq sinash
uchun kirish tugmasi. Server `NODE_ENV=production` da bu yo'lni
**o'zi rad etadi**, ya'ni yoqib qo'yilgan ilova ham ishlab
chiqarishda kira olmaydi.

⚠️ Ochiq HTTP faqat **debug** qurilishida ruxsat etilgan
(`src/debug/AndroidManifest.xml`). Release'da ilova faqat HTTPS
bilan ishlaydi — aks holda tasodifan HTTP manzilga yozilgan so'rov
do'kondagi ilovada ham jimgina ketardi.

**Ishlab chiqarish uchun:**

```bash
flutter build apk --release \
  --dart-define=API_URL=https://nazoratchi-ai-api.mysrv.uz/api \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web mijoz id>
```

---

## Tuzilma

```
lib/
  main.dart                    ilova + mavzu
  entities/session/            kirish: Google, onboarding, darvoza
  screens/                     ekranlar (bosh, murojaat, xarita, …)
  shared/
    api/      client.dart      HTTP + token (yagona nuqta)
              models.dart      server javoblari
    config/   env.dart         --dart-define sozlamalari
              labels.dart      yorliq/belgi — yagona manba
              theme.dart       ranglar (mini-ilovadan ko'chirilgan)
    util/     date_uz.dart     SANA FORMATI — yagona manba
    ui/       widgets.dart     takrorlanadigan ko'rinishlar
```

⚠️ **`shared/lib/` nomi ishlatilmaydi** (`shared/util/`): Dart
analizatori `lib/` ichidagi nisbiy importni `avoid_relative_lib_imports`
bilan rad etadi va butun loyiha ogohlantirishga to'ladi.

⚠️ **Sana matni faqat `date_uz.dart` da yig'iladi.** `intl` paketi va
`toLocal()` **taqiqlangan** — ular qurilma zonasiga bog'liq va panel
bilan ilova bir xil murojaatni boshqa vaqtda ko'rsatardi. Sabab
ildizdagi `CLAUDE.md` da.
