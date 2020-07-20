import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/thumbnail_viewer.dart';
import 'package:video_trimmer/trim_editor_painter.dart';
import 'package:video_trimmer/video_trimmer.dart';

VideoPlayerController videoPlayerController;

class TrimEditor extends StatefulWidget {
  /// For defining the total trimmer area width
  final double viewerWidth;

  /// For defining the total trimmer area height
  final double viewerHeight;

  /// For specifying a size to the holder at the
  /// two ends of the video trimmer area, while it is `idle`.
  /// By default it is set to `5.0`.
  final double circleSize;

  /// For specifying a size to the holder at
  /// the two ends of the video trimmer area, while it is being
  /// `dragged`. By default it is set to `8.0`.
  final double circleSizeOnDrag;

  /// For specifying a color to the circle.
  /// By default it is set to `Colors.white`.
  final Color circlePaintColor;

  /// For specifying a color to the border of
  /// the trim area. By default it is set to `Colors.white`.
  final Color borderPaintColor;

  /// For specifying a color to the video
  /// scrubber inside the trim area. By default it is set to
  /// `Colors.white`.
  final Color scrubberPaintColor;

  /// For specifying the quality of each
  /// generated image thumbnail, to be displayed in the trimmer
  /// area.
  final int thumbnailQuality;

  /// For showing the start and the end point of the
  /// video on top of the trimmer area. By default it is set to `true`.
  final bool showDuration;

  /// For providing a `TextStyle` to the
  /// duration text. By default it is set to
  /// `TextStyle(color: Colors.white)`
  final TextStyle durationTextStyle;

  /// Callback to the video start position
  ///
  /// Returns the selected video start position in `milliseconds`.
  final Function(double startValue) onChangeStart;

  /// Callback to the video end position.
  ///
  /// Returns the selected video end position in `milliseconds`.
  final Function(double endValue) onChangeEnd;

  /// Callback to the video playback
  /// state to know whether it is currently playing or paused.
  ///
  /// Returns a `boolean` value. If `true`, video is currently
  /// playing, otherwise paused.
  final Function(bool isPlaying) onChangePlaybackState;

  /// Widget for displaying the video trimmer.
  ///
  /// This has frame wise preview of the video with a
  /// slider for selecting the part of the video to be
  /// trimmed.
  ///
  /// The required parameters are [viewerWidth] & [viewerHeight]
  ///
  /// * [viewerWidth] to define the total trimmer area width.
  ///
  ///
  /// * [viewerHeight] to define the total trimmer area height.
  ///
  ///
  /// The optional parameters are:
  ///
  /// * [circleSize] for specifying a size to the holder at the
  /// two ends of the video trimmer area, while it is `idle`.
  /// By default it is set to `5.0`.
  ///
  ///
  /// * [circleSizeOnDrag] for specifying a size to the holder at
  /// the two ends of the video trimmer area, while it is being
  /// `dragged`. By default it is set to `8.0`.
  ///
  ///
  /// * [circlePaintColor] for specifying a color to the circle.
  /// By default it is set to `Colors.white`.
  ///
  ///
  /// * [borderPaintColor] for specifying a color to the border of
  /// the trim area. By default it is set to `Colors.white`.
  ///
  ///
  /// * [scrubberPaintColor] for specifying a color to the video
  /// scrubber inside the trim area. By default it is set to
  /// `Colors.white`.
  ///
  ///
  /// * [thumbnailQuality] for specifying the quality of each
  /// generated image thumbnail, to be displayed in the trimmer
  /// area.
  ///
  ///
  /// * [showDuration] for showing the start and the end point of the
  /// video on top of the trimmer area. By default it is set to `true`.
  ///
  ///
  /// * [durationTextStyle] is for providing a `TextStyle` to the
  /// duration text. By default it is set to
  /// `TextStyle(color: Colors.white)`
  ///
  ///
  /// * [onChangeStart] is a callback to the video start position.
  ///
  ///
  /// * [onChangeEnd] is a callback to the video end position.
  ///
  ///
  /// * [onChangePlaybackState] is a callback to the video playback
  /// state to know whether it is currently playing or paused.
  ///
  TrimEditor({
    @required this.viewerWidth,
    @required this.viewerHeight,
    this.circleSize = 5.0,
    this.circleSizeOnDrag = 8.0,
    this.circlePaintColor = Colors.white,
    this.borderPaintColor = Colors.white,
    this.scrubberPaintColor = Colors.white,
    this.thumbnailQuality = 75,
    this.showDuration = true,
    this.durationTextStyle = const TextStyle(
      color: Colors.white,
    ),
    this.onChangeStart,
    this.onChangeEnd,
    this.onChangePlaybackState,
  })  : assert(viewerWidth != null),
        assert(viewerHeight != null),
        assert(circleSize != null),
        assert(circleSizeOnDrag != null),
        assert(circlePaintColor != null),
        assert(borderPaintColor != null),
        assert(scrubberPaintColor != null),
        assert(thumbnailQuality != null),
        assert(showDuration != null),
        assert(durationTextStyle != null);

