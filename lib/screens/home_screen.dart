import 'package:flutter/material.dart';

import '../services/camera_service.dart';
import '../services/socket_service.dart';
import '../theme/app_theme.dart';
import 'tab_hal.dart';
import 'tab_isp.dart';
import 'tab_apis.dart';
import 'tab_lifecycle.dart';
import 'tab_pipeline.dart';
import 'tab_extensions.dart';
import 'tab_mlkit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentTab = 0;
  bool _connected = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  /// Previene bucle de sync: cuando el web nos envía slide_sync
  /// y cambiamos el tab, NO volvemos a emitir navigate al web.
  bool _syncingFromWeb = false;

  final _socket     = SocketService();
  final _serverCtrl = TextEditingController(text: 'http://192.168.1.1:3000');

  static const _labels = ['HAL', 'ISP', 'APIs', 'Ciclo', 'Pipeline', 'Ext.', 'ML Kit'];
  static const _icons  = [
    Icons.layers_outlined,
    Icons.blur_on_outlined,
    Icons.code_rounded,
    Icons.sync_rounded,
    Icons.videocam_outlined,
    Icons.auto_awesome_outlined,
    Icons.qr_code_scanner_rounded,
  ];
  static const _accentColors = [
    kCyan, kBlue, kPurple, kYellow, kOrange, kGreen, kPurple,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _socket.addConnectionListener(_onConnectionChange);

    // ── Sync web → móvil ──────────────────────────────────────────────
    // Cuando el presentador cambia el slide desde el browser,
    // el server envía 'slide_sync' → cambiamos el tab SIN emitir navigate.
    _socket.onSlideSync = (slideIndex) {
      if (!mounted) return;
      if (slideIndex >= 1 && slideIndex <= 7) {
        _syncingFromWeb = true;
        setState(() => _currentTab = slideIndex - 1);
        // Solo notificar tab_change (log en web), no navigate (evita bucle)
        _socket.emitTabChange(slideIndex);
        _syncingFromWeb = false;
      } else if (slideIndex == 0) {
        // Portada — no hay tab correspondiente, solo log
        _syncingFromWeb = false;
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) => _showServerDialog());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _socket.removeConnectionListener(_onConnectionChange);
    _socket.onSlideSync = null;
    _serverCtrl.dispose();
    super.dispose();
  }

  // ── AppLifecycleState ──────────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _lifecycleState = state;
    _socket.emitLifecycleEvent(state.name);

    final cam = CameraService();
    if (state == AppLifecycleState.paused)   cam.pausePreview();
    if (state == AppLifecycleState.resumed)  cam.resumePreview();
  }

  AppLifecycleState get lifecycleState => _lifecycleState;

  void _onConnectionChange(bool c) {
    if (mounted) setState(() => _connected = c);
  }

  // ── Diálogo de servidor ───────────────────────────────────────────────
  void _showServerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi, color: kCyan, size: 18),
            SizedBox(width: 8),
            Text('Conectar al servidor'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'IP del PC donde corre node server.js.\nEjemplo: http://192.168.0.10:3000',
              style: TextStyle(fontSize: 12, color: kTextDim, height: 1.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _serverCtrl,
              keyboardType: TextInputType.url,
              style: const TextStyle(
                fontFamily: 'monospace', fontSize: 13, color: Colors.white,
              ),
              decoration: const InputDecoration(
                hintText: 'http://192.168.x.x:3000',
                prefixIcon: Icon(Icons.link, size: 16, color: kTextMut),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Omitir', style: TextStyle(color: kTextMut)),
          ),
          ElevatedButton(
            onPressed: () {
              _socket.connect(_serverCtrl.text.trim());
              Navigator.of(ctx).pop();
            },
            child: const Text('CONECTAR'),
          ),
        ],
      ),
    );
  }

  // ── Cambio de tab (iniciado por el usuario) ───────────────────────────
  void _onTabChanged(int index) {
    if (_syncingFromWeb) return;
    if (_currentTab == 5 || _currentTab == 6) CameraService().stopImageStream(); // A-4: detener stream al salir de Pipeline o ML Kit
    setState(() => _currentTab = index);
    // navigateSlide = emitTabChange + navigate → mueve el slide web
    _socket.navigateSlide(index + 1);
  }

  // ── Navegación manual de slides (prev / next / portada) ───────────────
  void _navPrev() {
    final target = (_currentTab - 1).clamp(0, 6);
    _onTabChanged(target);
  }

  void _navNext() {
    final target = (_currentTab + 1).clamp(0, 6);
    _onTabChanged(target);
  }

  void _navCover() {
    // Navega a portada (slide 0) sin cambiar tab
    _socket.navigate(0);
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final accent = _accentColors[_currentTab];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CAMINSIDE'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kBorder),
        ),
        actions: [
          // Botón portada (slide 0)
          IconButton(
            onPressed: _navCover,
            icon: const Icon(Icons.home_outlined, size: 20),
            tooltip: 'Ir a portada',
            color: kTextMut,
          ),
          // Indicador de conexión — tap para reconfigurar
          GestureDetector(
            onTap: _showServerDialog,
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _connected
                      ? kGreen.withValues(alpha: 0.35)
                      : kBorder,
                ),
                borderRadius: BorderRadius.circular(20),
                color: kBgCard,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _connected ? kGreen : kTextMut,
                      boxShadow: _connected
                          ? [BoxShadow(
                              color: kGreen.withValues(alpha: 0.6),
                              blurRadius: 6,
                            )]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _connected ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 10,
                      color: _connected ? kGreen : kTextMut,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      body: _buildTab(_currentTab),

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Remote de presentación ─────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: kBgCard2,
              border: Border(top: BorderSide(color: kBorder)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                // Prev
                _RemoteBtn(
                  icon: Icons.chevron_left_rounded,
                  label: 'PREV',
                  onTap: _currentTab > 0 ? _navPrev : null,
                ),
                const SizedBox(width: 8),
                // Indicador de slide actual
                Expanded(
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent,
                              boxShadow: [BoxShadow(
                                color: accent.withValues(alpha: 0.7),
                                blurRadius: 6,
                              )],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'SLIDE ${_currentTab + 1} · ${_labels[_currentTab]}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: accent,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Next
                _RemoteBtn(
                  icon: Icons.chevron_right_rounded,
                  label: 'NEXT',
                  onTap: _currentTab < 6 ? _navNext : null,
                ),
              ],
            ),
          ),
          // Línea de acento
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 2,
            color: accent.withValues(alpha: 0.5),
          ),
          BottomNavigationBar(
            currentIndex: _currentTab,
            onTap: _onTabChanged,
            items: List.generate(7, (i) => BottomNavigationBarItem(
              icon: Icon(_icons[i], size: 20),
              activeIcon: Icon(_icons[i], size: 22, color: _accentColors[i]),
              label: _labels[i],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0: return const TabHal();
      case 1: return const TabIsp();
      case 2: return const TabApis();
      case 3: return TabLifecycle(
          currentState: _lifecycleState,
          onSimulate: (state) {
            _lifecycleState = state;
            _socket.emitLifecycleEvent(state.name);
            if (mounted) setState(() {});
          },
        );
      case 4: return const TabPipeline();
      case 5: return const TabExtensions();
      case 6: return const TabMlKit();
      default: return const TabHal();
    }
  }
}

// ── Botón del remote ──────────────────────────────────────────────────────
class _RemoteBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _RemoteBtn({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: enabled ? kBgCard : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? kBorder : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label == 'NEXT') ...[
              Text(label, style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: enabled ? kTextDim : kTextMut.withValues(alpha: 0.3),
              )),
              const SizedBox(width: 2),
            ],
            Icon(icon, size: 18,
                color: enabled ? kText : kTextMut.withValues(alpha: 0.3)),
            if (label == 'PREV') ...[
              const SizedBox(width: 2),
              Text(label, style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: enabled ? kTextDim : kTextMut.withValues(alpha: 0.3),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
