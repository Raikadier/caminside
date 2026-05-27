# CamInside

App móvil Android de demostración para la exposición **"Cámara Android: Bajo el Capó"**.  
Muestra en tiempo real cómo funciona la cámara de Android a nivel de software, enviando telemetría a la diapositiva web vía WebSocket.

> **Universidad Popular del Cesar · Ingeniería de Sistemas · Programación Móvil · Mayo 2026**

---

## Índice

1. [¿Qué hace la app?](#qué-hace-la-app)
2. [Requisitos previos](#requisitos-previos)
3. [Instalación y configuración](#instalación-y-configuración)
4. [Ejecutar en desarrollo](#ejecutar-en-desarrollo)
5. [Generar APK para la expo](#generar-apk-para-la-expo)
6. [Descripción de cada tab](#descripción-de-cada-tab)
7. [Conectar con la diapositiva](#conectar-con-la-diapositiva)
8. [Arquitectura del proyecto](#arquitectura-del-proyecto)
9. [Setup completo el día de la expo](#setup-completo-el-día-de-la-expo)
10. [Solución de problemas](#solución-de-problemas)

---

## ¿Qué hace la app?

CamInside es el **control remoto inteligente** de la exposición. Mientras la diapositiva web se proyecta en pantalla, el presentador usa su teléfono Android para:

- Navegar entre los 7 slides desde el teléfono (o desde la diapositiva — se sincronizan)
- Demostrar en vivo las capas HAL del sistema Android
- Ajustar el balance de blancos del ISP con un slider real
- Mostrar el ciclo de vida `AppLifecycleState` del propio dispositivo
- Iniciar el pipeline de captura simultánea de CameraX
- Escanear códigos QR en tiempo real con Google ML Kit

Cada acción en la app **emite un evento WebSocket** que la diapositiva recibe y visualiza instantáneamente.

---

## Requisitos previos

### En el PC de desarrollo

| Herramienta | Versión mínima | Descarga |
|---|---|---|
| Flutter SDK | 3.11.0 | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Dart SDK | incluido con Flutter | — |
| Android Studio | Hedgehog o superior | [developer.android.com](https://developer.android.com/studio) |
| Java JDK | 17 | incluido con Android Studio |

Verificar instalación:
```bash
flutter doctor
```
Todos los ítems deben estar en verde (excepto Xcode si estás en Windows).

### En el teléfono Android

- Android **6.0 (API 23)** o superior
- Cámara trasera disponible
- Conexión a la **misma red WiFi** que el PC donde corre el servidor

---

## Instalación y configuración

### 1. Clonar el repositorio

```bash
git clone https://github.com/Raikadier/caminside.git
cd caminside
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Conectar el teléfono

1. En el teléfono: **Ajustes → Opciones de desarrollador → Depuración USB** → activar
2. Conectar con cable USB al PC
3. Aceptar el cuadro de diálogo "¿Confiar en este PC?" en el teléfono
4. Verificar que el dispositivo es detectado:

```bash
flutter devices
```

Debe aparecer tu teléfono en la lista.

---

## Ejecutar en desarrollo

```bash
flutter run
```

La app se instala y lanza automáticamente en el teléfono conectado.  
La primera vez pedirá permiso de cámara — concederlo.

Para ver los logs en tiempo real mientras corre:
```bash
flutter run --verbose
```

---

## Generar APK para la expo

### Opción A — Script automático (recomendado)

Doble clic en **`build-apk.bat`** en la raíz del proyecto.  
El script hace todo automáticamente y genera `CamInside.apk` en la misma carpeta.

### Opción B — Comando manual

```bash
flutter build apk --release
```

El archivo queda en:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Instalar la APK en el teléfono

1. Copiar `CamInside.apk` al teléfono (cable USB, Google Drive, WhatsApp, etc.)
2. En el teléfono: **Ajustes → Aplicaciones → Instalar apps desconocidas** → habilitar para la app desde donde abres el archivo
3. Abrir el archivo `.apk` en el teléfono y pulsar **Instalar**

> La APK de release no necesita Android Studio ni cable USB para funcionar.

---

## Descripción de cada tab

La app tiene 7 tabs que corresponden a los 7 slides de la exposición.

### Tab 1 — HAL (Hardware Abstraction Layer)

Muestra las 5 capas del stack de software de cámara en Android:

```
App Flutter → Framework/SDK → HAL → Kernel Driver → Linux/Hardware
```

- **Tap en una capa** → la activa con un glow animado y envía `hal_info` al servidor con la capa seleccionada
- **Botón "LEER CARACTERÍSTICAS HAL"** → lee los datos reales del `CameraManager` del dispositivo (focal length, apertura, orientación del sensor, resolución de preview) y los envía al servidor
- La diapositiva web recibe los datos y los muestra en el log en tiempo real

### Tab 2 — ISP (Image Signal Processor)

Visualiza el pipeline del procesador de imagen:

```
Sensor RAW (Bayer) → Demosaicing → Noise Reduction → White Balance → Tonemapping
```

- **Slider de Balance de Blancos** (2500K – 8000K) → cambia el color de una cuadrícula Bayer en la app Y en la diapositiva simultáneamente
- La diapositiva muestra la temperatura de color en su propia cuadrícula Bayer animada

### Tab 3 — APIs de Cámara

Compara visualmente dos enfoques para acceder a la cámara:

- **Platform Channel nativo** (Camera2 API) → ~280 líneas de código, ~1020ms de inicialización
- **Flutter Camera Package** → ~35 líneas, ~74ms

Botón **"Simular inicialización"** → ejecuta una comparativa animada que aparece en la diapositiva.

### Tab 4 — Ciclo de Vida

Muestra los estados `AppLifecycleState` de Flutter en tiempo real:

| Estado | Significado |
|---|---|
| `resumed` | App en primer plano, cámara activa |
| `inactive` | Transición (llamada entrante, multitarea) |
| `paused` | App en segundo plano, hardware liberado |
| `detached` | App destruida |

- **Los estados reales** se detectan automáticamente cuando minimizas o bloqueas el teléfono
- **Botones de simulación** → fuerzan un estado manualmente para demostrar sin tener que usar el botón físico

### Tab 5 — Pipeline de Captura

Muestra el preview de cámara en vivo y las tres superficies simultáneas de CameraX:

| Superficie | Formato | Uso |
|---|---|---|
| Preview Surface | GPU / SurfaceTexture | Lo que ves en pantalla |
| Capture Surface | JPEG / Full Resolution | Foto guardada en disco |
| Analysis Surface | YUV_420_888 / RAM | Frames para ML Kit |

- **INICIAR STREAM** → activa el preview y el buffer de análisis, emite evento al servidor
- **CAPTURAR** → toma una foto real y emite el evento

### Tab 6 — Extensiones CameraX

Compara el método antiguo (screenshot del preview) con las extensiones nativas del fabricante:

- Tarjeta **MÉTODO ANTIGUO** → captura del buffer del display, baja calidad
- Tarjeta **EXTENSIÓN NATIVA** → acceso directo al pipeline ISP del fabricante (HDR, Modo Noche, Bokeh)

Tocando una tarjeta se emite `extension_mode` a la diapositiva.

### Tab 7 — Google ML Kit

Activa el escáner de códigos QR/barras en tiempo real usando la cámara:

- Abre la cámara en modo **ImageAnalysis**
- Procesa cada frame en formato **YUV_420_888**
- Detecta QR codes, barcodes, URLs, WiFi, email, etc.
- **Cada detección** envía `mlkit_result` al servidor con el tipo, valor, formato y coordenadas del código

**Para demostrar:** preparar un QR code impreso o en otro teléfono y apuntar la cámara.

---

## Conectar con la diapositiva

### Requisitos de red

- El PC con el servidor y el teléfono con la app deben estar en la **misma red WiFi**
- Si la red universitaria bloquea tráfico entre dispositivos, usar el **hotspot del teléfono** y conectar el PC a ese hotspot

### Pasos

1. En el PC, iniciar el servidor (ver [repo caminside-expo](https://github.com/Raikadier/caminside-expo))
2. Obtener la IP local del PC:
   - Windows: `ipconfig` en cmd → buscar "Dirección IPv4"
   - O leer la IP que muestra el script `iniciar-expo.bat`
3. Abrir CamInside en el teléfono
4. Al iniciar aparece el diálogo de conexión → ingresar `http://192.168.X.X:3000` con la IP del PC
5. El indicador de la app cambia a **Online** (punto verde) cuando la conexión es exitosa

### Sincronización bidireccional

| Acción | Resultado |
|---|---|
| Cambiar tab en la app | La diapositiva web navega al slide correspondiente |
| Cambiar slide en la diapositiva web | La app cambia al tab correspondiente |
| Cualquier interacción en la app | La diapositiva muestra los datos en tiempo real |

---

## Arquitectura del proyecto

```
lib/
├── main.dart                  # Entrada, splash, solicitud de permisos
├── screens/
│   ├── home_screen.dart       # Scaffold principal, BottomNav, remote de slides
│   ├── tab_hal.dart           # Slide 1 — Capas HAL
│   ├── tab_isp.dart           # Slide 2 — ISP y Balance de Blancos
│   ├── tab_apis.dart          # Slide 3 — Comparativa de APIs
│   ├── tab_lifecycle.dart     # Slide 4 — AppLifecycleState
│   ├── tab_pipeline.dart      # Slide 5 — Pipeline de CameraX
│   ├── tab_extensions.dart    # Slide 6 — Extensiones CameraX
│   └── tab_mlkit.dart         # Slide 7 — Google ML Kit
├── services/
│   ├── camera_service.dart    # Singleton — CameraController compartido
│   └── socket_service.dart    # Singleton — conexión Socket.io
├── widgets/
│   ├── slide_header.dart      # Header reutilizable por tab
│   └── log_panel.dart         # Terminal de logs con timestamps
└── theme/
    └── app_theme.dart         # Colores, tema Material, helpers de decoración
```

### Servicios singleton

**`CameraService`** — un único `CameraController` compartido entre todos los tabs:
- `init()` → inicializa la cámara trasera con formato YUV 420
- `startImageStream(callback)` → inicia el análisis frame a frame
- `stopImageStream()` → para el stream (se llama al cambiar de tab)
- `takePicture()` → captura JPEG
- `pausePreview()` / `resumePreview()` → gestión del ciclo de vida

**`SocketService`** — conexión Socket.io persistente:
- `connect(url)` → establece la conexión con el servidor
- `navigateSlide(index)` → mueve el slide web Y notifica el cambio de tab
- `emitTabChange(index)` → solo notifica el tab (sin mover el slide, evita bucle)
- Métodos tipados por slide: `emitHalInfo`, `emitIspWhiteBalance`, `emitLifecycleEvent`, `emitCapture`, `emitExtensionMode`, `emitMlKitResult`

### Protocolo WebSocket

```
App (móvil)              Servidor Node.js           Diapositiva (web)
    │                         │                          │
    │── telemetria_movil ──→  │── cambio_diapositiva ──→ │
    │   { evento, data }      │   { evento, data }       │
    │                         │                          │
    │← ─── slide_sync ───────  │←── slide_changed ───── │
    │   { index }             │   { index }              │
```

---

## Setup completo el día de la expo

### 15 minutos antes

```
1. Encender el PC y conectarlo al WiFi del salón (o hotspot)
2. Abrir caminside-expo/ → doble clic en iniciar-expo.bat
3. Anotar la IP que aparece (ej: 192.168.1.45)
4. Abrir CamInside en el teléfono
5. Ingresar http://192.168.1.45:3000 en el diálogo de conexión
6. Verificar que el HUD de la diapositiva muestra "1 móvil conectado"
7. Conectar el teléfono al PC con scrcpy para proyectar la pantalla del teléfono
8. Ajustar las ventanas en el proyector: diapositiva a la izquierda, scrcpy a la derecha
```

### Durante la demo

- El presentador **toca la app** → el público ve el teléfono en pantalla (scrcpy) y la diapositiva reacciona
- Los botones PREV/NEXT en la app también mueven los slides
- Si hay problemas de conexión WiFi → tocar el indicador Online/Offline en la app para reconectar

---

## Solución de problemas

### La app no detecta la cámara
- Verificar que se concedió el permiso de cámara en el primer inicio
- Ir a **Ajustes del teléfono → Apps → CamInside → Permisos → Cámara** → habilitar
- Reiniciar la app

### No conecta con el servidor (muestra Offline)
- Verificar que PC y teléfono están en la **misma red WiFi**
- Verificar que `iniciar-expo.bat` está corriendo en el PC
- Confirmar la IP del PC con `ipconfig` en cmd
- Desactivar el firewall de Windows temporalmente si sigue sin conectar:  
  `Ajustes → Seguridad de Windows → Firewall → Desactivar`

### El tab ML Kit no escanea
- Asegurarse de buena iluminación
- El código QR debe estar a 10–40 cm de la cámara
- Si el stream está activo pero no detecta, tocar DETENER y luego INICIAR ESCANEO de nuevo

### `flutter doctor` muestra errores
- Error de Android SDK → abrir Android Studio → SDK Manager → instalar Android 6.0+
- Error de dispositivo → verificar que la Depuración USB está activa en el teléfono

---

## Dependencias principales

| Paquete | Versión | Uso |
|---|---|---|
| `camera` | ^0.10.9 | CameraController, preview, stream de frames |
| `socket_io_client` | ^2.0.3+1 | Conexión WebSocket con el servidor |
| `google_mlkit_barcode_scanning` | ^0.13.0 | Detección de QR y códigos de barras |
| `permission_handler` | ^11.3.1 | Solicitud de permiso de cámara en runtime |

---

*Proyecto académico — Universidad Popular del Cesar · 2026*