  @override
  _TrimEditorState createState() => _TrimEditorState();
}

class _TrimEditorState extends State<TrimEditor> with TickerProviderStateMixin {
  File _videoFile;

  double _videoStartPos = 0.0;
  double _videoEndPos = 0.0;

  bool _canUpdateStart = true;
  bool _isLeftDrag = true;

  Offset _startPos = Offset(0, 0);
  Offset _endPos = Offset(0, 0);

  double _startFraction = 0.0;
  double _endFraction = 1.0;

  int _videoDuration = 0;
  int _currentPosition = 0;

  double _thumbnailViewerW = 0.0;
  double _thumbnailViewerH = 0.0;

  int _numberOfThumbnails = 0;

  double _circleSize;

  ThumbnailViewer thumbnailWidget;

  Animation<double> _scrubberAnimation;
  AnimationController _animationController;
  Tween<double> _linearTween;

  TextEditingController _startHourCtrl = TextEditingController();
  TextEditingController _startMinCtrl = TextEditingController();
  TextEditingController _startSecCtrl = TextEditingController();
  TextEditingController _startFracsCtrl = TextEditingController();

  TextEditingController _endHourCtrl = TextEditingController();
  TextEditingController _endMinCtrl = TextEditingController();
  TextEditingController _endSecCtrl = TextEditingController();
  TextEditingController _endFracsCtrl = TextEditingController();

  Future<void> _initializeVideoController() async {
    if (_videoFile != null) {
      videoPlayerController.addListener(() {
        final bool isPlaying = videoPlayerController.value.isPlaying;

        if (isPlaying) {
          widget.onChangePlaybackState(true);
          setState(() {
            _currentPosition =
                videoPlayerController.value.position.inMilliseconds;
            print("CURRENT POS: $_currentPosition");

            if (_currentPosition > _videoEndPos.toInt()) {
              widget.onChangePlaybackState(false);
              videoPlayerController.pause();
              _animationController.stop();
            } else {
              if (!_animationController.isAnimating) {
                widget.onChangePlaybackState(true);
                _animationController.forward();
              }
            }
          });
        } else {
          if (videoPlayerController.value.initialized) {
            if (_animationController != null) {
              print(
                  'ANI VALUE: ${(_scrubberAnimation.value).toInt()} && END: ${(_endPos.dx).toInt()}');
              if ((_scrubberAnimation.value).toInt() == (_endPos.dx).toInt()) {
                _animationController.reset();
              }
              _animationController.stop();
              widget.onChangePlaybackState(false);
            }
          }
        }
      });

      videoPlayerController.setVolume(1.0);
      _videoDuration = videoPlayerController.value.duration.inMilliseconds;
      print(_videoFile.path);

      _videoEndPos = _videoDuration.toDouble();
      widget.onChangeEnd(_videoEndPos);

      final ThumbnailViewer _thumbnailWidget = ThumbnailViewer(
        videoFile: _videoFile,
        videoDuration: _videoDuration,
        thumbnailHeight: _thumbnailViewerH,
        numberOfThumbnails: _numberOfThumbnails,
        quality: widget.thumbnailQuality,
      );
      thumbnailWidget = _thumbnailWidget;
    }
  }

