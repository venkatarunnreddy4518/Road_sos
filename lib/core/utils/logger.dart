// lib/core/utils/logger.dart

enum LogLevel { INFO, WARNING, ERROR, DEBUG }

class AppLogger {
  static void log(String message, {LogLevel level = LogLevel.INFO, Object? error, StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toIso8601String();
    final prefix = '[${level.name}]';

    final logMessage = '$timestamp $prefix $message';

    switch (level) {
      case LogLevel.INFO:
        log(logMessage);
        break;
      case LogLevel.WARNING:
        log('⚠️ $logMessage');
        break;
      case LogLevel.ERROR:
        log('❌ $logMessage');
        if (error != null) log('Error: $error');
        if (stackTrace != null) log('StackTrace: $stackTrace');
        break;
      case LogLevel.DEBUG:
        log('🔍 $logMessage');
        break;
    }
  }
}
