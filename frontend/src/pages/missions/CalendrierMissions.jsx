import { useCallback, useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronLeft, ChevronRight, Calendar, X } from 'lucide-react'

import { missionsAPI } from '../../services/api'
import PageHeader from '../../components/Common/PageHeader'
import { Button, SkeletonCard } from '../../components/UI'
import { useAuth } from '../../contexts/AuthContext'

const JOURS = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']

const MOIS_NOMS = [
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
]

const STATUT_COLORS = {
  brouillon: { bg: '#9CA3AF', light: '#F3F4F6', text: '#374151', label: 'Brouillon' },
  soumise:   { bg: '#003DA5', light: '#DBEAFE', text: '#1E40AF', label: 'Soumise' },
  approuvee: { bg: '#00A650', light: '#DCFCE7', text: '#166534', label: 'Approuvée' },
  rejetee:   { bg: '#EF4444', light: '#FEE2E2', text: '#991B1B', label: 'Rejetée' },
  en_cours:  { bg: '#F59E0B', light: '#FEF3C7', text: '#92400E', label: 'En cours' },
  terminee:  { bg: '#8B5CF6', light: '#F3E8FF', text: '#6D28D9', label: 'Terminée' },
  annulee:   { bg: '#6B7280', light: '#F3F4F6', text: '#374151', label: 'Annulée' },
}

function getStatutColor(statut) {
  const s = (statut ?? '').toLowerCase().replace(/[éè]/g, 'e')
  return STATUT_COLORS[s] ?? STATUT_COLORS.brouillon
}

function getCalendarDays(year, month) {
  const first = new Date(year, month, 1)
  const last = new Date(year, month + 1, 0)
  let startDay = first.getDay() - 1
  if (startDay < 0) startDay = 6
  const days = []
  for (let i = startDay - 1; i >= 0; i--) {
    const d = new Date(year, month, -i)
    days.push({ date: d, inMonth: false })
  }
  for (let d = 1; d <= last.getDate(); d++) {
    days.push({ date: new Date(year, month, d), inMonth: true })
  }
  while (days.length % 7 !== 0) {
    const d = new Date(year, month + 1, days.length - last.getDate() - startDay + 1)
    days.push({ date: d, inMonth: false })
  }
  return days
}

