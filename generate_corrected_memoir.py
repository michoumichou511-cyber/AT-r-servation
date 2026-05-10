#!/usr/bin/env python3
"""
Génère le mémoire corrigé avec les UML rectifiés.
Corrections appliquées :
  - Fig 5  : Utilisateur consultatif = lecture seule uniquement
  - Fig 6  : chaîne <<extend>> corrigée (Approuver/Rejeter/Renvoyer étendent "Traiter une demande")
  - Fig 8  : table "validations" → "circuits_validation"
  - Texte II.4.2 : même correction table
"""

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import Ellipse, FancyArrowPatch
import numpy as np
import zipfile, shutil, io, re
from pathlib import Path

ORIG = '/root/.claude/uploads/083fccd4-276c-437e-8f40-cbfe617ab622/3351c54a-Memoir_FINAL_v3.docx'
OUT  = '/home/user/AT-r-servation/Memoir_AT_Reservations_FINAL_CORRIGE.docx'

IMG5 = 'ef92ff8c7054b12c2522a2f6b3091f99324332a1.png'
IMG6 = '3ccfeeb29c66d5721984e22e4b22adc0962868cb.png'
IMG8 = '193f3ec6a25daeea565db1c84945415cc5dd9776.png'

# ── helpers ───────────────────────────────────────────────────────────────────
def actor(ax, cx, cy, label, fs=8):
    r = 0.22
    head = plt.Circle((cx, cy+0.55), r, fill=False, ec='black', lw=1.4, zorder=4)
    ax.add_patch(head)
    ax.plot([cx,cx],[cy+0.33,cy+0.00], 'k-', lw=1.4, zorder=4)
    ax.plot([cx-.4,cx+.4],[cy+.18,cy+.18], 'k-', lw=1.4, zorder=4)
    ax.plot([cx,cx-.3],[cy,cy-.42], 'k-', lw=1.4, zorder=4)
    ax.plot([cx,cx+.3],[cy,cy-.42], 'k-', lw=1.4, zorder=4)
    ax.text(cx, cy-.58, label, ha='center', va='top', fontsize=fs, fontweight='bold', zorder=4)

def uc(ax, cx, cy, text, w=2.5, h=0.72, fs=7.5):
    e = Ellipse((cx,cy), w, h, facecolor='white', edgecolor='black', lw=1.3, zorder=3)
    ax.add_patch(e)
    lines = text.split('\n')
    step = 0.17
    base = cy + step*(len(lines)-1)/2
    for i,l in enumerate(lines):
        ax.text(cx, base - i*step, l, ha='center', va='center', fontsize=fs, zorder=4)

def solid(ax, x1,y1, x2,y2):
    ax.plot([x1,x2],[y1,y2],'k-',lw=1.1, zorder=2)

def dashed(ax, x1,y1, x2,y2, lbl='', loff=(0,.12)):
    ax.annotate('', xy=(x2,y2), xytext=(x1,y1),
        arrowprops=dict(arrowstyle='->', color='black', lw=1.0,
                        connectionstyle='arc3,rad=0',
                        linestyle='dashed'), zorder=2)
    if lbl:
        mx,my = (x1+x2)/2+loff[0], (y1+y2)/2+loff[1]
        ax.text(mx, my, lbl, ha='center', va='bottom', fontsize=6.5, style='italic', zorder=4)

def ext_arrow(ax, x1,y1, x2,y2, lbl='«extend»'):
    """Flèche <<extend>> : pointillée avec flèche VERS le cas de base"""
    ax.annotate('', xy=(x2,y2), xytext=(x1,y1),
        arrowprops=dict(arrowstyle='->', color='black', lw=1.0,
                        connectionstyle='arc3,rad=0',
                        linestyle='dashed'), zorder=2)
    mx,my = (x1+x2)/2, (y1+y2)/2+0.12
    ax.text(mx, my, lbl, ha='center', va='bottom', fontsize=6.5, style='italic', zorder=4)

