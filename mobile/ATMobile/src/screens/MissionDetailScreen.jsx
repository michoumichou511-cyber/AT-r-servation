import React, { useEffect, useState } from 'react';
import { ActivityIndicator, ScrollView, StyleSheet, Text, View } from 'react-native';
import { missionAPI } from '../services/api';
import StatusBadge from '../components/StatusBadge';
import { COLORS, RADIUS, SPACING } from '../constants/theme';

function Row({ label, value }) {
  return (
    <View style={s.row}>
      <Text style={s.rowLabel}>{label}</Text>
      <Text style={s.rowValue}>{value ?? '—'}</Text>
    </View>
  );
}

function fmtDate(d) {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('fr-FR', { day: '2-digit', month: 'long', year: 'numeric' });
}

export default function MissionDetailScreen({ route }) {
  const { id } = route.params;
  const [mission, setMission] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error,   setError]   = useState('');

  useEffect(() => {
    (async () => {
      try {
        const res = await missionAPI.detail(id);
        setMission(res.data?.data ?? res.data);
      } catch (err) {
        setError(err?.response?.data?.message ?? 'Impossible de charger la mission.');
      } finally {
        setLoading(false);
      }
    })();
  }, [id]);

  if (loading) return <View style={s.center}><ActivityIndicator size="large" color={COLORS.primary} /></View>;
  if (error)   return <View style={s.center}><Text style={{ color: COLORS.error }}>{error}</Text></View>;
  if (!mission) return null;

  const dest = [mission.destination_ville, mission.destination_pays].filter(Boolean).join(', ');

  return (
    <ScrollView style={s.root} contentContainerStyle={s.content}>
      {/* Header */}
      <View style={s.header}>
        <Text style={s.numero}>{mission.numero_unique ?? '#' + mission.id}</Text>
        <StatusBadge statut={mission.statut} />
        <Text style={s.titre}>{mission.titre ?? 'Mission ' + dest}</Text>
      </View>

      {/* Infos */}
      <View style={s.card}>
        <Text style={s.section}>Détails de la mission</Text>
        <Row label="Objet"        value={mission.objet} />
        <Row label="Destination"  value={dest || '—'} />
        <Row label="Date départ"  value={fmtDate(mission.date_depart)} />
        <Row label="Date retour"  value={fmtDate(mission.date_retour)} />
        <Row label="Type"         value={mission.type_mission} />
        <Row label="Budget prévu" value={mission.budget_previsionnel ? Number(mission.budget_previsionnel).toLocaleString('fr-FR') + ' DA' : null} />
      </View>

      {/* Demandeur */}
      {mission.user && (
        <View style={s.card}>
          <Text style={s.section}>Demandeur</Text>
          <Row label="Nom"       value={mission.user.prenom + ' ' + mission.user.nom} />
          <Row label="Matricule" value={mission.user.matricule} />
          <Row label="Direction" value={mission.user.direction} />
          <Row label="Service"   value={mission.user.service} />
        </View>
      )}

      {/* Logistique DML */}
      {mission.traitement_dml && (
        <View style={s.card}>
          <Text style={s.section}>Logistique DML</Text>
          {mission.traitement_dml.hotel_nom_libre && (
            <Row label="Hôtel" value={mission.traitement_dml.hotel_nom_libre} />
          )}
          <Row label="N° bon"   value={mission.traitement_dml.numero_bon} />
          <Row label="Statut"   value={mission.traitement_dml.statut} />
        </View>
      )}
    </ScrollView>
  );
}

const s = StyleSheet.create({
  root:      { flex: 1, backgroundColor: COLORS.background },
  content:   { padding: SPACING.md, paddingBottom: SPACING.xl },
  center:    { flex: 1, justifyContent: 'center', alignItems: 'center' },
  header:    { backgroundColor: COLORS.secondary, borderRadius: RADIUS.lg, padding: SPACING.lg, marginBottom: SPACING.md, alignItems: 'flex-start', gap: 8 },
  numero:    { color: 'rgba(255,255,255,0.7)', fontSize: 12, fontFamily: 'monospace' },
  titre:     { color: '#fff', fontSize: 18, fontWeight: '700', marginTop: 4, lineHeight: 24 },
  card:      { backgroundColor: COLORS.card, borderRadius: RADIUS.md, padding: SPACING.md, marginBottom: SPACING.md, elevation: 2, shadowColor: '#000', shadowOpacity: 0.05, shadowRadius: 4, shadowOffset: { width: 0, height: 1 } },
  section:   { fontSize: 13, fontWeight: '700', color: COLORS.secondary, textTransform: 'uppercase', letterSpacing: 0.5, marginBottom: SPACING.sm },
  row:       { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 8, borderBottomWidth: 1, borderBottomColor: COLORS.border },
  rowLabel:  { fontSize: 14, color: COLORS.textSecondary, flex: 1 },
  rowValue:  { fontSize: 14, color: COLORS.text, fontWeight: '600', flex: 1.5, textAlign: 'right' },
});
