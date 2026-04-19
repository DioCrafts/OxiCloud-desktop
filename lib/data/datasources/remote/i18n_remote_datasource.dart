import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';

/// Locale info returned by the server.
class LocaleDto {
  final String code;
  final String name;
  final String nativeName;

  const LocaleDto({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  factory LocaleDto.fromJson(Map<String, dynamic> json) {
    return LocaleDto(
      code: json['code'] as String,
      name: json['name'] as String,
      nativeName: json['native_name'] as String? ?? json['name'] as String,
    );
  }
}

/// Translation result.
class TranslationResult {
  final String key;
  final String locale;
  final String text;

  const TranslationResult({
    required this.key,
    required this.locale,
    required this.text,
  });

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      key: json['key'] as String,
      locale: json['locale'] as String,
      text: json['text'] as String,
    );
  }
}

class I18nRemoteDatasource {
  final Dio _dio;

  I18nRemoteDatasource(this._dio);

  /// Get all available locales.
  Future<List<LocaleDto>> getLocales() async {
    try {
      final response = await _dio.get(ApiEndpoints.i18nLocales);
      return (response.data as List<dynamic>)
          .map((e) => LocaleDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// Translate a single key to the given locale.
  Future<TranslationResult> translate(String key, {String? locale}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.i18nTranslate,
        queryParameters: {
          'key': key,
          if (locale != null) 'locale': locale,
        },
      );
      return TranslationResult.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// Get all translations for a specific locale.
  Future<Map<String, dynamic>> getTranslationsByLocale(
      String localeCode) async {
    try {
      final response =
          await _dio.get(ApiEndpoints.i18nLocale(localeCode));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }
}
