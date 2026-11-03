package com.souvikbiswas.video_trimmer;

import android.content.Context;
import android.graphics.Bitmap;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;
import androidx.annotation.OptIn;
import androidx.media3.common.MediaItem;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.transformer.Composition;
import androidx.media3.transformer.EditedMediaItem;
import androidx.media3.transformer.ExportException;
import androidx.media3.transformer.ExportResult;
import androidx.media3.transformer.Transformer;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * The package's native side on Android: JPEG thumbnails for the trim viewer
 * ({@code video_trimmer/thumbnails}) and trimming with Media3 Transformer
 * ({@code video_trimmer/trim}).
 *
 * <p>The class name is deliberately specific: Flutter registers plugins by
 * class name, and generic names such as {@code VideoThumbnailPlugin} or
 * {@code VideoTrimmerPlugin} are already used by other packages.
 */
public class VideoTrimmerNativePlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    private static final String THUMBNAIL_CHANNEL = "video_trimmer/thumbnails";
    private static final String TRIM_CHANNEL = "video_trimmer/trim";

    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private MethodChannel channel;
    private MethodChannel trimChannel;
    // Held while an export runs; Transformer is only used on the main thread.
    private Transformer transformer;
    private ExecutorService executor;
    private Context context;

    // Only touched on [executor]. The trim viewer asks for many frames of the
    // same file in a row, so the retriever is kept open between calls.
    private MediaMetadataRetriever retriever;
    private String retrieverPath;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        executor = Executors.newSingleThreadExecutor();
        channel = new MethodChannel(binding.getBinaryMessenger(), THUMBNAIL_CHANNEL);
        channel.setMethodCallHandler(this);
        trimChannel = new MethodChannel(binding.getBinaryMessenger(), TRIM_CHANNEL);
        trimChannel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
        trimChannel.setMethodCallHandler(null);
        trimChannel = null;
        if (transformer != null) {
            transformer.cancel();
            transformer = null;
        }
        executor.execute(this::releaseRetriever);
        executor.shutdown();
        executor = null;
        context = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "thumbnail":
                final String path = call.argument("path");
                if (path == null) {
                    result.error("bad_args", "path is required", null);
                    return;
                }
                final long timeMs = asLong(call.argument("timeMs"), 0);
                final int maxWidth = (int) asLong(call.argument("maxWidth"), 0);
                final int maxHeight = (int) asLong(call.argument("maxHeight"), 0);
                final int quality = (int) asLong(call.argument("quality"), 75);
                executor.execute(() -> {
                    try {
                        final byte[] bytes = thumbnail(path, timeMs, maxWidth, maxHeight, quality);
                        mainHandler.post(() -> result.success(bytes));
                    } catch (Exception e) {
                        mainHandler.post(() -> result.error("thumbnail_failed", String.valueOf(e.getMessage()), path));
                    }
                });
                break;
            case "trim":
                trim(call, result);
                break;
            case "release":
                executor.execute(() -> {
                    releaseRetriever();
                    mainHandler.post(() -> result.success(null));
                });
                break;
            default:
                result.notImplemented();
        }
    }

    /**
     * Exports [startMs, endMs) of the video to an MP4 at {@code outputPath}.
     * Trim optimization copies the samples that need no re-encoding, so a cut
     * near keyframes is fast and lossless; the rest is transcoded.
     */
    @OptIn(markerClass = UnstableApi.class)
    private void trim(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        final String path = call.argument("path");
        final String outputPath = call.argument("outputPath");
        final Object start = call.argument("startMs");
        final Object end = call.argument("endMs");
        if (path == null || outputPath == null || !(start instanceof Number) || !(end instanceof Number)) {
            result.error("bad_args", "path, outputPath, startMs and endMs are required", null);
            return;
        }
        if (transformer != null) {
            result.error("trim_busy", "Another trim is still running.", path);
            return;
        }
        final long startMs = ((Number) start).longValue();
        final long endMs = ((Number) end).longValue();
        // Transformer must be created and driven on a thread with a Looper.
        mainHandler.post(() -> {
            try {
                final File output = new File(outputPath);
                if (output.exists() && !output.delete()) {
                    result.error("trim_failed", "Cannot overwrite " + outputPath, path);
                    return;
                }
                final MediaItem item = new MediaItem.Builder()
                        .setUri(toUri(path))
                        .setClippingConfiguration(new MediaItem.ClippingConfiguration.Builder()
                                .setStartPositionMs(startMs)
                                .setEndPositionMs(endMs)
                                .build())
                        .build();
                transformer = new Transformer.Builder(context)
                        .experimentalSetTrimOptimizationEnabled(true)
                        .addListener(new Transformer.Listener() {
                            @Override
                            public void onCompleted(@NonNull Composition composition,
                                                    @NonNull ExportResult exportResult) {
                                transformer = null;
                                result.success(outputPath);
                            }

                            @Override
                            public void onError(@NonNull Composition composition,
                                                @NonNull ExportResult exportResult,
                                                @NonNull ExportException exception) {
                                transformer = null;
                                result.error("trim_failed", String.valueOf(exception.getMessage()), path);
                            }
                        })
                        .build();
                transformer.start(new EditedMediaItem.Builder(item).build(), outputPath);
            } catch (RuntimeException e) {
                transformer = null;
                result.error("trim_failed", String.valueOf(e.getMessage()), path);
            }
        });
    }

    private static Uri toUri(String path) {
        if (path.startsWith("content://") || path.startsWith("file://")) return Uri.parse(path);
        return Uri.fromFile(new File(path));
    }

    private byte[] thumbnail(String path, long timeMs, int maxWidth, int maxHeight, int quality) {
        if (retriever == null || !path.equals(retrieverPath)) {
            releaseRetriever();
            retriever = new MediaMetadataRetriever();
            if (path.startsWith("content://") || path.startsWith("file://")) {
                retriever.setDataSource(context, Uri.parse(path));
            } else {
                retriever.setDataSource(path);
            }
            retrieverPath = path;
        }

        final long timeUs = timeMs * 1000L;
        Bitmap frame = retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST);
        if (frame == null) {
            // OPTION_CLOSEST can come back empty for timestamps in the last
            // few frames; the nearest sync frame is close enough there.
            frame = retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST_SYNC);
        }
        if (frame == null) {
            throw new IllegalStateException("No frame at " + timeMs + " ms");
        }

        final Bitmap scaled = scaleToFit(frame, maxWidth, maxHeight);
        final ByteArrayOutputStream out = new ByteArrayOutputStream();
        scaled.compress(Bitmap.CompressFormat.JPEG, clamp(quality, 0, 100), out);
        if (scaled != frame) scaled.recycle();
        frame.recycle();
        return out.toByteArray();
    }

    /** Scales down, never up, so the frame fits inside the given box. 0 means unbounded. */
    private static Bitmap scaleToFit(Bitmap src, int maxWidth, int maxHeight) {
        final int w = src.getWidth();
        final int h = src.getHeight();
        double scale = 1.0;
        if (maxWidth > 0 && w > maxWidth) scale = Math.min(scale, (double) maxWidth / w);
        if (maxHeight > 0 && h > maxHeight) scale = Math.min(scale, (double) maxHeight / h);
        if (scale >= 1.0) return src;
        final int dw = Math.max(1, (int) Math.round(w * scale));
        final int dh = Math.max(1, (int) Math.round(h * scale));
        return Bitmap.createScaledBitmap(src, dw, dh, true);
    }

    private void releaseRetriever() {
        if (retriever != null) {
            try {
                retriever.release();
            } catch (IOException | RuntimeException ignored) {
                // Nothing useful to do; the retriever is being discarded.
            }
        }
        retriever = null;
        retrieverPath = null;
    }

    private static long asLong(Object value, long fallback) {
        return value instanceof Number ? ((Number) value).longValue() : fallback;
    }

    private static int clamp(int v, int lo, int hi) {
        return Math.max(lo, Math.min(hi, v));
    }
}