def inc_arrow(ax, x1,y1, x2,y2, lbl='«include»'):
    """Flèche <<include>> : pointillée vers S'authentifier"""
    ax.annotate('', xy=(x2,y2), xytext=(x1,y1),
        arrowprops=dict(arrowstyle='->', color='black', lw=1.0,
                        connectionstyle='arc3,rad=0',
                        linestyle='dashed'), zorder=2)
    mx,my = (x1+x2)/2+0.05, (y1+y2)/2+0.1
    ax.text(mx, my, lbl, ha='center', va='bottom', fontsize=6, style='italic', zorder=4)

def border(ax, title):
    for sp in ax.spines.values(): sp.set_visible(False)
    ax.set_xticks([]); ax.set_yticks([])
    xl,yl = ax.get_xlim(), ax.get_ylim()
    rect = mpatches.FancyBboxPatch((xl[0]+.05,yl[0]+.05),
        xl[1]-xl[0]-.1, yl[1]-yl[0]-.1,
        boxstyle="square,pad=0", fill=False, ec='black', lw=1.5, zorder=0)
    ax.add_patch(rect)
    ax.text((xl[0]+xl[1])/2, yl[1]-.15, title, ha='center', va='top', fontsize=9, zorder=5)

def save_fig(fig, dpi=150):
    buf = io.BytesIO()
    fig.savefig(buf, format='png', dpi=dpi, bbox_inches='tight',
                facecolor='white', edgecolor='none')
    plt.close(fig)
    buf.seek(0)
    return buf.read()


# ═══════════════════════════════════════════════════════════════════════════════
# FIGURE 5 — Demandeur et Utilisateur consultatif (CORRIGÉ)
# ═══════════════════════════════════════════════════════════════════════════════
def gen_fig5():
    fig, ax = plt.subplots(figsize=(13, 11))
    ax.set_xlim(0, 13); ax.set_ylim(0, 11)
    ax.set_aspect('equal'); ax.axis('off')

    # ── Acteurs ───────────────────────────────────────────────────────────────
    actor(ax, 1.0, 8.2, 'Demandeur', fs=9)
    actor(ax, 1.0, 2.8, 'Utilisateur\nconsultatif', fs=9)

    # ── Cas d'utilisation — Demandeur ─────────────────────────────────────────
    uc(ax, 5.5, 10.0, 'Créer demande\nde mission')
    uc(ax, 5.5,  8.5, 'Soumettre\nla demande')
    uc(ax, 5.5,  7.0, 'Joindre\ndocuments')
    uc(ax, 5.5,  5.5, 'Envoyer\nmessage interne')
    uc(ax, 5.5,  4.0, 'Consulter\nmes missions')
    uc(ax, 5.5,  2.5, 'Recevoir\nnotifications')

    # ── Cas d'utilisation — Utilisateur ──────────────────────────────────────
    uc(ax, 5.5,  1.0, 'Consulter\norganigramme')

    # ── S'authentifier ────────────────────────────────────────────────────────
    uc(ax, 11.0, 5.5, "S'authentifier", w=2.8, h=0.8, fs=8)

    # ── Connexions acteur → cas (trait plein) ─────────────────────────────────
    for y in [10.0, 8.5, 7.0, 5.5, 4.0, 2.5]:
        solid(ax, 1.5, 8.2, 4.25, y)
    for y in [4.0, 2.5, 1.0]:
        solid(ax, 1.5, 2.8, 4.25, y)

    # ── <<extend>> entre cas Demandeur ────────────────────────────────────────
    ext_arrow(ax, 5.5, 9.65, 5.5, 8.86)   # Soumettre extends Créer
    ext_arrow(ax, 5.5, 8.14, 5.5, 7.36)   # Joindre extends Soumettre

    # ── <<include>> vers S'authentifier ──────────────────────────────────────
    for y in [10.0, 8.5, 7.0, 5.5, 4.0, 2.5, 1.0]:
        inc_arrow(ax, 6.75, y, 9.6, 5.5)

    # ── Cadre ─────────────────────────────────────────────────────────────────
    border(ax, "Diagramme de cas d'utilisation du Demandeur et de l'Utilisateur consultatif")

    fig.tight_layout(pad=0.5)
    return save_fig(fig, dpi=160)


