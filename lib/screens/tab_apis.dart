import 'package:flutter/material.dart';

import '../services/socket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/slide_header.dart';
import '../widgets/log_panel.dart';

class TabApis extends StatefulWidget {
  const TabApis({super.key});

  @override
  State<TabApis> createState() => _TabApisState();
}

class _TabApisState extends State<TabApis> {
  final _log = <LogEntry>[];
  bool _runningNative = false;
  bool _runningFlutter = false;
  int? _nativeMs;
  int? _flutterMs;

  @override
  void initState() {
    super.initState();
    SocketService().emitTabChange(3);
    _addLog('Comparativa de APIs lista', kTextDim);
  }

  void _addLog(String msg, Color color) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, LogEntry(msg, color));
      if (_log.length > 20) _log.removeLast();
    });
  }

  Future<void> _simNative() async {
    if (_runningNative) return;
    setState(() { _runningNative = true; _nativeMs = null; });
    _addLog('Platform Channel → abriendo sesión...', kTextMut);
    await Future.delayed(const Duration(milliseconds: 200));
    _addLog('camera2 API → CameraManager.openCamera()', kOrange);
    await Future.delayed(const Duration(milliseconds: 180));
    _addLog('Registrando CameraDevice.StateCallback...', kOrange);
    await Future.delayed(const Duration(milliseconds: 220));
    _addLog('Creando CaptureSession...', kOrange);
    await Future.delayed(const Duration(milliseconds: 240));
    _addLog('Configurando CaptureRequest.Builder...', kOrange);
    await Future.delayed(const Duration(milliseconds: 180));
    _addLog('Iniciando preview — listo (≈ 1020ms)', kRed);
    setState(() { _runningNative = false; _nativeMs = 1020; });
  }

  Future<void> _simFlutter() async {
    if (_runningFlutter) return;
    setState(() { _runningFlutter = true; _flutterMs = null; });
    _addLog('Flutter camera: ^0.10 → init...', kTextMut);
    await Future.delayed(const Duration(milliseconds: 60));
    _addLog('CameraController.initialize() — listo (≈ 74ms)', kGreen);
    setState(() { _runningFlutter = false; _flutterMs = 74; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SlideHeader(
          index: 3,
          title: 'APIs de Cámara en Android',
          subtitle: 'Platform Channel nativo vs Flutter camera package',
          accent: kPurple,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Tarjetas comparativas
                Expanded(
                  flex: 5,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _NativeCard(
                        running: _runningNative,
                        resultMs: _nativeMs,
                        onTap: _simNative,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _FlutterCard(
                        running: _runningFlutter,
                        resultMs: _flutterMs,
                        onTap: _simFlutter,
                      )),
                    ],
                  ),
                ),
                // Estadísticas de reducción si ambas corrieron
                if (_nativeMs != null && _flutterMs != null) ...[
                  const SizedBox(height: 10),
                  _StatsRow(nativeMs: _nativeMs!, flutterMs: _flutterMs!),
                ],
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

// ── Tarjeta: Platform Channel nativo ─────────────────────────────────────
class _NativeCard extends StatelessWidget {
  final bool running;
  final int? resultMs;
  final VoidCallback onTap;
  const _NativeCard({required this.running, required this.resultMs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: cardDecoration(borderColor: kOrange.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: kRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: kRed.withValues(alpha: 0.4)),
                ),
                child: const Text('Kotlin nativo',
                    style: TextStyle(fontSize: 9, color: kRed, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Platform Channel\n+ camera2 API',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kOrange)),
          const SizedBox(height: 8),
          ..._codeSnippet(),
          const Spacer(),
          if (resultMs != null)
            _TimingBadge(ms: resultMs!, color: kRed),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: running ? null : onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kOrange),
                foregroundColor: kOrange,
              ),
              child: running
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: kOrange))
                  : const Text('SIMULAR', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _codeSnippet() => [
    '// ~280 líneas de código',
    'CameraManager mgr =',
    '  getSystemService(',
    '    CAMERA_SERVICE);',
    'mgr.openCamera(id,',
    '  callback, handler);',
    '// CaptureRequest...',
    '// StateCallback...',
  ].map((line) => Text(line, style: const TextStyle(
    fontFamily: 'monospace', fontSize: 9, color: kTextDim, height: 1.6,
  ))).toList();
}

// ── Tarjeta: Flutter camera package ──────────────────────────────────────
class _FlutterCard extends StatelessWidget {
  final bool running;
  final int? resultMs;
  final VoidCallback onTap;
  const _FlutterCard({required this.running, required this.resultMs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: glowDecoration(kGreen, radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: kGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: kGreen.withValues(alpha: 0.4)),
                ),
                child: const Text('Flutter · Dart',
                    style: TextStyle(fontSize: 9, color: kGreen, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('camera: ^0.10\npackage pub.dev',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kGreen)),
          const SizedBox(height: 8),
          ..._codeSnippet(),
          const Spacer(),
          if (resultMs != null)
            _TimingBadge(ms: resultMs!, color: kGreen),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: running ? null : onTap,
              child: running
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: kBg))
                  : const Text('SIMULAR', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _codeSnippet() => [
    '// ~35 líneas de código',
    'final ctrl =',
    '  CameraController(',
    '    cameras[0],',
    '    ResolutionPreset',
    '      .high,',
    '  );',
    'await ctrl.initialize();',
  ].map((line) => Text(line, style: const TextStyle(
    fontFamily: 'monospace', fontSize: 9, color: kTextDim, height: 1.6,
  ))).toList();
}

// ── Badge de timing ───────────────────────────────────────────────────────
class _TimingBadge extends StatelessWidget {
  final int ms;
  final Color color;
  const _TimingBadge({required this.ms, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '⏱ ${ms}ms',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: color,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// ── Fila de estadísticas ──────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int nativeMs;
  final int flutterMs;
  const _StatsRow({required this.nativeMs, required this.flutterMs});

  @override
  Widget build(BuildContext context) {
    final codeSaving = 87;
    final timeSaving = (((nativeMs - flutterMs) / nativeMs) * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: glowDecoration(kCyan, radius: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat('-$codeSaving%', 'menos código'),
          Container(width: 1, height: 30, color: kBorder),
          _Stat('-$timeSaving%', 'tiempo init'),
          Container(width: 1, height: 30, color: kBorder),
          _Stat('×1', 'línea flutter'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w900, color: kCyan,
            )),
        Text(label,
            style: const TextStyle(fontSize: 9, color: kTextDim)),
      ],
    );
  }
}
