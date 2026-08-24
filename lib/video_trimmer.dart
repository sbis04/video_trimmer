library;

export 'package:video_trimmer/src/trimmer.dart';
export 'package:video_trimmer/src/video_viewer.dart';
export 'package:video_trimmer/src/utils/duration_style.dart';
export 'package:video_trimmer/src/utils/storage_dir.dart';
export 'package:video_trimmer/src/trim_viewer/trim_editor_properties.dart';
export 'package:video_trimmer/src/trim_viewer/trim_area_properties.dart';
// Two types of trim viewers, the `TrimViewer` class helps to auto select
// based on the length.
export 'package:video_trimmer/src/trim_viewer/trim_viewer.dart';
// The concrete viewers, exported so they can be used directly and referred to
// in tests.
export 'package:video_trimmer/src/trim_viewer/fixed_viewer/fixed_trim_viewer.dart';
export 'package:video_trimmer/src/trim_viewer/scrollable_viewer/scrollable_trim_viewer.dart';
