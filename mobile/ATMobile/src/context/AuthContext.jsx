import React, { createContext, useCallback, useContext, useEffect, useState } from 'react';
import { authAPI } from '../services/api';
import { AuthStorage } from '../services/auth';

const AuthContext = createContext(null);

function getRoleName(user) {
  if (!user) return '';
  const r = user.role;
  if (!r) return '';
  if (typeof r === 'string') return r.toLowerCase();
  return (r.name ?? '').toLowerCase();
}

export function AuthProvider({ children }) {
  const [user,    setUser]    = useState(null);
  const [token,   setToken]   = useState(null);
  const [loading, setLoading] = useState(true);

  // Restaure la session au démarrage
  useEffect(() => {
    (async () => {
      try {
        const savedToken = await AuthStorage.getToken();
        if (savedToken) {
          setToken(savedToken);
          const res = await authAPI.me();
          const u = res.data?.data?.user ?? res.data?.data ?? null;
          if (u?.id) setUser(u);
          else        await AuthStorage.clear();
        }
      } catch {
        await AuthStorage.clear();
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  /**
   * Connexion : LDAP → fallback DB (géré côté backend).
   * Bloque l'admin sur mobile.
   */
  const login = useCallback(async (email, password) => {
    const res  = await authAPI.login(email, password);
    const body = res.data;
    const t    = body?.data?.token ?? body?.token;
    const u    = body?.data?.user  ?? body?.user;

    if (!t || !u) throw new Error('Réponse serveur invalide.');

    if (getRoleName(u) === 'admin') {
      throw new Error(
        "L'accès administrateur n'est pas disponible sur mobile.\nVeuillez utiliser la version web."
      );
    }

    await AuthStorage.saveToken(t);
    await AuthStorage.saveUser(u);
    setToken(t);
    setUser(u);
    return getRoleName(u);
  }, []);

  const logout = useCallback(async () => {
    try { await authAPI.logout(); } catch { /* ignore */ }
    await AuthStorage.clear();
    setUser(null);
    setToken(null);
  }, []);

  const refresh = useCallback(async () => {
    try {
      const res = await authAPI.me();
      const u = res.data?.data?.user ?? res.data?.data ?? null;
      if (u?.id) { setUser(u); await AuthStorage.saveUser(u); }
    } catch { /* ignore */ }
  }, []);

  const hasRole = useCallback((...roles) => {
    const r = getRoleName(user);
    return roles.some(role => r.includes(role.toLowerCase()));
  }, [user]);

  return (
    <AuthContext.Provider value={{
      user, token, loading,
      isAuthenticated: !!(user && token),
      roleName: getRoleName(user),
      login, logout, refresh, hasRole,
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth doit être utilisé dans AuthProvider');
  return ctx;
}