function dateKey(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

export default function CalendrierMissions() {
  const { darkMode } = useAuth()
  const navigate = useNavigate()

  const now = new Date()
  const [year, setYear] = useState(now.getFullYear())
  const [month, setMonth] = useState(now.getMonth())
  const [loading, setLoading] = useState(true)
  const [events, setEvents] = useState([])
  const [popup, setPopup] = useState(null)
  const [filterStatut, setFilterStatut] = useState('all')

  const charger = useCallback(async () => {
    setLoading(true)
    try {
      const res = await missionsAPI.calendrier({ mois: month + 1, annee: year })
      setEvents(res.data?.events ?? res.data?.data ?? [])
    } catch {
      setEvents([])
    } finally {
      setLoading(false)
    }
  }, [month, year])

  useEffect(() => { charger() }, [charger])

  const filteredEvents = useMemo(() => {
    if (filterStatut === 'all') return events
    return events.filter(e => (e.status ?? '').toLowerCase().replace(/[éè]/g, 'e') === filterStatut)
  }, [events, filterStatut])

  const days = useMemo(() => getCalendarDays(year, month), [year, month])

  const eventsByDay = useMemo(() => {
    const map = {}
    for (const ev of filteredEvents) {
      const start = new Date(ev.start)
      const end = new Date(ev.end ?? ev.start)
      for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
        const key = dateKey(d)
        if (!map[key]) map[key] = []
        map[key].push(ev)
      }
    }
    return map
  }, [filteredEvents])

  const prevMonth = () => {
    if (month === 0) { setMonth(11); setYear(y => y - 1) }
    else setMonth(m => m - 1)
  }
  const nextMonth = () => {
    if (month === 11) { setMonth(0); setYear(y => y + 1) }
    else setMonth(m => m + 1)
  }

  const todayKey = dateKey(now)

  if (loading) {
    return (
      <div>
        <PageHeader title="Calendrier" subtitle="Chargement..." />
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {[0, 1, 2, 3].map(i => <SkeletonCard key={i} />)}
        </div>
      </div>
    )
  }

  return (
    <div>
      <PageHeader title="Calendrier des missions" subtitle={`${MOIS_NOMS[month]} ${year}`} />

      {/* Navigation + filtres */}
      <div className="flex flex-wrap items-center justify-between gap-3 mb-4">
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={prevMonth}>
            <ChevronLeft size={16} />
          </Button>
          <span className="text-sm font-semibold text-[#1A1D26] dark:text-[#E8EAF0] min-w-[140px] text-center">
            {MOIS_NOMS[month]} {year}
          </span>
          <Button variant="outline" size="sm" onClick={nextMonth}>
            <ChevronRight size={16} />
          </Button>
        </div>

        <div className="flex items-center gap-2 overflow-x-auto">
          <button
            type="button"
            onClick={() => setFilterStatut('all')}
            className={[
              'px-3 py-1 rounded-full text-xs font-semibold transition-all whitespace-nowrap',
              filterStatut === 'all'
                ? 'bg-[#00A650] text-white'
                : 'bg-[#F4F6FA] text-[#5A6070] dark:bg-[#252840] dark:text-[#9AA0AE]',
            ].join(' ')}
          >
            Tous
          </button>
          {Object.entries(STATUT_COLORS).map(([key, val]) => (
            <button
              key={key}
              type="button"
              onClick={() => setFilterStatut(key)}
              className={[
                'px-3 py-1 rounded-full text-xs font-semibold transition-all whitespace-nowrap',
                filterStatut === key
                  ? 'text-white'
                  : 'bg-[#F4F6FA] text-[#5A6070] dark:bg-[#252840] dark:text-[#9AA0AE]',
              ].join(' ')}
              style={filterStatut === key ? { backgroundColor: val.bg } : undefined}
            >
              {val.label}
            </button>
          ))}
        </div>
      </div>

      {/* Desktop: Grid calendar */}
      <div className="hidden md:block at-card-surface overflow-hidden">
        {/* Header */}
        <div className="grid grid-cols-7 border-b border-[#EAECF0] dark:border-[#2A2D3E]">
          {JOURS.map(j => (
            <div key={j} className="py-2 text-center text-xs font-semibold text-[#9AA0AE] uppercase tracking-wider">
              {j}
            </div>
          ))}
        </div>

        {/* Days */}
        <div className="grid grid-cols-7">
          {days.map((day, i) => {
            const key = dateKey(day.date)
            const dayEvents = eventsByDay[key] ?? []
            const isToday = key === todayKey
            return (
              <div
                key={i}
                className={[
                  'min-h-[90px] border-b border-r border-[#EAECF0]/50 dark:border-[#2A2D3E] p-1.5 transition-colors',
                  !day.inMonth ? 'bg-[#F8FAFB]/50 dark:bg-[#141727]/30' : '',
                  isToday ? 'bg-[#00A650]/5 dark:bg-[#00A650]/10' : '',
                ].join(' ')}
              >
                <div className={[
                  'text-xs font-semibold mb-1',
                  !day.inMonth ? 'text-[#EAECF0] dark:text-[#2A2D3E]' : 'text-[#5A6070] dark:text-[#9AA0AE]',
                  isToday ? 'text-[#00A650] font-bold' : '',
                ].join(' ')}>
                  {day.date.getDate()}
                </div>
                <div className="space-y-0.5">
                  {dayEvents.slice(0, 3).map((ev, j) => {
                    const sc = getStatutColor(ev.status)
                    return (
                      <button
                        key={`${ev.id}-${j}`}
                        type="button"
                        onClick={() => setPopup(ev)}
                        className="w-full text-left text-[10px] font-medium px-1.5 py-0.5 rounded truncate transition-opacity hover:opacity-80"
                        style={{ backgroundColor: sc.bg, color: '#fff' }}
                      >
                        {ev.title}
                      </button>
                    )
                  })}
                  {dayEvents.length > 3 && (
                    <div className="text-[10px] text-[#9AA0AE] pl-1">
                      +{dayEvents.length - 3} autre(s)
                    </div>
                  )}
                </div>
              </div>
            )
          })}
        </div>
      </div>

      {/* Mobile: list chronologique */}
      <div className="block md:hidden space-y-2">
        {filteredEvents.length === 0 ? (
          <div className="text-center py-12 text-[#9AA0AE]">
            <Calendar size={40} className="mx-auto mb-3 opacity-40" />
            <p className="text-sm">Aucune mission ce mois</p>
          </div>
        ) : (
          filteredEvents.map((ev, i) => {
            const sc = getStatutColor(ev.status)
            return (
              <motion.button
                key={ev.id}
                type="button"
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.03 }}
                onClick={() => navigate(ev.url ?? `/missions/${ev.id}`)}
                className="at-card-surface w-full text-left p-3 flex items-center gap-3"
              >
                <span className="w-2.5 h-2.5 rounded-full flex-shrink-0" style={{ backgroundColor: sc.bg }} />
                <div className="min-w-0 flex-1">
                  <div className="text-sm font-semibold text-[#1A1D26] dark:text-[#E8EAF0] truncate">
                    {ev.title}
                  </div>
                  <div className="text-xs text-[#5A6070] dark:text-[#9AA0AE]">
                    {ev.start} - {ev.end}
                  </div>
                </div>
                <span
                  className="text-[10px] font-semibold px-2 py-0.5 rounded-full"
                  style={{ backgroundColor: sc.light, color: sc.text }}
                >
                  {sc.label}
                </span>
              </motion.button>
            )
          })
        )}
      </div>

      {/* Popup */}
      <AnimatePresence>
        {popup && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40"
            onClick={() => setPopup(null)}
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              onClick={e => e.stopPropagation()}
              className={[
                'w-full max-w-sm rounded-2xl shadow-2xl p-6',
                darkMode ? 'bg-[#1E2235] text-[#E8EAF0]' : 'bg-white text-[#1A1D26]',
              ].join(' ')}
            >
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-bold truncate pr-4">{popup.title}</h3>
                <button type="button" onClick={() => setPopup(null)} className="text-[#9AA0AE] hover:text-[#5A6070]">
                  <X size={20} />
                </button>
              </div>
              <div className="space-y-2 text-sm">
                <div className="flex items-center gap-2">
                  <span className="text-[#5A6070] dark:text-[#9AA0AE]">Statut :</span>
                  <span
                    className="text-xs font-semibold px-2 py-0.5 rounded-full"
                    style={{ backgroundColor: getStatutColor(popup.status).light, color: getStatutColor(popup.status).text }}
                  >
                    {getStatutColor(popup.status).label}
                  </span>
                </div>
                <div>
                  <span className="text-[#5A6070] dark:text-[#9AA0AE]">Dates : </span>
                  <span>{popup.start} - {popup.end}</span>
                </div>
              </div>
              <Button
                className="w-full mt-5"
                onClick={() => { setPopup(null); navigate(popup.url ?? `/missions/${popup.id}`) }}
              >
                Voir le detail
              </Button>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