  // Sets the start value of video.
  // Assumes that ThumbnailViewer is screen width - 10
  void _setVideoStartByCtrl(double time) async {
    double widgetWidth = MediaQuery
        .of(context)
        .size
        .width - 10;
    setState(() {
      _videoStartPos = time;
      _startFraction = _videoStartPos / _videoDuration;
      _startPos = Offset(_startFraction * widgetWidth, _startPos.dy);
      widget.onChangeStart(_videoStartPos);
    });

    await videoPlayerController
        .seekTo(Duration(milliseconds: _videoStartPos.toInt()));
    _linearTween.begin = _startPos.dx;
    _animationController.duration =
        Duration(milliseconds: (_videoEndPos - _videoStartPos).toInt());
    _animationController.reset();
  }

  // Sets the end value of video.
  // Assumes that ThumbnailViewer is screen width - 10
  void _setVideoEndByCtrl(double time) async {
    double widgetWidth = MediaQuery
        .of(context)
        .size
        .width - 10;
    setState(() {
      _videoEndPos = time;
      _endFraction = _videoEndPos / _videoDuration;
      _endPos = Offset(_endFraction * widgetWidth, _endPos.dy);

      widget.onChangeEnd(_videoEndPos);
    });

    await videoPlayerController
        .seekTo(Duration(milliseconds: _videoEndPos.toInt()));
    _linearTween.end = _endPos.dx;
    _animationController.duration =
        Duration(milliseconds: (_videoEndPos - _videoStartPos).toInt());
    _animationController.reset();
  }

  void _setVideoStartPosition(DragUpdateDetails details) async {
    if (!(_startPos.dx + details.delta.dx < 0) &&
        !(_startPos.dx + details.delta.dx > _thumbnailViewerW) &&
        !(_startPos.dx + details.delta.dx > _endPos.dx)) {
      setState(() {
        _startPos += details.delta;
        _startFraction = (_startPos.dx / _thumbnailViewerW);
        print("START PERCENT: $_startFraction");
        _videoStartPos = _videoDuration * _startFraction;
        widget.onChangeStart(_videoStartPos);
      });
      await videoPlayerController.pause();
      await videoPlayerController
          .seekTo(Duration(milliseconds: _videoStartPos.toInt()));
      _linearTween.begin = _startPos.dx;
      _animationController.duration =
          Duration(milliseconds: (_videoEndPos - _videoStartPos).toInt());
      _animationController.reset();
    }
  }

  void _setVideoEndPosition(DragUpdateDetails details) async {
    if (!(_endPos.dx + details.delta.dx > _thumbnailViewerW) &&
        !(_endPos.dx + details.delta.dx < 0) &&
        !(_endPos.dx + details.delta.dx < _startPos.dx)) {
      setState(() {
        _endPos += details.delta;
        _endFraction = _endPos.dx / _thumbnailViewerW;
        print("END PERCENT: $_endFraction");
        _videoEndPos = _videoDuration * _endFraction;
        widget.onChangeEnd(_videoEndPos);
      });
      await videoPlayerController.pause();
      await videoPlayerController
          .seekTo(Duration(milliseconds: _videoEndPos.toInt()));
      _linearTween.end = _endPos.dx;
      _animationController.duration =
          Duration(milliseconds: (_videoEndPos - _videoStartPos).toInt());
      _animationController.reset();
    }
  }

  // Checks if start or end time inputted to dialog is valid,
  // if not valid, moves start or end to valid area
  validateTime({bool start}) {
    int inputtedMillis = inputToMillis(start: start);
    if (inputtedMillis == null) {
      return;
    }
    if (start && inputtedMillis > _videoEndPos) {
      setCtrlTimes(_videoEndPos, start: start);
      return;
    }
    else if (!start && inputtedMillis < _videoStartPos) {
      setCtrlTimes(_videoStartPos, start: start);
      return;
    }
    if (inputtedMillis > _videoDuration) {
      setCtrlTimes(_videoDuration.toDouble(), start: start);
      return;
    }
    if (inputtedMillis < 0) {
      setCtrlTimes(0, start: start);
      return;
    }
  }


