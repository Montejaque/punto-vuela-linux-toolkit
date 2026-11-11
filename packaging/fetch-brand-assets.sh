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

python3 - "$ASSETS/logotipovuela.svg" "$ASSETS/logotipo-v.svg" <<'PY'
import re, sys
from pathlib import Path
source, target = map(Path, sys.argv[1:])
svg = source.read_text(encoding="utf-8")
match = re.search(r'viewBox=["\']\s*([\d.+-]+)[ ,]+([\d.+-]+)[ ,]+([\d.+-]+)[ ,]+([\d.+-]+)\s*["\']', svg)
if not match:
    raise SystemExit("El SVG oficial no declara un viewBox; no se puede generar el símbolo V sin alterar la marca.")
x, y, width, height = map(float, match.groups())
# The Punto Vuela symbol is placed at the left of the horizontal logo.
symbol_width = width * 0.30
target.write_text(
    f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
    f'viewBox="{x:g} {y:g} {symbol_width:g} {height:g}" width="1024" height="1024">'
    f'<image x="{x:g}" y="{y:g}" width="{width:g}" height="{height:g}" '
    f'xlink:href="logotipovuela.svg" href="logotipovuela.svg"/></svg>',
    encoding="utf-8",
)
print(f"Símbolo V preparado en {target}")
PY
