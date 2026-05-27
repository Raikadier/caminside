import 'package:flutter/material.dart';

import '../services/socket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/slide_header.dart';
import '../widgets/log_panel.dart';

class TabExtensions extends StatefulWidget {
  const TabExtensions({super.key});

  @override
  State<TabExtensions> createState() => _TabExtensionsState();
}

class _TabExtensionsState extends State<TabExtensions> {
  final _socket = SocketService();
  final _log = <LogEntry>[];
  String? _selectedMode; // 'old' | 'new' | 'night' | 'hdr' | 'bokeh'

  static const _extensions = [
    _Ext('night',  '🌙', 'NIGHT',  kBlue,   'Fusión multi-frame · ISP nativo'),
    _Ext('hdr',    '☀️',  'HDR',    kYellow, 'High Dynamic Range · tone mapping'),
    _Ext('bokeh',  '🎯', 'BOKEH',  kPurple, 'Desenfoque portátil · depth map'),
    _Ext('beauty', '✨', 'BEAUTY', kGreen,  'Retoque facial · edge detection'),
    _Ext('auto',   '🔮', 'AUTO',   kCyan,   'HAL selecciona automáticamente'),
  ];

  @override
  void initState() {
    super.initState();
    _socket.emitTabChange(6);
    _addLog('Extensiones de CameraX disponibles', kTextDim);
  }

  void _addLog(String msg, Color color) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, LogEntry(msg, color));
      if (_log.length > 15) _log.removeLast();
    });
  }

  void _selectMode(String mode) {
    setState(() => _selectedMode = mode);

    if (mode == 'old') {
      _socket.emitExtensionMode('screenshot');
      _addLog('MODO: Screenshot del Preview — sin ISP nativo', kRed);
      _addLog('ExtensionMode: NONE · ruta genérica', kTextMut);
    } else {
      final ext = _extensions.firstWhere((e) => e.id == mode, orElse: () => _extensions[4]);
      _socket.emitExtensionMode('nativa');
      _addLog('MODO: Extensión Nativa activada ✓', kGreen);
      _addLog('ExtensionMode: ${ext.label} · pipeline ISP completo', kGreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SlideHeader(
          index: 6,
          title: 'API de Extensiones CameraX',
          subtitle: 'Acceso directo al ISP del fabricante',
          accent: kGreen,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Comparativa de modos
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modo viejo: screenshot
                    Expanded(
                      child: _ModeCard(
                        id: 'old',
                        title: 'Screenshot\ndel Preview',
                        badge: 'Sin ISP',
                        badgeColor: kRed,
                        icon: Icons.screenshot_monitor,
                        iconColor: kRed,
                        bullets: const [
                          ('❌', 'Sin acceso al HAL'),
                          ('❌', 'Resolución limitada'),
                          ('❌', 'Sin procesamiento nativo'),
                          ('❌', 'Resultados genéricos'),
                        ],
                        selected: _selectedMode == 'old',
                        onTap: () => _selectMode('old'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Modo nuevo: extensión nativa
                    Expanded(
                      child: _ModeCard(
                        id: 'new',
                        title: 'Extensión\nNativa CameraX',
                        badge: 'ISP Nativo',
                        badgeColor: kGreen,
                        icon: Icons.auto_awesome,
                        iconColor: kGreen,
                        bullets: const [
                          ('✅', 'Pipeline HAL completo'),
                          ('✅', 'Full resolution'),
                          ('✅', 'Procesado por fabricante'),
                          ('✅', 'Night / HDR / Bokeh'),
                        ],
                        selected: _selectedMode != null && _selectedMode != 'old',
                        onTap: () => _selectMode('bokeh'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Grid de extensiones disponibles
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'EXTENSIONES DISPONIBLES',
                    style: TextStyle(
                      fontSize: 9, color: kTextMut,
                      letterSpacing: 1.5, fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _extensions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final e = _extensions[i];
                      final sel = _selectedMode == e.id;
                      return GestureDetector(
                        onTap: () => _selectMode(e.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 80,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: sel ? e.color.withValues(alpha: 0.12) : kBgCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel ? e.color : kBorder,
                              width: sel ? 1.5 : 1,
                            ),
                            boxShadow: sel
                                ? [BoxShadow(
                                    color: e.color.withValues(alpha: 0.25),
                                    blurRadius: 12,
                                  )]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(e.icon, style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 4),
                              Text(
                                e.label,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: sel ? e.color : kTextDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(child: LogPanel(entries: _log)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Datos de extensión ─────────────────────────────────────────────────────
class _Ext {
  final String id, icon, label, desc;
  final Color color;
  const _Ext(this.id, this.icon, this.label, this.color, this.desc);
}

// ── Tarjeta de modo ────────────────────────────────────────────────────────
class _ModeCard extends StatelessWidget {
  final String id, title, badge;
  final Color badgeColor, iconColor;
  final IconData icon;
  final List<(String, String)> bullets;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.id,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.icon,
    required this.iconColor,
    required this.bullets,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? badgeColor.withValues(alpha: 0.07) : kBgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? badgeColor.withValues(alpha: 0.6) : kBorder,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(
                  color: badgeColor.withValues(alpha: 0.15), blurRadius: 16,
                )]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(badge,
                      style: TextStyle(
                        fontSize: 8, fontWeight: FontWeight.w800, color: badgeColor,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: selected ? badgeColor : kText,
                  height: 1.3,
                )),
            const SizedBox(height: 8),
            ...bullets.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Text(b.$1, style: const TextStyle(fontSize: 10)),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(b.$2,
                        style: const TextStyle(fontSize: 9, color: kTextDim)),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
