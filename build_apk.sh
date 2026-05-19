#!/bin/bash
# Script para generar APK de VeLink
# Uso: bash build_apk.sh
# Requiere: Flutter en PATH

set -e

export GRADLE_USER_HOME=/c/gradle
TRANSFORMS_DIR="$GRADLE_USER_HOME/caches/8.13/transforms"

echo "=== VeLink — Build APK ==="
echo ""

# Mata procesos Java que puedan tener locks sobre el cache
taskkill //F //IM java.exe 2>/dev/null && echo "[OK] Procesos Java detenidos" || echo "[OK] No habia procesos Java activos"

# Promueve directorios temporales UUID a la ubicacion inmutable final.
# Gradle en Windows falla con AccessDeniedException al intentar renombrar
# un directorio temporal cuando otro thread ya creo el destino final.
# Esta funcion resuelve ese estado dejando solo el directorio final valido.
promote_stuck_transforms() {
  [ -d "$TRANSFORMS_DIR" ] || return
  local count=0
  for tempdir in "$TRANSFORMS_DIR"/*-????????-????-????-????-????????????; do
    [ -d "$tempdir" ] || continue
    local base
    base=$(basename "$tempdir" | sed 's/-[0-9a-f]\{8\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}-[0-9a-f]\{12\}$//')
    local final="$TRANSFORMS_DIR/$base"
    if [ ! -d "$final" ]; then
      mv "$tempdir" "$final" 2>/dev/null && count=$((count + 1)) || true
    else
      rm -rf "$tempdir" 2>/dev/null || true
    fi
  done
  [ $count -gt 0 ] && echo "[OK] $count transform(s) promovido(s)" || true
}

# Ciclo de build con reintentos
# Cada intento acumula mas transforms en cache; en 3-5 intentos el build
# tendra todos los transforms necesarios y completara sin race conditions.
MAX_ATTEMPTS=10
for attempt in $(seq 1 $MAX_ATTEMPTS); do
  echo ""
  echo "--- Intento $attempt / $MAX_ATTEMPTS ---"
  promote_stuck_transforms
  taskkill //F //IM java.exe 2>/dev/null || true

  if flutter build apk --split-per-abi --release 2>&1; then
    echo ""
    echo "=== APKs generados ==="
    ls -lh build/app/outputs/flutter-apk/app-*-release.apk 2>/dev/null
    echo ""
    echo "Ruta: $(pwd)/build/app/outputs/flutter-apk/"
    exit 0
  fi

  if [ $attempt -lt $MAX_ATTEMPTS ]; then
    echo ""
    echo "[!] Fallo en intento $attempt. Promoviendo transforms y reintentando..."
    promote_stuck_transforms
  fi
done

echo ""
echo "[ERROR] El build fallo despues de $MAX_ATTEMPTS intentos."
exit 1
