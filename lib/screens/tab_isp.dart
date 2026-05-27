import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../services/socket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/slide_header.dart';
import '../widgets/log_panel.dart';

class TabIsp extends StatefulWidget {
  const TabIsp({super.key});

  @override
  State<TabIsp> createState() => _TabIspState();
}

class _TabIspState extends State<TabIsp> with SingleTickerProviderStateMixin {
  final _socket = SocketService();
  double _wbTemp = 5500;
  int _activeStep = 0;
  late AnimationController _stepCtrl;
  final _log = <LogEntry>[];

  static const _steps = ['Demosaicing', 'Noise Reduction', 'White Balance', 'Tonemapping'];
  static const _stepColors = [kCyan, kBlue, kOrange, kGreen];

  @override
  void initState() {
    super.initState();
    _socket.emitTabChange(2);
    _addLog('Pipeline ISP listo', kTextDim);

    _stepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() {
        if (_stepCtrl.isCompleted) {
          if (mounted) {
            setState(() => _activeStep = (_activeStep + 1) % 4);
            _stepCtrl.forward(from: 0);
          }
        }
      });
    _stepCtrl.forward();
  }

  @override
  void dispose() {
    _stepCtrl.dispose();
    super.dispose();
  }

  void _addLog(String msg, Color color) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, LogEntry(msg, color));
      if (_log.length > 15) _log.removeLast();
    });
  }

  void _sendWB() {
    final temp = _wbTemp.round();
    _socket.emitIspWhiteBalance(temp);
    _addLog('WB enviado → ${temp}K  ${_wbLabel(temp)}', kOrange);
  }

  String _wbLabel(int temp) {
    if (temp < 3000) return '(Tungsteno)';
    if (temp < 4000) return '(Cálido)';
    if (temp < 5000) return '(Fluorescente)';
    if (temp < 6000) return '(Luz día)';
    if (temp < 7000) return '(Nublado)';
    return '(Sombra)';
  }

  // Temperatura → color RGB simplificado
  Color _tempToColor(double temp) {
    final t = (temp - 2500) / (8000 - 2500); // 0.0 → 1.0
    final r = (255 * (1.0 - t * 0.35)).round().clamp(0, 255);
    final g = 210;
    final b = (80 + (175 * t)).round().clamp(0, 255);
    return Color.fromARGB(255, r, g, b);
  }

  // Colores del patrón Bayer RGGB
  Color _bayerColor(int row, int col, double temp) {
    final wbColor = _tempToColor(temp);
    final isRed  = row.isEven && col.isEven;
    final isBlue = row.isOdd  && col.isOdd;
    final v = 60 + math.Random(row * 8 + col).nextInt(80);
    if (isRed)  return Color.fromARGB(255, wbColor.r.round(), v ~/ 3, v ~/ 3);
    if (isBlue) return Color.fromARGB(255, v ~/ 3, v ~/ 3, wbColor.b.round());
    return Color.fromARGB(255, v ~/ 3, v, v ~/ 3); // Green
  }

  @override
  Widget build(BuildContext context) {
    final wbColor = _tempToColor(_wbTemp);
    final tempInt = _wbTemp.round();

    return Column(
      children: [
        const SlideHeader(
          index: 2,
          title: 'Image Signal Processor',
          subtitle: 'De fotones crudos a píxeles procesados',
          accent: kBlue,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Pipeline ISP steps
                Row(
                  children: List.generate(4, (i) {
                    final active = i == _activeStep;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? _stepColors[i].withValues(alpha: 0.15)
                              : kBgCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: active
                                ? _stepColors[i]
                                : kBorder,
                          ),
                          boxShadow: active
                              ? [BoxShadow(
                                  color: _stepColors[i].withValues(alpha: 0.3),
                                  blurRadius: 10,
                                )]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 9,
                                color: active ? _stepColors[i] : kTextMut,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _steps[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                color: active ? _stepColors[i] : kTextDim,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),

                // Bayer grid + WB swatch
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patrón Bayer 8×8
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SENSOR RAW · Patrón Bayer',
                            style: TextStyle(
                              fontSize: 9,
                              color: kTextDim,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AspectRatio(
                            aspectRatio: 1,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 8,
                                mainAxisSpacing: 2,
                                crossAxisSpacing: 2,
                              ),
                              itemCount: 64,
                              itemBuilder: (_, idx) {
                                final row = idx ~/ 8;
                                final col = idx % 8;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: _bayerColor(row, col, _wbTemp),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // WB info + swatch
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BALANCE DE BLANCOS',
                            style: TextStyle(
                              fontSize: 9,
                              color: kTextDim,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Swatch de color resultante
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: wbColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kBorder),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Temperatura actual
                          Text(
                            '${tempInt}K',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: wbColor,
                            ),
                          ),
                          Text(
                            _wbLabel(tempInt),
                            style: const TextStyle(fontSize: 11, color: kTextDim),
                          ),
                          const SizedBox(height: 12),
                          // Rangos de referencia
                          ..._wbReference(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Slider de temperatura
                Row(
                  children: [
                    const Text('2500K', style: TextStyle(fontSize: 10, color: kTextMut)),
                    Expanded(
                      child: Slider(
                        value: _wbTemp,
                        min: 2500,
                        max: 8000,
                        divisions: 55,
                        label: '${_wbTemp.round()}K',
                        onChanged: (v) => setState(() => _wbTemp = v),
                        onChangeEnd: (_) => _sendWB(),
                      ),
                    ),
                    const Text('8000K', style: TextStyle(fontSize: 10, color: kTextMut)),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sendWB,
                    icon: const Icon(Icons.send, size: 14),
                    label: const Text('ENVIAR WB A DIAPOSITIVA'),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: LogPanel(entries: _log),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _wbReference() {
    const refs = [
      ('2700K', 'Tungsteno', kOrange),
      ('5500K', 'Luz día', Colors.white),
      ('7500K', 'Sombra', kBlue),
    ];
    return refs.map((r) => Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: r.$3,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${r.$1}  ${r.$2}',
            style: const TextStyle(fontSize: 9, color: kTextDim),
          ),
        ],
      ),
    )).toList();
  }
}
