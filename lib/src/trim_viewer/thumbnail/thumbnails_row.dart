import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

class ThumbnailsRow extends StatelessWidget {
  final int length;
  final Size size;
  final BoxFit? fit;
  final List<Uint8List?> imageBytes;

  const ThumbnailsRow({
    super.key,
    required this.length,
    required this.size,
    this.fit,
    required this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    if (imageBytes.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: List.generate(
        length,
        (index) => SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 0.2,
                child: Image.memory(
                  imageBytes[0] ?? kTransparentImage,
                  width: size.width,
                  height: size.height,
                  cacheWidth: size.width.toInt(),
                  fit: fit,
                ),
              ),
              index < imageBytes.length
                  ? FadeInImage(
                      placeholder: ResizeImage.resizeIfNeeded(
                        size.width.toInt(),
                        null,
                        MemoryImage(kTransparentImage),
                      ),
                      image: ResizeImage.resizeIfNeeded(
                        size.width.toInt(),
                        null,
                        MemoryImage(imageBytes[index]!),
                      ),
                      width: size.width,
                      height: size.height,
                      fit: fit,
                    )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
