import 'package:camera/camera.dart';

/// Singleton que gestiona el único CameraController de la app.
/// Garantiza que no se abran dos sesiones de cámara simultáneamente.
class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _initialized = false;
  bool _streamActive = false;

  CameraController? get controller => _controller;
  List<CameraDescription> get cameras => _cameras;
  bool get initialized => _initialized;
  bool get streamActive => _streamActive;

  // ── Inicializar ────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;

    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    _controller = CameraController(
      _cameras.first,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.yuv420,
      enableAudio: false,
    );

    await _controller!.initialize();
    _initialized = true;
  }

  // ── Captura de foto ────────────────────────────────────────────────────
  Future<XFile?> takePicture() async {
    if (!_initialized || _controller == null) return null;
    if (_streamActive) await stopImageStream();
    try {
      final file = await _controller!.takePicture();
      return file;
    } catch (_) {
      return null;
    }
  }

  // ── Stream de imágenes (para ML Kit) ──────────────────────────────────
  Future<void> startImageStream(void Function(CameraImage) onImage) async {
    if (!_initialized || _controller == null || _streamActive) return;
    _streamActive = true;
    await _controller!.startImageStream(onImage);
  }

  Future<void> stopImageStream() async {
    if (!_initialized || _controller == null || !_streamActive) return;
    _streamActive = false;
    await _controller!.stopImageStream();
  }

  // ── Preview pause/resume (en cambios de ciclo de vida) ────────────────
  Future<void> pausePreview() async {
    if (!_initialized || _controller == null) return;
    try { await _controller!.pausePreview(); } catch (_) {}
  }

  Future<void> resumePreview() async {
    if (!_initialized || _controller == null) return;
    try { await _controller!.resumePreview(); } catch (_) {}
  }

  // ── Características legibles ───────────────────────────────────────────
  Map<String, dynamic> getCharacteristics() {
    if (!_initialized || _controller == null) return {};
    final desc = _controller!.description;
    final size = _controller!.value.previewSize;

    return {
      'cameraCount': _cameras.length,
      'lensDirection': desc.lensDirection.name,
      'sensorOrientation': desc.sensorOrientation,
      'previewWidth': size?.width.toInt() ?? 0,
      'previewHeight': size?.height.toInt() ?? 0,
      'cameraId': desc.name,
    };
  }

  // ── Liberar ────────────────────────────────────────────────────────────
  Future<void> dispose() async {
    if (_streamActive) await stopImageStream();
    await _controller?.dispose();
    _controller = null;
    _initialized = false;
  }
}
