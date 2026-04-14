#!/usr/bin/env bash
# Génère les diagrammes PNG à partir de diagrammes.puml (PlantUML)
# Prérequis : Java + plantuml.jar (https://plantuml.com/download)
#
# Usage depuis la racine du dépôt :
#   bash docs/GENERER_DIAGRAMMES.sh
#
# Ou manuellement :
#   cd docs
#   java -jar plantuml.jar diagrammes.puml

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ ! -f "diagrammes.puml" ]]; then
  echo "Erreur : diagrammes.puml introuvable dans $SCRIPT_DIR" >&2
  exit 1
fi

PLANTUML_JAR="${PLANTUML_JAR:-plantuml.jar}"

if [[ ! -f "$PLANTUML_JAR" ]]; then
  echo "Placez plantuml.jar dans le dossier docs/ ou définissez PLANTUML_JAR=/chemin/vers/plantuml.jar"
  echo "Téléchargement : https://github.com/plantuml/plantuml/releases"
  exit 1
fi

java -jar "$PLANTUML_JAR" diagrammes.puml
echo "OK : fichiers PNG générés à côté de diagrammes.puml"
