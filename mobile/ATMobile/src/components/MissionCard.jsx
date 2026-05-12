import React from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { COLORS, RADIUS, SPACING } from '../constants/theme';
import StatusBadge from './StatusBadge';

function fmtDate(d) {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short' });
}

export default function MissionCard({ mission, onPress, showUser = false }) {
  const dest = [mission.destination_ville, mission.destination_pays].filter(Boolean).join(', ') || '—';
  return (
    <TouchableOpacity style={s.card} onPress={onPress} activeOpacity={0.85}>
      <View style={s.top}>
        <View style={{ flex: 1 }}>
          <Text style={s.num}>{mission.numero_unique ?? '#' + mission.id}</Text>
          {showUser && mission.user && (
            <Text style={s.user}>{mission.user.prenom} {mission.user.nom}</Text>
          )}
        </View>
        <StatusBadge statut={mission.statut} size="sm" />
      </View>
      <Text style={s.titre} numberOfLines={2}>
        {mission.titre ?? ('Mission — ' + dest)}
      </Text>
      <View style={s.footer}>
        <Text style={s.dest}>📍 {dest}</Text>
        <Text style={s.dates}>{fmtDate(mission.date_depart)} → {fmtDate(mission.date_retour)}</Text>
      </View>
    </TouchableOpacity>
  );
}

const s = StyleSheet.create({
  card:   { backgroundColor: COLORS.card, borderRadius: RADIUS.md, padding: SPACING.md, marginBottom: SPACING.sm, elevation: 3, shadowColor: '#000', shadowOpacity: 0.06, shadowRadius: 6, shadowOffset: { width: 0, height: 2 } },
  top:    { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 8 },
  num:    { fontSize: 11, color: COLORS.textSecondary, fontFamily: 'monospace' },
  user:   { fontSize: 12, color: COLORS.secondary, fontWeight: '600', marginTop: 2 },
  titre:  { fontSize: 15, fontWeight: '700', color: COLORS.text, marginBottom: 10, lineHeight: 20 },
  footer: { borderTopWidth: 1, borderTopColor: COLORS.border, paddingTop: 8, gap: 4 },
  dest:   { fontSize: 13, color: COLORS.textSecondary },
  dates:  { fontSize: 12, color: COLORS.textSecondary },
});
