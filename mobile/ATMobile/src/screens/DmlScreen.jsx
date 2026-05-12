import React, { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator, Alert, FlatList, RefreshControl,
  StyleSheet, Text, TextInput, TouchableOpacity, View,
} from 'react-native';
import { dmlAPI } from '../services/api';
import MissionCard from '../components/MissionCard';
import RoleGuard from '../components/RoleGuard';
import { COLORS, RADIUS, SPACING } from '../constants/theme';

function DmlItem({ mission, onRefresh }) {
  const [obs,    setObs]    = useState('');
  const [acting, setActing] = useState(false);

  const marquerOk = async () => {
    Alert.alert('Confirmer', 'Marquer la logistique comme OK pour cette mission ?', [
      { text: 'Annuler', style: 'cancel' },
      {
        text: 'Confirmer',
        onPress: async () => {
          setActing(true);
          try {
            await dmlAPI.logistiqueOk(mission.id);
            Alert.alert('🚀', 'Logistique marquée OK !');
            onRefresh();
          } catch (err) {
            Alert.alert('Erreur', err?.response?.data?.message ?? 'Echec.');
          } finally { setActing(false); }
        },
      },
    ]);
  };

  return (
    <View style={s.item}>
      <MissionCard mission={mission} onPress={() => {}} showUser />
      <View style={s.obsWrap}>
        <TextInput
          style={s.obsInput}
          placeholder="Observations (optionnel)"
          value={obs}
          onChangeText={setObs}
          multiline
        />
        <TouchableOpacity
          style={[s.okBtn, acting && s.off]}
          onPress={marquerOk}
          disabled={acting}
          activeOpacity={0.85}
        >
          {acting
            ? <ActivityIndicator color="#fff" size="small" />
            : <Text style={s.okTxt}>🚀 Logistique OK</Text>
          }
        </TouchableOpacity>
      </View>
    </View>
  );
}

export default function DmlScreen() {
  const [missions,   setMissions]   = useState([]);
  const [loading,    setLoading]    = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error,      setError]      = useState('');

  const fetch = useCallback(async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true); else setLoading(true);
    setError('');
    try {
      const res = await dmlAPI.missionsValidees();
      const data = res.data?.data?.data ?? res.data?.data ?? res.data ?? [];
      setMissions(Array.isArray(data) ? data : []);
    } catch (err) {
      setError(err?.response?.data?.message ?? 'Impossible de charger les missions.');
    } finally { setLoading(false); setRefreshing(false); }
  }, []);

  useEffect(() => { fetch(); }, [fetch]);

  return (
    <RoleGuard roles={['agent_dml']}>
      <View style={{ flex: 1, backgroundColor: COLORS.background }}>
        {loading ? (
          <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
            <ActivityIndicator size="large" color={COLORS.primary} />
          </View>
        ) : (
          <FlatList
            data={missions}
            keyExtractor={item => String(item.id)}
            contentContainerStyle={{ padding: SPACING.md, paddingBottom: SPACING.xl }}
            refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => fetch(true)} colors={[COLORS.primary]} />}
            ListEmptyComponent={
              <View style={{ alignItems: 'center', marginTop: 80 }}>
                <Text style={{ fontSize: 48, marginBottom: 12 }}>🚀</Text>
                <Text style={{ fontSize: 18, fontWeight: '700', color: COLORS.text }}>Aucune mission à traiter</Text>
              </View>
            }
            renderItem={({ item }) => <DmlItem mission={item} onRefresh={() => fetch(true)} />}
          />
        )}
      </View>
    </RoleGuard>
  );
}

const s = StyleSheet.create({
  item:    { marginBottom: SPACING.sm },
  obsWrap: { backgroundColor: COLORS.card, marginHorizontal: SPACING.md, marginTop: -4, borderBottomLeftRadius: RADIUS.md, borderBottomRightRadius: RADIUS.md, padding: SPACING.sm, elevation: 2, shadowColor: '#000', shadowOpacity: 0.04, shadowRadius: 4, shadowOffset: { width: 0, height: 1 } },
  obsInput:{ borderWidth: 1, borderColor: COLORS.border, borderRadius: RADIUS.sm, padding: SPACING.sm, minHeight: 60, fontSize: 14, color: COLORS.text, marginBottom: SPACING.sm },
  okBtn:   { backgroundColor: COLORS.primary, borderRadius: RADIUS.md, paddingVertical: 13, alignItems: 'center', elevation: 3 },
  okTxt:   { color: '#fff', fontWeight: '700', fontSize: 15 },
  off:     { opacity: 0.65 },
});
