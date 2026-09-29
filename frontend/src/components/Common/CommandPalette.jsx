import { useState, useEffect, useRef, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { AnimatePresence, motion } from 'framer-motion'
import {
  Search, LayoutDashboard, FileText, CheckSquare,
  MessageCircle, Bell, User, Users, Building2,
  Wallet, ClipboardList, BarChart3, CalendarDays,
  Moon, Sun, LogOut, Command,
} from 'lucide-react'
import { useAuth } from '../../contexts/AuthContext'

export default function CommandPalette() {
  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState('')
  const [selected, setSelected] = useState(0)
  const inputRef = useRef(null)
  const navigate = useNavigate()
  const { t } = useTranslation()
  const { user, hasRole, logout, darkMode, toggleDarkMode } = useAuth()

  const isAdmin = hasRole('admin')
  const isValidateur = hasRole('validateur', 'admin')
  const isAgentDml = hasRole('agent_dml')

  useEffect(() => {
    const handler = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault()
        setOpen((v) => !v)
      }
      if (e.key === 'Escape') setOpen(false)
    }
    document.addEventListener('keydown', handler)
    return () => document.removeEventListener('keydown', handler)
  }, [])

  useEffect(() => {
    if (open) {
      setQuery('')
      setSelected(0)
      setTimeout(() => inputRef.current?.focus(), 50)
    }
  }, [open])

  const commands = useMemo(() => {
    const items = []

    if (isAgentDml) {
      items.push(
        { id: 'dml', label: t('nav.dml'), icon: LayoutDashboard, action: () => navigate('/dml') },
        { id: 'dml-missions', label: t('nav.missions'), icon: FileText, action: () => navigate('/dml/missions') },
      )
    } else {
      items.push(
        { id: 'dashboard', label: t('nav.dashboard'), icon: LayoutDashboard, action: () => navigate('/') },
      )
      if (!isAdmin) {
        items.push(
          { id: 'missions', label: t('dashboard.my_missions'), icon: FileText, action: () => navigate('/missions') },
          { id: 'calendar', label: t('nav.calendar'), icon: CalendarDays, action: () => navigate('/missions/calendrier') },
        )
      }
      if (isValidateur) {
        items.push(
          { id: 'validations', label: t('nav.validations'), icon: CheckSquare, action: () => navigate('/validations') },
        )
      }
    }

    items.push(
      { id: 'messaging', label: t('nav.messaging'), icon: MessageCircle, action: () => navigate('/messagerie') },
      { id: 'notifications', label: t('nav.notifications'), icon: Bell, action: () => navigate('/notifications') },
      { id: 'profile', label: t('nav.profile'), icon: User, action: () => navigate('/profil') },
    )

    if (isAdmin) {
      items.push(
        { id: 'users', label: t('nav.users'), icon: Users, action: () => navigate('/admin/utilisateurs'), group: t('nav.admin') },
        { id: 'providers', label: t('nav.providers'), icon: Building2, action: () => navigate('/admin/prestataires'), group: t('nav.admin') },
        { id: 'budgets', label: t('nav.budgets'), icon: Wallet, action: () => navigate('/admin/budgets'), group: t('nav.admin') },
        { id: 'audit', label: t('nav.audit_logs'), icon: ClipboardList, action: () => navigate('/admin/audit-logs'), group: t('nav.admin') },
        { id: 'stats', label: t('nav.statistics'), icon: BarChart3, action: () => navigate('/admin/statistiques'), group: t('nav.admin') },
      )
    }

    items.push(
      { id: 'dark-mode', label: darkMode ? 'Mode clair' : 'Mode sombre', icon: darkMode ? Sun : Moon, action: () => toggleDarkMode() },
      { id: 'logout', label: t('auth.logout'), icon: LogOut, action: () => { logout(); navigate('/login') } },
    )

    return items
  }, [isAdmin, isValidateur, isAgentDml, darkMode, t, navigate, logout, toggleDarkMode])

  const filtered = useMemo(() => {
    if (!query.trim()) return commands
    const q = query.toLowerCase()
    return commands.filter((c) =>
      c.label.toLowerCase().includes(q) ||
      c.id.includes(q) ||
      (c.group && c.group.toLowerCase().includes(q))
    )
  }, [query, commands])

  useEffect(() => {
    setSelected(0)
  }, [query])

  const run = (cmd) => {
    setOpen(false)
    cmd.action()
  }

  const onKeyDown = (e) => {
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      setSelected((s) => (s + 1) % filtered.length)
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      setSelected((s) => (s - 1 + filtered.length) % filtered.length)
    } else if (e.key === 'Enter' && filtered[selected]) {
      e.preventDefault()
      run(filtered[selected])
    }
  }

  if (!user) return null

  return (
    <AnimatePresence>
      {open && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.15 }}
          className="fixed inset-0 z-[99999] flex items-start justify-center pt-[15vh]"
          style={{ background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(4px)' }}
          onClick={() => setOpen(false)}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: -10 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: -10 }}
            transition={{ duration: 0.15 }}
            className="w-full max-w-lg bg-white dark:bg-[#1E2235] rounded-2xl shadow-2xl border border-gray-200 dark:border-gray-700 overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center gap-3 px-4 py-3 border-b border-gray-200 dark:border-gray-700">
              <Search size={18} className="text-gray-400 flex-shrink-0" />
              <input
                ref={inputRef}
                type="text"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={onKeyDown}
                placeholder={t('common.search') + '...'}
                className="flex-1 bg-transparent border-0 outline-none text-sm text-gray-800 dark:text-gray-100 placeholder:text-gray-400"
              />
              <kbd className="hidden sm:inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded text-[10px] font-mono text-gray-400 bg-gray-100 dark:bg-gray-700 border border-gray-200 dark:border-gray-600">
                ESC
              </kbd>
            </div>

            <div className="max-h-[340px] overflow-y-auto py-2">
              {filtered.length === 0 && (
                <p className="text-center text-sm text-gray-400 py-8">{t('common.no_data')}</p>
              )}
              {filtered.map((cmd, i) => {
                const Icon = cmd.icon
                return (
                  <button
                    key={cmd.id}
                    type="button"
                    onClick={() => run(cmd)}
                    onMouseEnter={() => setSelected(i)}
                    className={`w-full flex items-center gap-3 px-4 py-2.5 text-sm transition-colors ${
                      i === selected
                        ? 'bg-[#00A650]/10 text-[#00A650]'
                        : 'text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700/50'
                    }`}
                  >
                    <Icon size={16} className="flex-shrink-0" />
                    <span className="flex-1 text-left">{cmd.label}</span>
                    {cmd.group && (
                      <span className="text-[10px] text-gray-400 bg-gray-100 dark:bg-gray-700 px-1.5 py-0.5 rounded">
                        {cmd.group}
                      </span>
                    )}
                  </button>
                )
              })}
            </div>

            <div className="flex items-center justify-between px-4 py-2 border-t border-gray-200 dark:border-gray-700 text-[10px] text-gray-400">
              <div className="flex items-center gap-3">
                <span className="flex items-center gap-1">
                  <kbd className="px-1 py-0.5 rounded bg-gray-100 dark:bg-gray-700 font-mono">↑↓</kbd>
                  naviguer
                </span>
                <span className="flex items-center gap-1">
                  <kbd className="px-1 py-0.5 rounded bg-gray-100 dark:bg-gray-700 font-mono">↵</kbd>
                  ouvrir
                </span>
              </div>
              <div className="flex items-center gap-1">
                <Command size={10} />
                <span>+K</span>
              </div>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
