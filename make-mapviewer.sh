#!/usr/bin/env bash
# Build a deep-zoom viewer (HTML + tiles) from a PDF map.
# Re-run after each Therion compile to refresh the viewer.
#
#   usage: ./make-mapviewer.sh [input.pdf] [dpi] [outdir]
#     input.pdf  default: map.pdf
#     dpi        default: 600
#     outdir     default: directory of the PDF
#   env:
#     HTML_NAME  output HTML filename (default: <pdfname>.html)
#     REVISION   optional SVN revision shown in the info bar
set -euo pipefail

PDF="${1:-map.pdf}"
DPI="${2:-600}"
OUTDIR="${3:-$(dirname "$PDF")}"
NAME="$(basename "${PDF%.pdf}")"
PDFBASE="$(basename "$PDF")"
TILES="${NAME}_tiles"
HTML="${HTML_NAME:-${NAME}.html}"
SCALE=$(python3 -c "print($DPI/72)")

mkdir -p "$OUTDIR"
# Copy the PDF next to the viewer so the "open PDF" link works.
if [ "$(realpath "$PDF")" != "$(realpath -m "$OUTDIR/$PDFBASE")" ]; then
  cp "$PDF" "$OUTDIR/$PDFBASE"
fi

echo "Rendering $PDF at ${DPI} dpi..."
T="$OUTDIR/$TILES"
rm -rf "$T"
mkdir -p "$T"
# Render vector PDF at high res, flatten onto white, cut into a DZI pyramid.
vips pdfload "$PDF" "$T/full.v" --scale "$SCALE" 2>/dev/null
vips flatten "$T/full.v" "$T/flat.v" --background 255 2>/dev/null
vips dzsave "$T/flat.v" "$T/map" --tile-size 512 --overlap 1 \
  --suffix .png --layout dz 2>/dev/null
W=$(vipsheader -f width  "$T/flat.v" 2>/dev/null)
H=$(vipsheader -f height "$T/flat.v" 2>/dev/null)
rm -f "$T/full.v" "$T/flat.v"

INFO="${PDFBASE} · ${W}×${H}px @ ${DPI}dpi"
if [ -n "${REVISION:-}" ]; then
  INFO="SVN r${REVISION} · built $(date -u +%Y-%m-%d) · ${INFO}"
fi

cat > "$OUTDIR/$HTML" <<EOF
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${NAME} – deep zoom</title>
<style>
  html, body { margin: 0; height: 100%; background: #2b2b2b; font-family: system-ui, sans-serif; }
  #viewer { position: absolute; inset: 0; }
  #info { position: absolute; left: 10px; bottom: 10px; z-index: 10; color: #ddd;
          background: rgba(0,0,0,.55); padding: 4px 8px; border-radius: 4px; font-size: 12px; }
  #info a { color: #9cf; }
</style>
</head>
<body>
<div id="viewer"></div>
<div id="info">${INFO} · <a href="${PDFBASE}">open PDF</a></div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/openseadragon/4.1.0/openseadragon.min.js"></script>
<script>
  OpenSeadragon({
    id: "viewer",
    prefixUrl: "https://cdnjs.cloudflare.com/ajax/libs/openseadragon/4.1.0/images/",
    // Inline DZI descriptor so it also works when opened via file:// (no XHR).
    tileSources: {
      Image: {
        xmlns: "http://schemas.microsoft.com/deepzoom/2008",
        Url: "${TILES}/map_files/",
        Format: "png",
        Overlap: "1",
        TileSize: "512",
        Size: { Width: "${W}", Height: "${H}" }
      }
    },
    showNavigator: true,
    navigatorPosition: "TOP_RIGHT",
    maxZoomPixelRatio: 4,
    visibilityRatio: 0.5,
    constrainDuringPan: true,
    gestureSettingsMouse: { clickToZoom: false, dblClickToZoom: true },
    showRotationControl: true,
    showFullPageControl: true
  });
</script>
</body>
</html>
EOF

echo "Done: $OUTDIR/$HTML  (${W}x${H}px, $(find "$T" -name '*.png' | wc -l) tiles, $(du -sh "$T" | cut -f1))"
