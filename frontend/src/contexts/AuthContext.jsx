import { createContext, useContext, useState, useEffect, useCallback } from 'react';
import toast from 'react-hot-toast';
import { authAPI } from '../services/api';

const AuthContext = createContext(null);

/** Extrait l'utilisateur depuis la réponse /auth/me (évite isAuthenticated sans user). */
function extraireUser(payload) {
  if (payload == null) return null;
  const u = payload.user ?? payload;
  if (u == null || typeof u !== 'object') return null;
  if (!u.id && !u.email) return null;
  return u;
}

export function AuthProvider({ children }) {
  const [user, setUser]              = useState(null);
  const [loading, setLoading]        = useState(true);
  const [isAuthenticated, setIsAuth] = useState(false);
  const [authMethod, setAuthMethod]  = useState(
    () => localStorage.getItem('at_auth_method') ?? 'db'
  );
  const [darkMode, setDarkMode]      = useState(
    localStorage.getItem('at_dark') === 'true'
  );

  useEffect(() => {
    if (darkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
    localStorage.setItem('at_dark', String(darkMode));
  }, [darkMode]);

  useEffect(() => {
    const verifier = async () => {
      const token = localStorage.getItem('at_token');
      if (!token) { setLoading(false); return; }
      try {
        const res = await authAPI.me();
        const payload = res.data?.data;
        const u = extraireUser(payload);
        if (u) {
          setUser(u);
          setIsAuth(true);
        } else {
          localStorage.removeItem('at_token');
          localStorage.removeItem('at_user');
          setUser(null);
          setIsAuth(false);
        }
      } catch (err) {
        const status = err.response?.status;
        if (!status) {
          toast.error('Serveur injoignable. Vérifiez votre connexion ou réessayez plus tard.');
        } else if (status !== 401) {
          toast.error(
            err.response?.data?.message ?? 'Impossible de restaurer la session.',
          );
        }
        localStorage.removeItem('at_token');
        localStorage.removeItem('at_user');
        setUser(null);
        setIsAuth(false);
      } finally {
        setLoading(false);
      }
    };
    verifier();
  }, []);

  /** Nettoie session locale (401, token invalide) sans appel API */
  const clearSession = useCallback(() => {
    localStorage.removeItem('at_token');
    localStorage.removeItem('at_user');
    localStorage.removeItem('at_auth_method');
    setUser(null);
    setIsAuth(false);
    setAuthMethod('db');
  }, []);

  const login = async (email, password) => {
    // 1. Login pour obtenir le token + auth_method
    const res  = await authAPI.login({ email, password });
    const body = res.data;
    const t    = body?.data?.token ?? body?.token;
    const am   = body?.data?.auth_method ?? 'db';
    localStorage.setItem('at_token', t);
    localStorage.setItem('at_auth_method', am);
    setAuthMethod(am);

    // 2. Récupère le profil complet avec le rôle via /auth/me
    const meRes   = await authAPI.me();
    const payload = meRes.data?.data;
    const u       = extraireUser(payload);
    if (!u) {
      clearSession();
      throw new Error('Profil utilisateur invalide après connexion');
    }
    localStorage.setItem('at_user', JSON.stringify(u));
    setUser(u);
    setIsAuth(true);
    return u?.role?.name ?? u?.role ?? '';
  };

  const logout = async () => {
    try { await authAPI.logout(); } catch { /* ignore */ }
    localStorage.removeItem('at_token');
    localStorage.removeItem('at_user');
    localStorage.removeItem('at_auth_method');
    setUser(null);
    setIsAuth(false);
    setAuthMethod('db');
  };

  const updateUser = (data) => {
    if (!user || data == null) return;
    const updated = { ...user, ...data };
    setUser(updated);
    localStorage.setItem('at_user', JSON.stringify(updated));
  };

  const hasRole = (...roles) => {
    const r = (
      user?.role?.name ?? user?.role ?? ''
    ).toLowerCase();
    return roles.some(role =>
      r.includes(role.toLowerCase())
    );
  };

  const toggleDarkMode = () => setDarkMode(prev => !prev);

  return (
    <AuthContext.Provider value={{
      user, loading, isAuthenticated,
      login, logout, clearSession, updateUser,
      hasRole, darkMode, toggleDarkMode,
      authMethod,
    }}>
      {children}
    </AuthContext.Provider>
  );
}

// Hook exporté à côté du provider — pattern classique React
// eslint-disable-next-line react-refresh/only-export-components
export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (ctx == null) {
    throw new Error('useAuth doit être utilisé dans AuthProvider');
  }
  return ctx;
};
