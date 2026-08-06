import React, { useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate, useLocation, useNavigate } from 'react-router-dom';
import AnimatedBackground from './components/AnimatedBackground';
import { Toaster } from 'react-hot-toast';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { setUnauthorizedHandler } from './services/api';
import ErrorBoundary from './components/Common/ErrorBoundary';
import MainLayout       from './components/Layout/MainLayout';
import PrivateRoute     from './components/Common/PrivateRoute';

/**
 * RETEST-5 fix : helper qui transforme un lazy() en lazy-avec-retry
 * Si le chunk JS echoue (reseau, HMR conflict, AnimatePresence race),
 * on retente 2 fois apres 500ms. Si tout echoue on affiche une page
 * d'erreur lisible au lieu d'un spinner infini.
 */
function lazyRetry(loader, label = 'la page') {
  return React.lazy(() =>
    loader()
      .catch(() => new Promise((res) => setTimeout(res, 500)).then(loader))
      .catch(() => new Promise((res) => setTimeout(res, 1500)).then(loader))
      .catch(() => ({
        default: () => (
          <div className="flex flex-col items-center justify-center min-h-[300px] gap-4 p-8 text-center">
            <div className="text-5xl">⚠️</div>
            <h2 className="text-xl font-semibold text-gray-800">
              Impossible de charger {label}
            </h2>
            <p className="text-gray-500 text-sm max-w-md">
              Le module n'a pas pu etre telecharge. Verifiez votre connexion
              et rechargez la page.
            </p>
            <button
              type="button"
              onClick={() => window.location.reload()}
              className="px-4 py-2 bg-at-green text-white rounded-lg hover:opacity-90"
            >
              Recharger
            </button>
          </div>
        ),
      }))
  );
}

const Organigramme     = lazyRetry(() => import('./pages/Organigramme'), "l'organigramme");
const Login            = lazyRetry(() => import('./pages/auth/Login'), 'la connexion');
const Register         = lazyRetry(() => import('./pages/auth/Register'), "l'inscription");
const Dashboard        = lazyRetry(() => import('./pages/dashboard/Dashboard'), 'le tableau de bord');
const MissionsList     = lazyRetry(() => import('./pages/missions/MissionsList'), 'la liste des missions');
const MissionDetail    = lazyRetry(() => import('./pages/missions/MissionDetail'), 'le detail de la mission');
const NewMissionWizard = lazyRetry(() => import('./pages/missions/NewMission/NewMissionWizard'), 'le formulaire de mission');
const Validations      = lazyRetry(() => import('./pages/validations/Validations'), 'les validations');
const Messagerie       = lazyRetry(() => import('./pages/messagerie/Messagerie'), 'la messagerie');
const Notifications    = lazyRetry(() => import('./pages/notifications/Notifications'), 'les notifications');
const Profil           = lazyRetry(() => import('./pages/profil/Profil'), 'le profil');
const Utilisateurs     = lazyRetry(() => import('./pages/admin/Utilisateurs'), 'la liste des utilisateurs');
const Prestataires     = lazyRetry(() => import('./pages/admin/Prestataires'), 'les prestataires');
const Budgets          = lazyRetry(() => import('./pages/admin/Budgets'), 'les budgets');
const AuditLogs        = lazyRetry(() => import('./pages/admin/AuditLogs'), "le journal d'audit");
const Statistiques     = lazyRetry(() => import('./pages/admin/Statistiques'), 'les statistiques');
const Rapports         = lazyRetry(() => import('./pages/rapports/Rapports'), 'les rapports');
const DmlDashboard     = lazyRetry(() => import('./pages/dml/DmlDashboard'), 'le module DML');
const About              = lazyRetry(() => import('./pages/About'), 'la page A propos');
const CalendrierMissions = lazyRetry(() => import('./pages/missions/CalendrierMissions'), 'le calendrier');
const DashboardExecutif = lazyRetry(() => import('./pages/admin/DashboardExecutif'), 'le dashboard DSI');
const SimulateurBudget  = lazyRetry(() => import('./pages/admin/SimulateurBudget'), 'le simulateur budget');
const Page404          = lazyRetry(() => import('./pages/errors/Page404'), 'la page');
const Page403          = lazyRetry(() => import('./pages/errors/Page403'), 'la page');

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
  const { isAuthenticated, loading, user } = useAuth();

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
    <React.Suspense fallback={
      <div className="flex items-center justify-center h-screen bg-[#F4F6FA]">
        <div className="flex flex-col items-center gap-4">
          <div className="w-12 h-12 border-4 border-at-green/20 border-t-at-green rounded-full animate-spin" />
          <span className="text-at-green font-semibold text-lg tracking-wide">
            AT Réservations
          </span>
        </div>
      </div>
    }>
      <Routes>
        <Route path="/login"    element={isAuthenticated ? <Navigate to={user?.role?.name === 'agent_dml' ? '/dml' : '/'} /> : <Login />} />
        <Route path="/register" element={isAuthenticated ? <Navigate to={user?.role?.name === 'agent_dml' ? '/dml' : '/'} /> : <Register />} />
        <Route path="/403"      element={<Page403 />} />

        <Route element={<PrivateRoute><MainLayout /></PrivateRoute>}>
          <Route path="/"                    element={<Dashboard />} />
          <Route path="/organigramme"        element={<Organigramme />} />
          <Route path="/missions"            element={<MissionsList />} />
          <Route path="/missions/nouvelle"   element={<NewMissionWizard />} />
          <Route path="/missions/calendrier"  element={<CalendrierMissions />} />
          <Route path="/missions/:id"        element={<MissionDetail />} />
          <Route path="/validations"         element={
            <PrivateRoute roles={['validateur', 'directeur', 'admin']}>
              <Validations />
            </PrivateRoute>
          } />
          <Route path="/messagerie"          element={<Messagerie />} />
          <Route path="/notifications"       element={<Notifications />} />
          <Route path="/profil"              element={<Profil />} />
          <Route path="/about"               element={<About />} />
          <Route path="/rapports"            element={
            <PrivateRoute roles={['admin', 'directeur']}>
              <Rapports />
            </PrivateRoute>
          } />
          <Route path="/dml"               element={
            <PrivateRoute roles={['agent_dml']}>
              <DmlDashboard />
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
          <Route path="/admin/dashboard-executif" element={
            <PrivateRoute roles={['admin']}><DashboardExecutif /></PrivateRoute>
          } />
          <Route path="/admin/simulateur-budget" element={
            <PrivateRoute roles={['admin']}><SimulateurBudget /></PrivateRoute>
          } />
        </Route>

        <Route path="*" element={<Page404 />} />
      </Routes>
    </React.Suspense>
  );
}

function AnimatedBackgroundGate() {
  const { pathname } = useLocation();
  const isAuthRoute = pathname === '/login' || pathname === '/register';
  if (isAuthRoute) return null;
  return <AnimatedBackground />;
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <AnimatedBackgroundGate />
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
