import { useState } from 'react'
import { NavLink, useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import {
  LayoutDashboard, FileText, CheckSquare, MessageCircle,
  Bell, User, Users, Building2, Wallet, ClipboardList,
  BarChart3, FileBarChart, LogOut, ChevronDown, ChevronRight,
  X, Settings,
} from 'lucide-react'
import { useAuth } from '../../contexts/AuthContext'
import { messagesAPI, notificationsAPI } from '../../services/api'
import { usePolling } from '../../hooks/usePolling'

const roleCouleurs = {
  admin:       'bg-purple-500',
  validateur:  'bg-blue-500',
  utilisateur: 'bg-green-500',
  demandeur:   'bg-orange-500',
}

const roleBadge = {
  admin:       'bg-purple-100 text-purple-700',
  validateur:  'bg-blue-100 text-blue-700',
  utilisateur: 'bg-green-100 text-green-700',
  demandeur:   'bg-orange-100 text-orange-700',
}

function NavItem({ to, icon: Icon, label, badge, end = false, onClick }) {
  return (
    <NavLink
      to={to}
      end={end}
      onClick={onClick}
      className={({ isActive }) => [
        'flex items-center gap-3 py-2.5 text-sm transition-all duration-200 relative group',
        isActive
          ? 'pl-2 pr-3 rounded-r-lg font-semibold bg-[#E6F7EE] text-[#00A650] border-l-[3px] border-[#00A650] dark:bg-[#1a3a2a] dark:text-[#4ade80] dark:border-[#4ade80]'
          : 'px-3 rounded-xl font-medium text-[#5A6070] hover:bg-[#F8F9FA] dark:text-gray-400 dark:hover:bg-[#252840]',
      ].join(' ')}
    >
      <Icon size={18} className="flex-shrink-0" />
      <span className="flex-1 truncate">{label}</span>
      {badge > 0 && (
        <span className="w-5 h-5 bg-red-500 text-white text-[10px] font-bold
                         rounded-full flex items-center justify-center leading-none flex-shrink-0">
          {badge > 99 ? '99+' : badge}
        </span>
      )}
    </NavLink>
  )
}

export default function Sidebar({ onClose }) {
  const { user, hasRole, logout } = useAuth()
  const navigate = useNavigate()
  const [msgCount, setMsgCount]     = useState(0)
  const [notifCount, setNotifCount] = useState(0)
  const [adminOpen, setAdminOpen]   = useState(true)

  const role = (user?.role?.name ?? user?.role ?? 'utilisateur').toLowerCase()
  const avatarColor = roleCouleurs[role] ?? 'bg-gray-500'
  const badgeColor  = roleBadge[role]  ?? 'bg-gray-100 text-gray-600'

  const initiales = [user?.prenom?.[0], user?.nom?.[0]]
    .filter(Boolean).join('').toUpperCase()

  // Sondage messages
  usePolling(async () => {
    try {
      const res = await messagesAPI.nonLusCount()
      setMsgCount(res.data?.data?.count ?? res.data?.count ?? 0)
    } catch {
      /* ignore */
    }
  }, 10000, !!user)

  // Sondage notifs
  usePolling(async () => {
    try {
      const res = await notificationsAPI.count()
      setNotifCount(res.data?.data?.count ?? res.data?.data ?? res.data?.count ?? 0)
    } catch {
      /* ignore */
    }
  }, 30000, !!user)

  const handleLogout = async () => {
    await logout()
    navigate('/login')
  }

  const isAdmin      = hasRole('admin')
  const isValidateur = hasRole('validateur', 'admin')

  return (
    <aside className="w-64 h-full bg-white border-r border-gray-100 shadow-lg
                      flex flex-col overflow-hidden">
      {/* ── HEADER ── */}
      <div className="flex items-center justify-between flex-shrink-0 min-w-0">
        <div
          style={{
            padding: '20px 16px 16px',
            borderBottom: '1px solid #EAECF0',
            background: 'linear-gradient(135deg, #f8fffe 0%, #f0f9ff 100%)',
            display: 'flex',
            alignItems: 'center',
            gap: 10,
            flex: 1,
            minWidth: 0,
          }}
        >
          <img
            src="/logo-at.jpg"
            alt="Algérie Télécom"
            style={{
              height: 40,
              width: 'auto',
              objectFit: 'contain',
              borderRadius: 8,
              background: 'white',
              padding: 2,
              border: '1px solid #EAECF0',
            }}
          />
          <div>
            <div style={{ fontWeight: 700, fontSize: 14, color: '#1A1D26' }}>
              Réservations AT
            </div>
            <div style={{ fontSize: 11, color: '#9AA0AE' }}>
              Algérie Télécom
            </div>
          </div>
        </div>
        <button
          onClick={onClose}
          className="md:hidden p-1.5 rounded-lg text-gray-400 hover:bg-gray-100"
        >
          <X size={16} />
        </button>
      </div>

      {/* ── PROFIL ── */}
      {user && (
        <div
          style={{
            margin: '12px 12px 4px',
            padding: '12px',
            borderRadius: 12,
            background:
              role === 'admin'
                ? 'linear-gradient(135deg, #F5F3FF,#EDE9FE)'
                : role === 'validateur'
                  ? 'linear-gradient(135deg, #EFF6FF,#DBEAFE)'
                  : role === 'utilisateur'
                    ? 'linear-gradient(135deg, #F0FDF4,#DCFCE7)'
                    : 'linear-gradient(135deg, #FFF7ED,#FED7AA)',
            border: '1px solid rgba(0,0,0,0.05)',
          }}
          className="dark:bg-[#252840]"
        >
          <div className="flex items-center gap-3">
            {user.avatar_url
              ? <img src={user.avatar_url} alt="" className="w-10 h-10 rounded-full object-cover flex-shrink-0" />
              : (
                <div className={`w-10 h-10 rounded-full ${avatarColor} flex items-center justify-center
                                  text-white font-bold text-sm flex-shrink-0`}>
                  {initiales || '?'}
                </div>
              )
            }
            <div className="min-w-0">
              <p className="text-sm font-semibold text-gray-800 truncate">
                {user.prenom} {user.nom}
              </p>
              <span className={`inline-block px-2 py-0.5 rounded-full text-[10px] font-semibold mt-0.5 capitalize ${badgeColor}`}>
                {role}
              </span>
            </div>
          </div>
        </div>
      )}

      {/* ── NAVIGATION ── */}
      <nav className="flex-1 overflow-y-auto px-2 py-2 space-y-0.5">
        <NavItem to="/"             icon={LayoutDashboard} label="Tableau de bord" end onClick={onClose} />
        <NavItem to="/missions"     icon={FileText}        label="Mes missions"               onClick={onClose} />

        {isValidateur && (
          <NavItem to="/validations" icon={CheckSquare} label="Validations" onClick={onClose} />
        )}

        <NavItem
          to="/messagerie"
          icon={MessageCircle}
          label="Messagerie"
          badge={msgCount}
          onClick={onClose}
        />
        <NavItem
          to="/notifications"
          icon={Bell}
          label="Notifications"
          badge={notifCount}
          onClick={onClose}
        />
        <NavItem to="/profil" icon={User} label="Mon profil" onClick={onClose} />

        {(isValidateur || isAdmin) && (
          <NavItem to="/rapports" icon={FileBarChart} label="Rapports" onClick={onClose} />
        )}

        {/* Section ADMIN */}
        {isAdmin && (
          <div className="pt-3">
            <button
              onClick={() => setAdminOpen(v => !v)}
              className="flex items-center justify-between w-full px-3 py-1.5 text-[10px]
                         font-semibold text-gray-400 uppercase tracking-widest
                         hover:text-gray-600 transition-colors"
            >
              <span>Administration</span>
              {adminOpen ? <ChevronDown size={12} /> : <ChevronRight size={12} />}
            </button>

            <AnimatePresence>
              {adminOpen && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: 'auto', opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  transition={{ duration: 0.2 }}
                  className="overflow-hidden space-y-0.5"
                >
                  <NavItem to="/admin/utilisateurs"  icon={Users}         label="Utilisateurs"  onClick={onClose} />
                  <NavItem to="/admin/prestataires"  icon={Building2}     label="Prestataires"  onClick={onClose} />
                  <NavItem to="/admin/budgets"       icon={Wallet}        label="Budgets"       onClick={onClose} />
                  <NavItem to="/admin/audit-logs"    icon={ClipboardList} label="Audit Logs"    onClick={onClose} />
                  <NavItem to="/admin/statistiques"  icon={BarChart3}     label="Statistiques"  onClick={onClose} />
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        )}
      </nav>

      {/* ── DÉCONNEXION ── */}
      <div className="px-2 py-3 border-t border-gray-100 flex-shrink-0">
        <button
          onClick={handleLogout}
          type="button"
          className="flex items-center gap-3 w-full px-3 py-2.5 rounded-xl text-sm
                     font-medium transition-all duration-200"
          style={{ color: '#EF4444' }}
          onMouseEnter={(e) => {
            e.currentTarget.style.background = '#FEF2F2'
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.background = 'transparent'
          }}
        >
          <LogOut size={18} />
          <span>Déconnexion</span>
        </button>
      </div>
    </aside>
  )
}
