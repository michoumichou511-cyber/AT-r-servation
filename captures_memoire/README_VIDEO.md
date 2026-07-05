# Vidéo soutenance — AT Réservations

Ce dossier contient les captures + le script pour générer une vidéo MP4 locale (gratuit, sans watermark).

## Captures disponibles

- `figure13.png` à `figure19.png` — Page de connexion AT (animation login)
- `diagram1_architecture.png` — Architecture 3 couches (React/Flutter → Laravel → MySQL)
- `diagram2_workflow.png` — Workflow états mission (Brouillon → Terminée)
- `diagram3_erd.png` — Modèle de données (7 tables, relations)
- `diagram4_roles.png` — Matrice RBAC (5 rôles × 5 actions)

## Générer la vidéo

```bash
cd captures_memoire
bash generate_video.sh
```

Output : `at_reservations_soutenance.mp4` (1080p, ~25s)

## Personnalisation

Ouvre `generate_video.sh` et modifie :
- `DURATION=5` — durée par slide (en secondes)
- `SLIDES=(...)` — ordre/liste des images
- `color=#003DA5` — couleur de fond (bleu AT)

## Ajouter du voiceover

Une fois la vidéo générée, importe-la dans :
- **DaVinci Resolve** (gratuit) → ajoute ta voix
- **CapCut** (gratuit) → simple drag-and-drop
- **OBS Studio** (gratuit) → enregistre l'écran avec narration

## Ajouter musique de fond

```bash
ffmpeg -i at_reservations_soutenance.mp4 -i musique.mp3 \
  -c:v copy -c:a aac -shortest at_reservations_avec_musique.mp4
```

Sources musique libre :
- https://pixabay.com/music/ (gratuit, commercial OK)
- https://incompetech.com (Kevin MacLeod, attribution requise)
