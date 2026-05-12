import React from 'react';
import { ActivityIndicator, View } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { PaperProvider } from 'react-native-paper';
import { StatusBar } from 'expo-status-bar';

import { AuthProvider, useAuth } from './src/context/AuthContext';
import LoginScreen           from './src/screens/LoginScreen';
import MissionsScreen        from './src/screens/MissionsScreen';
import MissionDetailScreen   from './src/screens/MissionDetailScreen';
import ValidationScreen      from './src/screens/ValidationScreen';
import DmlScreen             from './src/screens/DmlScreen';
import NotificationsScreen   from './src/screens/NotificationsScreen';
import ProfilScreen          from './src/screens/ProfilScreen';
import { COLORS }            from './src/constants/theme';

const Stack = createNativeStackNavigator();
const Tab   = createBottomTabNavigator();

// ── Icônes texte (emoji) pour les onglets ─────────────────────────────────────
const TAB_ICONS = {
  Missions:      '📋',
  Validation:    '✅',
  DML:           '🚚',
  Notifications: '🔔',
  Profil:        '👤',
};

function tabIcon(name) {
  return ({ focused }) => (
    <View style={{ alignItems: 'center' }}>
      <View style={{
        width: focused ? 36 : 28, height: focused ? 36 : 28,
        borderRadius: 18,
        backgroundColor: focused ? COLORS.primary + '20' : 'transparent',
        justifyContent: 'center', alignItems: 'center',
      }}>
        <View style={{ fontSize: focused ? 22 : 18 }}>
          {/* Utiliser un Text pour l'emoji */}
        </View>
      </View>
    </View>
  );
}

// ── Bottom Tabs adaptatifs selon le rôle ─────────────────────────────────────
function MainTabs() {
  const { roleName, user } = useAuth();
  const isDirecteur = roleName === 'directeur' || roleName === 'admin';
  const isAgentDml  = roleName === 'agent_dml';

  return (
    <Tab.Navigator
      screenOptions={{
        tabBarActiveTintColor:   COLORS.primary,
        tabBarInactiveTintColor: COLORS.textSecondary,
        tabBarStyle: {
          backgroundColor:  COLORS.card,
          borderTopColor:   COLORS.border,
          paddingBottom:    8,
          paddingTop:       4,
          height:           62,
        },
        tabBarLabelStyle: { fontSize: 11, fontWeight: '600', marginBottom: 2 },
        headerStyle:   { backgroundColor: COLORS.secondary },
        headerTintColor: '#fff',
        headerTitleStyle: { fontWeight: '700', fontSize: 17 },
      }}
    >
      <Tab.Screen
        name="Missions"
        component={MissionsScreen}
        options={{ title: 'Mes missions', tabBarLabel: 'Missions', tabBarIcon: () => null }}
      />

      {isDirecteur && (
        <Tab.Screen
          name="Validation"
          component={ValidationScreen}
          options={{ title: 'Validations', tabBarLabel: 'Validation', tabBarIcon: () => null }}
        />
      )}

      {isAgentDml && (
        <Tab.Screen
          name="DML"
          component={DmlScreen}
          options={{ title: 'DML — Logistique', tabBarLabel: 'DML', tabBarIcon: () => null }}
        />
      )}

      <Tab.Screen
        name="Notifications"
        component={NotificationsScreen}
        options={{ title: 'Notifications', tabBarLabel: 'Notifs', tabBarIcon: () => null }}
      />

      <Tab.Screen
        name="Profil"
        component={ProfilScreen}
        options={{ title: 'Mon profil', tabBarLabel: 'Profil', tabBarIcon: () => null }}
      />
    </Tab.Navigator>
  );
}

// ── Navigator racine ─────────────────────────────────────────────────────────
function RootNavigator() {
  const { isAuthenticated, loading } = useAuth();

  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: COLORS.secondary }}>
        <ActivityIndicator size="large" color="#fff" />
      </View>
    );
  }

  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      {isAuthenticated ? (
        <>
          <Stack.Screen name="Main" component={MainTabs} />
          <Stack.Screen
            name="MissionDetail"
            component={MissionDetailScreen}
            options={{
              headerShown: true,
              title: 'Détail mission',
              headerStyle: { backgroundColor: COLORS.secondary },
              headerTintColor: '#fff',
              headerTitleStyle: { fontWeight: '700' },
            }}
          />
        </>
      ) : (
        <Stack.Screen name="Login" component={LoginScreen} />
      )}
    </Stack.Navigator>
  );
}

// ── App root ─────────────────────────────────────────────────────────────────
export default function App() {
  return (
    <PaperProvider>
      <AuthProvider>
        <NavigationContainer>
          <StatusBar style="light" backgroundColor={COLORS.secondary} />
          <RootNavigator />
        </NavigationContainer>
      </AuthProvider>
    </PaperProvider>
  );
}