# ═══════════════════════════════════════════════════════════════════════════════
# FIGURE 6 — Validateur (CORRIGÉ — extend vers "Traiter une demande")
# ═══════════════════════════════════════════════════════════════════════════════
def gen_fig6():
    fig, ax = plt.subplots(figsize=(13, 11))
    ax.set_xlim(0, 13); ax.set_ylim(0, 11)
    ax.set_aspect('equal'); ax.axis('off')

    # ── Acteur ────────────────────────────────────────────────────────────────
    actor(ax, 1.0, 5.5, 'Validateur', fs=9)

    # ── Cas d'utilisation ────────────────────────────────────────────────────
    uc(ax, 5.5, 10.0, 'Consulter demandes\nen attente')
    uc(ax, 5.5,  8.2, 'Traiter\nune demande')       # CAS DE BASE
    uc(ax, 8.5,  9.5, 'Approuver\nla demande')
    uc(ax, 8.5,  7.8, 'Rejeter la demande\n(avec motif)')
    uc(ax, 8.5,  6.1, 'Renvoyer pour\nmodification')
    uc(ax, 5.5,  4.0, 'Exporter rapports\n(PDF / Excel)')
    uc(ax, 5.5,  2.5, 'Recevoir\nnotifications')

    # ── S'authentifier ────────────────────────────────────────────────────────
    uc(ax, 11.5, 5.5, "S'authentifier", w=2.8, h=0.8, fs=8)

    # ── Connexions acteur → cas ───────────────────────────────────────────────
    for y in [10.0, 8.2, 4.0, 2.5]:
        solid(ax, 1.5, 5.5, 4.25, y)

    # ── <<extend>> depuis Traiter une demande ─────────────────────────────────
    # Flèche de l'extension vers le cas de base (convention UML : pointe vers base)
    ext_arrow(ax, 7.75, 9.5,  6.75, 8.55)
    ext_arrow(ax, 7.75, 7.8,  6.75, 8.0)
    ext_arrow(ax, 7.75, 6.1,  6.75, 7.85)

    # ── <<include>> vers S'authentifier ──────────────────────────────────────
    for y in [10.0, 8.2, 9.5, 7.8, 6.1, 4.0, 2.5]:
        xi = 6.75 if y in [10.0,8.2,4.0,2.5] else 9.75
        inc_arrow(ax, xi, y, 10.1, 5.5)

    # ── Légende ───────────────────────────────────────────────────────────────
    ax.text(5.5, 8.2+0.05, '', ha='center')  # rien
    # Petite note sous "Traiter"
    ax.text(5.5, 7.65, '(cas de base)', ha='center', va='top', fontsize=6.5, color='gray')

    border(ax, "Diagramme de cas d'utilisation du Validateur")
    fig.tight_layout(pad=0.5)
    return save_fig(fig, dpi=160)


