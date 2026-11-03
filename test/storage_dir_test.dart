import 'package:flutter_test/flutter_test.dart';
import 'package:video_trimmer/video_trimmer.dart';

void main() {
  group('StorageDir', () {
    test('exposes the three supported locations in a stable order', () {
      expect(StorageDir.values, [
        StorageDir.temporaryDirectory,
        StorageDir.applicationDocumentsDirectory,
        StorageDir.externalStorageDirectory,
      ]);
    });

    test('indexes match the order callers may have persisted', () {
      expect(StorageDir.temporaryDirectory.index, 0);
      expect(StorageDir.applicationDocumentsDirectory.index, 1);
      expect(StorageDir.externalStorageDirectory.index, 2);
    });

    test('toString stays the bare name, as before it became an enum', () {
      expect(StorageDir.temporaryDirectory.toString(), 'temporaryDirectory');
      expect(StorageDir.applicationDocumentsDirectory.toString(),
          'applicationDocumentsDirectory');
      expect(StorageDir.externalStorageDirectory.toString(),
          'externalStorageDirectory');
    });
  });
}
