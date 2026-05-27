import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'services/camera_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CamInsideApp());
}

class CamInsideApp extends StatelessWidget {
  const CamInsideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CamInside',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const _SplashGate(),
    );
  }
}

// ── Splash: pide permisos e inicializa la cámara ──────────────────────────
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  String _status = 'Iniciando...';
  bool _ready = false;
  bool _cameraGranted = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await _step('Verificando permisos de cámara...');

    final status = await Permission.camera.request();
    _cameraGranted = status.isGranted;

    if (_cameraGranted) {
      await _step('Iniciando cámara...');
      try {
        await CameraService().init();
      } catch (e) {
        await _step('Cámara no disponible — continuando sin hardware...');
        await Future.delayed(const Duration(seconds: 1));
      }
    } else {
      await _step('Permiso de cámara denegado — funcionalidad limitada');
      await Future.delayed(const Duration(seconds: 1));
    }

    await _step('Listo ✓');
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _step(String msg) async {
    if (mounted) setState(() => _status = msg);
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const HomeScreen();

    return Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
                children: [
                  TextSpan(text: 'CAM', style: TextStyle(color: Colors.white)),
                  TextSpan(text: 'INSIDE', style: TextStyle(color: kCyan)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Demo · Cámara Android: Bajo el Capó',
              style: TextStyle(fontSize: 11, color: kTextDim, letterSpacing: 0.5),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: kCyan, strokeWidth: 2),
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              style: const TextStyle(
                fontSize: 11,
                color: kTextMut,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
