import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Lightweight application logger with level-based methods.
///
/// - `debug` and `info` logs are suppressed in release builds.
/// - `warn` and `error` logs are always emitted.
class AppLogger {
  AppLogger._();

  static const String _loggerName = 'NotifyApp';

  /// Developer-friendly messages for local debugging.
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (kReleaseMode) return;
    developer.log(
      message,
      name: _loggerName,
      level: 500, // debug
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// High-level informational messages for development observability.
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    if (kReleaseMode) return;
    developer.log(
      message,
      name: _loggerName,
      level: 800, // info
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Warnings should be rare and visible in all builds.
  static void warn(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _loggerName,
      level: 900, // warning
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Errors should always be logged. Consider integrating Crashlytics later.
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _loggerName,
      level: 1000, // error
      error: error,
      stackTrace: stackTrace,
    );
  }
}


