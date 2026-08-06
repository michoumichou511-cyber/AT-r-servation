import { useCallback, useEffect, useState } from 'react'
import { ResponsiveContainer, PieChart, Pie, Cell, Tooltip } from 'recharts'
import { motion } from 'framer-motion'
import { Leaf, TrendingDown, TreePine, Plane, Car } from 'lucide-react'
import * as CountUpModule from 'react-countup'

import { dashboardAPI } from '../../services/api'
import { useAuth } from '../../contexts/AuthContext'

const CountUp = CountUpModule.default?.default ?? CountUpModule.default

export default function CarbonWidget() {
  const { darkMode } = useAuth()
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)

  const charger = useCallback(async () => {
    setLoading(true)
    try {
      const res = await dashboardAPI.empreinteCarbone({ periode: 'mois' })
      setData(res.data?.data ?? res.data ?? null)
    } catch {
      setData(null)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { charger() }, [charger])

  if (loading) {
    return (
      <div className="at-card-surface p-5 animate-pulse">
        <div className="h-5 bg-gray-200 dark:bg-gray-700 rounded w-40 mb-4" />
        <div className="h-20 bg-gray-200 dark:bg-gray-700 rounded" />
      </div>
    )
  }

  if (!data) return null

  const totalCo2 = data.total_co2_kg ?? 0
  const arbres = data.equivalent_arbres ?? 0
  const avion = data.co2_avion ?? 0
  const terrestre = data.co2_terrestre ?? 0
  const suggestions = data.suggestions_terrestre ?? 0

  const pieData = [
    { name: 'Avion', value: avion, color: '#EF4444' },
    { name: 'Terrestre', value: terrestre, color: '#00A650' },
  ].filter(d => d.value > 0)

  const txtSecondary = darkMode ? '#9AA0AE' : '#6B7280'
  const tooltipBg = darkMode ? '#1E2235' : '#FFFFFF'
  const txtPrimary = darkMode ? '#E8EAF0' : '#1A1D2E'
  const gridColor = darkMode ? '#2A2D3E' : '#E5E7EB'

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: 0.3 }}
      className="at-card-surface p-5"
      style={{ borderTop: '3px solid #00A650' }}
    >
      <div className="flex items-center gap-2 mb-4">
        <div className="w-8 h-8 rounded-lg flex items-center justify-center bg-[#00A650]/10">
          <Leaf size={18} className="text-[#00A650]" />
        </div>
        <h3 className="text-sm font-semibold text-gray-800 dark:text-gray-100">
          Empreinte carbone
        </h3>
      </div>

      <div className="flex items-start gap-6">
        {/* Left: KPIs */}
        <div className="flex-1 space-y-3">
          <div>
            <div className="text-3xl font-bold text-gray-900 dark:text-gray-100">
              {CountUp ? <CountUp end={totalCo2} duration={1.2} separator=" " decimals={0} /> : totalCo2}
              <span className="text-sm font-normal text-gray-500 dark:text-gray-400 ml-1">kg CO2</span>
            </div>
            <div className="text-xs text-gray-500 dark:text-gray-400">ce mois</div>
          </div>

          <div className="flex items-center gap-3">
            <div className="flex items-center gap-1.5">
              <TreePine size={14} className="text-[#00A650]" />
              <span className="text-sm font-semibold text-gray-700 dark:text-gray-300">{arbres}</span>
              <span className="text-xs text-gray-400">arbres/an</span>
            </div>
          </div>

          <div className="flex items-center gap-3 text-xs">
            <div className="flex items-center gap-1">
              <Plane size={12} className="text-red-500" />
              <span className="text-gray-600 dark:text-gray-300">{avion.toLocaleString('fr-FR')} kg</span>
            </div>
            <div className="flex items-center gap-1">
              <Car size={12} className="text-[#00A650]" />
              <span className="text-gray-600 dark:text-gray-300">{terrestre.toLocaleString('fr-FR')} kg</span>
            </div>
          </div>

          {suggestions > 0 && (
            <div className="flex items-start gap-2 p-2 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <TrendingDown size={14} className="text-amber-500 mt-0.5 flex-shrink-0" />
              <span className="text-[11px] text-amber-700 dark:text-amber-300">
                {suggestions} mission(s) auraient pu etre terrestre(s)
              </span>
            </div>
          )}
        </div>

        {/* Right: Mini donut */}
        {pieData.length > 0 && (
          <div className="w-24 h-24 flex-shrink-0">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={pieData}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  innerRadius={25}
                  outerRadius={40}
                  paddingAngle={2}
                >
                  {pieData.map((d, i) => (
                    <Cell key={i} fill={d.color} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    backgroundColor: tooltipBg,
                    border: `1px solid ${gridColor}`,
                    borderRadius: 8,
                    color: txtPrimary,
                    fontSize: 11,
                  }}
                  formatter={(val) => [`${val} kg`, '']}
                />
              </PieChart>
            </ResponsiveContainer>
            <div className="flex justify-center gap-3 mt-1">
              {pieData.map(d => (
                <div key={d.name} className="flex items-center gap-1">
                  <span className="w-2 h-2 rounded-full" style={{ backgroundColor: d.color }} />
                  <span className="text-[9px] text-gray-400">{d.name}</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </motion.div>
  )
}
