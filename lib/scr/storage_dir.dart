/// Supported storage locations.
///
/// * [temporaryDirectory]
///
/// * [applicationDocumentsDirectory]
///
/// * [externalStorageDirectory]
///
class StorageDir {
  const StorageDir._(this.index);

  final int index;

  static const StorageDir temporaryDirectory = StorageDir._(0);
  static const StorageDir applicationDocumentsDirectory = StorageDir._(1);
  static const StorageDir externalStorageDirectory = StorageDir._(2);

  static const List<StorageDir> values = <StorageDir>[
    temporaryDirectory,
    applicationDocumentsDirectory,
    externalStorageDirectory,
  ];

  @override
  String toString() {
    return const <int, String>{
      0: 'temporaryDirectory',
      1: 'applicationDocumentsDirectory',
      2: 'externalStorageDirectory',
    }[index];
  }
}
