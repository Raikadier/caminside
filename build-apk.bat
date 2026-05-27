@echo off
chcp 65001 >nul
title CamInside — Build APK

echo.
echo  ══════════════════════════════════════════════════
echo    CamInside  ^|  Build APK Release
echo  ══════════════════════════════════════════════════
echo.

:: ── Ir al directorio de la app ────────────────────────────────
cd /d "%~dp0"

:: ── flutter pub get ───────────────────────────────────────────
echo  [1/3] Verificando dependencias...
call flutter pub get
if %ERRORLEVEL% neq 0 (
    echo.
    echo  ERROR: flutter pub get fallo. ^¿Flutter esta instalado y en el PATH?
    pause & exit /b 1
)

:: ── Build APK release ─────────────────────────────────────────
echo.
echo  [2/3] Compilando APK en modo release ^(puede tardar 2-5 min^)...
echo.
call flutter build apk --release
if %ERRORLEVEL% neq 0 (
    echo.
    echo  ERROR: La compilacion fallo. Revisa el log arriba.
    pause & exit /b 1
)

:: ── Copiar APK junto al script con nombre legible ─────────────
echo.
echo  [3/3] Copiando APK...
copy "build\app\outputs\flutter-apk\app-release.apk" "%~dp0CamInside.apk" >nul

echo.
echo  ══════════════════════════════════════════════════
echo    APK lista:  CamInside.apk
echo.
echo    Pasos para instalar en el telefono:
echo    1. Copia CamInside.apk al telefono (USB / Drive)
echo    2. En Android: Ajustes ^> Instalar apps desconocidas
echo    3. Abre el archivo en el telefono e instala
echo  ══════════════════════════════════════════════════
echo.

explorer "%~dp0"
pause
