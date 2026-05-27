import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../services/camera_service.dart';
import '../services/socket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/slide_header.dart';
import '../widgets/log_panel.dart';

class TabPipeline extends StatefulWidget {
  const TabPipeline({super.key});

  @override
  State<TabPipeline> createState() => _TabPipelineState();
}

class _TabPipelineState extends State<TabPipeline> {
  final _cam = CameraService();
  final _socket = SocketService();
  final _log = <LogEntry>[];

  bool _previewActive = false;
  bool _analysisActive = false;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _socket.emitTabChange(5);
    _addLog('Pipeline de CameraX listo', kTextDim);
    if (_cam.initialized) {
      _startStream();
    } else {
      _addLog('⚠ Cámara no disponible', kRed);
    }
  }

  @override
  void dispose() {
    _cam.stopImageStream(); // A-3: liberar stream al salir del tab
    super.dispose();
  }

  void _addLog(String msg, Color color) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, LogEntry(msg, color));
      if (_log.length > 20) _log.removeLast();
    });
  }

  void _startStream() {
    setState(() {
      _previewActive = true;
      _analysisActive = true;
    });
    _socket.emitCaptureStart();
    _addLog('Preview Surface → stream a 30 FPS · GPU', kYellow);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _addLog('Analysis Surface → buffer YUV_420_888 · RAM', kGreen);
    });
  }

  Future<void> _capture() async {
    if (_capturing || !_cam.initialized) return;
    setState(() => _capturing = true);

    _socket.emitCapture();
    _addLog('Capture Surface → frame congelado · máx resolución', kOrange);

    final file = await _cam.takePicture();
    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      setState(() => _capturing = false);
      if (file != null) {
        _addLog('JPEG guardado · ${file.path.split('/').last}', kGreen);
      } else {
        _addLog('⚠ Error en captura', kRed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SlideHeader(
          index: 5,
          title: 'Pipeline de Captura',
          subtitle: 'Preview · Capture · Analysis — tres superficies simultáneas',
          accent: kOrange,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Vista de cámara
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _previewActive
                              ? kYellow.withValues(alpha: 0.5)
                              : kBorder,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _cam.initialized && _cam.controller!.value.isInitialized
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                CameraPreview(_cam.controller!),
                                // Overlay de superficies activas
                                Positioned(
                                  top: 8, left: 8,
                                  child: _SurfaceChip('PREVIEW', kYellow, _previewActive),
                                ),
                                Positioned(
                                  top: 8, right: 8,
                                  child: _SurfaceChip('ANALYSIS', kGreen, _analysisActive),
                                ),
                                if (_capturing)
                                  Container(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    child: const Center(
                                      child: Icon(Icons.camera, color: Colors.white, size: 48),
                                    ),
                                  ),
                              ],
                            )
                          : Container(
                              color: kBgCard,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.videocam_off_outlined,
                                        size: 48, color: kTextMut),
                                    SizedBox(height: 8),
                                    Text('Cámara no disponible',
                                        style: TextStyle(color: kTextMut, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Superficies del pipeline
                Row(
                  children: [
                    _SurfaceCard(
                      label: 'Preview Surface',
                      sub: '30 FPS · GPU',
                      color: kYellow,
                      active: _previewActive,
                    ),
                    const SizedBox(width: 6),
                    _SurfaceCard(
                      label: 'Capture Surface',
                      sub: 'JPEG · Full Res',
                      color: kOrange,
                      active: _capturing,
                    ),
                    const SizedBox(width: 6),
                    _SurfaceCard(
                      label: 'Analysis Surface',
                      sub: 'YUV_420_888 · RAM',
                      color: kGreen,
                      active: _analysisActive,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _previewActive ? null : _startStream,
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('INICIAR STREAM'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kYellow,
                          side: const BorderSide(color: kYellow),
                          disabledForegroundColor: kTextMut,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _capturing ? null : _capture,
                        icon: _capturing
                            ? const SizedBox(width: 14, height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: kBg))
                            : const Icon(Icons.camera_alt, size: 16),
                        label: const Text('CAPTURAR'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Expanded(
                  flex: 2,
                  child: LogPanel(entries: _log),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────
class _SurfaceChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  const _SurfaceChip(this.label, this.color, this.active);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: active ? 1.0 : 0.3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? color : kTextMut,
                boxShadow: active
                    ? [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 6)]
                    : null,
              ),
            ),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(
              fontSize: 9, color: color, fontWeight: FontWeight.w700,
            )),
          ],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;
  final bool active;
  const _SurfaceCard({
    required this.label, required this.sub,
    required this.color, required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.08) : kBgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.5) : kBorder,
          ),
          boxShadow: active
              ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: active ? color : kTextDim,
                )),
            Text(sub,
                style: const TextStyle(fontSize: 8, color: kTextMut)),
            const SizedBox(height: 4),
            Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: active ? color : kBorder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
