import React, { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator, Alert, FlatList, Modal,
  RefreshControl, StyleSheet, Text,
  TextInput, TouchableOpacity, View,
} from 'react-native';
import { missionAPI } from '../services/api';
import MissionCard from '../components/MissionCard';
import RoleGuard from '../components/RoleGuard';
import { COLORS, RADIUS, SPACING } from '../constants/theme';

function ActionModal({ visible, title, placeholder, onConfirm, onCancel, confirmColor, confirmLabel, loading }) {
  const [text, setText] = useState('');
  const reset = () => setText('');
  return (
    <Modal visible={visible} transparent animationType="slide">
      <View style={m.overlay}>
        <View style={m.box}>
          <Text style={m.title}>{title}</Text>
          <TextInput
            style={m.input}
            placeholder={placeholder}
            value={text}
            onChangeText={setText}
            multiline
            numberOfLines={4}
            textAlignVertical="top"
          />
          <View style={m.row}>
            <TouchableOpacity style={[m.btn, m.cancel]} onPress={() => { reset(); onCancel(); }}>
              <Text style={m.cancelText}>Annuler</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[m.btn, { backgroundColor: confirmColor }, loading && m.off]}
              onPress={() => { onConfirm(text); reset(); }}
              disabled={loading || !text.trim()}
            >
              {loading ? <ActivityIndicator color="#fff" /> : <Text style={m.confirmText}>{confirmLabel}</Text>}
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
}

const m = StyleSheet.create({
  overlay:     { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'flex-end' },
  box:         { backgroundColor: '#fff', borderTopLeftRadius: 20, borderTopRightRadius: 20, padding: SPACING.lg },
  title:       { fontSize: 17, fontWeight: '700', color: COLORS.text, marginBottom: SPACING.md },
  input:       { borderWidth: 1, borderColor: COLORS.border, borderRadius: RADIUS.sm, padding: SPACING.sm, minHeight: 100, fontSize: 14, color: COLORS.text, marginBottom: SPACING.md },
  row:         { flexDirection: 'row', gap: SPACING.sm },
  btn:         { flex: 1, paddingVertical: 12, borderRadius: RADIUS.md, alignItems: 'center' },
  cancel:      { backgroundColor: COLORS.background, borderWidth: 1, borderColor: COLORS.border },
  cancelText:  { color: COLORS.text, fontWeight: '600' },
  confirmText: { color: '#fff', fontWeight: '700' },
  off:         { opacity: 0.65 },
});

function ValidationItem({ validation, onRefresh }) {
  const [rejetModal, setRejetModal]  = useState(false);
  const [modifModal, setModifModal]  = useState(false);
  const [acting,     setActing]      = useState(false);

  const approuver = async () => {
    Alert.alert('Confirmer', 'Approuver cette mission ?', [
      { text: 'Annuler', style: 'cancel' },
      {
        text: 'Approuver',
        onPress: async () => {
          setActing(true);
          try {
            await missionAPI.approuver(validation.id);
            Alert.alert('✅', 'Mission approuvée avec succès.');
            onRefresh();
          } catch (err) {
            Alert.alert('Erreur', err?.response?.data?.message ?? 'Echec de l\'approbation.');
          } finally { setActing(false); }
        },
      },
    ]);
  };

  return (
    <View style={v.card}>
      <MissionCard mission={validation.mission} onPress={() => {}} showUser />
      <View style={v.btns}>
        <TouchableOpacity style={[v.btn, { backgroundColor: COLORS.primary }]} onPress={approuver} disabled={acting}>
          <Text style={v.btnText}>✅ Valider</Text>
        </TouchableOpacity>
        <TouchableOpacity style={[v.btn, { backgroundColor: COLORS.warning }]} onPress={() => setModifModal(true)}>
          <Text style={v.btnText}>🔄 Modifier</Text>
        </TouchableOpacity>
        <TouchableOpacity style={[v.btn, { backgroundColor: COLORS.error }]} onPress={() => setRejetModal(true)}>
          <Text style={v.btnText}>❌ Refuser</Text>
        </TouchableOpacity>
      </View>

      <ActionModal
        visible={rejetModal}
        title="Motif du refus"
        placeholder="Expliquez pourquoi la mission est refusée…"
        confirmColor={COLORS.error}
        confirmLabel="Refuser"
        loading={acting}
        onCancel={() => setRejetModal(false)}
        onConfirm={async (motif) => {
          setActing(true);
          setRejetModal(false);
          try {
            await missionAPI.rejeter(validation.id, motif);
            Alert.alert('❌', 'Mission refusée.');
            onRefresh();
          } catch (err) {
            Alert.alert('Erreur', err?.response?.data?.message ?? 'Echec.');
          } finally { setActing(false); }
        }}
      />

      <ActionModal
        visible={modifModal}
        title="Demander des modifications"
        placeholder="Indiquez les modifications souhaitées…"
        confirmColor={COLORS.warning}
        confirmLabel="Envoyer"
        loading={acting}
        onCancel={() => setModifModal(false)}
        onConfirm={async (commentaire) => {
          setActing(true);
          setModifModal(false);
          try {
            await missionAPI.demanderModif(validation.id, commentaire);
            Alert.alert('🔄', 'Modifications demandées.');
            onRefresh();
          } catch (err) {
            Alert.alert('Erreur', err?.response?.data?.message ?? 'Echec.');
          } finally { setActing(false); }
        }}
      />
    </View>
  );
}

const v = StyleSheet.create({
  card: { marginBottom: SPACING.sm },
  btns: { flexDirection: 'row', gap: 6, paddingHorizontal: SPACING.md, paddingBottom: SPACING.sm, marginTop: -4 },
  btn:  { flex: 1, paddingVertical: 10, borderRadius: RADIUS.sm, alignItems: 'center' },
  btnText: { color: '#fff', fontWeight: '700', fontSize: 12 },
});

export default function ValidationScreen() {
  const [validations, setValidations] = useState([]);
  const [loading,     setLoading]     = useState(true);
  const [refreshing,  setRefreshing]  = useState(false);
  const [error,       setError]       = useState('');

  const fetch = useCallback(async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true); else setLoading(true);
    setError('');
    try {
      const res = await missionAPI.pending();
      const data = res.data?.data?.data ?? res.data?.data ?? res.data ?? [];
      setValidations(Array.isArray(data) ? data : []);
    } catch (err) {
      setError(err?.response?.data?.message ?? 'Impossible de charger les validations.');
    } finally { setLoading(false); setRefreshing(false); }
  }, []);

  useEffect(() => { fetch(); }, [fetch]);

  return (
    <RoleGuard roles={['directeur', 'admin']}>
      <View style={{ flex: 1, backgroundColor: COLORS.background }}>
        {loading ? (
          <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
            <ActivityIndicator size="large" color={COLORS.primary} />
          </View>
        ) : (
          <FlatList
            data={validations}
            keyExtractor={item => String(item.id)}
            contentContainerStyle={{ padding: SPACING.md, paddingBottom: SPACING.xl }}
            refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => fetch(true)} colors={[COLORS.primary]} />}
            ListEmptyComponent={
              <View style={{ alignItems: 'center', marginTop: 80 }}>
                <Text style={{ fontSize: 48, marginBottom: 12 }}>✅</Text>
                <Text style={{ fontSize: 18, fontWeight: '700', color: COLORS.text }}>Aucune validation en attente</Text>
              </View>
            }
            renderItem={({ item }) => <ValidationItem validation={item} onRefresh={() => fetch(true)} />}
          />
        )}
      </View>
    </RoleGuard>
  );
}
