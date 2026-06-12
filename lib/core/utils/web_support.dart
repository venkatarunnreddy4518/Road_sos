// Conditional barrel: real web helpers on Flutter web, no-op stubs elsewhere.
export 'web_support_stub.dart' if (dart.library.html) 'web_support_web.dart';
