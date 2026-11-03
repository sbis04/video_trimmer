import AVFoundation
import Flutter
import UIKit

/// Extracts JPEG thumbnails from local video files for the trim viewer.
///
/// The class name is deliberately specific: Flutter registers plugins by class
/// name, and generic names such as `VideoThumbnailPlugin` or
/// `VideoTrimmerPlugin` are already used by other packages. Two plugins with
/// the same name crash the app at launch on iOS.
public class VideoTrimmerThumbnailsPlugin: NSObject, FlutterPlugin {
  private let queue = DispatchQueue(label: "video_trimmer.thumbnails", qos: .userInitiated)

  // Only touched on `queue`. The trim viewer asks for many frames of the same
  // file in a row, so the generator is kept between calls.
  private var generator: AVAssetImageGenerator?
  private var generatorPath: String?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "video_trimmer/thumbnails", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(VideoTrimmerThumbnailsPlugin(), channel: channel)
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
          if let image = image,
            let data = UIImage(cgImage: image).jpegData(
              compressionQuality: CGFloat(min(max(quality, 0), 100)) / 100)
          {
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

  private func generator(for path: String, maxWidth: Int, maxHeight: Int) -> AVAssetImageGenerator {
    let generator: AVAssetImageGenerator
    if let cached = self.generator, generatorPath == path {
      generator = cached
    } else {
      let url = path.hasPrefix("file://") ? URL(string: path)! : URL(fileURLWithPath: path)
      generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
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
    if #available(iOS 16.0, *) {
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
