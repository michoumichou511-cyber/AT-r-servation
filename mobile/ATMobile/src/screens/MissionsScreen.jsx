import React, { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator, FlatList, RefreshControl,
  StyleSheet, Text, View,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { missionAPI } from '../services/api';
import MissionCard from '../components/MissionCard';
import { COLORS, SPACING } from '../constants/theme';

export default function MissionsScreen() {
  const nav = useNavigation();
  const [missions,    setMissions]    = useState([]);
  const [loading,     setLoading]     = useState(true);
  const [refreshing,  setRefreshing]  = useState(false);
  const [error,       setError]       = useState('');

  const fetchMissions = useCallback(async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true); else setLoading(true);
    setError('');
    try {
      const res = await missionAPI.myMissions();
      const data = res.data?.data?.data ?? res.data?.data ?? res.data ?? [];
      setMissions(Array.isArray(data) ? data : []);
    } catch (err) {
      setError(err?.response?.data?.message ?? 'Impossible de charger les missions.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => { fetchMissions(); }, [fetchMissions]);

  if (loading) return (
    <View style={s.center}>
      <ActivityIndicator size="large" color={COLORS.primary} />
    </View>
  );

  return (
    <View style={s.root}>
      {!!error && (
        <View style={s.errBox}>
          <Text style={s.errText}>⚠️  {error}</Text>
        </View>
      )}
      <FlatList
        data={missions}
        keyExtractor={item => String(item.id)}
        contentContainerStyle={s.list}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={() => fetchMissions(true)}
            colors={[COLORS.primary]}
            tintColor={COLORS.primary}
          />
        }
        ListEmptyComponent={
          <View style={s.empty}>
            <Text style={s.emptyIcon}>📋</Text>
            <Text style={s.emptyTitle}>Aucune mission</Text>
            <Text style={s.emptySub}>Vos missions apparaîtront ici</Text>
          </View>
        }
        renderItem={({ item }) => (
          <MissionCard
            mission={item}
            onPress={() => nav.navigate('MissionDetail', { id: item.id })}
          />
        )}
      />
    </View>
  );
}

const s = StyleSheet.create({
  root:       { flex: 1, backgroundColor: COLORS.background },
  center:     { flex: 1, justifyContent: 'center', alignItems: 'center' },
  list:       { padding: SPACING.md, paddingBottom: SPACING.xl },
  errBox:     { margin: SPACING.md, backgroundColor: '#FEE2E2', borderRadius: 8, padding: SPACING.sm, borderLeftWidth: 4, borderLeftColor: COLORS.error },
  errText:    { color: '#B91C1C', fontSize: 14 },
  empty:      { flex: 1, justifyContent: 'center', alignItems: 'center', marginTop: 80 },
  emptyIcon:  { fontSize: 56, marginBottom: SPACING.md },
  emptyTitle: { fontSize: 18, fontWeight: '700', color: COLORS.text, marginBottom: 6 },
  emptySub:   { fontSize: 14, color: COLORS.textSecondary },
});
