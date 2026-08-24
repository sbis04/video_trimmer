/// Supported storage locations for the trimmed output.
///
/// * [temporaryDirectory] — only accessible from inside the app, and the
///   system can clear it at any time.
///
/// * [applicationDocumentsDirectory] — only accessible from inside the app.
///
/// * [externalStorageDirectory] — Android only, accessible externally.
///   Resolving this on any other platform throws.
enum StorageDir {
  temporaryDirectory,
  applicationDocumentsDirectory,
  externalStorageDirectory;

  /// Kept as the bare name for backwards compatibility: this used to be a
  /// hand-rolled enum-like class whose `toString` returned just the name.
  @override
  String toString() => name;
}
