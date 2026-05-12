import React, { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator, FlatList, RefreshControl,
  StyleSheet, Text, TouchableOpacity, View,
} from 'react-native';
import { notificationsAPI } from '../services/api';
import { COLORS, RADIUS, SPACING } from '../constants/theme';

const TYPE_COLORS = {
  success: { bg: '#D1FAE5', border: COLORS.success, icon: '✅' },
  danger:  { bg: '#FEE2E2', border: COLORS.error,   icon: '❌' },
  warning: { bg: '#FEF3C7', border: COLORS.warning,  icon: '⚠️' },
  info:    { bg: '#EFF6FF', border: COLORS.info,     icon: 'ℹ️' },
};

function NotifItem({ notif, onRead }) {
  const cfg = TYPE_COLORS[notif.type] ?? TYPE_COLORS.info;
  return (
    <TouchableOpacity
      style={[s.card, { backgroundColor: cfg.bg, borderLeftColor: cfg.border }, !notif.lu && s.unread]}
      onPress={() => !notif.lu && onRead(notif.id)}
      activeOpacity={0.85}
    >
      <View style={s.row}>
        <Text style={s.icon}>{cfg.icon}</Text>
        <View style={{ flex: 1 }}>
          <Text style={s.titre}>{notif.titre}</Text>
          <Text style={s.msg} numberOfLines={3}>{notif.message}</Text>
          <Text style={s.date}>
            {new Date(notif.created_at).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })}
          </Text>
        </View>
        {!notif.lu && <View style={s.dot} />}
      </View>
    </TouchableOpacity>
  );
}

export default function NotificationsScreen() {
  const [notifs,     setNotifs]     = useState([]);
  const [loading,    setLoading]    = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetch = useCallback(async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true); else setLoading(true);
    try {
      const res = await notificationsAPI.list();
      const data = res.data?.data?.data ?? res.data?.data ?? res.data ?? [];
      setNotifs(Array.isArray(data) ? data : []);
    } catch { /* ignore */ } finally { setLoading(false); setRefreshing(false); }
  }, []);

  useEffect(() => { fetch(); }, [fetch]);

  const markRead = async (id) => {
    try {
      await notificationsAPI.markRead(id);
      setNotifs(prev => prev.map(n => n.id === id ? { ...n, lu: true } : n));
    } catch { /* ignore */ }
  };

  const markAll = async () => {
    try {
      await notificationsAPI.markAll();
      setNotifs(prev => prev.map(n => ({ ...n, lu: true })));
    } catch { /* ignore */ }
  };

  if (loading) return <View style={s.center}><ActivityIndicator size="large" color={COLORS.primary} /></View>;

  const unread = notifs.filter(n => !n.lu).length;

  return (
    <View style={{ flex: 1, backgroundColor: COLORS.background }}>
      {unread > 0 && (
        <TouchableOpacity style={s.markAllBtn} onPress={markAll}>
          <Text style={s.markAllText}>Tout marquer comme lu ({unread})</Text>
        </TouchableOpacity>
      )}
      <FlatList
        data={notifs}
        keyExtractor={item => String(item.id)}
        contentContainerStyle={s.list}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => fetch(true)} colors={[COLORS.primary]} />}
        ListEmptyComponent={
          <View style={s.empty}>
            <Text style={{ fontSize: 48, marginBottom: 12 }}>🔔</Text>
            <Text style={{ fontSize: 18, fontWeight: '700', color: COLORS.text }}>Aucune notification</Text>
          </View>
        }
        renderItem={({ item }) => <NotifItem notif={item} onRead={markRead} />}
      />
    </View>
  );
}

const s = StyleSheet.create({
  center:      { flex: 1, justifyContent: 'center', alignItems: 'center' },
  list:        { padding: SPACING.md, paddingBottom: SPACING.xl },
  card:        { borderRadius: RADIUS.md, padding: SPACING.md, marginBottom: SPACING.sm, borderLeftWidth: 4, elevation: 2, shadowColor: '#000', shadowOpacity: 0.05, shadowRadius: 4, shadowOffset: { width: 0, height: 1 } },
  unread:      { elevation: 4 },
  row:         { flexDirection: 'row', gap: 12, alignItems: 'flex-start' },
  icon:        { fontSize: 20, marginTop: 2 },
  titre:       { fontSize: 14, fontWeight: '700', color: COLORS.text, marginBottom: 4 },
  msg:         { fontSize: 13, color: COLORS.textSecondary, lineHeight: 18 },
  date:        { fontSize: 11, color: COLORS.textSecondary, marginTop: 6 },
  dot:         { width: 8, height: 8, borderRadius: 4, backgroundColor: COLORS.primary, marginTop: 6 },
  markAllBtn:  { backgroundColor: COLORS.secondary, padding: SPACING.sm, alignItems: 'center' },
  markAllText: { color: '#fff', fontWeight: '600', fontSize: 13 },
  empty:       { alignItems: 'center', marginTop: 80 },
});