  // Returns TextFields' summed value in milliseconds
  // or null if field is empty or invalid
  int inputToMillis({bool start}) {
    int inputtedMillis = 0;
    try {
      if (start) {
        inputtedMillis += (int.parse(_startHourCtrl.value.text) * 3600000);
        inputtedMillis += (int.parse(_startMinCtrl.value.text) * 60000);
        inputtedMillis += (int.parse(_startSecCtrl.value.text) * 1000);
        inputtedMillis += (int.parse(_startFracsCtrl.value.text) * 100);
      } else {
        inputtedMillis += (int.parse(_endHourCtrl.value.text) * 3600000);
        inputtedMillis += (int.parse(_endMinCtrl.value.text) * 60000);
        inputtedMillis += (int.parse(_endSecCtrl.value.text) * 1000);
        inputtedMillis += (int.parse(_endFracsCtrl.value.text) * 100);
      }
      return inputtedMillis;
    }
    catch (e) {
      return null;
    }
  }


  void setCtrlTimes(double time, {bool start,}) {
    int hours = time ~/ 3600000;
    int mins = (time - hours * 3600000) ~/ 60000;
    int secs = (time - (hours * 3600000) - (mins * 60000)) ~/ 1000;
    int fracs = (time - (hours * 3600000) - (mins * 60000) -
        (secs * 1000)) ~/ 100;
    if (start) {
      _startHourCtrl.text = hours.toString();
      _startMinCtrl.text = mins.toString();
      _startSecCtrl.text = secs.toString();
      _startFracsCtrl.text = fracs.toString();
    }
    else {
      _endHourCtrl.text = hours.toString();
      _endMinCtrl.text = mins.toString();
      _endSecCtrl.text = secs.toString();
      _endFracsCtrl.text = fracs.toString();
    }
  }


  timeInputArrowTap({bool start, int amount}) {
    int millis = inputToMillis(start: start);
    if (millis == null) {
      setCtrlTimes(0, start: start);
    }
    else {
      setCtrlTimes(millis.toDouble() + amount, start: start);
    }
    validateTime(start: start);
  }


