import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Singleton que gestiona la conexión WebSocket con el servidor Node.js.
///
/// Protocolo:
///   Móvil  → Server → Web  :  'telemetria_movil'  { evento, data }
///   Web    → Server → Móvil:  'slide_changed'      { index }
///                              → servidor re-emite como 'slide_sync'
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  String _serverUrl = 'http://192.168.1.1:3000';
  bool _connected = false;

  bool get connected => _connected;
  String get serverUrl => _serverUrl;

  final List<void Function(bool)> _connListeners = [];

  /// Callback invocado cuando el web cambia de slide (web→móvil sync).
  /// Recibe el índice del slide (0-7).
  void Function(int)? onSlideSync;

  // ── Listeners de conexión ──────────────────────────────────────────────
  void addConnectionListener(void Function(bool) fn) =>
      _connListeners.add(fn);
  void removeConnectionListener(void Function(bool) fn) =>
      _connListeners.remove(fn);

  void _notify(bool state) {
    _connected = state;
    for (final fn in List.of(_connListeners)) fn(state);
  }

  // ── Conectar ───────────────────────────────────────────────────────────
  void connect(String url) {
    _serverUrl = url;
    _socket?.disconnect();

    _socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setReconnectionDelay(1500)
          .setReconnectionDelayMax(5000)
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      // Identificarse como cliente móvil → el server asigna room 'mobile'
      _socket!.emit('identify', 'mobile');
      _notify(true);
    });

    _socket!.onDisconnect((_) => _notify(false));
    _socket!.onConnectError((_) => _notify(false));

    // ── Web → Móvil: el presentador cambió de slide ───────────────────
    // El server reenvía 'slide_changed' del browser como 'slide_sync' al móvil.
    _socket!.on('slide_sync', (data) {
      final map   = data is Map ? data : <String, dynamic>{};
      final index = (map['index'] as num?)?.toInt() ?? 0;
      onSlideSync?.call(index);
    });

    _socket!.connect();
  }

  // ── Emitir telemetría genérica ─────────────────────────────────────────
  void emit(String evento, Map<String, dynamic> data) {
    if (_socket == null || !_connected) return;
    _socket!.emit('telemetria_movil', {'evento': evento, 'data': data});
  }

  // ── Tab change (solo logging en el web, sin navegación) ────────────────
  /// Notifica al web qué tab está activo — aparece en los logs de cada slide.
  void emitTabChange(int tab) => emit('tab_change', {'tab': tab});

  // ── Navegación (mueve el Reveal.js) ───────────────────────────────────
  /// Navega la diapositiva web al slide correspondiente Y notifica tab change.
  /// Úsalo solo cuando el USUARIO cambie de tab manualmente en la app.
  void navigateSlide(int tab) {
    emitTabChange(tab);
    emit('navigate', {'slide': tab});
  }

  /// Navega directamente a un slide por índice (0 = portada, 1-7 = secciones).
  void navigate(int slideIndex) =>
      emit('navigate', {'slide': slideIndex});

  // ── Eventos tipados por slide ──────────────────────────────────────────

  void emitHalInfo({
    required String capa,
    double? focalLength,
    double? aperture,
    String? nivelSoporte,
    int? sensorOrientation,
    int? cameraCount,
    String? lensDirection,
    String? previewSize,
  }) {
    emit('hal_info', {
      'capa': capa,
      if (focalLength != null)      'focal_length':      focalLength,
      if (aperture != null)         'aperture':          aperture,
      if (nivelSoporte != null)     'nivel_soporte':     nivelSoporte,
      if (sensorOrientation != null)'sensor_orientation':sensorOrientation,
      if (cameraCount != null)      'camera_count':      cameraCount,
      if (lensDirection != null)    'lens_direction':    lensDirection,
      if (previewSize != null)      'preview_size':      previewSize,
    });
  }

  void emitIspWhiteBalance(int temperatura) =>
      emit('isp_white_balance', {'temperatura': temperatura});

  void emitLifecycleEvent(String estado) =>
      emit('lifecycle_event', {'estado': estado});

  void emitCaptureStart() =>
      emit('capture_event', {'accion': 'start_preview', 'iniciar': true});

  void emitCapture() =>
      emit('capture_event', {'accion': 'capturar'});

  void emitExtensionMode(String modo) =>
      emit('extension_mode', {'modo': modo});

  void emitMlKitResult({
    required String tipo,
    required String valor,
    String formato = 'QR_CODE',
    double? confianza,
    Map<String, dynamic>? coordenadas,
  }) {
    emit('mlkit_result', {
      'tipo':      tipo,
      'valor':     valor,
      'formato':   formato,
      'confianza': confianza ?? 0.95,
      if (coordenadas != null) 'coordenadas': coordenadas,
    });
  }

  // ── Desconectar ────────────────────────────────────────────────────────
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _connected = false;
  }
}
