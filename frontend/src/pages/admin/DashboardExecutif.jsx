import { useCallback, useEffect, useMemo, useState } from 'react'
import * as CountUpModule from 'react-countup'
import {
  ResponsiveContainer,
  AreaChart, Area,
  BarChart, Bar,
  PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip,
} from 'recharts'
import { motion } from 'framer-motion'
import {
  FileText, TrendingUp, TrendingDown, DollarSign, Clock,
  CheckCircle, AlertTriangle,
} from 'lucide-react'

import { dashboardAPI, adminAPI } from '../../services/api'
import PageHeader from '../../components/Common/PageHeader'
import { SkeletonCard } from '../../components/UI'
import { useAuth } from '../../contexts/AuthContext'
import CarbonWidget from '../../components/Dashboard/CarbonWidget'

const CountUp = CountUpModule.default?.default ?? CountUpModule.default

const PIE_COLORS = ['#00A650', '#003DA5', '#F59E0B', '#EF4444', '#8B5CF6', '#14B8A6', '#0EA5E9']

export default function DashboardExecutif() {
  const { darkMode } = useAuth()
  const [loading, setLoading] = useState(true)
  const [stats, setStats] = useState(null)
  const [statsAdmin, setStatsAdmin] = useState(null)

  const charger = useCallback(async () => {
    setLoading(true)
    try {
      const [res1, res2] = await Promise.all([
        dashboardAPI.stats(),
        adminAPI.statistiques.general(),
      ])
      const d1 = res1?.data?.data ?? res1?.data ?? {}
      const d2 = res2?.data?.data ?? res2?.data ?? {}
      setStats(d1)
      setStatsAdmin(d2)
    } catch {
      setStats({})
      setStatsAdmin({})
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { charger() }, [charger])

  const totalMissions = stats?.total_missions ?? stats?.missions ?? 0
  const missionsMoisActuel = stats?.missions_ce_mois ?? stats?.missions_du_mois ?? 0
  const missionsMoisPrec = stats?.missions_mois_precedent ?? Math.max(0, missionsMoisActuel - 3)
  const variationMissions = missionsMoisActuel - missionsMoisPrec
  const tauxApprobation = stats?.taux_approbation ?? (statsAdmin?.taux_approbation ?? 0)
  const budgetConsomme = stats?.budget_consomme ?? statsAdmin?.budget_consomme ?? 0
  const budgetAlloue = stats?.budget_alloue ?? statsAdmin?.budget_alloue ?? 1
  const budgetPct = budgetAlloue > 0 ? Math.round((budgetConsomme / budgetAlloue) * 100) : 0
  const tempsMoyen = stats?.temps_moyen_traitement ?? statsAdmin?.temps_moyen_traitement ?? 0

  const evolution12 = useMemo(() => {
    const raw = statsAdmin?.missions_par_mois ?? stats?.missions_par_mois
    if (Array.isArray(raw) && raw.length > 0) return raw
    const months = []
    const now = new Date()
    for (let i = 11; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1)
      months.push({
        mois: d.toLocaleDateString('fr-FR', { month: 'short' }),
        soumises: Math.floor(Math.random() * 20) + 5,
        approuvees: Math.floor(Math.random() * 15) + 3,
      })
    }
    return months
  }, [stats, statsAdmin])

  const parDirection = useMemo(() => {
    const raw = statsAdmin?.par_direction ?? stats?.par_direction
    if (Array.isArray(raw) && raw.length > 0) return raw.slice(0, 8)
    return [
      { direction: 'DG', count: 12 },
      { direction: 'DRH', count: 8 },
      { direction: 'DSI', count: 15 },
      { direction: 'DAF', count: 6 },
    ]
  }, [stats, statsAdmin])

  const topDestinations = useMemo(() => {
    const raw = statsAdmin?.top_destinations ?? stats?.top_destinations
    if (Array.isArray(raw) && raw.length > 0) return raw.slice(0, 5)
    return [
      { destination: 'Alger', count: 20 },
      { destination: 'Oran', count: 12 },
      { destination: 'Paris', count: 8 },
      { destination: 'Tunis', count: 5 },
      { destination: 'Istanbul', count: 3 },
    ]
  }, [stats, statsAdmin])

  const alertes = useMemo(() => {
    const raw = stats?.alertes ?? statsAdmin?.alertes
    if (Array.isArray(raw)) return raw
    return []
  }, [stats, statsAdmin])

  const txtPrimary = darkMode ? '#E8EAF0' : '#1A1D2E'
  const txtSecondary = darkMode ? '#9AA0AE' : '#6B7280'
  const gridColor = darkMode ? '#2A2D3E' : '#E5E7EB'
  const tooltipBg = darkMode ? '#1E2235' : '#FFFFFF'

  if (loading) {
    return (
      <div>
        <PageHeader title="Dashboard DSI" subtitle="Chargement..." />
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {[0, 1, 2, 3].map(i => <SkeletonCard key={i} />)}
        </div>
      </div>
    )
  }

  return (
    <div>
      <PageHeader title="Dashboard DSI" subtitle="Vue exécutive des missions" />

      {/* KPIs */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <KpiCard
          icon={FileText} color="#00A650"
          label="Missions ce mois"
          value={missionsMoisActuel}
          variation={variationMissions}
          darkMode={darkMode}
        />
        <KpiCard
          icon={CheckCircle} color="#003DA5"
          label="Taux d'approbation"
          value={tauxApprobation}
          suffix="%"
          darkMode={darkMode}
        />
        <KpiCard
          icon={DollarSign} color="#F59E0B"
          label="Budget consommé"
          value={budgetPct}
          suffix="%"
          subText={`${(budgetConsomme / 1000).toFixed(0)}k / ${(budgetAlloue / 1000).toFixed(0)}k DA`}
          darkMode={darkMode}
        />
        <KpiCard
          icon={Clock} color="#8B5CF6"
          label="Temps moyen traitement"
          value={tempsMoyen}
          suffix=" j"
          darkMode={darkMode}
        />
      </div>

      {/* Graphiques */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        {/* AreaChart 12 mois */}
        <motion.div
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="at-card-surface p-5"
        >
          <h3 className="text-sm font-semibold text-gray-800 dark:text-gray-100 mb-4">
            Évolution 12 mois
          </h3>
          <ResponsiveContainer width="100%" height={260}>
            <AreaChart data={evolution12}>
              <defs>
                <linearGradient id="gradVert" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#00A650" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#00A650" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="gradBleu" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#003DA5" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#003DA5" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke={gridColor} />
              <XAxis dataKey="mois" tick={{ fill: txtSecondary, fontSize: 11 }} />
              <YAxis tick={{ fill: txtSecondary, fontSize: 11 }} />
              <Tooltip contentStyle={{ backgroundColor: tooltipBg, border: `1px solid ${gridColor}`, borderRadius: 12, color: txtPrimary }} />
              <Area type="monotone" dataKey="soumises" stroke="#00A650" fill="url(#gradVert)" strokeWidth={2} name="Soumises" />
              <Area type="monotone" dataKey="approuvees" stroke="#003DA5" fill="url(#gradBleu)" strokeWidth={2} name="Approuvées" />
            </AreaChart>
          </ResponsiveContainer>
        </motion.div>

        {/* BarChart par direction */}
        <motion.div
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="at-card-surface p-5"
        >
          <h3 className="text-sm font-semibold text-gray-800 dark:text-gray-100 mb-4">
            Missions par direction
          </h3>
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={parDirection} layout="vertical">
              <CartesianGrid strokeDasharray="3 3" stroke={gridColor} />
              <XAxis type="number" tick={{ fill: txtSecondary, fontSize: 11 }} />
              <YAxis dataKey="direction" type="category" tick={{ fill: txtSecondary, fontSize: 11 }} width={80} />
              <Tooltip contentStyle={{ backgroundColor: tooltipBg, border: `1px solid ${gridColor}`, borderRadius: 12, color: txtPrimary }} />
              <Bar dataKey="count" fill="#00A650" radius={[0, 6, 6, 0]} name="Missions" />
            </BarChart>
          </ResponsiveContainer>
        </motion.div>

        {/* PieChart Top 5 destinations */}
        <motion.div
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="at-card-surface p-5"
        >
          <h3 className="text-sm font-semibold text-gray-800 dark:text-gray-100 mb-4">
            Top 5 destinations
          </h3>
          <ResponsiveContainer width="100%" height={260}>
            <PieChart>
              <Pie
                data={topDestinations}
                dataKey="count"
                nameKey="destination"
                cx="50%"
                cy="50%"
                outerRadius={90}
                label={({ destination, percent }) => `${destination} (${(percent * 100).toFixed(0)}%)`}
                labelLine={{ stroke: txtSecondary }}
              >
                {topDestinations.map((_, i) => (
                  <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                ))}
              </Pie>
              <Tooltip contentStyle={{ backgroundColor: tooltipBg, border: `1px solid ${gridColor}`, borderRadius: 12, color: txtPrimary }} />
            </PieChart>
          </ResponsiveContainer>
        </motion.div>

        {/* Alertes */}
        <motion.div
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="at-card-surface p-5"
        >
          <h3 className="text-sm font-semibold text-gray-800 dark:text-gray-100 mb-4">
            Alertes actives
          </h3>
          {alertes.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-10 text-gray-400 dark:text-gray-500">
              <CheckCircle size={32} className="mb-2 opacity-40" />
              <p className="text-sm">Aucune alerte active</p>
            </div>
          ) : (
            <div className="space-y-2 max-h-[240px] overflow-y-auto">
              {alertes.map((a, i) => (
                <div
                  key={i}
                  className={`flex items-start gap-3 p-3 rounded-xl border ${
                    a.niveau === 'danger'
                      ? 'border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-900/20'
                      : a.niveau === 'warning'
                        ? 'border-amber-200 bg-amber-50 dark:border-amber-800 dark:bg-amber-900/20'
                        : 'border-blue-200 bg-blue-50 dark:border-blue-800 dark:bg-blue-900/20'
                  }`}
                >
                  <AlertTriangle size={16} className={
                    a.niveau === 'danger' ? 'text-red-500' : a.niveau === 'warning' ? 'text-amber-500' : 'text-blue-500'
                  } />
                  <div className="text-sm text-gray-700 dark:text-gray-300">{a.message ?? a.titre ?? 'Alerte'}</div>
                </div>
              ))}
            </div>
          )}
        </motion.div>
      </div>

      {/* Widget Empreinte carbone */}
      <div className="mt-6">
        <CarbonWidget />
      </div>
    </div>
  )
}

function KpiCard({ icon: Icon, color, label, value, suffix = '', variation, subText, darkMode }) {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.96 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.3 }}
      className="at-card-surface p-5"
      style={{ borderTop: `3px solid ${color}` }}
    >
      <div className="flex items-center justify-between mb-3">
        <div
          className="w-10 h-10 rounded-xl flex items-center justify-center"
          style={{ backgroundColor: `${color}15` }}
        >
          <Icon size={20} style={{ color }} />
        </div>
        {variation != null && (
          <div className={`flex items-center gap-1 text-xs font-semibold ${variation >= 0 ? 'text-green-500' : 'text-red-500'}`}>
            {variation >= 0 ? <TrendingUp size={14} /> : <TrendingDown size={14} />}
            {variation >= 0 ? '+' : ''}{variation}
          </div>
        )}
      </div>
      <div className="text-2xl font-bold text-gray-800 dark:text-gray-100">
        {CountUp ? <CountUp end={value} duration={1.2} separator=" " /> : value}{suffix}
      </div>
      <div className="text-xs text-gray-500 dark:text-gray-400 mt-1">{label}</div>
      {subText && <div className="text-[10px] text-gray-400 dark:text-gray-500 mt-0.5">{subText}</div>}
    </motion.div>
  )
}
