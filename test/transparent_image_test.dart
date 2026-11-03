import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:video_trimmer/src/utils/transparent_image.dart';

void main() {
  test('kTransparentImage is a 1x1 fully transparent PNG', () {
    final image = img.decodePng(kTransparentImage);
    expect(image, isNotNull);
    expect(image!.width, 1);
    expect(image.height, 1);
    expect(image.getPixel(0, 0).a, 0);
  });
}
