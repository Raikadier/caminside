import 'package:flutter/material.dart';

import '../services/socket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/slide_header.dart';
import '../widgets/log_panel.dart';

class TabLifecycle extends StatefulWidget {
  final AppLifecycleState currentState;
  final void Function(AppLifecycleState) onSimulate;

  const TabLifecycle({
    super.key,
    required this.currentState,
    required this.onSimulate,
  });

  @override
  State<TabLifecycle> createState() => _TabLifecycleState();
}

class _TabLifecycleState extends State<TabLifecycle> {
  final _log = <LogEntry>[];

  // Propiedades de cada estado Flutter
  static const _states = [
    _StateInfo(AppLifecycleState.resumed,  '▶', 'resumed',  'Cámara activa · UI visible',         kGreen),
    _StateInfo(AppLifecycleState.inactive, '⏸', 'inactive', 'App en foco parcial · sin input',     kYellow),
    _StateInfo(AppLifecycleState.paused,   '⏹', 'paused',   'App en background · cámara liberada', kRed),
    _StateInfo(AppLifecycleState.detached, '💀', 'detached', 'Flutter engine desconectado',          kTextMut),
  ];

  @override
  void initState() {
    super.initState();
    SocketService().emitTabChange(4);
    _addLog('Observer de ciclo de vida activo', kTextDim);
  }

  @override
  void didUpdateWidget(TabLifecycle old) {
    super.didUpdateWidget(old);
    if (old.currentState != widget.currentState) {
      final info = _stateInfo(widget.currentState);
      _addLog('→ ${info.name.toUpperCase()}  ${info.desc}', info.color);
    }
  }

  void _addLog(String msg, Color color) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, LogEntry(msg, color));
      if (_log.length > 20) _log.removeLast();
    });
  }

  _StateInfo _stateInfo(AppLifecycleState s) =>
      _states.firstWhere((i) => i.state == s, orElse: () => _states[0]);

  // ── Botones de simulación ─────────────────────────────────────────────
  void _simulate(AppLifecycleState state) {
    widget.onSimulate(state);
    final info = _stateInfo(state);
    _addLog('SIM → ${info.name}', info.color);
  }

  @override
  Widget build(BuildContext context) {
    final current = _stateInfo(widget.currentState);

    return Column(
      children: [
        const SlideHeader(
          index: 4,
          title: 'AppLifecycleState',
          subtitle: 'Ciclo de vida Flutter y gestión de la cámara',
          accent: kYellow,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Estado actual — destacado
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: glowDecoration(current.color, radius: 12),
                  child: Row(
                    children: [
                      Text(current.icon, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ESTADO ACTUAL',
                              style: TextStyle(
                                fontSize: 9,
                                color: current.color.withValues(alpha: 0.7),
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'AppLifecycleState.${current.name}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: current.color,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(current.desc,
                                style: const TextStyle(fontSize: 11, color: kTextDim)),
                          ],
                        ),
                      ),
                      // Indicador de cámara
                      Column(
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: current.state == AppLifecycleState.resumed
                                ? kGreen
                                : kRed,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            current.state == AppLifecycleState.resumed
                                ? 'ACTIVA'
                                : 'LIBERADA',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: current.state == AppLifecycleState.resumed
                                  ? kGreen
                                  : kRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Diagrama de transiciones
                Expanded(
                  flex: 3,
                  child: ListView.separated(
                    itemCount: _states.length,
                    separatorBuilder: (_, _) => const _StateArrow(),
                    itemBuilder: (_, i) {
                      final s = _states[i];
                      final isActive = s.state == widget.currentState;
                      return _StateRow(
                        info: s,
                        isActive: isActive,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Botones de simulación
                const Text(
                  'SIMULAR TRANSICIÓN',
                  style: TextStyle(
                    fontSize: 9,
                    color: kTextMut,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _SimButton(
                      label: 'RESUMED',
                      color: kGreen,
                      onTap: () => _simulate(AppLifecycleState.resumed),
                    )),
                    const SizedBox(width: 6),
                    Expanded(child: _SimButton(
                      label: 'INACTIVE',
                      color: kYellow,
                      onTap: () => _simulate(AppLifecycleState.inactive),
                    )),
                    const SizedBox(width: 6),
                    Expanded(child: _SimButton(
                      label: 'PAUSED',
                      color: kRed,
                      onTap: () => _simulate(AppLifecycleState.paused),
                    )),
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

class _StateInfo {
  final AppLifecycleState state;
  final String icon;
  final String name;
  final String desc;
  final Color color;
  const _StateInfo(this.state, this.icon, this.name, this.desc, this.color);
}

class _StateRow extends StatelessWidget {
  final _StateInfo info;
  final bool isActive;
  const _StateRow({required this.info, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? info.color.withValues(alpha: 0.08) : kBgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? info.color.withValues(alpha: 0.5) : kBorder,
        ),
      ),
      child: Row(
        children: [
          Text(info.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AppLifecycleState.${info.name}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? info.color : kTextDim,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(info.desc,
                    style: const TextStyle(fontSize: 10, color: kTextMut)),
              ],
            ),
          ),
          if (isActive)
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: info.color,
                boxShadow: [BoxShadow(
                  color: info.color.withValues(alpha: 0.7),
                  blurRadius: 8,
                )],
              ),
            ),
        ],
      ),
    );
  }
}

class _StateArrow extends StatelessWidget {
  const _StateArrow();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2),
        child: Icon(Icons.keyboard_arrow_down, size: 14, color: kTextMut),
      ),
    );
  }
}

class _SimButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SimButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