  openTimePicker({bool start}) {
    videoPlayerController.pause();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(20.0)),

            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FittedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            Text("h"),
                            GestureDetector(
                              onTap: () {
                                timeInputArrowTap(
                                    start: start, amount: 3600000);
                              },
                              child: Container(
                                  padding: EdgeInsets.all(8),
                                  height: 60,
                                  child: Icon(IconData(
                                      58134, fontFamily: 'MaterialIcons'),
                                    size: 50,)),
                            ),
                            Container(
                              width: 30,
                              child: TextField(
                                style: TextStyle(fontSize: 20),
                                controller: start
                                    ? _startHourCtrl
                                    : _endHourCtrl,
                                onChanged: (str) {
                                  validateTime(start: start)

                                  ;
                                },
                                decoration: InputDecoration(hintText: 'h'),
                                inputFormatters: [
                                  WhitelistingTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(1),
                                ],
                                keyboardType: TextInputType.number,),
                            ),
                            GestureDetector(
                              onTap: () {
                                timeInputArrowTap(
                                    start: start, amount: -3600000);
                              },
                              child: Container(
                                  padding: EdgeInsets.all(8),
                                  height: 60,
                                  child: Icon(IconData(
                                      58131, fontFamily: 'MaterialIcons'),
                                    size: 50,)),
                            ),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            Container(height: 20,),
                            Text(":"),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            Text("m"),
                            GestureDetector(
                              onTap: () {
                                timeInputArrowTap(start: start, amount: 60000);
                              },
                              child: Container(
                                  padding: EdgeInsets.all(8),
                                  height: 60,
                                  child: Icon(IconData(
                                      58134, fontFamily: 'MaterialIcons'),
                                    size: 50,)),
                            ),
                            Container(
                              width: 30,
                              child: TextField(
                                style: TextStyle(fontSize: 20),
                                onChanged: (str) {
                                  validateTime(start: start);
                                },
                                controller: start ? _startMinCtrl : _endMinCtrl,
                                decoration: InputDecoration(hintText: 'm'),
                                inputFormatters: [
                                  WhitelistingTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                  WhitelistingTextInputFormatter(
                                      RegExp("^[1-5]?[0-9]\$")),
                                ],
                                keyboardType: TextInputType.number,),
                            ),
                            GestureDetector(
                              onTap: () {
                                timeInputArrowTap(start: start, amount: -60000);
                              },
                              child: Container(
                                  padding: EdgeInsets.all(8),
                                  height: 60,
                                  child: Icon(IconData(
                                      58131, fontFamily: 'MaterialIcons'),
                                    size: 50,)),
                            ),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            Container(height: 20,),
                            Text(":"),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            Text("s"),
                            GestureDetector(
                              onTap: () {
                                timeInputArrowTap(start: start, amount: 1000);
                              },
                              child: Container(
                                  padding: EdgeInsets.all(8),
                                  height: 60,
                                  child: Icon(IconData(
                                      58134, fontFamily: 'MaterialIcons'),
                                    size: 50,)),
                            ),
                            Container(
                              width: 30,
                              child: TextField(
                                style: TextStyle(fontSize: 20),
                                onChanged: (str) {
                                  validateTime(start: start);
                                },
                                controller: start ? _startSecCtrl : _endSecCtrl,
                                decoration: InputDecoration(hintText: 's'),
                                inputFormatters: [
                                  WhitelistingTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                  WhitelistingTextInputFormatter(
                                      RegExp("^[1-5]?[0-9]\$")),
                                ],
                                keyboardType: TextInputType.number,),
                            ),
                            GestureDetector(
                              onTap: () {
                                timeInputArrowTap(start: start, amount: -1000);
                              },
                              child: Container(
                                  padding: EdgeInsets.all(8),
                                  height: 60,
                                  child: Icon(IconData(
                                      58131, fontFamily: 'MaterialIcons'),
                                    size: 50,)),
                            ),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            Container(height: 20,),
                            Text("."),
                          ],
                        ),
                        Column(

                          children: <Widget>[
                            Text(""),
                            GestureDetector(
                              onTap: () {
                                timeInputArrowTap(start: start, amount: 100);
                              },
                              child: Container(
                                  padding: EdgeInsets.all(8),
                                  height: 60,
                                  child: Icon(IconData(
                                      58134, fontFamily: 'MaterialIcons'),
                                    size: 50,)),
                            ),
                            Container(
                              width: 30,
                              child: TextField(
                                style: TextStyle(fontSize: 20),
                                onChanged: (str) {
                                  validateTime(start: start);
                                },
                                controller: start
                                    ? _startFracsCtrl
                                    : _endFracsCtrl,
                                decoration: InputDecoration(hintText: 'ms'),
                                inputFormatters: [
                                  WhitelistingTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(1),
                                ],
                                keyboardType: TextInputType.number,),
                            ),
                            GestureDetector(
                              onTap: () {
                                timeInputArrowTap(start: start, amount: -100);
                              },
                              child: Container(
                                  padding: EdgeInsets.all(8),
                                  height: 60,
                                  child: Icon(IconData(
                                      58131, fontFamily: 'MaterialIcons'),
                                    size: 50,)),
                            ),
                          ],
                        ),
                      ],),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        CupertinoButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text("Cancel"),),
                        CupertinoButton(
                          onPressed: () {
                            int millis = inputToMillis(start: start);
                            if (millis != null) {
                              Navigator.pop(context);
                              start ? _setVideoStartByCtrl(millis.toDouble())
                                  : _setVideoEndByCtrl(millis.toDouble());
                            }
                          }, child: Text("Ok"),),
                      ],),
                  ),
                ],
              ),
            ),
          );
        });
  }

  @override
  void initState() {
    super.initState();
    _circleSize = widget.circleSize;

    _videoFile = Trimmer.currentVideoFile;
    _thumbnailViewerH = widget.viewerHeight;

    _numberOfThumbnails = widget.viewerWidth ~/ _thumbnailViewerH;
    print('Number of thumbnails generated: $_numberOfThumbnails');
    _thumbnailViewerW = _numberOfThumbnails * _thumbnailViewerH;

    _endPos = Offset(_thumbnailViewerW, _thumbnailViewerH);
    _initializeVideoController();

    // Defining the tween points
    _linearTween = Tween(begin: _startPos.dx, end: _endPos.dx);

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_videoEndPos - _videoStartPos).toInt()),
    );

    _scrubberAnimation = _linearTween.animate(_animationController)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.stop();
        }
      });
  }

  @override
  void dispose() {
    videoPlayerController.pause();
    widget.onChangePlaybackState(false);
    if (_videoFile != null) {
      videoPlayerController.setVolume(0.0);
      videoPlayerController.pause();
      videoPlayerController.dispose();
      widget.onChangePlaybackState(false);
    }
    _startHourCtrl.dispose();
    _startMinCtrl.dispose();
    _startSecCtrl.dispose();
    _startFracsCtrl.dispose();
    _endHourCtrl.dispose();
    _endMinCtrl.dispose();
    _endSecCtrl.dispose();
    _endFracsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        print("START");
        print(details.localPosition);
        print((_startPos.dx - details.localPosition.dx).abs());
        print((_endPos.dx - details.localPosition.dx).abs());

        if (_endPos.dx >= _startPos.dx) {
          if ((_startPos.dx - details.localPosition.dx).abs() >
              (_endPos.dx - details.localPosition.dx).abs()) {
            setState(() {
              _canUpdateStart = false;
            });
          } else {
            setState(() {
              _canUpdateStart = true;
            });
          }
        } else {
          if (_startPos.dx > details.localPosition.dx) {
            _isLeftDrag = true;
          } else {
            _isLeftDrag = false;
          }
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        setState(() {
          _circleSize = widget.circleSize;
        });
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        print("UPDATE");
        print("START POINT: ${_startPos.dx + details.delta.dx}");
        print("END POINT: ${_endPos.dx + details.delta.dx}");

        _circleSize = widget.circleSizeOnDrag;

        if (_endPos.dx >= _startPos.dx) {
          _isLeftDrag = false;
          if (_canUpdateStart && _startPos.dx + details.delta.dx > 0) {
            _isLeftDrag = false; // To prevent from scrolling over
            _setVideoStartPosition(details);
          } else if (!_canUpdateStart &&
              _endPos.dx + details.delta.dx < _thumbnailViewerW) {
            _isLeftDrag = true; // To prevent from scrolling over
            _setVideoEndPosition(details);
          }
        } else {
          if (_isLeftDrag && _startPos.dx + details.delta.dx > 0) {
            _setVideoStartPosition(details);
          } else if (!_isLeftDrag &&
              _endPos.dx + details.delta.dx < _thumbnailViewerW) {
            _setVideoEndPosition(details);
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          widget.showDuration
              ? Container(
                  width: _thumbnailViewerW,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            setCtrlTimes(_videoStartPos, start: true);
                            openTimePicker(start: true);
                          },
                          child: Text(
                              Duration(milliseconds: _videoStartPos.toInt())
                                  .toString()
                                  .split('.')[0],
                              style: widget.durationTextStyle),
                        ),
                        GestureDetector(
                          onTap: () {
                            setCtrlTimes(_videoEndPos, start: false);
                            openTimePicker(start: false);
                          },
                          child: Text(
                            Duration(milliseconds: _videoEndPos.toInt())
                                .toString()
                                .split('.')[0],
                            style: widget.durationTextStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(),
          CustomPaint(
            foregroundPainter: TrimEditorPainter(
              startPos: _startPos,
              endPos: _endPos,
              scrubberAnimationDx: _scrubberAnimation.value,
              circleSize: _circleSize,
              circlePaintColor: widget.circlePaintColor,
              borderPaintColor: widget.borderPaintColor,
              scrubberPaintColor: widget.scrubberPaintColor,
            ),
            child: Container(
              color: Colors.grey[900],
              height: _thumbnailViewerH,
              width: _thumbnailViewerW,
              child: thumbnailWidget == null ? Column() : thumbnailWidget,
            ),
          ),
        ],
      ),
    );
  }
}
