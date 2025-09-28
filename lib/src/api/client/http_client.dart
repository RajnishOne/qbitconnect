import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:network_ninja/network_ninja.dart';

class HttpClientConfig {
  static const Duration connectTimeout = Duration(seconds: 4);
  static const Duration receiveTimeout = Duration(seconds: 4);
  static const Duration sendTimeout = Duration(seconds: 4);

  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static BaseOptions createBaseOptions(
    String baseUrl,
    Map<String, String>? defaultHeaders,
  ) {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return BaseOptions(
      baseUrl: normalizedBase,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 500,
      headers: {
        'Referer': normalizedBase,
        'Origin': normalizedBase,
        'X-Requested-With': 'XMLHttpRequest',
        'Accept': '*/*',
        'User-Agent': userAgent,
        if (defaultHeaders != null) ...defaultHeaders,
      },
    );
  }
}

/// Factory for creating configured Dio instances
class HttpClientFactory {
  static Dio createClient({
    required String baseUrl,
    Map<String, String>? defaultHeaders,
    bool enableLogging = true,
  }) {
    final dio = Dio(
      HttpClientConfig.createBaseOptions(baseUrl, defaultHeaders),
    );

    final cookieJar = CookieJar();
    dio.interceptors.add(CookieManager(cookieJar));

    if (enableLogging) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: false,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );

      NetworkNinjaController.addInterceptor(dio);
    }

    return dio;
  }
}
