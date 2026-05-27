import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../services/camera_service.dart';
import '../services/socket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/slide_header.dart';
import '../widgets/log_panel.dart';

class TabMlKit extends StatefulWidget {
  const TabMlKit({super.key});

  @override
  State<TabMlKit> createState() => _TabMlKitState();
}

class _TabMlKitState extends State<TabMlKit> {
  final _cam    = CameraService();
  final _socket = SocketService();
  final _log    = <LogEntry>[];

  late BarcodeScanner _scanner;
  bool _scanActive = false;
  bool _processing = false;
  String _fps = '—';
  int _frameCount = 0;
  DateTime _lastFpsUpdate = DateTime.now();

  // Último código detectado
  Barcode? _lastBarcode;

  @override
  void initState() {
    super.initState();
    _scanner = BarcodeScanner();
    _socket.emitTabChange(7);
    _addLog('ML Kit BarcodeScanner listo', kTextDim);
    _addLog('Formato: ALL_FORMATS habilitados', kTextDim);
  }

  @override
  void dispose() {
    _stopScan();
    _scanner.close();
    super.dispose();
  }

  void _addLog(String msg, Color color) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, LogEntry(msg, color));
      if (_log.length > 20) _log.removeLast();
    });
  }

  // ── Iniciar escaneo en tiempo real ────────────────────────────────────
  Future<void> _startScan() async {
    if (!_cam.initialized || _scanActive) return;
    setState(() => _scanActive = true);
    _addLog('ImageAnalysis pipeline iniciado · YUV_420_888', kCyan);
    await _cam.startImageStream(_onCameraImage);
  }

  void _stopScan() {
    if (!_scanActive) return;
    _scanActive = false;
    _cam.stopImageStream();
  }

  // ── Procesar frame del stream ─────────────────────────────────────────
  void _onCameraImage(CameraImage image) async {
    if (_processing || !mounted) return;
    _processing = true;

    // Actualizar FPS cada segundo
    _frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(_lastFpsUpdate).inMilliseconds;
    if (elapsed >= 1000) {
      final fps = (_frameCount * 1000 / elapsed).round();
      _frameCount = 0;
      _lastFpsUpdate = now;
      if (mounted) setState(() => _fps = '$fps');
    }

    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) { _processing = false; return; }

      final barcodes = await _scanner.processImage(inputImage);

      if (barcodes.isNotEmpty && mounted) {
        final barcode = barcodes.first;
        if (barcode.rawValue != _lastBarcode?.rawValue) {
          setState(() => _lastBarcode = barcode);
          _handleDetection(barcode);
        }
      }
    } catch (_) {
      // Frame descartado — continúa con el siguiente
    } finally {
      _processing = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image) {
    try {
      // A-2: guard null — si el controlador fue liberado, descartar el frame
      final controller = _cam.controller;
      if (controller == null) return null;

      // Concatenar todos los planos YUV
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final rotation = _sensorRotation(
        controller.description.sensorOrientation,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.yuv_420_888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  InputImageRotation _sensorRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:  return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default:  return InputImageRotation.rotation0deg;
    }
  }

  void _handleDetection(Barcode barcode) {
    final tipo   = _barcodeTypeName(barcode.type);
    final valor  = barcode.rawValue ?? '—';
    final format = barcode.format.name.toUpperCase();

    _addLog('──────────────────────────────────', kTextMut);
    _addLog('>>> $tipo DETECTADO', kCyan);
    _addLog('  Valor  : "$valor"', kText);
    _addLog('  Formato: $format', kTextDim);
    _addLog('  Canal  : YUV_420_888 · planes[0]', kTextMut);

    _socket.emitMlKitResult(
      tipo: tipo,
      valor: valor,
      formato: format,
      confianza: 0.97,
      coordenadas: barcode.boundingBox != null
          ? {
              'x': barcode.boundingBox!.left.round(),
              'y': barcode.boundingBox!.top.round(),
            }
          : null,
    );
  }

  String _barcodeTypeName(BarcodeType type) {
    switch (type) {
      case BarcodeType.url:     return 'URL';
      case BarcodeType.text:    return 'TEXT';
      case BarcodeType.wifi:    return 'WIFI';
      case BarcodeType.email:   return 'EMAIL';
      case BarcodeType.phone:   return 'PHONE';
      case BarcodeType.sms:     return 'SMS';
      case BarcodeType.isbn:    return 'ISBN';
      default:                  return 'QR_CODE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SlideHeader(
          index: 7,
          title: 'Google ML Kit',
          subtitle: 'BarcodeScanning · YUV_420_888 · Edge AI',
          accent: kPurple,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Visor de cámara + overlay ML Kit
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _scanActive
                                  ? kPurple.withValues(alpha: 0.6)
                                  : kBorder,
                              width: _scanActive ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _cam.initialized &&
                                  _cam.controller!.value.isInitialized
                              ? CameraPreview(_cam.controller!)
                              : Container(
                                  color: kBgCard,
                                  child: const Center(
                                    child: Icon(Icons.qr_code_scanner,
                                        size: 64, color: kTextMut),
                                  ),
                                ),
                        ),
                      ),

                      // HUD superior: FPS + estado
                      Positioned(
                        top: 10, left: 10, right: 10,
                        child: Row(
                          children: [
                            _HudChip(
                              label: '$_fps FPS',
                              color: _scanActive ? kGreen : kTextMut,
                              icon: Icons.speed,
                            ),
                            const SizedBox(width: 6),
                            _HudChip(
                              label: _scanActive ? 'ESCANEANDO' : 'INACTIVO',
                              color: _scanActive ? kPurple : kTextMut,
                              icon: Icons.qr_code_scanner,
                            ),
                          ],
                        ),
                      ),

                      // Resultado del último código
                      if (_lastBarcode != null)
                        Positioned(
                          bottom: 10, left: 10, right: 10,
                          child: _BarcodeResult(barcode: _lastBarcode!),
                        ),

                      // Reticle de escaneo
                      if (_scanActive)
                        Center(
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: kPurple.withValues(alpha: 0.6), width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Controles
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _scanActive ? null : _startScan,
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('INICIAR ESCANEO'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPurple,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: kBgCard,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _scanActive ? _stopScan : null,
                        icon: const Icon(Icons.stop, size: 16),
                        label: const Text('DETENER'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kRed,
                          side: const BorderSide(color: kRed),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Pipeline steps
                _PipelineSteps(),
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

// ── Pipeline steps ─────────────────────────────────────────────────────────
class _PipelineSteps extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const steps = [
      ('📷', 'CameraImage'),
      ('📊', 'planes[0] Y'),
      ('🤖', 'ML Kit'),
      ('📡', 'Socket'),
    ];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.chevron_right, size: 14, color: kTextMut),
          );
        }
        final s = steps[i ~/ 2];
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: cardDecoration(borderColor: kBorder, radius: 8),
            child: Column(
              children: [
                Text(s.$1, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 2),
                Text(s.$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 8, color: kTextDim)),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── HUD chip ──────────────────────────────────────────────────────────────
class _HudChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _HudChip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
            fontSize: 9, color: color, fontWeight: FontWeight.w700,
          )),
        ],
      ),
    );
  }
}

// ── Resultado de barcode ──────────────────────────────────────────────────
class _BarcodeResult extends StatelessWidget {
  final Barcode barcode;
  const _BarcodeResult({required this.barcode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kCyan.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code, color: kCyan, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  barcode.format.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9, color: kCyan,
                    fontWeight: FontWeight.w700, letterSpacing: 1,
                  ),
                ),
                Text(
                  barcode.rawValue ?? '—',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
