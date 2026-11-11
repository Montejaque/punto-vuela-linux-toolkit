#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/src/punto_vuela_toolkit/assets"
mkdir -p "$ASSETS"
curl --fail --location --silent --show-error \
  "https://puntosvuela.es/storage/images/logotipovuela.svg" \
  -o "$ASSETS/logotipovuela.svg"
grep -q "<svg" "$ASSETS/logotipovuela.svg"
echo "Logotipo oficial descargado en $ASSETS/logotipovuela.svg"
