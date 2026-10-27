plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "uz.mysrv.viloyat_shtabi"
    compileSdk = flutter.compileSdkVersion

    // ⚠️ NDK QO'LDA O'RNATILGAN BO'LISHI SHART (r28c =
    // 28.2.13676358), `Sdk/ndk/<versiya>/` ichiga. Sababi uzoqda:
    // `path_provider_android` → `jni` paketi native kod bilan
    // keladi va NDK'siz qurish UMUMAN boshlanmaydi.
    //
    // ⚠️ Bu mashinadagi `cmdline-tools` da `sdkmanager` YO'Q (uni
    // yangi `android` CLI almashtirgan) va u `ndk` paketini topa
    // olmaydi — xato esa "Android sdkmanager did not install NDK"
    // deb chiqib, nima qilish kerakligini aytmaydi. Yechim: NDK
    // zip'ini `dl.google.com/android/repository/` dan olib,
    // papkani versiya nomi bilan qo'yish.
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // ⚠️ DO'KONDAGI YAGONA NOM. Bir marta chiqarilgandan keyin
        // O'ZGARTIRIB BO'LMAYDI: Play uni BOSHQA ilova deb qabul
        // qiladi va mavjud foydalanuvchilar yangilanish olmasdi.
        //
        // ⚠️ `uz.mysrv.viloyat_shtabi` EMAS: avvalgi (Capacitor)
        // ilova aynan shu nom bilan qurilgan edi va mahsulot o'sha —
        // nom o'zgarsa, sinovdagi qurilmalarda ikki ilova yonma-yon
        // turib, qaysi biri yangi ekani bilinmasdi.
        applicationId = "uz.mysrv.nazoratchi"
        // ⚠️ minSdk 23: `flutter_secure_storage` v11 AES-GCM uchun
        // Android 6.0 ni talab qiladi. Standart (flutter.minSdkVersion)
        // past bo'lsa, qurilish shu paketda uzilardi.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
