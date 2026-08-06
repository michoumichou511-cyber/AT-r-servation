import { useCallback, useEffect, useMemo, useState } from 'react'
import {
  ResponsiveContainer, LineChart, Line,
  XAxis, YAxis, CartesianGrid, Tooltip,
} from 'recharts'
import { motion } from 'framer-motion'
import { DollarSign, AlertTriangle, Download } from 'lucide-react'

import { adminAPI } from '../../services/api'
import PageHeader from '../../components/Common/PageHeader'
import { Button, SkeletonCard } from '../../components/UI'
import { useAuth } from '../../contexts/AuthContext'

export default function SimulateurBudget() {
  const { darkMode } = useAuth()
  const [loading, setLoading] = useState(true)
  const [budgets, setBudgets] = useState([])
  const [slider, setSlider] = useState(0)

  const charger = useCallback(async () => {
    setLoading(true)
    try {
      const res = await adminAPI.budgetsCrud.stats()
      const data = res?.data?.data ?? res?.data ?? []
      setBudgets(Array.isArray(data) ? data : data.budgets ?? [])
    } catch {
      setBudgets([])
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { charger() }, [charger])

  const rows = useMemo(() => {
    return budgets.map(b => {
      const alloue = b.montant_alloue ?? 0
      const consomme = b.montant_consomme ?? 0
      const simule = consomme + slider * (alloue * 0.05)
      const reste = Math.max(0, alloue - simule)
      const pct = alloue > 0 ? Math.round((simule / alloue) * 100) : 0
      return { ...b, alloue, consomme: simule, reste, pct }
    })
  }, [budgets, slider])

  const projection = useMemo(() => {
    const moisActuel = new Date().getMonth() + 1
    const totalConsomme = rows.reduce((s, r) => s + (r.consomme ?? 0), 0)
    const totalAlloue = rows.reduce((s, r) => s + (r.alloue ?? 0), 0)
    const tauxMensuel = moisActuel > 0 ? totalConsomme / moisActuel : 0
    const points = []
    for (let m = 1; m <= 12; m++) {
      points.push({
        mois: ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'][m-1],
        actuel: m <= moisActuel ? Math.round(tauxMensuel * m) : null,
        projection: Math.round(tauxMensuel * m),
        budget: totalAlloue,
      })
    }
    return points
  }, [rows])

  const alertes = rows.filter(r => r.pct > 80)

  const exportCSV = () => {
    const header = 'Direction,Budget Alloué,Consommé,Reste,%\n'
    const body = rows.map(r =>
      `${r.direction ?? r.nom ?? ''},${r.alloue},${Math.round(r.consomme)},${Math.round(r.reste)},${r.pct}%`
    ).join('\n')
    const blob = new Blob([header + body], { type: 'text/csv;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `budget_simulation_${new Date().toISOString().slice(0, 10)}.csv`
    a.click()
    URL.revokeObjectURL(url)
  }

  const txtSecondary = darkMode ? '#9AA0AE' : '#6B7280'
  const gridColor = darkMode ? '#2A2D3E' : '#E5E7EB'
  const tooltipBg = darkMode ? '#1E2235' : '#FFFFFF'
  const txtPrimary = darkMode ? '#E8EAF0' : '#1A1D2E'

  if (loading) {
    return (
      <div>
        <PageHeader title="Simulateur Budget" subtitle="Chargement..." />
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {[0, 1, 2, 3].map(i => <SkeletonCard key={i} />)}
        </div>
      </div>
    )
  }

  return (
    <div>
      <PageHeader
        title="Simulateur Budget"
        subtitle="Projection et simulation budgétaire par direction"
        actions={
          <Button variant="outline" size="sm" onClick={exportCSV}>
            <Download size={16} /> Export CSV
          </Button>
        }
      />

      {alertes.length > 0 && (
        <div className="mb-4 p-4 rounded-xl border border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-900/20">
          <div className="flex items-center gap-2 text-sm font-semibold text-red-700 dark:text-red-300 mb-1">
            <AlertTriangle size={16} /> Alertes budgétaires
          </div>
          <div className="text-sm text-red-600 dark:text-red-400">
            {alertes.map(a => a.direction ?? a.nom ?? '').join(', ')} — dépassement &gt;80% du budget
          </div>
        </div>
      )}

      {/* Slider simulation */}
      <div className="at-card-surface p-5 mb-6">
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-sm font-semibold text-gray-800 dark:text-gray-100">
            Simulation : +{slider} missions supplémentaires
          </h3>
          <span className="text-xs text-gray-500 dark:text-gray-400">
            Chaque mission ~ 5% du budget direction
          </span>
        </div>
        <input
          type="range"
          min={0}
          max={20}
          value={slider}
          onChange={e => setSlider(Number(e.target.value))}
          className="w-full accent-[#00A650]"
        />
        <div className="flex justify-between text-xs text-gray-400 mt-1">
          <span>0</span><span>5</span><span>10</span><span>15</span><span>20</span>
        </div>
      </div>

      {/* Tableau */}
      <div className="at-card-surface mb-6 overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-100 dark:border-gray-700">
              <th className="text-left px-4 py-3 font-semibold text-gray-500 dark:text-gray-400">Direction</th>
              <th className="text-right px-4 py-3 font-semibold text-gray-500 dark:text-gray-400">Alloué</th>
              <th className="text-right px-4 py-3 font-semibold text-gray-500 dark:text-gray-400">Consommé</th>
              <th className="text-right px-4 py-3 font-semibold text-gray-500 dark:text-gray-400">Reste</th>
              <th className="px-4 py-3 font-semibold text-gray-500 dark:text-gray-400 w-40">%</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r, i) => {
              const barColor = r.pct < 50 ? '#00A650' : r.pct < 80 ? '#F59E0B' : '#EF4444'
              return (
                <motion.tr
                  key={r.id ?? i}
                  initial={{ opacity: 0, x: -8 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: i * 0.04 }}
                  className="border-b border-gray-50 dark:border-gray-800 last:border-b-0"
                >
                  <td className="px-4 py-3 font-medium text-gray-800 dark:text-gray-100">
                    {r.direction ?? r.nom ?? '—'}
                  </td>
                  <td className="px-4 py-3 text-right text-gray-600 dark:text-gray-300">
                    {r.alloue.toLocaleString('fr-FR')} DA
                  </td>
                  <td className="px-4 py-3 text-right text-gray-600 dark:text-gray-300">
                    {Math.round(r.consomme).toLocaleString('fr-FR')} DA
                  </td>
                  <td className="px-4 py-3 text-right text-gray-600 dark:text-gray-300">
                    {Math.round(r.reste).toLocaleString('fr-FR')} DA
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <div className="flex-1 h-2 rounded-full bg-gray-100 dark:bg-gray-700 overflow-hidden">
                        <div
                          className="h-full rounded-full transition-all duration-500"
                          style={{ width: `${Math.min(100, r.pct)}%`, backgroundColor: barColor }}
                        />
                      </div>
                      <span className="text-xs font-semibold tabular-nums" style={{ color: barColor }}>
                        {r.pct}%
                      </span>
                    </div>
                  </td>
                </motion.tr>
              )
            })}
          </tbody>
        </table>
      </div>

      {/* LineChart projection */}
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="at-card-surface p-5"
      >
        <h3 className="text-sm font-semibold text-gray-800 dark:text-gray-100 mb-4">
          Projection annuelle
        </h3>
        <ResponsiveContainer width="100%" height={280}>
          <LineChart data={projection}>
            <CartesianGrid strokeDasharray="3 3" stroke={gridColor} />
            <XAxis dataKey="mois" tick={{ fill: txtSecondary, fontSize: 11 }} />
            <YAxis tick={{ fill: txtSecondary, fontSize: 11 }} />
            <Tooltip contentStyle={{ backgroundColor: tooltipBg, border: `1px solid ${gridColor}`, borderRadius: 12, color: txtPrimary }} />
            <Line type="monotone" dataKey="actuel" stroke="#00A650" strokeWidth={2} dot={{ r: 3 }} name="Consommation réelle" connectNulls={false} />
            <Line type="monotone" dataKey="projection" stroke="#F59E0B" strokeWidth={2} strokeDasharray="6 3" dot={false} name="Projection" />
            <Line type="monotone" dataKey="budget" stroke="#EF4444" strokeWidth={1} strokeDasharray="3 3" dot={false} name="Budget total" />
          </LineChart>
        </ResponsiveContainer>
      </motion.div>
    </div>
  )
}
