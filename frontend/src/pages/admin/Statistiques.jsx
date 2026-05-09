import { useEffect, useMemo, useState } from 'react'
import _CountUpImport from 'react-countup'
// react-countup est un module CJS — Vite peut retourner l'objet entier ou le composant directement
const CountUp = (_CountUpImport?.default && typeof _CountUpImport.default === 'function')
  ? _CountUpImport.default : _CountUpImport
import {
  ResponsiveContainer, AreaChart, Area, BarChart, Bar,
  XAxis, YAxis, CartesianGrid, Tooltip, PieChart, Pie, Cell,
} from 'recharts'
import { motion, AnimatePresence } from 'framer-motion'
import { useNavigate } from 'react-router-dom'
import {
  RotateCcw, Activity, CheckCircle, Building2, FileText,
  Target, AlertCircle, TrendingUp,
} from 'lucide-react'
import toast from 'react-hot-toast'

import { adminAPI, missionsAPI } from '../../services/api'
import PageHeader from '../../components/Common/PageHeader'
import { Button, EmptyState, SkeletonCard } from '../../components/UI'
import { formatDZD } from '../../utils/format'

// ── Constantes ─────────────────────────────────────────────
const PIE_COLORS = ['#003DA5','#00A650','#F59E0B','#EF4444','#8B5CF6','#14B8A6','#0EA5E9','#EC4899']

const STATUS_META = {
  approuve:      { label: 'Approuvées',    color: '#00A650' },
  en_validation: { label: 'En validation', color: '#F59E0B' },
  soumis:        { label: 'Soumises',      color: '#3B82F6' },
  brouillon:     { label: 'Brouillons',    color: '#94A3B8' },
  rejete:        { label: 'Rejetées',      color: '#EF4444' },
  annule:        { label: 'Annulées',      color: '#6B7280' },
  termine:       { label: 'Terminées',     color: '#8B5CF6' },
}

function extractDashboardStats(res) {
  const d = res?.data
  if (!d || typeof d !== 'object') return {}
  if (d.missions != null || d.missions_par_mois != null) return d
  if (d.data != null && typeof d.data === 'object') return d.data
  return {}
}

// ── Tooltip personnalisé ────────────────────────────────────
function ChartTooltip({ active, payload, label }) {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-white dark:bg-[#1A1D2E] border border-[#EAECF0] dark:border-[#2A2D3E] rounded-xl px-3 py-2 shadow-lg text-xs">
      <p className="font-semibold text-gray-700 dark:text-gray-200 mb-1">{label}</p>
      {payload.map((p, i) => (
        <div key={i} className="flex items-center gap-2">
          <span className="w-2 h-2 rounded-full flex-shrink-0" style={{ background: p.color || p.fill }} />
          <span className="text-gray-500">{p.name} :</span>
          <span className="font-bold text-gray-800 dark:text-white">{p.value}</span>
        </div>
      ))}
    </div>
  )
}

// ── KPI Card ────────────────────────────────────────────────
const KPI_PALETTES = {
  blue:   { grad: 'from-blue-500 to-[#003DA5]',   ring: 'ring-blue-200 dark:ring-blue-900/50',   num: 'text-[#003DA5] dark:text-blue-300' },
  green:  { grad: 'from-green-400 to-[#00A650]',   ring: 'ring-green-200 dark:ring-green-900/50', num: 'text-[#00A650] dark:text-green-300' },
  amber:  { grad: 'from-amber-400 to-orange-500',  ring: 'ring-amber-200 dark:ring-amber-900/50', num: 'text-amber-600 dark:text-amber-300' },
  purple: { grad: 'from-purple-400 to-violet-600', ring: 'ring-purple-200 dark:ring-purple-900/50',num: 'text-purple-600 dark:text-purple-300' },
  sky:    { grad: 'from-sky-400 to-cyan-500',      ring: 'ring-sky-200 dark:ring-sky-900/50',     num: 'text-sky-600 dark:text-sky-300' },
}

