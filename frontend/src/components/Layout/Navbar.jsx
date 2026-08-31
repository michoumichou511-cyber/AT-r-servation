import { useState, useEffect } from 'react'
import { useNavigate, useLocation, Link } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Menu, Bell, Moon, Sun, User,
  LogOut, X,
} from 'lucide-react'
import { useAuth } from '../../contexts/AuthContext'
import { notificationsAPI } from '../../services/api'

const titresRoutes = {
  '/':                    'Tableau de bord',
  '/missions':            'Mes missions',
  '/validations':         'Validations',
  '/messagerie':          'Messagerie',
  '/notifications':       'Notifications',
  '/profil':              'Mon profil',
  '/rapports':            'Rapports',
  '/admin/utilisateurs':  'Utilisateurs',
  '/admin/prestataires':  'Prestataires',
  '/admin/budgets':       'Budgets',
  '/admin/audit-logs':    'Audit Logs',
  '/admin/statistiques':  'Statistiques',
}

export default function Navbar({ onMenuClick }) {
  const { user, logout, darkMode, toggleDarkMode } = useAuth()
  const navigate  = useNavigate()
  const location  = useLocation()

  const [dropdownOpen, setDropdownOpen]   = useState(false)
  const [notifCount, setNotifCount]       = useState(0)

  const titre = titresRoutes[location.pathname] ?? 'AT Réservations'

  // Notifications : polling 60s, en pause quand l'onglet est caché (perf)
  useEffect(() => {
    if (!user) {
      setNotifCount(0)
      return
    }
    let id = null
    const tick = async () => {
      try {
        const res = await notificationsAPI.count()
        setNotifCount(res.data?.data?.count ?? res.data?.count ?? 0)
      } catch {
        /* ignore */
      }
    }
    const start = () => { if (!id) { tick(); id = setInterval(tick, 60000) } }
    const stop = () => { if (id) { clearInterval(id); id = null } }
    const onVisibility = () => (document.hidden ? stop() : start())

    if (!document.hidden) start()
    document.addEventListener('visibilitychange', onVisibility)
    return () => {
      stop()
      document.removeEventListener('visibilitychange', onVisibility)
    }
  }, [user])

  // Titre d'onglet dynamique : "(3) AT Réservations" si non-lues
  useEffect(() => {
    document.title = notifCount > 0 ? `(${notifCount}) AT Réservations` : 'AT Réservations'
    return () => { document.title = 'AT Réservations' }
  }, [notifCount])

  const handleLogout = async () => {
    setDropdownOpen(false)
    await logout()
    navigate('/login')
  }

  const initiales = [user?.prenom?.[0], user?.nom?.[0]].filter(Boolean).join('').toUpperCase()

  return (
    <header
      className="h-16 border-b flex items-center justify-between px-4 md:px-6 flex-shrink-0"
      style={{
        position: 'sticky',
        top: 0,
        zIndex: 9999,
        backdropFilter: 'blur(16px)',
        WebkitBackdropFilter: 'blur(16px)',
        ...(darkMode
          ? {
              background: 'rgba(10, 15, 30, 0.8)',
              borderBottom: '1px solid rgba(255,255,255,0.06)',
            }
          : {
              background: 'rgba(248, 250, 251, 0.85)',
              borderBottom: '1px solid #EAECF0',
            }),
      }}
    >

      {/* GAUCHE */}
      <div className="flex items-center gap-3">
        <button
          onClick={onMenuClick}
          className="lg:hidden p-2 rounded-xl text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
        >
          <Menu size={20} />
        </button>
        <h1 className="font-semibold text-gray-800 dark:text-[#E8EAF0] text-base hidden sm:block">{titre}</h1>
      </div>

      {/* DROITE */}
      <div className="flex items-center gap-2">

        {/* Dark mode */}
        <motion.button
          onClick={toggleDarkMode}
          whileTap={{ rotate: 180 }}
          transition={{ duration: 0.3 }}
          className="p-2 rounded-xl text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
        >
          {darkMode ? <Sun size={18} /> : <Moon size={18} />}
        </motion.button>

        {/* Notifications */}
        <button
          onClick={() => navigate('/notifications')}
          className="relative p-2 rounded-xl text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
        >
          <Bell size={18} />
          {notifCount > 0 && (
            <span className="absolute top-0.5 right-0.5 min-w-[18px] h-[18px] bg-gradient-to-br from-red-500 to-red-600 text-white text-[9px]
                             font-bold rounded-full flex items-center justify-center leading-none px-1 shadow-[0_2px_8px_rgba(239,68,68,0.4)] animate-at-scale-in">
              {notifCount > 99 ? '99+' : notifCount}
            </span>
          )}
        </button>

        {/* Avatar + dropdown */}
        <div className="relative" style={{ position: 'relative', zIndex: 9999 }}>
          <button
            onClick={() => setDropdownOpen(v => !v)}
            className="flex items-center gap-2 pl-1 pr-2 py-1 rounded-xl
                       hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
          >
            {user?.avatar_url
              ? <img src={user.avatar_url} alt="" className="w-8 h-8 rounded-full object-cover" />
              : (
                <div className="w-8 h-8 rounded-full bg-[#00A650] flex items-center justify-center
                                text-white text-xs font-bold">
                  {initiales || '?'}
                </div>
              )
            }
            <span className="text-sm font-medium text-gray-700 dark:text-gray-200 hidden sm:block max-w-[100px] truncate">
              {user?.prenom}
            </span>
          </button>

          <AnimatePresence>
            {dropdownOpen && (
              <>
                <div
                  className="fixed inset-0"
                  style={{ zIndex: 9999 }}
                  onClick={() => setDropdownOpen(false)}
                />
                <motion.div
                  initial={{ opacity: 0, scale: 0.95, y: -8 }}
                  animate={{ opacity: 1, scale: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.95, y: -8 }}
                  transition={{ duration: 0.15 }}
                  className="absolute right-0 top-full mt-2 w-52 bg-white dark:bg-[#1E2235] rounded-[18px] shadow-at-card-lg
                             border border-[#EAECF0] dark:border-[#2A2D3E] z-20 py-2 overflow-hidden"
                  style={{ position: 'absolute', zIndex: 10000, isolation: 'isolate' }}
                >
                  {/* Infos utilisateur */}
                  <div className="px-4 py-2.5 border-b border-gray-100 dark:border-gray-700">
                    <p className="text-sm font-semibold text-gray-800 dark:text-gray-100 truncate">
                      {user?.prenom} {user?.nom}
                    </p>
                    <p className="text-xs text-gray-400 truncate">{user?.email}</p>
                  </div>

                  <Link
                    to="/profil"
                    onClick={() => setDropdownOpen(false)}
                    className="flex items-center gap-2.5 px-4 py-2.5 text-sm text-gray-700 dark:text-gray-200
                               hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                  >
                    <User size={15} />
                    Mon profil
                  </Link>

                  <hr className="my-1 border-gray-100 dark:border-gray-700" />

                  <button
                    onClick={handleLogout}
                    className="flex items-center gap-2.5 w-full px-4 py-2.5 text-sm
                               text-red-500 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
                  >
                    <LogOut size={15} />
                    Déconnexion
                  </button>
                </motion.div>
              </>
            )}
          </AnimatePresence>
        </div>
      </div>
    </header>
  )
}
