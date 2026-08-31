import { useCallback, useEffect, useMemo, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { FileText, RotateCcw, Search, Clock, User, Download } from 'lucide-react'
import toast from 'react-hot-toast'

import PageHeader from '../../components/Common/PageHeader'
import { adminAPI } from '../../services/api'
import { Badge, Button, EmptyState, SkeletonCard } from '../../components/UI'

const MODULE_OPTIONS = [
  { value: 'mission', label: 'Mission' },
  { value: 'reservation', label: 'Réservation' },
  { value: 'validation', label: 'Validation' },
  { value: 'user', label: 'Utilisateur' },
  { value: 'budget', label: 'Budget' },
]

const ACTION_OPTIONS = [
  { value: 'login', label: 'login' },
  { value: 'create', label: 'create' },
  { value: 'update', label: 'update' },
  { value: 'delete', label: 'delete' },
  { value: 'approve', label: 'approve' },
  { value: 'reject', label: 'reject' },
  { value: 'export', label: 'export' },
]

const PER_PAGE_OPTIONS = [10, 25, 50, 100]

function safeText(v) {
  if (v == null) return ''
  return String(v)
}

function formatDateHeure(value) {
  if (!value) return '—'
  const d = new Date(value)
  if (Number.isNaN(d.getTime())) return '—'
  return d.toLocaleString('fr-FR', { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' })
}

function actionBadgeStyle(action) {
  const a = (action ?? '').toLowerCase()
  if (a === 'create') return 'bg-blue-100 text-blue-800 dark:bg-blue-900/40 dark:text-blue-300'
  if (a === 'update') return 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300'
  if (a === 'delete') return 'bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-300'
  if (a === 'login') return 'bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-300'
  if (a === 'approve') return 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300'
  if (a === 'reject') return 'bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-300'
  if (a === 'export') return 'bg-purple-100 text-purple-800 dark:bg-purple-900/40 dark:text-purple-300'
  return 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-300'
}

function getUserName(log) {
  const user = log.user ?? {}
  const fallback = [user?.prenom, user?.nom].filter(Boolean).join(' ')
  return user?.nom_complet ?? (fallback || '—')
}

export default function AuditLogs() {
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [items, setItems] = useState([])
  const [pagination, setPagination] = useState(null)

  const [filterModule, setFilterModule] = useState('')
  const [filterAction, setFilterAction] = useState('')
  const [filterUser, setFilterUser] = useState('')
  const [dateDebut, setDateDebut] = useState('')
  const [dateFin, setDateFin] = useState('')
  const [perPage, setPerPage] = useState(25)

  const [page, setPage] = useState(1)

  const fetchLogs = useCallback(async (p = 1) => {
    setLoading(true)
    setError('')
    try {
      const params = {
        page: p,
        per_page: perPage,
        ...(filterModule ? { module: filterModule } : {}),
        ...(filterAction ? { action: filterAction } : {}),
        ...(dateDebut ? { date_debut: dateDebut } : {}),
        ...(dateFin ? { date_fin: dateFin } : {}),
      }

      const res = await adminAPI.auditLogs(params)
      const paginator = res.data?.data?.audit_logs ?? res.data?.audit_logs ?? {}
      const list = Array.isArray(paginator.data) ? paginator.data : []
      setItems(list)
      setPagination(paginator)
    } catch (err) {
      setItems([])
      setPagination(null)
      setError(
        err?.response?.data?.message ||
          err?.response?.data?.error ||
          err?.message ||
          'Erreur lors du chargement des audit logs'
      )
    } finally {
      setLoading(false)
    }
  }, [filterModule, filterAction, dateDebut, dateFin, perPage])

  const handleRetry = () => fetchLogs(1)

  useEffect(() => {
    fetchLogs(1)
  }, [fetchLogs])

  const handleApply = () => {
    setPage(1)
    fetchLogs(1)
  }

  const canPaginate = !!pagination && (pagination.last_page ?? 1) > 1
  const current = pagination?.current_page ?? page
  const last = pagination?.last_page ?? 1

  const resetFilters = () => {
    setFilterModule('')
    setFilterAction('')
    setFilterUser('')
    setDateDebut('')
    setDateFin('')
    setPage(1)
    fetchLogs(1)
  }

  const distinctUsers = useMemo(() => {
    const map = new Map()
    items.forEach((log) => {
      const name = getUserName(log)
      if (name && name !== '—' && !map.has(name)) {
        map.set(name, name)
      }
    })
    return Array.from(map.values()).sort()
  }, [items])

  const filteredItems = useMemo(() => {
    if (!filterUser) return items
    return items.filter((log) => getUserName(log) === filterUser)
  }, [items, filterUser])

  const exportCSV = () => {
    if (filteredItems.length === 0) {
      toast.error('Aucune donnee a exporter')
      return
    }
    const header = 'Date/Heure;Utilisateur;Action;Module;Description;IP'
    const rows = filteredItems.map((log) => {
      const date = formatDateHeure(log.created_at).replace(/;/g, ',')
      const user = getUserName(log).replace(/;/g, ',')
      const action = (log.action_formattee ?? log.action ?? '').replace(/;/g, ',')
      const module = (log.module_formattee ?? log.module ?? '').replace(/;/g, ',')
      const desc = safeText(log.description).replace(/;/g, ',').replace(/\n/g, ' ')
      const ip = (log.ip_address ?? '').replace(/;/g, ',')
      return `${date};${user};${action};${module};${desc};${ip}`
    })
    const csv = '﻿' + [header, ...rows].join('\n')
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `audit_logs_${new Date().toISOString().slice(0, 10)}.csv`
    a.click()
    URL.revokeObjectURL(url)
    toast.success('Export CSV telecharge')
  }

  const selectClass = 'w-full px-3 py-3 rounded-xl border border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-700 text-sm text-gray-800 dark:text-white focus:outline-none focus:ring-1 focus:ring-at-green/30 focus:border-at-green'
  const labelClass = 'block text-xs font-semibold text-gray-500 dark:text-gray-400 mb-2'

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      <PageHeader
        title="Audit Logs"
        subtitle="Journal des actions"
        backTo="/"
        actions={
          <div className="flex items-center gap-2">
            <Button size="sm" variant="outline" onClick={exportCSV} disabled={filteredItems.length === 0}>
              <Download size={16} /> CSV
            </Button>
            <Button size="sm" variant="outline" onClick={resetFilters}>
              <RotateCcw size={16} /> Réinitialiser
            </Button>
          </div>
        }
      />

      <div className="at-card-surface dark:bg-gray-800 dark:border-gray-700 mb-6 p-4">
        <div className="grid grid-cols-1 md:grid-cols-5 gap-3">
          <div>
            <label className={labelClass}>Module</label>
            <select value={filterModule} onChange={(e) => setFilterModule(e.target.value)} className={selectClass}>
              <option value="">Tous</option>
              {MODULE_OPTIONS.map(m => (
                <option key={m.value} value={m.value}>{m.label}</option>
              ))}
            </select>
          </div>

          <div>
            <label className={labelClass}>Action</label>
            <select value={filterAction} onChange={(e) => setFilterAction(e.target.value)} className={selectClass}>
              <option value="">Toutes</option>
              {ACTION_OPTIONS.map(a => (
                <option key={a.value} value={a.value}>{a.label}</option>
              ))}
            </select>
          </div>

          <div>
            <label className={labelClass}>Utilisateur</label>
            <select value={filterUser} onChange={(e) => setFilterUser(e.target.value)} className={selectClass}>
              <option value="">Tous</option>
              {distinctUsers.map(u => (
                <option key={u} value={u}>{u}</option>
              ))}
            </select>
          </div>

          <div>
            <label className={labelClass}>Date debut</label>
            <input type="date" value={dateDebut} onChange={(e) => setDateDebut(e.target.value)} className={selectClass} />
          </div>

          <div>
            <label className={labelClass}>Date fin</label>
            <input type="date" value={dateFin} onChange={(e) => setDateFin(e.target.value)} className={selectClass} />
          </div>
        </div>

        <div className="mt-4 flex items-center justify-between gap-2 flex-wrap">
          <div className="flex items-center gap-2">
            <label className="text-xs text-gray-500 dark:text-gray-400">Par page :</label>
            <select
              value={perPage}
              onChange={(e) => { setPerPage(Number(e.target.value)); setPage(1); fetchLogs(1) }}
              className="rounded-lg border border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-700 px-2 py-1.5 text-xs text-gray-700 dark:text-gray-200 focus:outline-none"
            >
              {PER_PAGE_OPTIONS.map(n => (
                <option key={n} value={n}>{n}</option>
              ))}
            </select>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" onClick={handleRetry} disabled={loading}>
              <RotateCcw size={16} /> Recharger
            </Button>
            <Button size="sm" onClick={handleApply} disabled={loading}>
              <Search size={16} /> Appliquer
            </Button>
          </div>
        </div>
      </div>

      {loading && (
        <div className="space-y-3">
          {[0, 1, 2, 3, 4].map(i => <SkeletonCard key={i} />)}
        </div>
      )}

      {!loading && error && (
        <EmptyState
          icon={FileText}
          title="Erreur de chargement"
          subtitle={error}
          actionLabel="Reessayer"
          onAction={handleRetry}
        />
      )}

      {!loading && !error && filteredItems.length === 0 && (
        <EmptyState
          icon={Clock}
          title="Aucun log"
          subtitle="Aucune action trouvee pour les filtres actuels."
          actionLabel="Reinitialiser"
          onAction={resetFilters}
        />
      )}

      {!loading && !error && filteredItems.length > 0 && (
        <>
          <div className="at-card-surface dark:bg-gray-800 dark:border-gray-700 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="min-w-[980px] w-full">
                <thead className="at-table-head border-b border-gray-200 dark:border-gray-700">
                  <tr>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400">Date/Heure</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400">Utilisateur</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400">Action</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400">Module</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400">Description</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 dark:text-gray-400">IP</th>
                  </tr>
                </thead>
                <tbody>
                  <AnimatePresence initial={false}>
                    {filteredItems.map((log, index) => {
                      const action = log.action ?? ''
                      const module = log.module_formattee ?? log.module ?? '—'
                      const userName = getUserName(log)
                      const desc = safeText(log.description)
                      const badgeClass = actionBadgeStyle(action)
                      return (
                        <motion.tr
                          key={log.id ?? index}
                          initial={{ opacity: 0, y: 20 }}
                          animate={{ opacity: 1, y: 0 }}
                          transition={{ delay: Math.min(index * 0.05, 0.4), duration: 0.3 }}
                          whileHover={{ backgroundColor: 'rgba(0,166,80,0.04)' }}
                          className="border-b border-gray-50 dark:border-gray-700/50"
                        >
                          <td className="px-4 py-3 text-sm text-gray-700 dark:text-gray-300 whitespace-nowrap">
                            {formatDateHeure(log.created_at)}
                          </td>
                          <td className="px-4 py-3 text-sm text-gray-800 dark:text-gray-200 whitespace-nowrap">
                            <div className="flex items-center gap-2">
                              <User size={14} className="text-gray-400 dark:text-gray-500" />
                              <span className="truncate">{userName}</span>
                            </div>
                          </td>
                          <td className="px-4 py-3">
                            <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold ${badgeClass}`}>
                              {log.action_formattee ?? action}
                            </span>
                          </td>
                          <td className="px-4 py-3 text-sm text-gray-700 dark:text-gray-300 whitespace-nowrap">
                            {module}
                          </td>
                          <td className="px-4 py-3 text-sm text-gray-600 dark:text-gray-400">
                            <div className="max-w-[420px] truncate">{desc}</div>
                          </td>
                          <td className="px-4 py-3 text-sm text-gray-600 dark:text-gray-400 whitespace-nowrap">
                            {log.ip_address ?? '—'}
                          </td>
                        </motion.tr>
                      )
                    })}
                  </AnimatePresence>
                </tbody>
              </table>
            </div>
          </div>

          {canPaginate && (
            <div className="mt-4 flex items-center justify-between gap-3 flex-wrap">
              <Button
                variant="outline"
                size="sm"
                disabled={current <= 1}
                onClick={() => {
                  const next = Math.max(1, current - 1)
                  setPage(next)
                  fetchLogs(next)
                }}
              >
                Precedent
              </Button>
              <div className="text-sm text-gray-500 dark:text-gray-400">
                Page {current} / {last}
              </div>
              <Button
                variant="outline"
                size="sm"
                disabled={current >= last}
                onClick={() => {
                  const next = current + 1
                  setPage(next)
                  fetchLogs(next)
                }}
              >
                Suivant
              </Button>
            </div>
          )}
        </>
      )}
    </motion.div>
  )
}