function KpiCard({ icon: Icon, label, value, suffix = '', color = 'blue', delay = 0, sub }) {
  const p = KPI_PALETTES[color] ?? KPI_PALETTES.blue
  return (
    <motion.div
      initial={{ opacity: 0, y: 28 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.45, delay }}
      className="at-card-surface p-5 group hover:-translate-y-1 hover:shadow-lg transition-all duration-300 cursor-default"
    >
      <div className="flex items-start justify-between">
        <div className={`p-2.5 rounded-xl bg-gradient-to-br ${p.grad} ring-2 ${p.ring} shadow-sm`}>
          <Icon size={18} className="text-white" />
        </div>
        <TrendingUp size={14} className="text-gray-300 dark:text-gray-600 opacity-0 group-hover:opacity-100 transition-opacity mt-0.5" />
      </div>
      <div className="mt-4">
        <div className="text-[1.6rem] font-extrabold text-gray-900 dark:text-white tabular-nums leading-none">
          {typeof value === 'number'
            ? <CountUp end={value} duration={1.8} suffix={suffix} separator=" " />
            : (value ?? '—')}
        </div>
        <div className="text-xs font-medium text-gray-500 dark:text-gray-400 mt-1.5">{label}</div>
        {sub && <div className="text-[10px] text-gray-400 mt-0.5">{sub}</div>}
      </div>
    </motion.div>
  )
}

