import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useAuth } from '../context/AuthContext';
import { COLORS, SPACING } from '../constants/theme';

export default function RoleGuard({ roles, children, fallback }) {
  const { hasRole } = useAuth();
  if (hasRole(...roles)) return children;
  if (fallback) return fallback;
  return (
    <View style={s.center}>
      <Text style={s.icon}>🔒</Text>
      <Text style={s.title}>Accès restreint</Text>
      <Text style={s.sub}>Section réservée aux : {roles.join(', ')}</Text>
    </View>
  );
}

const s = StyleSheet.create({
  center: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: SPACING.xl, backgroundColor: COLORS.background },
  icon:   { fontSize: 48, marginBottom: SPACING.md },
  title:  { fontSize: 18, fontWeight: '700', color: COLORS.text, marginBottom: 8, textAlign: 'center' },
  sub:    { fontSize: 14, color: COLORS.textSecondary, textAlign: 'center' },
});
