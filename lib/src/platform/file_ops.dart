// File-system work that differs between native platforms and the web. The
// default is a stub so that tools resolving imports without a platform (such
// as pub.dev's platform detection) never see dart:io.
export 'file_ops_stub.dart'
    if (dart.library.io) 'file_ops_io.dart'
    if (dart.library.js_interop) 'file_ops_web.dart';
