import 'package:flutter/material.dart';

import '../services/camera_service.dart';
import '../services/socket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/slide_header.dart';
import '../widgets/log_panel.dart';

class TabHal extends StatefulWidget {
  const TabHal({super.key});

  @override
  State<TabHal> createState() => _TabHalState();
}

class _TabHalState extends State<TabHal> {
  final _socket = SocketService();
  final _log = <LogEntry>[];
  String _activeLayer = 'hal';

  static const _layers = [
    _Layer('app',       '🔷', 'Application Layer',               'Flutter · Widget Tree · camera: ^0.10',   kPurple),
    _Layer('framework', '⚙️',  'Framework / SDK Layer',           'Platform Channel · Dart FFI · pub.dev',   kBlue),
    _Layer('hal',       '🔌', 'Hardware Abstraction Layer (HAL)', 'android.hardware.camera.provider@2.7',    kCyan),
    _Layer('driver',    '💾', 'Kernel Driver Layer',              'V4L2 · DMA Buffers · IRQ Handlers',       kOrange),
    _Layer('kernel',    '🔩', 'Linux Kernel · Hardware',          'CMOS Sensor · ISP · MIPI CSI-2',          kGreen),
  ];

  @override
  void initState() {
    super.initState();
    _addLog('Sistema de capas inicializado', kTextDim);
    _sendTabChange();
  }

  void _sendTabChange() {
    SocketService().emitTabChange(1);
  }

  void _addLog(String msg, Color color) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, LogEntry(msg, color));
      if (_log.length > 20) _log.removeLast();
    });
  }

  void _activateLayer(String id) {
    final layer = _layers.firstWhere((l) => l.id == id);
    setState(() => _activeLayer = id);

    final chars = CameraService().getCharacteristics();
    _socket.emitHalInfo(
      capa: id,
      focalLength: _typicalFocalLength(id),
      aperture: _typicalAperture(id),
      nivelSoporte: 'FULL',
      sensorOrientation: chars['sensorOrientation'] as int?,
      cameraCount: chars['cameraCount'] as int?,
      lensDirection: chars['lensDirection'] as String?,
      previewSize: chars.containsKey('previewWidth')
          ? '${chars['previewWidth']}x${chars['previewHeight']}'
          : null,
    );
    _addLog('Capa activa → ${layer.name}', layer.color);
  }

  void _readHardware() {
    final cam = CameraService();
    if (!cam.initialized) {
      _addLog('⚠ Cámara no inicializada', kRed);
      return;
    }
    final c = cam.getCharacteristics();
    _addLog('Cámaras detectadas: ${c['cameraCount']}', kCyan);
    _addLog('Sensor: ${c['lensDirection']} · ${c['sensorOrientation']}°', kCyan);
    _addLog('Preview: ${c['previewWidth']}×${c['previewHeight']}', kCyan);
    _addLog('ID de cámara: ${c['cameraId']}', kTextDim);

    _socket.emitHalInfo(
      capa: _activeLayer,
      focalLength: 4.3,
      aperture: 1.8,
      nivelSoporte: 'FULL',
      sensorOrientation: c['sensorOrientation'] as int?,
      cameraCount: c['cameraCount'] as int?,
      lensDirection: c['lensDirection'] as String?,
      previewSize: '${c['previewWidth']}x${c['previewHeight']}',
    );
  }

  double? _typicalFocalLength(String layer) =>
      layer == 'kernel' || layer == 'driver' ? 4.3 : null;
  double? _typicalAperture(String layer) =>
      layer == 'kernel' || layer == 'driver' ? 1.8 : null;

  @override
  Widget build(BuildContext context) {
    final activeData = _layers.firstWhere((l) => l.id == _activeLayer);

    return Column(
      children: [
        const SlideHeader(
          index: 1,
          title: 'Arquitectura de Capas HAL',
          subtitle: 'Del widget Flutter hasta el silicio',
          accent: kCyan,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Stack de capas — Column para altura natural (no ListView)
                for (int i = 0; i < _layers.length; i++) ...[
                  _LayerCard(
                    layer: _layers[i],
                    isActive: _layers[i].id == _activeLayer,
                    onTap: () => _activateLayer(_layers[i].id),
                  ),
                  if (i < _layers.length - 1) const _LayerConnector(),
                ],
                const SizedBox(height: 10),
                // Panel info de la capa activa
                _ActiveLayerPanel(layer: activeData),
                const SizedBox(height: 10),
                // Botón leer hardware
                ElevatedButton.icon(
                  onPressed: _readHardware,
                  icon: const Icon(Icons.memory, size: 16),
                  label: const Text('LEER CARACTERÍSTICAS HAL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCyan.withValues(alpha: 0.15),
                    foregroundColor: kCyan,
                    side: const BorderSide(color: kCyan, width: 1),
                  ),
                ),
                const SizedBox(height: 10),
                // Log
                SizedBox(
                  height: 130,
                  child: LogPanel(entries: _log.map((e) => LogEntry(e.msg, e.color)).toList()),
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

class _Layer {
  final String id;
  final String icon;
  final String name;
  final String desc;
  final Color color;
  const _Layer(this.id, this.icon, this.name, this.desc, this.color);
}

// _LogEntry es un alias privado — LogEntry de log_panel.dart se usa externamente.

class _LayerCard extends StatelessWidget {
  final _Layer layer;
  final bool isActive;
  final VoidCallback onTap;

  const _LayerCard({
    required this.layer,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? layer.color.withValues(alpha: 0.08)
              : kBgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: layer.color, width: isActive ? 4 : 2),
            top: BorderSide(
                color: isActive ? layer.color.withValues(alpha: 0.4) : kBorder),
            right: BorderSide(
                color: isActive ? layer.color.withValues(alpha: 0.4) : kBorder),
            bottom: BorderSide(
                color: isActive ? layer.color.withValues(alpha: 0.4) : kBorder),
          ),
          boxShadow: isActive
              ? [BoxShadow(color: layer.color.withValues(alpha: 0.15), blurRadius: 12)]
              : null,
        ),
        child: Row(
          children: [
            Text(layer.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    layer.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? layer.color : kText,
                    ),
                  ),
                  Text(
                    layer.desc,
                    style: const TextStyle(
                      fontSize: 10,
                      color: kTextDim,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: layer.color,
                  boxShadow: [
                    BoxShadow(color: layer.color.withValues(alpha: 0.7), blurRadius: 8),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LayerConnector extends StatelessWidget {
  const _LayerConnector();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(width: 2, height: 6, color: kBorder),
    );
  }
}

class _ActiveLayerPanel extends StatelessWidget {
  final _Layer layer;
  const _ActiveLayerPanel({required this.layer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: glowDecoration(layer.color, radius: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CAPA ACTIVA',
            style: TextStyle(
              fontSize: 9,
              color: layer.color.withValues(alpha: 0.7),
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            layer.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: layer.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(layer.desc, style: const TextStyle(fontSize: 11, color: kTextDim)),
        ],
      ),
    );
  }
}
