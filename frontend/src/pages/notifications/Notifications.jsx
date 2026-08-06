import { useCallback, useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { Bell, Briefcase, CheckCircle2, XCircle, MessageSquare, AlertTriangle, Truck, Filter } from 'lucide-react'
import toast from 'react-hot-toast'

import { notificationsAPI } from '../../services/api'
import { EmptyState, SkeletonCard, Button, Badge } from '../../components/UI'
import PageHeader from '../../components/Common/PageHeader'

function parseFrDateTime(fr) {
  if (typeof fr !== 'string') return null
  // "d/m/Y H:i:s" — pad each component to avoid invalid ISO (e.g. "14:5:30" → "14:05:30")
  const [datePart, timePart] = fr.split(' ')
  if (!datePart || !timePart) return null
  const d = datePart.split('/')
  if (d.length !== 3) return null
  const dd = String(d[0]).padStart(2, '0')
  const mm = String(d[1]).padStart(2, '0')
  const yyyy = d[2]
  const t = timePart.split(':')
  if (t.length < 3) return null
  // Date LOCALE (pas UTC) : le backend envoie l'heure locale, un suffixe "Z"
  // décalerait tous les "il y a X h" d'une heure (UTC+1 en Algérie).
  const dt = new Date(
    Number(yyyy), Number(mm) - 1, Number(dd),
    Number(t[0]), Number(t[1]), Number(t[2])
  )
  return Number.isNaN(dt.getTime()) ? null : dt
}

function groupeJour(fr) {
  const dt = parseFrDateTime(fr)
  if (!dt) return 'Plus ancien'
  const now = new Date()
  const startOfDay = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime()
  const diffJours = Math.round((startOfDay(now) - startOfDay(dt)) / 86400000)
  if (diffJours <= 0) return "Aujourd'hui"
  if (diffJours === 1) return 'Hier'
  if (diffJours < 7) return 'Cette semaine'
  return 'Plus ancien'
}

function formatRelative(fr) {
  const dt = parseFrDateTime(fr)
  if (!dt) return '—'
  const diffMs = Date.now() - dt.getTime()
  const diffMin = Math.floor(diffMs / (1000 * 60))
  if (diffMin < 1) return 'il y a moins d’une minute'
  if (diffMin < 60) return `il y a ${diffMin} min`
  const diffH = Math.floor(diffMin / 60)
  if (diffH < 24) return `il y a ${diffH} h`
  const diffD = Math.floor(diffH / 24)
  return `il y a ${diffD} j`
}

const CATEGORIES = {
  mission:    { label: 'Missions',    icon: Briefcase,    color: '#003DA5', bg: '#EFF6FF', darkBg: 'rgba(0,61,165,0.15)', border: '#003DA5' },
  validation: { label: 'Validations', icon: CheckCircle2, color: '#00A650', bg: '#DCFCE7', darkBg: 'rgba(0,166,80,0.15)', border: '#00A650' },
  logistique: { label: 'Logistique',  icon: Truck,        color: '#8B5CF6', bg: '#F3E8FF', darkBg: 'rgba(139,92,246,0.15)', border: '#8B5CF6' },
  message:    { label: 'Messages',    icon: MessageSquare, color: '#F59E0B', bg: '#FEF3C7', darkBg: 'rgba(245,158,11,0.15)', border: '#F59E0B' },
  systeme:    { label: 'Systeme',     icon: AlertTriangle, color: '#EF4444', bg: '#FEE2E2', darkBg: 'rgba(239,68,68,0.15)', border: '#EF4444' },
}

function detectCategory(n) {
  const t = ((n.type ?? '') + ' ' + (n.titre ?? '') + ' ' + (n.categorie ?? '')).toLowerCase()
  if (t.includes('mission') || t.includes('depart') || t.includes('deplacement') || t.includes('ordre')) return 'mission'
  if (t.includes('valid') || t.includes('approuv') || t.includes('rejet') || t.includes('approbation')) return 'validation'
  if (t.includes('logist') || t.includes('transport') || t.includes('billet') || t.includes('hotel') || t.includes('reserv')) return 'logistique'
  if (t.includes('message') || t.includes('chat') || t.includes('comment')) return 'message'
  if (t.includes('system') || t.includes('alert') || t.includes('warning') || t.includes('danger') || t.includes('critique')) return 'systeme'
  return 'mission'
}

export default function Notifications() {
  const navigate = useNavigate()

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [items, setItems] = useState([])
  const [pagination, setPagination] = useState(null)

  const [page, setPage] = useState(1)
  const [activeFilter, setActiveFilter] = useState('all')
  const perPage = 20

  const fetchNotifications = useCallback(async (p = page) => {
    setLoading(true)
    setError('')
    try {
      // Réponse backend : pagination Laravel (pas le format ApiResponse)
      const res = await notificationsAPI.list({ page: p, per_page: perPage })
      const data = res.data?.data ?? res.data?.notifications ?? res.data ?? []
      const pag =
        res.data?.pagination ??
        (res.data?.last_page ? res.data : null) // cas paginator brut

      setItems(Array.isArray(data) ? data : [])
      setPagination(pag)
    } catch (err) {
      setItems([])
      setError(
        err?.response?.data?.message || err?.message || 'Erreur lors du chargement des notifications'
      )
    } finally {
      setLoading(false)
    }
  }, [page])

  useEffect(() => {
    fetchNotifications(1)
    // Intentionnel : chargement initial page 1 uniquement (pas de refetch si `page` change ici)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleRetry = () => fetchNotifications(1)

  const nonLues = useMemo(() => items.filter(n => !n.is_read).length, [items])

  const filteredItems = useMemo(() => {
    if (activeFilter === 'all') return items
    return items.filter(n => detectCategory(n) === activeFilter)
  }, [items, activeFilter])

  const markAllRead = async () => {
    try {
      await notificationsAPI.marquerToutLu()
      toast.success('Toutes les notifications sont marquées lues ✅')
      setItems(prev => prev.map(n => ({ ...n, is_read: true, lue: true })))
    } catch (err) {
      toast.error(err?.response?.data?.message || err?.message || 'Erreur lors du marquage')
    }
  }

  const markOneRead = async (id) => {
    try {
      await notificationsAPI.marquerLu(id)
      setItems(prev => prev.map(n => (n.id === id ? { ...n, is_read: true, lue: true } : n)))
    } catch (err) {
      toast.error(err?.response?.data?.message || err?.message || 'Erreur')
    }
  }

  const canPaginate = useMemo(() => {
    const total = pagination?.total ?? pagination?.total ?? 0
    const last = pagination?.last_page ?? 1
    return total > perPage && last > 1
  }, [pagination])

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      <PageHeader
        title="Notifications"
        subtitle="Vos notifications"
        backTo="/"
        actions={
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" onClick={markAllRead} disabled={items.length === 0 || loading}>
              <CheckCircle2 size={16} /> Tout marquer lu
            </Button>
          </div>
        }
      />

      {/* Filter tabs */}
      {!loading && items.length > 0 && (
        <div className="flex items-center gap-2 mb-4 overflow-x-auto pb-1">
          <button
            type="button"
            onClick={() => setActiveFilter('all')}
            className={[
              'px-3 py-1.5 rounded-full text-xs font-semibold transition-all whitespace-nowrap',
              activeFilter === 'all'
                ? 'bg-[#00A650] text-white shadow-sm'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700',
            ].join(' ')}
          >
            <Filter size={12} className="inline mr-1 -mt-0.5" />
            Toutes ({items.length})
          </button>
          {Object.entries(CATEGORIES).map(([key, cat]) => {
            const count = items.filter(n => detectCategory(n) === key).length
            if (count === 0) return null
            const CatIcon = cat.icon
            return (
              <button
                key={key}
                type="button"
                onClick={() => setActiveFilter(key)}
                className={[
                  'px-3 py-1.5 rounded-full text-xs font-semibold transition-all whitespace-nowrap',
                  activeFilter === key
                    ? 'text-white shadow-sm'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700',
                ].join(' ')}
                style={activeFilter === key ? { backgroundColor: cat.color } : undefined}
              >
                <CatIcon size={12} className="inline mr-1 -mt-0.5" />
                {cat.label} ({count})
              </button>
            )
          })}
        </div>
      )}

      {loading && (
        <div className="space-y-3">
          {[0, 1, 2].map(i => (
            <SkeletonCard key={i} />
          ))}
        </div>
      )}

      {!loading && error && (
        <EmptyState
          icon={AlertTriangle}
          title="Erreur de chargement"
          subtitle={error}
          actionLabel="Réessayer"
          onAction={handleRetry}
        />
      )}

      {!loading && !error && items.length === 0 && (
        <EmptyState
          icon={Bell}
          title="Aucune notification"
          subtitle="Vous n'avez rien à voir pour le moment."
        />
      )}

      {!loading && !error && items.length > 0 && (
        <>
          <motion.div
            initial={{ scale: 0.95, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="mb-3 inline-flex items-center rounded-full border border-[#EAECF0] bg-[#E6F7EE] px-3 py-1 text-xs font-semibold text-[#00A650] dark:border-[#2A2D3E] dark:bg-[#00A650]/20 dark:text-[#4ade80]"
          >
            {nonLues > 0 ? `${nonLues} non lue(s)` : 'Tout est à jour'}
          </motion.div>

          <div className="space-y-3">
            <AnimatePresence initial={false}>
              {filteredItems.map((n, index) => {
                const isRead = !!(n.is_read ?? n.lue)
                const cat = CATEGORIES[detectCategory(n)] ?? CATEGORIES.mission
                const CatIcon = cat.icon
                const groupe = groupeJour(n.created_at)
                const groupePrecedent = index > 0 ? groupeJour(filteredItems[index - 1].created_at) : null
                const nouveauGroupe = groupe !== groupePrecedent
                return (
                  <div key={n.id ?? index}>
                  {nouveauGroupe && (
                    <div className="flex items-center gap-3 pt-2 pb-1">
                      <span className="text-[11px] font-bold uppercase tracking-wider text-gray-400 dark:text-gray-500">
                        {groupe}
                      </span>
                      <div className="flex-1 h-px bg-gray-100 dark:bg-gray-800" />
                    </div>
                  )}
                  <motion.div
                    initial={{ opacity: 0, x: -12 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: 12 }}
                    transition={{ delay: Math.min(index * 0.04, 0.3), duration: 0.25 }}
                    whileHover={{ y: -4, boxShadow: '0 8px 24px rgba(0,166,80,0.12)' }}
                    whileTap={{ scale: 0.98 }}
                    onClick={() => { if (!isRead) markOneRead(n.id) }}
                    className={[
                      'at-card-surface mb-2 flex items-start gap-3.5 rounded-[14px] p-4 cursor-pointer',
                      !isRead
                        ? 'border-l-[3px] dark:bg-opacity-20'
                        : 'border-l-[3px] border-l-transparent',
                    ].join(' ')}
                    style={!isRead ? { borderLeftColor: cat.border } : undefined}
                  >
                    <div
                      className="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0"
                      style={{
                        background: isRead ? 'var(--notif-icon-read-bg, #F1F5F9)' : cat.bg,
                        border: `1px solid ${isRead ? '#EAECF0' : cat.border}`,
                        color: cat.color,
                      }}
                    >
                      <CatIcon size={18} />
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="font-bold text-gray-900 dark:text-gray-100 text-sm truncate">
                        {n.titre ?? 'Notification'}
                      </div>
                      <div className="text-sm text-gray-700 dark:text-gray-300 mt-1 whitespace-pre-wrap">
                        {n.message ?? ''}
                      </div>
                      <div className="flex items-center gap-3 mt-2">
                        <span className="text-xs text-gray-500 dark:text-gray-400">
                          {formatRelative(n.created_at)}
                        </span>
                        <span
                          className="text-[10px] font-semibold px-2 py-0.5 rounded-full"
                          style={{ backgroundColor: `${cat.color}15`, color: cat.color }}
                        >
                          {cat.label}
                        </span>
                      </div>
                      {n.action_url && (
                        <button
                          type="button"
                          className="text-xs font-semibold text-at-green hover:underline mt-2"
                          onClick={(e) => { e.stopPropagation(); navigate(n.action_url) }}
                        >
                          Voir la mission
                        </button>
                      )}
                    </div>
                    <div className="flex flex-col items-end gap-2 flex-shrink-0">
                      {!isRead ? (
                        <Button variant="outline" size="sm" onClick={(e) => { e.stopPropagation(); markOneRead(n.id) }}>
                          Marquer lu
                        </Button>
                      ) : (
                        <div className="text-xs text-gray-400 dark:text-gray-500">Lu</div>
                      )}
                    </div>
                  </motion.div>
                  </div>
                )
              })}
            </AnimatePresence>
          </div>
        </>
      )}

      {!loading && !error && items.length > 0 && canPaginate && pagination && (
        <div className="mt-5 flex items-center justify-between">
          <Button
            variant="outline"
            size="sm"
            disabled={(pagination.current_page ?? page) <= 1}
            onClick={() => {
              const nextPage = Math.max(1, page - 1)
              setPage(nextPage)
              fetchNotifications(nextPage)
            }}
          >
            ← Précédent
          </Button>
          <div className="text-sm text-gray-500">
            Page {pagination.current_page ?? page} / {pagination.last_page ?? 1}
          </div>
          <Button
            variant="outline"
            size="sm"
            disabled={(pagination.current_page ?? page) >= (pagination.last_page ?? 1)}
            onClick={() => {
              const nextPage = page + 1
              setPage(nextPage)
              fetchNotifications(nextPage)
            }}
          >
            Suivant →
          </Button>
        </div>
      )}
    </motion.div>
  )
}
