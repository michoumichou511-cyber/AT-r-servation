import React, { useState } from 'react';
import {
  ActivityIndicator, KeyboardAvoidingView, Platform,
  ScrollView, StyleSheet, Text, TouchableOpacity, View,
} from 'react-native';
import { TextInput } from 'react-native-paper';
import { useAuth } from '../context/AuthContext';
import { COLORS, RADIUS, SPACING } from '../constants/theme';

export default function LoginScreen() {
  const { login } = useAuth();
  const [email,    setEmail]    = useState('');
  const [password, setPassword] = useState('');
  const [hidden,   setHidden]   = useState(true);
  const [loading,  setLoading]  = useState(false);
  const [error,    setError]    = useState('');

  const handleLogin = async () => {
    if (!email.trim() || !password) {
      setError('Veuillez renseigner tous les champs.');
      return;
    }
    setError('');
    setLoading(true);
    try {
      await login(email.trim(), password);
      // La navigation est gérée par App.jsx qui écoute isAuthenticated
    } catch (err) {
      setError(err?.message ?? 'Identifiants invalides.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView style={s.root} behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
      <ScrollView contentContainerStyle={s.scroll} keyboardShouldPersistTaps="handled">

        {/* Hero */}
        <View style={s.hero}>
          <View style={s.logoCircle}>
            <Text style={s.logoText}>AT</Text>
          </View>
          <Text style={s.heroTitle}>
            <Text style={{ color: COLORS.primary }}>AT </Text>
            <Text style={{ color: COLORS.secondary }}>Réservations</Text>
          </Text>
          <Text style={s.heroSub}>Algérie Télécom · Application Mobile</Text>
        </View>

        {/* Formulaire */}
        <View style={s.form}>
          <Text style={s.formTitle}>Connexion</Text>

          {!!error && (
            <View style={s.errBox}>
              <Text style={s.errText}>⚠️  {error}</Text>
            </View>
          )}

          <TextInput
            label="Adresse e-mail"
            value={email}
            onChangeText={setEmail}
            keyboardType="email-address"
            autoCapitalize="none"
            mode="outlined"
            outlineColor={COLORS.border}
            activeOutlineColor={COLORS.primary}
            style={s.input}
            left={<TextInput.Icon icon="email-outline" />}
          />

          <TextInput
            label="Mot de passe"
            value={password}
            onChangeText={setPassword}
            secureTextEntry={hidden}
            mode="outlined"
            outlineColor={COLORS.border}
            activeOutlineColor={COLORS.primary}
            style={s.input}
            left={<TextInput.Icon icon="lock-outline" />}
            right={
              <TextInput.Icon
                icon={hidden ? 'eye-outline' : 'eye-off-outline'}
                onPress={() => setHidden(v => !v)}
              />
            }
          />

          <TouchableOpacity
            style={[s.btn, loading && s.btnOff]}
            onPress={handleLogin}
            disabled={loading}
            activeOpacity={0.85}
          >
            {loading
              ? <ActivityIndicator color="#fff" />
              : <Text style={s.btnText}>Se connecter</Text>
            }
          </TouchableOpacity>

          <Text style={s.hint}>Utilisez vos identifiants Algérie Télécom</Text>
        </View>

        <Text style={s.footer}>© 2026 Algérie Télécom — Tous droits réservés</Text>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const s = StyleSheet.create({
  root:       { flex: 1, backgroundColor: COLORS.background },
  scroll:     { flexGrow: 1, padding: SPACING.lg },
  hero:       { alignItems: 'center', paddingVertical: SPACING.xl },
  logoCircle: { width: 90, height: 90, borderRadius: 45, backgroundColor: COLORS.secondary, justifyContent: 'center', alignItems: 'center', marginBottom: SPACING.md, elevation: 8, shadowColor: COLORS.secondary, shadowOpacity: 0.4, shadowRadius: 12, shadowOffset: { width: 0, height: 4 } },
  logoText:   { color: '#fff', fontSize: 30, fontWeight: '900' },
  heroTitle:  { fontSize: 28, fontWeight: '800', marginBottom: 6 },
  heroSub:    { fontSize: 14, color: COLORS.textSecondary },
  form:       { backgroundColor: COLORS.card, borderRadius: RADIUS.lg, padding: SPACING.lg, elevation: 4, shadowColor: '#000', shadowOpacity: 0.07, shadowRadius: 12, shadowOffset: { width: 0, height: 2 } },
  formTitle:  { fontSize: 20, fontWeight: '700', color: COLORS.text, marginBottom: SPACING.md },
  errBox:     { backgroundColor: '#FEE2E2', borderRadius: RADIUS.sm, padding: SPACING.sm, marginBottom: SPACING.md, borderLeftWidth: 4, borderLeftColor: COLORS.error },
  errText:    { color: '#B91C1C', fontSize: 14, lineHeight: 20 },
  input:      { marginBottom: SPACING.sm, backgroundColor: COLORS.card },
  btn:        { backgroundColor: COLORS.primary, borderRadius: RADIUS.md, paddingVertical: 14, alignItems: 'center', marginTop: SPACING.sm, elevation: 4 },
  btnOff:     { opacity: 0.65 },
  btnText:    { color: '#fff', fontSize: 16, fontWeight: '700' },
  hint:       { textAlign: 'center', color: COLORS.textSecondary, fontSize: 12, marginTop: SPACING.md },
  footer:     { textAlign: 'center', color: COLORS.textSecondary, fontSize: 11, marginTop: SPACING.xl },
});
