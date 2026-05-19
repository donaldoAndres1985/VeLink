#!/bin/bash
# Script para generar APK de VeLink
# Uso: bash build_apk.sh
# Requiere: Flutter en PATH

set -e

# Mueve el caché de Gradle fuera del perfil de usuario para evitar
# que Windows Defender bloquee el rename de archivos temporales
export GRADLE_USER_HOME=/c/gradle

echo "=== VeLink — Build APK ==="
echo ""

# Mata procesos Java que puedan tener locks sobre el caché
taskkill //F //IM java.exe 2>/dev/null && echo "[OK] Procesos Java detenidos" || echo "[OK] No habia procesos Java activos"

# Limpia caché de transforms problemático
rm -rf /c/gradle/caches/*/transforms/ 2>/dev/null && echo "[OK] Cache de transforms limpiada" || true

# Build
echo ""
echo "Construyendo APK release..."
flutter build apk --split-per-abi --release

echo ""
echo "=== APKs generados ==="
ls -lh build/app/outputs/flutter-apk/app-*-release.apk 2>/dev/null || ls -lh build/app/outputs/flutter-apk/*.apk
echo ""
echo "Ruta: $(pwd)/build/app/outputs/flutter-apk/"
