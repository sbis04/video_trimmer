import AVFoundation
import ImageIO

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#endif

/// The package's native side on iOS and macOS: JPEG thumbnails for the trim viewer
/// (`video_trimmer/thumbnails`) and trimming (`video_trimmer/trim`).
///
/// The class name is deliberately specific: Flutter registers plugins by class
/// name, and generic names such as `VideoThumbnailPlugin` or
/// `VideoTrimmerPlugin` are already used by other packages. Two plugins with
/// the same name crash the app at launch on iOS.
public class VideoTrimmerNativePlugin: NSObject, FlutterPlugin {
  private let queue = DispatchQueue(label: "video_trimmer.thumbnails", qos: .userInitiated)

  // Only touched on `queue`. The trim viewer asks for many frames of the same
  // file in a row, so the generator is kept between calls.
  private var generator: AVAssetImageGenerator?
  private var generatorPath: String?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = VideoTrimmerNativePlugin()
    #if os(iOS)
      let messenger = registrar.messenger()
    #else
      let messenger = registrar.messenger
    #endif
    for name in ["video_trimmer/thumbnails", "video_trimmer/trim"] {
      let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
      registrar.addMethodCallDelegate(instance, channel: channel)
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "thumbnail":
      guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
        result(FlutterError(code: "bad_args", message: "path is required", details: nil))
        return
      }
      let timeMs = (args["timeMs"] as? NSNumber)?.int64Value ?? 0
      let maxWidth = (args["maxWidth"] as? NSNumber)?.intValue ?? 0
      let maxHeight = (args["maxHeight"] as? NSNumber)?.intValue ?? 0
      let quality = (args["quality"] as? NSNumber)?.intValue ?? 75
      queue.async {
        let generator = self.generator(for: path, maxWidth: maxWidth, maxHeight: maxHeight)
        let time = CMTime(value: timeMs, timescale: 1000)
        Self.image(from: generator, at: time) { image, error in
          let reply: Any
          if let image = image, let data = Self.jpeg(image, quality: quality) {
            reply = FlutterStandardTypedData(bytes: data)
          } else {
            reply = FlutterError(
              code: "thumbnail_failed",
              message: error?.localizedDescription ?? "No frame at \(timeMs) ms",
              details: path)
          }
          DispatchQueue.main.async { result(reply) }
        }
      }
    case "trim":
      guard let args = call.arguments as? [String: Any],
        let path = args["path"] as? String,
        let outputPath = args["outputPath"] as? String,
        let startMs = (args["startMs"] as? NSNumber)?.int64Value,
        let endMs = (args["endMs"] as? NSNumber)?.int64Value
      else {
        result(
          FlutterError(
            code: "bad_args", message: "path, outputPath, startMs and endMs are required",
            details: nil))
        return
      }
      Self.trim(path: path, outputPath: outputPath, startMs: startMs, endMs: endMs) { error in
        DispatchQueue.main.async {
          if let error = error {
            result(
              FlutterError(code: "trim_failed", message: error.localizedDescription, details: path))
          } else {
            result(outputPath)
          }
        }
      }
    case "release":
      queue.async {
        self.generator = nil
        self.generatorPath = nil
        DispatchQueue.main.async { result(nil) }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// JPEG-encodes [image] with ImageIO, which both platforms share; UIImage
  /// would tie this file to iOS.
  private static func jpeg(_ image: CGImage, quality: Int) -> Data? {
    let data = NSMutableData()
    guard
      let destination = CGImageDestinationCreateWithData(
        data as CFMutableData, "public.jpeg" as CFString, 1, nil)
    else { return nil }
    let options =
      [kCGImageDestinationLossyCompressionQuality: Double(min(max(quality, 0), 100)) / 100]
      as CFDictionary
    CGImageDestinationAddImage(destination, image, options)
    return CGImageDestinationFinalize(destination) ? data as Data : nil
  }

  private static func url(for path: String) -> URL {
    path.hasPrefix("file://") ? URL(string: path)! : URL(fileURLWithPath: path)
  }

  /// Re-encodes [startMs, endMs) of the video at the highest quality preset,
  /// which cuts on the exact frame regardless of where the keyframes are.
  private static func trim(
    path: String, outputPath: String, startMs: Int64, endMs: Int64,
    completion: @escaping (Error?) -> Void
  ) {
    let asset = AVURLAsset(url: url(for: path))
    guard
      let session = AVAssetExportSession(
        asset: asset, presetName: AVAssetExportPresetHighestQuality)
    else {
      completion(TrimError.message("This video cannot be exported on this device."))
      return
    }
    let output = URL(fileURLWithPath: outputPath)
    // The export fails outright if the destination already exists.
    try? FileManager.default.removeItem(at: output)
    let type: AVFileType
    switch output.pathExtension.lowercased() {
    case "mov": type = .mov
    case "m4v": type = .m4v
    default: type = .mp4
    }
    session.timeRange = CMTimeRange(
      start: CMTime(value: startMs, timescale: 1000),
      end: CMTime(value: endMs, timescale: 1000))
    session.shouldOptimizeForNetworkUse = true

    if #available(iOS 18.0, macOS 15.0, *) {
      Task {
        do {
          try await session.export(to: output, as: type)
          completion(nil)
        } catch {
          completion(error)
        }
      }
    } else {
      session.outputURL = output
      session.outputFileType = type
      session.exportAsynchronously {
        switch session.status {
        case .completed: completion(nil)
        case .cancelled: completion(TrimError.message("The export was cancelled."))
        default: completion(session.error ?? TrimError.message("The export failed."))
        }
      }
    }
  }

  private enum TrimError: LocalizedError {
    case message(String)
    var errorDescription: String? {
      switch self {
      case .message(let text): return text
      }
    }
  }

  private func generator(for path: String, maxWidth: Int, maxHeight: Int) -> AVAssetImageGenerator {
    let generator: AVAssetImageGenerator
    if let cached = self.generator, generatorPath == path {
      generator = cached
    } else {
      generator = AVAssetImageGenerator(asset: AVURLAsset(url: Self.url(for: path)))
      // Without this, portrait recordings come back sideways.
      generator.appliesPreferredTrackTransform = true
      // Exact frames, matching what the scrubber shows at that timestamp.
      generator.requestedTimeToleranceBefore = .zero
      generator.requestedTimeToleranceAfter = .zero
      self.generator = generator
      generatorPath = path
    }
    // `maximumSize` fits the frame inside the box keeping its aspect ratio, so
    // an unbounded side just needs to be large enough never to bind.
    let unbounded = CGFloat(max(maxWidth, maxHeight, 1) * 20)
    if maxWidth > 0 || maxHeight > 0 {
      generator.maximumSize = CGSize(
        width: maxWidth > 0 ? CGFloat(maxWidth) : unbounded,
        height: maxHeight > 0 ? CGFloat(maxHeight) : unbounded)
    } else {
      generator.maximumSize = .zero
    }
    return generator
  }

  private static func image(
    from generator: AVAssetImageGenerator, at time: CMTime,
    completion: @escaping (CGImage?, Error?) -> Void
  ) {
    if #available(iOS 16.0, macOS 13.0, *) {
      generator.generateCGImageAsynchronously(for: time) { image, _, error in
        completion(image, error)
      }
    } else {
      do {
        completion(try generator.copyCGImage(at: time, actualTime: nil), nil)
      } catch {
        completion(nil, error)
      }
    }
  }
}
