import { useCallback, useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { AnimatePresence, motion } from 'framer-motion'
import { Search, Plus, FileText, RotateCcw } from 'lucide-react'
import {
  ATPageHeader,
  Badge,
  Button,
  EmptyState,
  Pagination,
  SkeletonCard,
} from '../../components/UI'
import { missionsAPI } from '../../services/api'
import { useAuth } from '../../contexts/AuthContext'

const STATUT_OPTIONS = [
  { label: 'Tous', value: '' },
  { label: 'Brouillon', value: 'brouillon' },
  { label: 'Soumis', value: 'soumis' },
  { label: 'En validation', value: 'en_validation' },
  { label: 'Approuvé', value: 'approuve' },
  { label: 'Rejeté', value: 'rejete' },
  { label: 'Annulé', value: 'annule' },
  { label: 'Terminé', value: 'termine' },
]

function formatDZD(v) {
  const n = typeof v === 'number' ? v : Number(v ?? 0)
  if (Number.isNaN(n)) return '0 DZD'
  return `${n.toLocaleString('fr-FR')} DZD`
}

const BORDER_STATUT = {
  brouillon: '#94A3B8',
  soumis: '#3B82F6',
  en_validation: '#F59E0B',
  approuve: '#00A650',
  rejete: '#EF4444',
  annule: '#6B7280',
  termine: '#8B5CF6',
}

export default function MissionsList() {
  const navigate = useNavigate()
  const { hasRole } = useAuth()

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [missions, setMissions] = useState([])
  const [pagination, setPagination] = useState(null)

  const [statut, setStatut] = useState('')
  const [search, setSearch] = useState('')
  const [debouncedSearch, setDebouncedSearch] = useState('')
  const [page, setPage] = useState(1)
  const [perPage, setPerPage] = useState(10)

  useEffect(() => {
    const t = setTimeout(() => setDebouncedSearch(search), 500)
    return () => clearTimeout(t)
  }, [search])

  const fetchMissions = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const params = {
        page,
        per_page: perPage,
        ...(statut ? { statut } : {}),
        ...(debouncedSearch ? { search: debouncedSearch } : {}),
      }
      const res = await missionsAPI.list(params)

      const data = res.data?.data
      const pag = res.data?.pagination

      setMissions(Array.isArray(data) ? data : [])
      setPagination(pag ?? null)
    } catch (err) {
      setMissions([])
      const msg =
        err?.response?.data?.message ||
        err?.message ||
        'Erreur lors du chargement des missions'
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [debouncedSearch, page, perPage, statut])

  useEffect(() => {
    fetchMissions()
  }, [fetchMissions])

  useEffect(() => {
    setPage(1)
  }, [debouncedSearch])

  const canShowPagination = useMemo(() => {
    const total = pagination?.total ?? 0
    return total > perPage
  }, [pagination, perPage])

  const handleRetry = () => {
    setPage(1)
    fetchMissions()
  }

  const missionsCount = missions.length
  const total = pagination?.total ?? missionsCount

  const canExport = hasRole('admin', 'validateur')

  const downloadBlob = (blob, filename) => {
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = filename
    document.body.appendChild(a)
    a.click()
    a.remove()
    window.URL.revokeObjectURL(url)
  }

  const handleExport = async (format) => {
    const res = await missionsAPI.export(format)
    const date = new Date()
    const stamp = [
      date.getFullYear(),
      String(date.getMonth() + 1).padStart(2, '0'),
      String(date.getDate()).padStart(2, '0'),
      '-',
      String(date.getHours()).padStart(2, '0'),
      String(date.getMinutes()).padStart(2, '0'),
    ].join('')
    const ext = format === 'pdf' ? 'pdf' : 'xlsx'
    downloadBlob(res.data, `missions_export_${stamp}.${ext}`)
  }

  const bordureStatut = (st) => {
    const s = (st ?? '').toLowerCase()
    return BORDER_STATUT[s] ?? '#94A3B8'
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
      className="pb-2"
    >
      <ATPageHeader
        title="Mes missions"
        subtitle={`${total} mission(s) au total`}
        right={(
          <div className="flex flex-wrap items-center gap-2">
            {canExport && (
              <>
                <button
                  type="button"
                  onClick={() => handleExport('xlsx')}
                  className="inline-flex items-center gap-2 rounded-xl px-3 py-2 text-sm font-semibold text-white"
                  style={{ background: '#00A650' }}
                >
                  📥 Export Excel
                </button>
                <button
                  type="button"
                  onClick={() => handleExport('pdf')}
                  className="inline-flex items-center gap-2 rounded-xl px-3 py-2 text-sm font-semibold text-white"
                  style={{ background: '#dc2626' }}
                >
                  📄 Export PDF
                </button>
              </>
            )}
            <Button
              type="button"
              variant="gradient"
              size="md"
              onClick={() => navigate('/missions/nouvelle')}
            >
              <Plus size={16} />
              Nouvelle mission
            </Button>
          </div>
        )}
      />

      {/* Filtres */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3, delay: 0.05 }}
        className="at-card-surface mb-6 p-4 md:p-5"
      >
        <div className="grid gap-3 grid-cols-[repeat(auto-fit,minmax(280px,1fr))]">
          <div>
            <label className="mb-2 block text-xs font-semibold text-[#5A6070] dark:text-[#9AA0AE]">
              Statut
            </label>
            <select
              value={statut}
              onChange={(e) => {
                setStatut(e.target.value)
                setPage(1)
              }}
              className="at-input cursor-pointer"
            >
              {STATUT_OPTIONS.map((o) => (
                <option key={o.value || 'all'} value={o.value}>
                  {o.label}
                </option>
              ))}
            </select>
          </div>

          <div className="md:col-span-2">
            <label className="mb-2 block text-xs font-semibold text-[#5A6070] dark:text-[#9AA0AE]">
              Recherche
            </label>
            <div className="relative">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-[#9AA0AE]">
                <Search size={16} />
              </span>
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Titre ou destination..."
                className="at-input pl-10"
              />
            </div>
          </div>
        </div>
      </motion.div>

      {loading && (
        <div className="space-y-3">
          {[0, 1, 2].map((i) => (
            <SkeletonCard key={i} />
          ))}
        </div>
      )}

      {!loading && error && (
        <motion.div
          role="alert"
          aria-live="assertive"
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-6 rounded-[20px] border border-red-200 bg-red-50 p-4 dark:border-red-900/50 dark:bg-red-950/30"
        >
          <div className="flex items-start gap-3">
            <div className="mt-0.5 font-bold text-red-600 dark:text-red-400">Erreur</div>
            <div className="flex-1 text-sm text-red-800 dark:text-red-200">{error}</div>
          </div>
          <div className="mt-4 flex gap-2">
            <Button variant="gradient" size="sm" onClick={handleRetry}>
              <RotateCcw size={16} />
              Réessayer
            </Button>
          </div>
        </motion.div>
      )}

      {!loading && !error && missionsCount === 0 && (
        <EmptyState
          icon={FileText}
          title="Aucune mission"
          subtitle="Créez votre première mission en cliquant sur le bouton."
          actionLabel="Créer une mission"
          onAction={() => navigate('/missions/nouvelle')}
        />
      )}

      {!loading && !error && missionsCount > 0 && (
        <>
          <div className="space-y-3">
            <AnimatePresence initial={false}>
              {missions.map((m, index) => {
                const dest = m?.destination ?? ''
                const [destination_ville, destination_pays] = typeof dest === 'string'
                  ? dest.split(',').map((s) => s.trim())
                  : [undefined, undefined]

                const depart = m?.dates?.depart ?? '—'
                const retour = m?.dates?.retour ?? '—'

                return (
                  <motion.div
                    key={m.id ?? `${m.numero_unique}_${index}`}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -6 }}
                    transition={{ duration: 0.3, delay: Math.min(index * 0.06, 0.3), ease: [0.25, 0.1, 0.25, 1] }}
                    onClick={() => navigate(`/missions/${m.id}`)}
                    role="button"
                    tabIndex={0}
                    onKeyDown={(e) => e.key === 'Enter' && navigate(`/missions/${m.id}`)}
                    className="at-card-interactive flex items-center justify-between px-4 py-4 md:px-5 group"
                  >
                    <div className="flex min-w-0 flex-1 items-start gap-4">
                      <div
                        className="mt-1.5 w-2.5 h-2.5 rounded-full shrink-0 ring-[3px] ring-opacity-20 transition-transform duration-300 group-hover:scale-125"
                        style={{ backgroundColor: bordureStatut(m.statut), '--tw-ring-color': bordureStatut(m.statut) + '33' }}
                      />
                      <div className="min-w-0 flex-1">
                        <div className="mb-1 flex items-center gap-2 font-mono text-xs text-[#9AA0AE]">
                          <span className="bg-[#F4F6FA] dark:bg-[#252840] px-2 py-0.5 rounded-md">{m.numero_unique ?? 'OM-—'}</span>
                          {m.created_at && (
                            <span className="text-gray-400 dark:text-gray-500">
                              {new Date(m.created_at).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' })}
                            </span>
                          )}
                        </div>
                        <div className="mb-1.5 truncate text-base font-bold text-[#1A1D26] dark:text-[#E8EAF0] group-hover:text-at-green transition-colors duration-200">
                          {m.titre ?? 'Sans titre'}
                        </div>
                        <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-sm text-[#5A6070] dark:text-[#9AA0AE]">
                          <span className="inline-flex items-center gap-1">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-[#9AA0AE]"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
                            <span className="font-medium text-[#1A1D26] dark:text-[#E8EAF0]">{destination_ville || '—'}</span>
                            {destination_pays ? <span className="text-[#9AA0AE]">{destination_pays}</span> : null}
                          </span>
                          <span className="inline-flex items-center gap-1 text-[#9AA0AE]">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                            {depart} → {retour}
                          </span>
                          <span className="at-number text-[#1A1D26] dark:text-[#E8EAF0]">
                            {formatDZD(m.budget_previsionnel)}
                          </span>
                        </div>
                      </div>

                      <div className="flex shrink-0 flex-col items-end gap-3">
                        <Badge status={m.statut} />
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={(e) => {
                            e.stopPropagation()
                            navigate(`/missions/${m.id}`)
                          }}
                        >
                          Voir
                        </Button>
                      </div>
                    </div>
                  </motion.div>
                )
              })}
            </AnimatePresence>
          </div>

          {canShowPagination && pagination && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.2 }}
              className="mt-6"
            >
              <Pagination
                currentPage={pagination.current_page ?? page}
                totalPages={pagination.last_page ?? 1}
                totalItems={pagination.total ?? 0}
                perPage={perPage}
                onPageChange={(p) => setPage(p)}
                onPerPageChange={(pp) => { setPerPage(pp); setPage(1) }}
              />
            </motion.div>
          )}
        </>
      )}
    </motion.div>
  )
}
