import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'trimmer.dart';

class VideoViewer extends StatefulWidget {
  /// The Trimmer instance controlling the data.
  final Trimmer trimmer;

  /// For specifying the color of the video
  /// viewer area border. By default it is set to `Colors.transparent`.
  final Color borderColor;

  /// For specifying the border width around
  /// the video viewer area. By default it is set to `0.0`.
  final double borderWidth;

  /// For specifying a padding around the video viewer
  /// area. By default it is set to `EdgeInsets.all(0.0)`.
  final EdgeInsets padding;

  /// For showing the video playback area.
  ///
  /// This only contains optional parameters. They are:
  ///
  /// * [borderColor] for specifying the color of the video
  /// viewer area border. By default it is set to `Colors.transparent`.
  ///
  ///
  /// * [borderWidth] for specifying the border width around
  /// the video viewer area. By default it is set to `0.0`.
  ///
  ///
  /// * [padding] for specifying a padding around the video viewer
  /// area. By default it is set to `EdgeInsets.all(0.0)`.
  ///
  const VideoViewer({
    super.key,
    required this.trimmer,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0.0,
    this.padding = const EdgeInsets.all(0.0),
  });

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  StreamSubscription<TrimmerEvent>? _subscription;

  /// Quick access to VideoPlayerController, only not null after [TrimmerEvent.initialized]
  /// has been emitted.
  VideoPlayerController? get videoPlayerController =>
      widget.trimmer.videoPlayerController;

  @override
  void initState() {
    super.initState();
    _subscription = widget.trimmer.eventStream.listen((event) {
      if (event == TrimmerEvent.initialized && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // Only the subscription is ours. This used to call
    // `widget.trimmer.dispose()`, closing a stream controller the widget does
    // not own, which broke every later loadVideo on the same Trimmer.
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = videoPlayerController;
    return controller == null
        ? Container()
        : Padding(
            padding: widget.padding,
            child: Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: controller.value.isInitialized
                    ? Container(
                        foregroundDecoration: BoxDecoration(
                          border: Border.all(
                            width: widget.borderWidth,
                            color: widget.borderColor,
                          ),
                        ),
                        child: VideoPlayer(controller),
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.white,
                        ),
                      ),
              ),
            ),
          );
  }
}
