import React from 'react';
import { Alert, ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { useAuth } from '../context/AuthContext';
import { COLORS, RADIUS, SPACING } from '../constants/theme';

const ROLE_LABELS = {
  admin:      'Administrateur',
  directeur:  'Directeur',
  assistante: 'Assistante',
  demandeur:  'Demandeur',
  agent_dml:  'Agent DML',
};

function InfoRow({ label, value }) {
  if (!value) return null;
  return (
    <View style={s.row}>
      <Text style={s.rowLabel}>{label}</Text>
      <Text style={s.rowValue}>{value}</Text>
    </View>
  );
}

export default function ProfilScreen() {
  const { user, logout, roleName } = useAuth();

  const handleLogout = () => {
    Alert.alert('Déconnexion', 'Voulez-vous vous déconnecter ?', [
      { text: 'Annuler', style: 'cancel' },
      { text: 'Déconnecter', style: 'destructive', onPress: logout },
    ]);
  };

  if (!user) return null;

  const initiales = [(user.prenom ?? '')[0], (user.nom ?? '')[0]].filter(Boolean).join('').toUpperCase() || '?';

  return (
    <ScrollView style={s.root} contentContainerStyle={s.content}>
      {/* Avatar Hero */}
      <View style={s.hero}>
        <View style={s.avatar}>
          <Text style={s.avatarText}>{initiales}</Text>
        </View>
        <Text style={s.name}>{user.prenom} {user.nom}</Text>
        <View style={s.roleBadge}>
          <Text style={s.roleText}>{ROLE_LABELS[roleName] ?? roleName}</Text>
        </View>
      </View>

      {/* Infos */}
      <View style={s.card}>
        <Text style={s.section}>Informations personnelles</Text>
        <InfoRow label="E-mail"     value={user.email} />
        <InfoRow label="Matricule"  value={user.matricule} />
        <InfoRow label="Direction"  value={user.direction} />
        <InfoRow label="Service"    value={user.service} />
        <InfoRow label="Poste"      value={user.poste} />
        <InfoRow label="Téléphone"  value={user.telephone} />
      </View>

      {/* Déconnexion */}
      <TouchableOpacity style={s.logoutBtn} onPress={handleLogout} activeOpacity={0.85}>
        <Text style={s.logoutText}>🚪  Se déconnecter</Text>
      </TouchableOpacity>

      <Text style={s.footer}>AT Réservations · Algérie Télécom · v1.0</Text>
    </ScrollView>
  );
}

const s = StyleSheet.create({
  root:      { flex: 1, backgroundColor: COLORS.background },
  content:   { padding: SPACING.md, paddingBottom: SPACING.xl },
  hero:      { alignItems: 'center', paddingVertical: SPACING.xl, backgroundColor: COLORS.card, borderRadius: RADIUS.lg, marginBottom: SPACING.md, elevation: 3, shadowColor: '#000', shadowOpacity: 0.06, shadowRadius: 8, shadowOffset: { width: 0, height: 2 } },
  avatar:    { width: 80, height: 80, borderRadius: 40, backgroundColor: COLORS.secondary, justifyContent: 'center', alignItems: 'center', marginBottom: SPACING.md, elevation: 6 },
  avatarText:{ color: '#fff', fontSize: 28, fontWeight: '900' },
  name:      { fontSize: 20, fontWeight: '800', color: COLORS.text, marginBottom: 8 },
  roleBadge: { backgroundColor: COLORS.primary, paddingHorizontal: 16, paddingVertical: 4, borderRadius: RADIUS.full },
  roleText:  { color: '#fff', fontWeight: '700', fontSize: 13 },
  card:      { backgroundColor: COLORS.card, borderRadius: RADIUS.md, padding: SPACING.md, marginBottom: SPACING.md, elevation: 2, shadowColor: '#000', shadowOpacity: 0.05, shadowRadius: 4, shadowOffset: { width: 0, height: 1 } },
  section:   { fontSize: 12, fontWeight: '700', color: COLORS.secondary, textTransform: 'uppercase', letterSpacing: 0.5, marginBottom: SPACING.sm },
  row:       { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 10, borderBottomWidth: 1, borderBottomColor: COLORS.border },
  rowLabel:  { fontSize: 14, color: COLORS.textSecondary, flex: 1 },
  rowValue:  { fontSize: 14, color: COLORS.text, fontWeight: '600', flex: 1.5, textAlign: 'right' },
  logoutBtn: { backgroundColor: COLORS.error, borderRadius: RADIUS.md, paddingVertical: 15, alignItems: 'center', marginBottom: SPACING.md, elevation: 3 },
  logoutText:{ color: '#fff', fontWeight: '700', fontSize: 16 },
  footer:    { textAlign: 'center', color: COLORS.textSecondary, fontSize: 11, marginTop: 8 },
});
