import { useCallback, useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import * as CountUpModule from 'react-countup'
import { Code2, Database, Palette, Server, Users, FileText, Building2, Info } from 'lucide-react'

import { dashboardAPI } from '../services/api'
import PageHeader from '../components/Common/PageHeader'
import { useAuth } from '../contexts/AuthContext'

const CountUp = CountUpModule.default?.default ?? CountUpModule.default

const STACK = [
  { name: 'React 18', icon: Code2, color: '#61DAFB', desc: 'Interface utilisateur' },
  { name: 'Laravel 12', icon: Server, color: '#FF2D20', desc: 'API backend' },
  { name: 'MySQL', icon: Database, color: '#4479A1', desc: 'Base de donnees' },
  { name: 'Tailwind CSS', icon: Palette, color: '#06B6D4', desc: 'Design systeme' },
]

export default function About() {
  const { darkMode } = useAuth()
  const [stats, setStats] = useState(null)

  const charger = useCallback(async () => {
    try {
      const res = await dashboardAPI.stats()
      setStats(res.data?.data ?? res.data ?? {})
    } catch {
      setStats({})
    }
  }, [])

  useEffect(() => { charger() }, [charger])

  const liveStats = [
    { label: 'Utilisateurs', value: stats?.total_users ?? stats?.utilisateurs ?? 0, icon: Users, color: '#003DA5' },
    { label: 'Missions', value: stats?.total_missions ?? stats?.missions ?? 0, icon: FileText, color: '#00A650' },
    { label: 'Prestataires', value: stats?.total_prestataires ?? stats?.prestataires ?? 0, icon: Building2, color: '#8B5CF6' },
  ]

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
    >
      <PageHeader title="A propos" subtitle="AT Reservations v2.0" backTo="/" />

      {/* Hero */}
      <div className="at-card-surface p-8 mb-6 text-center" style={{ borderTop: '3px solid #00A650' }}>
        <img src="/logo-at.jpg" alt="Algerie Telecom" className="w-16 h-16 mx-auto rounded-xl shadow-md mb-4 object-contain" />
        <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">AT Reservations</h1>
        <p className="text-sm text-[#00A650] font-semibold mt-1">v2.0</p>
        <p className="text-sm text-gray-600 dark:text-gray-400 mt-3 max-w-lg mx-auto">
          Plateforme de gestion des missions et deplacements — DSI Algerie Telecom
        </p>
      </div>

      {/* Stats live */}
      {stats && (
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
          {liveStats.map((s, i) => {
            const Icon = s.icon
            return (
              <motion.div
                key={s.label}
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.1 + i * 0.1 }}
                className="at-card-surface p-5 text-center"
                style={{ borderTop: `3px solid ${s.color}` }}
              >
                <div className="w-10 h-10 mx-auto rounded-xl flex items-center justify-center mb-2" style={{ backgroundColor: `${s.color}15` }}>
                  <Icon size={20} style={{ color: s.color }} />
                </div>
                <div className="text-2xl font-bold text-gray-900 dark:text-gray-100">
                  {CountUp ? <CountUp end={s.value} duration={1} separator=" " /> : s.value}
                </div>
                <div className="text-xs text-gray-500 dark:text-gray-400 mt-1">{s.label}</div>
              </motion.div>
            )
          })}
        </div>
      )}

      {/* Stack technique */}
      <div className="at-card-surface p-6 mb-6">
        <h2 className="text-sm font-semibold text-gray-800 dark:text-gray-100 mb-4 flex items-center gap-2">
          <Info size={16} className="text-[#003DA5]" />
          Stack technique
        </h2>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
          {STACK.map((tech, i) => {
            const Icon = tech.icon
            return (
              <motion.div
                key={tech.name}
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 + i * 0.08 }}
                className="text-center p-4 rounded-xl bg-gray-50 dark:bg-gray-800/50"
              >
                <Icon size={28} className="mx-auto mb-2" style={{ color: tech.color }} />
                <div className="text-sm font-semibold text-gray-800 dark:text-gray-100">{tech.name}</div>
                <div className="text-xs text-gray-500 dark:text-gray-400">{tech.desc}</div>
              </motion.div>
            )
          })}
        </div>
      </div>

      {/* Credits + Version */}
      <div className="at-card-surface p-6">
        <div className="text-center space-y-2">
          <p className="text-sm text-gray-700 dark:text-gray-300">
            Developpe par <span className="font-semibold text-[#003DA5]">Ramzi</span> — Projet de fin de formation ISIL
          </p>
          <p className="text-xs text-gray-400 dark:text-gray-500">
            Version 2.0 — Mise a jour : Aout 2026
          </p>
        </div>
      </div>
    </motion.div>
  )
}
