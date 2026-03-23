import { useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { setUnauthorizedHandler } from './services/api';
import ErrorBoundary from './components/Common/ErrorBoundary';
import MainLayout       from './components/Layout/MainLayout';
import PrivateRoute     from './components/Common/PrivateRoute';
import Login            from './pages/auth/Login';
import Register         from './pages/auth/Register';
import Dashboard        from './pages/dashboard/Dashboard';
import MissionsList     from './pages/missions/MissionsList';
import MissionDetail    from './pages/missions/MissionDetail';
import NewMissionWizard from './pages/missions/NewMission/NewMissionWizard';
import Validations      from './pages/validations/Validations';
import Messagerie       from './pages/messagerie/Messagerie';
import Notifications    from './pages/notifications/Notifications';
import Profil           from './pages/profil/Profil';
import Utilisateurs     from './pages/admin/Utilisateurs';
import Prestataires     from './pages/admin/Prestataires';
import Budgets          from './pages/admin/Budgets';
import AuditLogs        from './pages/admin/AuditLogs';
import Statistiques     from './pages/admin/Statistiques';
import Rapports         from './pages/rapports/Rapports';
import Page404          from './pages/errors/Page404';
import Page403          from './pages/errors/Page403';

/** 401 : déconnexion SPA sans rechargement complet (évite flash blanc). */
function SessionExpiredNav() {
  const navigate = useNavigate();
  const { clearSession } = useAuth();

  useEffect(() => {
    setUnauthorizedHandler(() => {
      clearSession();
      navigate('/login', { replace: true });
    });
    return () => setUnauthorizedHandler(null);
  }, [navigate, clearSession]);

  return null;
}

function AppRoutes() {
  const { isAuthenticated, loading } = useAuth();

  if (loading) return (
    <div className="flex items-center justify-center h-screen bg-[#F4F6FA]">
      <div className="flex flex-col items-center gap-4">
        <div className="w-12 h-12 border-4 border-at-green/20 border-t-at-green rounded-full animate-spin" />
        <span className="text-at-green font-semibold text-lg tracking-wide">
          AT Réservations
        </span>
      </div>
    </div>
  );

  return (
    <Routes>
      <Route path="/login"    element={isAuthenticated ? <Navigate to="/" /> : <Login />} />
      <Route path="/register" element={isAuthenticated ? <Navigate to="/" /> : <Register />} />
      <Route path="/403"      element={<Page403 />} />

      <Route element={<PrivateRoute><MainLayout /></PrivateRoute>}>
        <Route path="/"                    element={<Dashboard />} />
        <Route path="/missions"            element={<MissionsList />} />
        <Route path="/missions/nouvelle"   element={<NewMissionWizard />} />
        <Route path="/missions/:id"        element={<MissionDetail />} />
        <Route path="/validations"         element={
          <PrivateRoute roles={['validateur', 'admin']}>
            <Validations />
          </PrivateRoute>
        } />
        <Route path="/messagerie"          element={<Messagerie />} />
        <Route path="/notifications"       element={<Notifications />} />
        <Route path="/profil"              element={<Profil />} />
        <Route path="/rapports"            element={
          <PrivateRoute roles={['admin', 'validateur']}>
            <Rapports />
          </PrivateRoute>
        } />
        <Route path="/admin/utilisateurs"  element={
          <PrivateRoute roles={['admin']}><Utilisateurs /></PrivateRoute>
        } />
        <Route path="/admin/prestataires"  element={
          <PrivateRoute roles={['admin']}><Prestataires /></PrivateRoute>
        } />
        <Route path="/admin/budgets"       element={
          <PrivateRoute roles={['admin']}><Budgets /></PrivateRoute>
        } />
        <Route path="/admin/audit-logs"    element={
          <PrivateRoute roles={['admin']}><AuditLogs /></PrivateRoute>
        } />
        <Route path="/admin/statistiques"  element={
          <PrivateRoute roles={['admin']}><Statistiques /></PrivateRoute>
        } />
      </Route>

      <Route path="*" element={<Page404 />} />
    </Routes>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <SessionExpiredNav />
        <Toaster
          position="top-right"
          toastOptions={{
            duration: 3000,
            style: { fontFamily: 'IBM Plex Sans', fontSize: '13px' },
          }}
        />
        <ErrorBoundary variant="fullscreen">
          <AppRoutes />
        </ErrorBoundary>
      </AuthProvider>
    </BrowserRouter>
  );
}