// ── Composant principal ─────────────────────────────────────
export default function Statistiques() {
  const navigate = useNavigate()
  const [loading, setLoading]               = useState(true)
  const [stats, setStats]                   = useState(null)
  const [missionsTotal, setMissionsTotal]   = useState(0)
  const [missionsSample, setMissionsSample] = useState([])
  const [prestatairesTotal, setPrestatairesTotal] = useState(0)
  const [prestatairesList, setPrestatairesList]   = useState([])
  const [fetchErrors, setFetchErrors] = useState({ stats: null, missions: null, prestataires: null })
  const [trigger, setTrigger] = useState(0)

  useEffect(() => {
    let cancelled = false
    const load = async () => {
      setLoading(true)
      setFetchErrors({ stats: null, missions: null, prestataires: null })

      const [sR, mR, pR] = await Promise.allSettled([
        adminAPI.statistiques.general({ annee: new Date().getFullYear() }),
        missionsAPI.list({ page: 1, per_page: 50 }),
        adminAPI.prestataires({ page: 1, per_page: 50 }),
      ])
      if (cancelled) return

      if (sR.status === 'fulfilled') {
        setStats(extractDashboardStats(sR.value) ?? {})
      } else {
        setStats({})
        const msg = sR.reason?.response?.data?.message || sR.reason?.message || 'Stats indisponibles'
        setFetchErrors(e => ({ ...e, stats: msg }))
        toast.error(msg)
      }

      if (mR.status === 'fulfilled') {
        const body = mR.value?.data
        const list = Array.isArray(body?.data) ? body.data : []
        setMissionsSample(list)
        setMissionsTotal(Number(body?.pagination?.total ?? list.length) || 0)
      } else {
        setMissionsSample([]); setMissionsTotal(0)
        const msg = mR.reason?.response?.data?.message || mR.reason?.message || 'Missions indisponibles'
        setFetchErrors(e => ({ ...e, missions: msg }))
      }

      if (pR.status === 'fulfilled') {
        const r = pR.value
        const data = r?.data?.data ?? r?.data ?? []
        const list = Array.isArray(data) ? data : []
        setPrestatairesList(list)
        setPrestatairesTotal(Number(r?.data?.pagination?.total ?? list.length) || 0)
      } else {
        setPrestatairesList([]); setPrestatairesTotal(0)
        const msg = pR.reason?.response?.data?.message || pR.reason?.message || 'Prestataires indisponibles'
        setFetchErrors(e => ({ ...e, prestataires: msg }))
      }

      setLoading(false)
    }
    load()
    return () => { cancelled = true }
  }, [trigger])

  const retry = () => setTrigger(t => t + 1)

  // ── Valeurs calculées ──────────────────────────────────────
  const kpis = useMemo(() => {
    const s = stats ?? {}
    const m = s.missions ?? {}
    const r = s.reservations ?? {}
    const approuvees = Number(m.approuvees ?? m.missions_approuvees ?? 0) || 0
    const totalS     = Number(m.total ?? m.total_missions ?? 0) || 0
    const denom      = totalS > 0 ? totalS : missionsTotal
    const budgets    = Array.isArray(s.budgets) ? s.budgets : []
    return {
      missions:     missionsTotal,
      taux:         denom > 0 ? Math.round((approuvees / denom) * 100) : 0,
      budget:       budgets.reduce((sum, b) => sum + (Number(b?.montant_alloue ?? 0) || 0), 0),
      prestataires: prestatairesTotal,
      reservations: Number(r?.confirmees ?? 0) || 0,
    }
  }, [stats, missionsTotal, prestatairesTotal])

  const areaData = useMemo(() => {
    const raw = Array.isArray(stats?.missions_par_mois) ? stats.missions_par_mois : []
    return raw.slice(-6).map(x => ({ mois: x?.mois ?? '', total: Number(x?.total ?? 0) || 0 }))
  }, [stats])

  const pieData = useMemo(() => {
    const counts = {}
    for (const m of missionsSample) {
      const t = m?.type_mission ?? 'autre'
      counts[t] = (counts[t] ?? 0) + 1
    }
    return Object.entries(counts)
      .map(([name, value]) => ({ name, value }))
      .sort((a, b) => b.value - a.value)
  }, [missionsSample])

  const statusBreakdown = useMemo(() => {
    const counts = {}
    for (const m of missionsSample) {
      const s = m?.statut ?? 'brouillon'
      counts[s] = (counts[s] ?? 0) + 1
    }
    const total = Object.values(counts).reduce((a, b) => a + b, 0)
    return Object.entries(counts)
      .map(([status, count]) => ({
        status, count,
        pct: total > 0 ? Math.round((count / total) * 100) : 0,
        ...(STATUS_META[status] ?? { label: status, color: '#94A3B8' }),
      }))
      .sort((a, b) => b.count - a.count)
  }, [missionsSample])

  const depensesData = useMemo(() => {
    const raw = Array.isArray(stats?.depenses_par_type) ? stats.depenses_par_type : []
    return raw.map(r => ({ type: r?.type ?? '—', montant: Number(r?.montant ?? 0) || 0 }))
  }, [stats])

  const topPrestataires = useMemo(() => {
    const fromStats = Array.isArray(stats?.top_prestataires) ? stats.top_prestataires : []
    if (fromStats.length > 0) {
      return fromStats
        .map(p => ({ nom: p?.nom ?? '—', nb: Number(p?.nb_reservations ?? 0) || 0 }))
        .sort((a, b) => b.nb - a.nb).slice(0, 8)
    }
    return prestatairesList.slice(0, 8).map(p => ({
      nom: p?.nom ?? '—',
      nb: Number(p?.nombre_evaluations ?? p?.note_moyenne ?? 0) || 0,
    }))
  }, [stats, prestatairesList])

  const maxNb      = useMemo(() => Math.max(...topPrestataires.map(p => p.nb), 1), [topPrestataires])
  const hasError   = fetchErrors.stats || fetchErrors.missions || fetchErrors.prestataires
  const year       = new Date().getFullYear()
  const areaTotal  = areaData.reduce((s, d) => s + d.total, 0)

  // ── Rendu ──────────────────────────────────────────────────
  return (
    <div className="space-y-6">
      <PageHeader
        title="Statistiques"
        subtitle={`Tableau de bord analytique — ${year}`}
        backTo="/"
        actions={
          <Button size="sm" variant="outline" onClick={retry} disabled={loading}>
            <RotateCcw size={15} className={loading ? 'animate-spin' : ''} />
            {loading ? 'Chargement…' : 'Rafraîchir'}
          </Button>
        }
      />

      {/* ── Hero gradient banner ─────────────────────────────── */}
      <motion.div
        initial={{ opacity: 0, y: -14 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="relative overflow-hidden rounded-[20px] p-6 text-white"
        style={{ background: 'linear-gradient(135deg,#003DA5 0%,#005A9E 45%,#00A650 100%)' }}
      >
        {/* Cercles décoratifs */}
        {[80,130,180,230,280].map((size, i) => (
          <div
            key={i}
            className="absolute rounded-full border border-white/20 pointer-events-none"
            style={{
              width: size, height: size,
              top: `${-30 + i * 8}%`, right: `${2 + i * 3}%`,
              opacity: 0.12 + i * 0.04,
            }}
          />
        ))}
        <div className="relative z-10 flex flex-wrap items-center justify-between gap-6">
          <div>
            <div className="text-xs font-semibold text-white/60 uppercase tracking-widest mb-1">Exercice en cours</div>
            <div className="text-4xl font-black">{year}</div>
            <div className="text-sm text-white/75 mt-1.5">
              {missionsTotal} missions · {prestatairesTotal} prestataires actifs
            </div>
          </div>
          <div className="flex flex-wrap gap-6 text-center">
            {[
              { val: `${kpis.taux}%`, sub: "Taux d'approbation" },
              { val: kpis.reservations, sub: 'Rés. confirmées' },
              { val: kpis.budget > 0 ? formatDZD(kpis.budget) : 'N/A', sub: 'Budget total' },
            ].map(({ val, sub }, i) => (
              <div key={i} className="flex flex-col items-center">
                <div className="text-2xl font-bold tabular-nums leading-none">{val}</div>
                <div className="text-[11px] text-white/65 mt-1">{sub}</div>
              </div>
            ))}
          </div>
        </div>
      </motion.div>

      {/* ── Erreurs partielles ───────────────────────────────── */}
      {!loading && hasError && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="rounded-xl border border-amber-200 bg-amber-50 dark:border-amber-900/50 dark:bg-amber-950/30 px-4 py-3 text-sm"
        >
          <div className="flex items-start gap-2 text-amber-900 dark:text-amber-100">
            <AlertCircle size={16} className="flex-shrink-0 mt-0.5" />
            <div>
              <span className="font-semibold">Données partielles</span>
              {fetchErrors.stats        && <span className="ml-2 text-xs opacity-75">· {fetchErrors.stats}</span>}
              {fetchErrors.missions     && <span className="ml-2 text-xs opacity-75">· {fetchErrors.missions}</span>}
              {fetchErrors.prestataires && <span className="ml-2 text-xs opacity-75">· {fetchErrors.prestataires}</span>}
            </div>
          </div>
        </motion.div>
      )}

      {/* ── Skeleton ─────────────────────────────────────────── */}
      {loading && (
        <div className="space-y-4">
          <div className="grid grid-cols-2 xl:grid-cols-5 gap-4">
            {[...Array(5)].map((_, i) => <SkeletonCard key={i} />)}
          </div>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <SkeletonCard /><SkeletonCard />
          </div>
          <div className="grid grid-cols-1 xl:grid-cols-3 gap-4">
            <SkeletonCard /><SkeletonCard className="xl:col-span-2" />
          </div>
        </div>
      )}

      {!loading && (
        <>
          {/* ── KPI Cards ───────────────────────────────────── */}
          <div className="grid grid-cols-2 xl:grid-cols-5 gap-4">
            <KpiCard icon={Activity}    label="Total missions"       value={kpis.missions}          color="blue"   delay={0}    />
            <KpiCard icon={CheckCircle} label="Taux d'approbation"   value={kpis.taux}              color="green"  delay={0.06} suffix="%" />
            <KpiCard icon={Building2}   label="Prestataires"         value={kpis.prestataires}      color="sky"    delay={0.12} />
            <KpiCard icon={FileText}    label="Réservations conf."   value={kpis.reservations}      color="purple" delay={0.18} />
            <KpiCard icon={Target}      label="Échantillon missions"  value={missionsSample.length} color="amber"  delay={0.24} sub="50 dernières chargées" />
          </div>

          {/* ── Row 1 : Area chart + Status breakdown ───────── */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">

            {/* Area chart missions/mois */}
            <motion.div
              initial={{ opacity: 0, x: -22 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.28 }}
              className="at-card-surface p-5"
            >
              <div className="flex items-center justify-between mb-4">
                <div>
                  <h3 className="text-sm font-semibold text-gray-800 dark:text-white">Tendance missions</h3>
                  <p className="text-xs text-gray-500 mt-0.5">6 derniers mois enregistrés</p>
                </div>
                {areaData.length > 0 && (
                  <span className="text-xs font-semibold bg-blue-50 text-[#003DA5] dark:bg-blue-900/40 dark:text-blue-300 px-2.5 py-1 rounded-full">
                    {areaTotal} total
                  </span>
                )}
              </div>
              {areaData.length === 0
                ? <EmptyState icon={Activity} title="Aucune donnée" subtitle="Historique mensuel non disponible." />
                : (
                  <div style={{ height: 230 }}>
                    <ResponsiveContainer width="100%" height="100%">
                      <AreaChart data={areaData} margin={{ top: 6, right: 8, left: -22, bottom: 0 }}>
                        <defs>
                          <linearGradient id="gradArea" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="5%"  stopColor="#003DA5" stopOpacity={0.22} />
                            <stop offset="95%" stopColor="#003DA5" stopOpacity={0}    />
                          </linearGradient>
                        </defs>
                        <CartesianGrid strokeDasharray="3 3" stroke="#F0F0F0" />
                        <XAxis dataKey="mois" tick={{ fontSize: 11 }} />
                        <YAxis tick={{ fontSize: 11 }} allowDecimals={false} />
                        <Tooltip content={<ChartTooltip />} />
                        <Area
                          type="monotone" dataKey="total" name="Missions"
                          stroke="#003DA5" strokeWidth={2.5} fill="url(#gradArea)"
                          dot={{ r: 4, fill: '#003DA5', stroke: '#fff', strokeWidth: 2 }}
                          activeDot={{ r: 6, fill: '#00A650' }}
                        />
                      </AreaChart>
                    </ResponsiveContainer>
                  </div>
                )}
            </motion.div>

            {/* Status breakdown */}
            <motion.div
              initial={{ opacity: 0, x: 22 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.32 }}
              className="at-card-surface p-5"
            >
              <div className="mb-4">
                <h3 className="text-sm font-semibold text-gray-800 dark:text-white">Répartition par statut</h3>
                <p className="text-xs text-gray-500 mt-0.5">Échantillon de {missionsSample.length} missions</p>
              </div>
              {statusBreakdown.length === 0
                ? <EmptyState icon={FileText} title="Aucune mission" subtitle="Aucune donnée de statut disponible." />
                : (
                  <div className="space-y-3.5 mt-2">
                    {statusBreakdown.map((s, i) => (
                      <motion.div
                        key={s.status}
                        initial={{ opacity: 0, x: 12 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: 0.34 + i * 0.06 }}
                      >
                        <div className="flex items-center justify-between text-xs mb-1.5">
                          <div className="flex items-center gap-1.5">
                            <span className="w-2 h-2 rounded-full flex-shrink-0" style={{ background: s.color }} />
                            <span className="font-medium text-gray-700 dark:text-gray-300">{s.label}</span>
                          </div>
                          <span className="font-semibold text-gray-500 tabular-nums">
                            {s.count} <span className="text-gray-400 font-normal">({s.pct}%)</span>
                          </span>
                        </div>
                        <div className="h-2 bg-gray-100 dark:bg-gray-700/60 rounded-full overflow-hidden">
                          <motion.div
                            className="h-full rounded-full"
                            style={{ background: s.color }}
                            initial={{ width: 0 }}
                            animate={{ width: `${Math.max(s.pct, 2)}%` }}
                            transition={{ duration: 0.85, delay: 0.42 + i * 0.06, ease: 'easeOut' }}
                          />
                        </div>
                      </motion.div>
                    ))}
                  </div>
                )}
            </motion.div>
          </div>

          {/* ── Row 2 : Pie + Top prestataires ──────────────── */}
          <div className="grid grid-cols-1 xl:grid-cols-3 gap-5">

            {/* Pie chart types de missions */}
            <motion.div
              initial={{ opacity: 0, y: 22 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.38 }}
              className="at-card-surface p-5"
            >
              <h3 className="text-sm font-semibold text-gray-800 dark:text-white">Types de missions</h3>
              <p className="text-xs text-gray-500 mt-0.5 mb-3">Répartition par catégorie</p>
              {pieData.length === 0
                ? <EmptyState icon={FileText} title="Aucune donnée" subtitle="Types non calculables." />
                : (
                  <>
                    <div style={{ height: 180 }}>
                      <ResponsiveContainer width="100%" height="100%">
                        <PieChart>
                          <Tooltip content={<ChartTooltip />} />
                          <Pie
                            data={pieData} dataKey="value" nameKey="name"
                            outerRadius={74} innerRadius={34} paddingAngle={3}
                          >
                            {pieData.map((_, i) => (
                              <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                            ))}
                          </Pie>
                        </PieChart>
                      </ResponsiveContainer>
                    </div>
                    <div className="mt-2 space-y-1.5">
                      {pieData.slice(0, 5).map((d, i) => (
                        <div key={d.name} className="flex items-center justify-between text-xs">
                          <div className="flex items-center gap-1.5 min-w-0">
                            <span className="w-2 h-2 flex-shrink-0 rounded-full" style={{ background: PIE_COLORS[i % PIE_COLORS.length] }} />
                            <span className="text-gray-600 dark:text-gray-400 truncate capitalize">{d.name}</span>
                          </div>
                          <span className="font-bold text-gray-800 dark:text-white ml-2">{d.value}</span>
                        </div>
                      ))}
                    </div>
                  </>
                )}
            </motion.div>

            {/* Top prestataires */}
            <motion.div
              initial={{ opacity: 0, y: 22 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.43 }}
              className="at-card-surface p-5 xl:col-span-2"
            >
              <div className="flex items-center justify-between mb-4">
                <div>
                  <h3 className="text-sm font-semibold text-gray-800 dark:text-white">Top prestataires</h3>
                  <p className="text-xs text-gray-500 mt-0.5">Classement par réservations</p>
                </div>
                <Button size="sm" variant="outline" onClick={() => navigate('/admin/prestataires')}>
                  Voir tout
                </Button>
              </div>
              {topPrestataires.length === 0
                ? <EmptyState icon={Building2} title="Aucun prestataire" subtitle="Données non disponibles." />
                : (
                  <div className="space-y-3">
                    <AnimatePresence initial={false}>
                      {topPrestataires.map((p, i) => {
                        const medals = ['🥇','🥈','🥉']
                        const barPct = maxNb > 0 ? Math.round((p.nb / maxNb) * 100) : 0
                        const barBg  = i === 0
                          ? 'linear-gradient(90deg,#003DA5,#00A650)'
                          : i === 1 ? '#00A650' : i === 2 ? '#F59E0B' : '#94A3B8'
                        return (
                          <motion.div
                            key={p.nom}
                            initial={{ opacity: 0, x: 18 }}
                            animate={{ opacity: 1, x: 0 }}
                            transition={{ delay: 0.45 + i * 0.05 }}
                            className="flex items-center gap-3"
                          >
                            <span className="w-6 text-center flex-shrink-0 text-base leading-none">
                              {medals[i] ?? <span className="text-xs font-bold text-gray-400">{i + 1}</span>}
                            </span>
                            <div className="flex-1 min-w-0">
                              <div className="flex items-center justify-between text-xs mb-1">
                                <span className="font-semibold text-gray-800 dark:text-white truncate">{p.nom}</span>
                                <span className="text-gray-500 ml-2 flex-shrink-0 tabular-nums">{p.nb}</span>
                              </div>
                              <div className="h-1.5 bg-gray-100 dark:bg-gray-700/60 rounded-full overflow-hidden">
                                <motion.div
                                  className="h-full rounded-full"
                                  style={{ background: barBg }}
                                  initial={{ width: 0 }}
                                  animate={{ width: `${Math.max(barPct, 3)}%` }}
                                  transition={{ duration: 0.75, delay: 0.52 + i * 0.05, ease: 'easeOut' }}
                                />
                              </div>
                            </div>
                          </motion.div>
                        )
                      })}
                    </AnimatePresence>
                  </div>
                )}
            </motion.div>
          </div>

          {/* ── Dépenses par type (si dispo) ─────────────────── */}
          {depensesData.length > 0 && (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.48 }}
              className="at-card-surface p-5"
            >
              <h3 className="text-sm font-semibold text-gray-800 dark:text-white">Dépenses par type</h3>
              <p className="text-xs text-gray-500 mt-0.5 mb-4">Réservations confirmées (DZD)</p>
              <div style={{ height: 220 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={depensesData} margin={{ top: 5, right: 10, left: -10, bottom: 0 }}>
                    <defs>
                      <linearGradient id="gradBar" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%"   stopColor="#00A650" stopOpacity={1}   />
                        <stop offset="100%" stopColor="#003DA5" stopOpacity={0.8} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="#F0F0F0" />
                    <XAxis dataKey="type" tick={{ fontSize: 10 }} />
                    <YAxis tick={{ fontSize: 11 }} />
                    <Tooltip content={<ChartTooltip />} />
                    <Bar dataKey="montant" name="Montant (DZD)" fill="url(#gradBar)" radius={[6,6,0,0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </motion.div>
          )}
        </>
      )}
    </div>
  )
}
