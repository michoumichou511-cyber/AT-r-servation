import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { COLORS, RADIUS } from '../constants/theme';

const STATUT = {
  brouillon:                { label: 'Brouillon',     bg: '#F3F4F6', color: '#6B7280' },
  soumis:                   { label: 'Soumis',        bg: '#EFF6FF', color: COLORS.info },
  en_validation:            { label: 'En validation', bg: '#FEF3C7', color: COLORS.warning },
  approuve:                 { label: 'Approuvée',     bg: '#D1FAE5', color: COLORS.success },
  rejete:                   { label: 'Refusée',       bg: '#FEE2E2', color: COLORS.error },
  termine:                  { label: 'Terminée',      bg: '#D1FAE5', color: '#065F46' },
  en_traitement_logistique: { label: 'Logistique',    bg: '#E0E7FF', color: '#3730A3' },
};

export default function StatusBadge({ statut, size = 'md' }) {
  const cfg = STATUT[statut] ?? { label: statut, bg: '#F3F4F6', color: '#374151' };
  const sm  = size === 'sm';
  return (
    <View style={[s.badge, { backgroundColor: cfg.bg }, sm && s.small]}>
      <Text style={[s.label, { color: cfg.color }, sm && s.labelSm]}>{cfg.label}</Text>
    </View>
  );
}

const s = StyleSheet.create({
  badge:   { paddingHorizontal: 12, paddingVertical: 4, borderRadius: RADIUS.full, alignSelf: 'flex-start' },
  small:   { paddingHorizontal: 8, paddingVertical: 2 },
  label:   { fontSize: 13, fontWeight: '600' },
  labelSm: { fontSize: 11 },
});