# ═══════════════════════════════════════════════════════════════════════════════
# FIGURE 8 — Séquence Créer/Valider mission (CORRIGÉ — circuits_validation)
# ═══════════════════════════════════════════════════════════════════════════════
def gen_fig8():
    fig, ax = plt.subplots(figsize=(16, 14))
    ax.set_xlim(0, 16); ax.set_ylim(0, 14)
    ax.axis('off')

    TITLE = "Diagramme de séquence : Créer et valider une demande de mission"
    ax.text(8, 13.7, TITLE, ha='center', va='top', fontsize=11, fontweight='bold')

    # ── Participants (boîtes en haut) ─────────────────────────────────────────
    parts = [
        (1.4,  'Demandeur'),
        (4.2,  'NewMission\nWizard.jsx'),
        (7.2,  'API Laravel\n(backend)'),
        (10.5, 'BD MySQL\n(circuits_validation)'),   # ← NOM CORRIGÉ
        (14.2, 'Validateur'),
    ]

    BOX_TOP = 13.0
    BOX_H   = 0.9

    for x, lbl in parts:
        rect = mpatches.FancyBboxPatch((x-.85, BOX_TOP-BOX_H), 1.7, BOX_H,
            boxstyle="square,pad=0.08", facecolor='#E8F4FD', edgecolor='black', lw=1.2, zorder=3)
        ax.add_patch(rect)
        lines = lbl.split('\n')
        for i, l in enumerate(lines):
            ax.text(x, BOX_TOP - BOX_H/2 + (len(lines)-1-2*i)*0.14,
                    l, ha='center', va='center', fontsize=8, fontweight='bold', zorder=4)

    # ── Lignes de vie (pointillées verticales) ────────────────────────────────
    life_bottom = 0.4
    for x, _ in parts:
        ax.plot([x,x],[BOX_TOP-BOX_H, life_bottom], 'k--', lw=0.8, zorder=1, alpha=0.5)

    # ── Flèches de séquence ───────────────────────────────────────────────────
    def msg(y, x1, x2, label, ret=False, color='black'):
        ls = '--' if ret else '-'
        style = '<-' if ret else '->'
        ax.annotate('', xy=(x2,y), xytext=(x1,y),
            arrowprops=dict(arrowstyle=style, color=color, lw=1.1,
                           linestyle=ls, connectionstyle='arc3,rad=0'), zorder=2)
        lx = (x1+x2)/2
        ly = y + (0.14 if not ret else 0.14)
        ax.text(lx, ly, label, ha='center', va='bottom',
                fontsize=7.5, color=color, style=('italic' if ret else 'normal'), zorder=4)

    def self_msg(y, x, label):
        ax.annotate('', xy=(x+0.5, y-0.28), xytext=(x+0.5, y),
            arrowprops=dict(arrowstyle='->', color='black', lw=1.0,
                           connectionstyle='arc3,rad=-0.5'), zorder=2)
        ax.text(x+1.0, y-0.14, label, ha='left', va='center', fontsize=7.5, zorder=4)

    def note(y, text, color='#555555'):
        ax.text(0.1, y, text, ha='left', va='center', fontsize=7, color=color, style='italic')

    # Étape 1 — Remplir formulaire
    msg(12.2, 1.4, 4.2, 'remplir formulaire multi-étapes (4 étapes)')
    # Étape 2 — Créer mission brouillon
    msg(11.4, 4.2, 7.2, 'POST /api/missions  (statut=brouillon)')
    msg(11.1, 7.2, 10.5, 'INSERT INTO ordres_de_mission')
    msg(10.8, 10.5, 7.2, 'mission_id', ret=True)
    # Étape 3 — Ajouter réservations
    msg(10.2, 4.2, 7.2, 'POST /api/missions/{id}/reservations')
    msg(9.9,  7.2, 10.5, 'INSERT INTO reservations')
    msg(9.6,  10.5, 7.2, 'OK', ret=True)
    msg(9.3,  7.2, 4.2, 'mission enregistrée (brouillon)', ret=True)
    # Étape 4 — Soumettre
    msg(8.6, 1.4, 4.2, 'cliquer "Soumettre"')
    msg(8.2, 4.2, 7.2, 'POST /api/missions/{id}/submit')
    msg(7.9, 7.2, 10.5, 'UPDATE statut = soumis')
    msg(7.6, 7.2, 10.5, 'INSERT INTO circuits_validation')   # ← NOM CORRIGÉ
    msg(7.3, 7.2, 10.5, 'INSERT notification (validateur)')
    msg(7.0, 10.5, 7.2, 'OK', ret=True)
    msg(6.7, 7.2, 4.2, '200 — confirmation soumission', ret=True)
    msg(6.4, 4.2, 1.4, 'Mission soumise avec succès', ret=True)

    # Étape 5 — Validateur consulte
    msg(5.7, 14.2, 4.2, 'consulter liste "À valider"')
    msg(5.4, 4.2, 7.2, 'GET /api/validations?statut=en_attente')
    msg(5.1, 7.2, 10.5, 'SELECT missions + circuits_validation')  # ← NOM CORRIGÉ
    msg(4.8, 10.5, 7.2, 'liste missions', ret=True)
    msg(4.5, 7.2, 4.2, '', ret=True)
    msg(4.2, 14.2, 4.2, 'cliquer "Approuver"')

    # Étape 6 — Approbation
    msg(3.6, 4.2, 7.2, 'POST /api/validations/{id}/approuver')
    msg(3.3, 7.2, 10.5, 'UPDATE circuits_validation (statut=approuvé)')  # ← NOM CORRIGÉ
    msg(3.0, 7.2, 10.5, 'UPDATE missions (statut=approuvé)')
    msg(2.7, 7.2, 10.5, 'INSERT notification (demandeur)')
    msg(2.4, 10.5, 7.2, 'OK', ret=True)
    msg(2.1, 7.2, 4.2, '200 — mission approuvée', ret=True)
    msg(1.8, 4.2, 1.4, 'mission approuvée', ret=True)

    # ── Répéter boîtes en bas ─────────────────────────────────────────────────
    BOT = 0.38
    for x, lbl in parts:
        rect = mpatches.FancyBboxPatch((x-.85, BOT), 1.7, BOX_H,
            boxstyle="square,pad=0.08", facecolor='#E8F4FD', edgecolor='black', lw=1.2, zorder=3)
        ax.add_patch(rect)
        lines = lbl.split('\n')
        for i, l in enumerate(lines):
            ax.text(x, BOT + BOX_H/2 + (len(lines)-1-2*i)*0.14,
                    l, ha='center', va='center', fontsize=8, fontweight='bold', zorder=4)

    fig.tight_layout(pad=0.4)
    return save_fig(fig, dpi=150)


