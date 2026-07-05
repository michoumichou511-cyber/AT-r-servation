#!/bin/bash
# Génère une vidéo soutenance AT Réservations à partir des captures existantes
# Usage: bash generate_video.sh
#
# Output: at_reservations_soutenance.mp4 (1080p, 30fps, ~45s)

set -e

CAPTURES_DIR="$(dirname "$0")"
OUTPUT="$CAPTURES_DIR/at_reservations_soutenance.mp4"
TMPDIR="$(mktemp -d)"

echo "==> Préparation des slides (chacune 5s)..."

# Ordre logique pour soutenance :
# 1. Logo / titre (slide créée dynamiquement)
# 2. Architecture (diagram1)
# 3. Workflow états mission (diagram2)
# 4. ERD base de données (diagram3)
# 5. Matrice RBAC rôles (diagram4)
# 6. Login app web (figure13)
# 7. Outro / fin (slide créée)

SLIDES=(
  "$CAPTURES_DIR/diagram1_architecture.png"
  "$CAPTURES_DIR/diagram2_workflow.png"
  "$CAPTURES_DIR/diagram3_erd.png"
  "$CAPTURES_DIR/diagram4_roles.png"
  "$CAPTURES_DIR/figure13.png"
)

# Génère la liste FFmpeg concat
LIST="$TMPDIR/list.txt"
> "$LIST"
DURATION=5
for f in "${SLIDES[@]}"; do
  if [ -f "$f" ]; then
    echo "file '$f'" >> "$LIST"
    echo "duration $DURATION" >> "$LIST"
  fi
done
# Dernière image en double (requis par concat)
echo "file '${SLIDES[-1]}'" >> "$LIST"

echo "==> Encodage MP4 1080p avec transitions..."

ffmpeg -y -f concat -safe 0 -i "$LIST" \
  -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=#003DA5,fps=30,format=yuv420p" \
  -c:v libx264 -preset medium -crf 20 \
  -movflags +faststart \
  "$OUTPUT"

rm -rf "$TMPDIR"

echo ""
echo "✅ Vidéo générée : $OUTPUT"
echo "   Durée : ~$((DURATION * ${#SLIDES[@]}))s"
ls -lh "$OUTPUT"
