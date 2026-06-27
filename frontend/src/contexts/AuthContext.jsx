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
      try {
        const res = await authAPI.me();
        const payload = res.data?.data;
        const u = extraireUser(payload);
        if (u) {
          setUser(u);
          setIsAuth(true);
        } else {
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
    setUser(null);
    setIsAuth(false);
  }, []);

  const login = async (email, password) => {
    await authAPI.login({ email, password });

    const meRes   = await authAPI.me();
    const payload = meRes.data?.data;
    const u       = extraireUser(payload);
    if (!u) {
      clearSession();
      throw new Error('Profil utilisateur invalide après connexion');
    }
    setUser(u);
    setIsAuth(true);
    return u?.role?.name ?? u?.role ?? '';
  };

  const logout = async () => {
    try { await authAPI.logout(); } catch { /* ignore */ }
    setUser(null);
    setIsAuth(false);
  };

  const updateUser = (data) => {
    if (!user || data == null) return;
    setUser({ ...user, ...data });
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