# ═══════════════════════════════════════════════════════════════════════════════
# Copier le DOCX et remplacer les images + corriger le texte
# ═══════════════════════════════════════════════════════════════════════════════
def build_docx():
    print("Génération Fig 5 (Demandeur/Utilisateur)…")
    img5 = gen_fig5()
    print("Génération Fig 6 (Validateur)…")
    img6 = gen_fig6()
    print("Génération Fig 8 (Séquence mission)…")
    img8 = gen_fig8()

    shutil.copy2(ORIG, OUT)

    # Lire tout le ZIP en mémoire
    with zipfile.ZipFile(ORIG, 'r') as zin:
        names   = zin.namelist()
        contents = {n: zin.read(n) for n in names}

    # Remplacer les 3 images
    contents[f'word/media/{IMG5}'] = img5
    contents[f'word/media/{IMG6}'] = img6
    contents[f'word/media/{IMG8}'] = img8

    # Corriger le texte dans le XML du document
    doc_xml = contents['word/document.xml'].decode('utf-8')
    # "table validations" → "table circuits_validation" (dans II.4.2)
    doc_xml = doc_xml.replace(
        'dans la table validations',
        'dans la table circuits_validation'
    )
    doc_xml = doc_xml.replace(
        'INSERT INTO validations',
        'INSERT INTO circuits_validation'
    )
    contents['word/document.xml'] = doc_xml.encode('utf-8')

    # Réécrire le DOCX
    with zipfile.ZipFile(OUT, 'w', zipfile.ZIP_DEFLATED) as zout:
        for name, data in contents.items():
            zout.writestr(name, data)

    size = Path(OUT).stat().st_size
    print(f"\nFichier généré : {OUT}")
    print(f"Taille : {size/1024:.0f} Ko")
    print("Corrections appliquées :")
    print("  ✓ Fig 5  — Utilisateur consultatif = lecture seule uniquement")
    print("  ✓ Fig 6  — <<extend>> depuis 'Traiter une demande' (plus de chaîne Approuver→Rejeter→Renvoyer)")
    print("  ✓ Fig 8  — 'circuits_validation' (nom réel de la table)")
    print("  ✓ Texte  — II.4.2 : 'table circuits_validation'")

if __name__ == '__main__':
    build_docx()
