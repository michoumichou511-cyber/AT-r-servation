import { motion } from 'framer-motion'
import {
  Plus, Send, CheckCircle, XCircle,
  Edit, Truck, MessageSquare, Clock,
} from 'lucide-react'

const TYPE_CONFIG = {
  creation:     { icon: Plus, color: '#00A650', label: 'Création' },
  soumission:   { icon: Send, color: '#003DA5', label: 'Soumission' },
  validation:   { icon: CheckCircle, color: '#00A650', label: 'Validation' },
  rejet:        { icon: XCircle, color: '#EF4444', label: 'Rejet' },
  modification: { icon: Edit, color: '#F59E0B', label: 'Modification' },
  logistique:   { icon: Truck, color: '#8B5CF6', label: 'Logistique' },
  commentaire:  { icon: MessageSquare, color: '#6B7280', label: 'Commentaire' },
}

function SkeletonItem() {
  return (
    <div className="flex gap-4 animate-pulse">
      <div className="flex flex-col items-center">
        <div className="w-8 h-8 rounded-full bg-gray-200 dark:bg-gray-700" />
        <div className="flex-1 w-0.5 bg-gray-200 dark:bg-gray-700 mt-1" />
      </div>
      <div className="flex-1 pb-6">
        <div className="h-4 w-32 bg-gray-200 dark:bg-gray-700 rounded mb-2" />
        <div className="h-3 w-48 bg-gray-200 dark:bg-gray-700 rounded" />
      </div>
    </div>
  )
}

export default function MissionTimeline({ events = [], loading = false }) {
  if (loading) {
    return (
      <div className="space-y-0">
        {[0, 1, 2, 3].map(i => <SkeletonItem key={i} />)}
      </div>
    )
  }

  if (events.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-10 gap-3">
        <Clock size={40} className="text-gray-300 dark:text-gray-600" />
        <p className="text-sm text-gray-400 dark:text-gray-500">Aucun historique disponible</p>
      </div>
    )
  }

  return (
    <div className="relative">
      {events.map((ev, i) => {
        const cfg = TYPE_CONFIG[ev.type] ?? TYPE_CONFIG.commentaire
        const Icon = cfg.icon
        const isLast = i === events.length - 1

        return (
          <motion.div
            key={ev.id ?? i}
            initial={{ opacity: 0, x: -12 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: Math.min(i * 0.05, 0.5), duration: 0.3 }}
            className="flex gap-4"
          >
            <div className="flex flex-col items-center">
              <div
                className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full shadow-sm"
                style={{ backgroundColor: `${cfg.color}20` }}
              >
                <Icon size={16} style={{ color: cfg.color }} />
              </div>
              {!isLast && (
                <div className="flex-1 w-0.5 bg-gray-200 dark:bg-gray-700 mt-1" />
              )}
            </div>

            <div className={`flex-1 ${isLast ? '' : 'pb-6'}`}>
              <div className="flex items-center gap-2 flex-wrap">
                <span className="text-sm font-semibold text-gray-800 dark:text-gray-100">
                  {ev.action ?? cfg.label}
                </span>
                <span
                  className="inline-block rounded-full px-2 py-0.5 text-[10px] font-bold text-white"
                  style={{ backgroundColor: cfg.color }}
                >
                  {cfg.label}
                </span>
              </div>

              {ev.user_name && (
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                  par {ev.user_name}
                </p>
              )}

              {ev.details && (
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  {ev.details}
                </p>
              )}

              {ev.date && (
                <p className="text-[11px] text-gray-400 dark:text-gray-500 mt-1">
                  {new Date(ev.date).toLocaleDateString('fr-FR', {
                    day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit',
                  })}
                </p>
              )}
            </div>
          </motion.div>
        )
      })}
    </div>
  )
}
