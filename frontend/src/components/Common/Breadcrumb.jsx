import { Link, useLocation } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { ChevronRight, Home } from 'lucide-react'

const routeLabels = {
  '': 'nav.dashboard',
  missions: 'nav.missions',
  calendrier: 'nav.calendar',
  validations: 'nav.validations',
  messagerie: 'nav.messaging',
  notifications: 'nav.notifications',
  profil: 'nav.profile',
  rapports: 'nav.reports',
  admin: 'nav.admin',
  utilisateurs: 'nav.users',
  prestataires: 'nav.providers',
  budgets: 'nav.budgets',
  'audit-logs': 'nav.audit_logs',
  statistiques: 'nav.statistics',
  dml: 'nav.dml',
  about: 'nav.about',
}

export default function Breadcrumb() {
  const location = useLocation()
  const { t } = useTranslation()

  const segments = location.pathname.split('/').filter(Boolean)
  if (segments.length === 0) return null

  const crumbs = segments.map((seg, i) => {
    const path = '/' + segments.slice(0, i + 1).join('/')
    const labelKey = routeLabels[seg]
    const label = labelKey ? t(labelKey) : seg.charAt(0).toUpperCase() + seg.slice(1)
    const isLast = i === segments.length - 1
    return { path, label, isLast }
  })

  return (
    <nav aria-label="Breadcrumb" className="flex items-center gap-1.5 text-xs text-gray-400 dark:text-gray-500 mb-4">
      <Link
        to="/"
        className="flex items-center gap-1 text-gray-400 dark:text-gray-500 hover:text-[#00A650] transition-colors"
      >
        <Home size={13} />
      </Link>
      {crumbs.map((crumb) => (
        <span key={crumb.path} className="flex items-center gap-1.5">
          <ChevronRight size={12} className="text-gray-300 dark:text-gray-600" />
          {crumb.isLast ? (
            <span className="font-medium text-gray-600 dark:text-gray-300">{crumb.label}</span>
          ) : (
            <Link
              to={crumb.path}
              className="hover:text-[#00A650] transition-colors"
            >
              {crumb.label}
            </Link>
          )}
        </span>
      ))}
    </nav>
  )
}
