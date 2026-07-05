import 'package:flutter/material.dart';

// ─── Source de vérité unique pour couleurs et labels de statut ─────────────
//
// Utilisé par DS.colorForStatut(), ATColors.forStatut(), et tout widget
// qui a besoin d'afficher la couleur ou le libellé d'un statut de mission.
//
// Convention : on normalise les deux formes (avec/sans accord féminin),
// ex : 'soumis' == 'soumise', 'approuve' == 'approuvee'.

Color statusColor(String statut) {
  switch (statut.toLowerCase()) {
    case 'brouillon':
      return const Color(0xFF9CA3AF);
    case 'soumis':
    case 'soumise':
    case 'en_attente':
      return const Color(0xFF2196F3);     // bleu
    case 'en_validation':
      return const Color(0xFFFF9800);     // orange
    case 'approuve':
    case 'approuvee':
    case 'valide':
    case 'validee':
      return const Color(0xFF00A650);     // AT vert
    case 'rejete':
    case 'rejetee':
      return const Color(0xFFF44336);     // rouge
    case 'termine':
    case 'terminee':
      return const Color(0xFF9E9E9E);     // gris
    case 'annule':
    case 'annulee':
      return const Color(0xFF607D8B);     // gris bleu
    case 'en_traitement_logistique':
    case 'en_cours':
      return const Color(0xFF6366F1);     // indigo
    default:
      return const Color(0xFF9CA3AF);
  }
}

String statusLabel(String statut) {
  switch (statut.toLowerCase()) {
    case 'brouillon':                    return 'Brouillon';
    case 'soumis':
    case 'soumise':                      return 'Soumise';
    case 'en_attente':                   return 'En attente';
    case 'en_validation':                return 'En validation';
    case 'approuve':
    case 'approuvee':                    return 'Approuvée';
    case 'valide':
    case 'validee':                      return 'Validée';
    case 'rejete':
    case 'rejetee':                      return 'Rejetée';
    case 'termine':
    case 'terminee':                     return 'Terminée';
    case 'annule':
    case 'annulee':                      return 'Annulée';
    case 'en_traitement_logistique':     return 'Logistique';
    case 'en_cours':                     return 'En cours';
    default:                             return statut;
  }
}
