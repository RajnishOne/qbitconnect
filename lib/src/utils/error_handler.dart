import 'package:easy_localization/easy_localization.dart';
import '../constants/locale_keys.dart';

class ErrorHandler {
  static String getUserFriendlyMessage(dynamic error) {
    if (error == null) return LocaleKeys.unknownErrorOccurred.tr();

    final errorString = error.toString().toLowerCase();

    // Connection timeout errors
    if (errorString.contains('connection timeout') ||
        errorString.contains('connect timeout')) {
      return LocaleKeys.connectionTimedOutMessage.tr();
    }

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection refused')) {
      return LocaleKeys.networkErrorMessage.tr();
    }

    // DNS resolution errors
    if (errorString.contains('dns') ||
        errorString.contains('host not found') ||
        errorString.contains('name resolution')) {
      return LocaleKeys.cannotFindServerMessage.tr();
    }

    // SSL/TLS errors
    if (errorString.contains('ssl') ||
        errorString.contains('certificate') ||
        errorString.contains('tls') ||
        errorString.contains('handshake')) {
      return LocaleKeys.sslTlsErrorMessage.tr();
    }

    // Authentication errors
    if (errorString.contains('login failed') ||
        errorString.contains('unauthorized') ||
        errorString.contains('401') ||
        errorString.contains('403')) {
      return LocaleKeys.authenticationFailedMessage.tr();
    }

    // Server not found errors
    if (errorString.contains('404') || errorString.contains('not found')) {
      return LocaleKeys.serverNotFoundMessage.tr();
    }

    // Server error responses
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return LocaleKeys.serverErrorMessage.tr();
    }

    // Malformed URL errors
    if (errorString.contains('invalid url') ||
        errorString.contains('malformed')) {
      return LocaleKeys.invalidUrlFormatMessage.tr();
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return LocaleKeys.requestTimedOutMessage.tr();
    }

    // Generic Dio errors
    if (errorString.contains('dioexception')) {
      return LocaleKeys.connectionErrorMessage.tr();
    }

    // If we can't identify the specific error, provide a generic message
    return LocaleKeys.connectionFailedMessage.tr();
  }

  static String getShortErrorMessage(dynamic error) {
    if (error == null) return LocaleKeys.connectionFailed.tr();

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('connection timeout') ||
        errorString.contains('connect timeout')) {
      return LocaleKeys.connectionTimedOut.tr();
    }

    if (errorString.contains('login failed') ||
        errorString.contains('unauthorized') ||
        errorString.contains('401') ||
        errorString.contains('403')) {
      return LocaleKeys.authenticationFailed.tr();
    }

    if (errorString.contains('404') || errorString.contains('not found')) {
      return LocaleKeys.serverNotFound.tr();
    }

    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection refused')) {
      return LocaleKeys.networkError.tr();
    }

    if (errorString.contains('dns') || errorString.contains('host not found')) {
      return LocaleKeys.cannotFindServer.tr();
    }

    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return LocaleKeys.requestTimedOut.tr();
    }

    return LocaleKeys.connectionFailed.tr();
  }
}
