/// SERVER BILAN ALOQA — YAGONA NUQTA.
///
/// ⚠️ `http.get/post` TO'G'RIDAN-TO'G'RI CHAQIRILMAYDI (bu fayldan
/// boshqa joyda): token qo'shish, xatoni o'zbekcha matnga aylantirish
/// va 401 da chiqib ketish har chaqiruvda takrorlanardi — bittasida
/// albatta unutilardi.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';

/// SERVER QAYTARGAN XATO.
///
/// ⚠️ MATN SERVERDAN OLINADI: u o'zbekcha va aniq sabab aytadi
/// ("Hisobingiz vaqtincha cheklangan"). Mijozda yozilgan umumiy
/// "Xatolik yuz berdi" fuqaroga nima qilishni aytmasdi.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// TOKEN SAQLAGICH.
///
/// ⚠️ `SharedPreferences` EMAS, SHIFRLANGAN SAQLAGICH: token 30 kun
/// yashaydi va u bilan fuqaro nomidan murojaat yuborish mumkin.
/// Oddiy `SharedPreferences` fayli root'langan qurilmada ochiq
/// o'qilardi.
class TokenStore {
  const TokenStore._();

  static const _key = 'vsh.mobile.token';

  /// ⚠️ `resetOnError` STANDART HOLDA YONIQ (v11): qurilma kaliti
  /// yo'qolganda (zaxiradan tiklash, Android yangilanishi) saqlagich
  /// o'zini tozalaydi. Usiz ilova har ochilishda shifrlash xatosi
  /// bilan yiqilib, fuqaroda chiqish yo'li qolmasdi — qayta kirish
  /// esa aynan shu tozalashni talab qilardi.
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());

  /// ⚠️ XOTIRADA HAM SAQLANADI: har so'rovda diskdan o'qish
  /// (shifrlash bilan) ro'yxat sahifasida sezilarli kechikish
  /// berardi.
  static String? _cached;

  static Future<String?> read() async {
    if (_cached != null) return _cached;
    try {
      _cached = await _storage.read(key: _key);
    } on Exception {
      // Saqlagich ochilmadi — kirmagan deb hisoblanadi.
      _cached = null;
    }
    return _cached;
  }

  static Future<void> write(String token) async {
    _cached = token;
    try {
      await _storage.write(key: _key, value: token);
    } on Exception {
      // Jim: xotiradagi nusxa bilan sessiya baribir ishlaydi.
    }
  }

  static Future<void> clear() async {
    _cached = null;
    try {
      await _storage.delete(key: _key);
    } on Exception {
      // Jim.
    }
  }
}

class ApiClient {
  const ApiClient._();

  static const Duration _timeout = Duration(seconds: 30);

  static Uri _uri(String path, [Map<String, String>? query]) {
    final clean = path.startsWith('/') ? path : '/$path';
    final base = Uri.parse('${Env.apiUrl}$clean');
    if (query == null || query.isEmpty) return base;

    // ⚠️ BO'SH QIYMATLAR TASHLANADI: `?status=` serverdagi
    // `ValidationPipe` uchun bo'sh satr bo'lib, filtr "hech narsa"
    // ga aylanardi.
    final filtered = <String, String>{};
    query.forEach((k, v) {
      if (v.isNotEmpty) filtered[k] = v;
    });
    return base.replace(queryParameters: filtered.isEmpty ? null : filtered);
  }

  static Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await TokenStore.read();
    return <String, String>{
      if (json) 'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// JAVOBNI O'QIYDI VA XATONI ANIQ MATNGA AYLANTIRADI.
  ///
  /// ⚠️ `response.body` BO'SH BO'LISHI MUMKIN (204): `jsonDecode('')`
  /// yiqilardi.
  static dynamic _parse(http.Response response) {
    final body = response.body;
    final ok = response.statusCode >= 200 && response.statusCode < 300;

    dynamic decoded;
    if (body.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        decoded = null;
      }
    }

    if (ok) return decoded;

    // Nest standart xato shakli: { message, statusCode }.
    var message = 'Serverga ulanib bo\'lmadi';
    if (decoded is Map<String, dynamic>) {
      final raw = decoded['message'];
      if (raw is String && raw.isNotEmpty) {
        message = raw;
      } else if (raw is List && raw.isNotEmpty) {
        // ⚠️ `ValidationPipe` RO'YXAT QAYTARADI: birinchisi yetarli,
        // hammasi ko'rsatilsa ekranga sig'masdi.
        message = raw.first.toString();
      }
    }

    throw ApiException(response.statusCode, message);
  }

  /// ⚠️ TARMOQ XATOSI ALOHIDA USHLANADI: `SocketException` ning
  /// ingliz tilidagi matni fuqaroga ko'rsatilsa, u "ilova buzilgan"
  /// deb o'ylardi — aslida internet yo'q.
  static Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on SocketException {
      throw ApiException(0, 'Internetga ulanib bo\'lmadi. Aloqani tekshiring.');
    } on HttpException {
      throw ApiException(0, 'Serverga ulanib bo\'lmadi. Keyinroq urinib ko\'ring.');
    }
  }

  static Future<dynamic> get(String path, [Map<String, String>? query]) =>
      _guard(() async {
        final response = await http
            .get(_uri(path, query), headers: await _headers(json: false))
            .timeout(_timeout);
        return _parse(response);
      });

  static Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _guard(() async {
        final response = await http
            .post(
              _uri(path),
              headers: await _headers(),
              body: jsonEncode(body ?? <String, dynamic>{}),
            )
            .timeout(_timeout);
        return _parse(response);
      });

  static Future<dynamic> patch(String path, [Map<String, dynamic>? body]) =>
      _guard(() async {
        final response = await http
            .patch(
              _uri(path),
              headers: await _headers(),
              body: jsonEncode(body ?? <String, dynamic>{}),
            )
            .timeout(_timeout);
        return _parse(response);
      });

  /// FAYL YUKLASH (`POST /mobile/uploads`).
  ///
  /// ⚠️ `Content-Type` QO'LDA QO'YILMAYDI: `MultipartRequest` uni
  /// chegara (boundary) bilan birga o'zi yozadi va ustiga yozilsa,
  /// server qismlarni ajrata olmasdi.
  ///
  /// ⚠️ FAYL TURINI SERVER ICHIDAGI BAYTLARDAN ANIQLAYDI — biz
  /// yuborgan `Content-Type` ga ishonmaydi. Shuning uchun uni
  /// to'g'ri yuborish shart emas, lekin yuborilsa ham zarari yo'q.
  static Future<dynamic> upload(String path, File file) => _guard(() async {
    final request = http.MultipartRequest('POST', _uri(path));
    final token = await TokenStore.read();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send().timeout(
      const Duration(seconds: 120),
    );
    final response = await http.Response.fromStream(streamed);
    return _parse(response);
  });
}
