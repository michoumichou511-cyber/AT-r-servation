import { useState, useRef, useEffect } from 'react'
import { useTranslation } from 'react-i18next'
import { Languages } from 'lucide-react'

const LANGS = [
  { code: 'fr', label: 'Français', flag: '🇫🇷', dir: 'ltr' },
  { code: 'ar', label: 'العربية', flag: '🇩🇿', dir: 'rtl' },
]

export default function LanguageSwitcher({ compact = false }) {
  const { i18n } = useTranslation()
  const [open, setOpen] = useState(false)
  const ref = useRef(null)

  useEffect(() => {
    const handler = (e) => {
      if (ref.current && !ref.current.contains(e.target)) setOpen(false)
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  const switchLang = (code) => {
    i18n.changeLanguage(code)
    document.documentElement.dir = code === 'ar' ? 'rtl' : 'ltr'
    document.documentElement.lang = code
    setOpen(false)
  }

  const current = LANGS.find((l) => l.code === i18n.language) || LANGS[0]

  return (
    <div ref={ref} className="relative">
      <button
        type="button"
        onClick={() => setOpen(!open)}
        className={`flex items-center gap-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors ${
          compact ? 'p-2' : 'px-3 py-2'
        }`}
        title={i18n.t('language.switch')}
      >
        <Languages size={16} className="text-gray-500 dark:text-gray-400" />
        {!compact && (
          <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
            {current.flag} {current.label}
          </span>
        )}
      </button>

      {open && (
        <div className="absolute right-0 top-full mt-1 w-44 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 shadow-lg z-50 overflow-hidden">
          {LANGS.map((lang) => (
            <button
              key={lang.code}
              type="button"
              onClick={() => switchLang(lang.code)}
              className={`w-full flex items-center gap-3 px-4 py-3 text-sm font-medium transition-colors ${
                i18n.language === lang.code
                  ? 'bg-[#00A650]/10 text-[#00A650] dark:bg-[#00A650]/20'
                  : 'text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700'
              }`}
            >
              <span className="text-lg">{lang.flag}</span>
              <span>{lang.label}</span>
              {i18n.language === lang.code && (
                <span className="ml-auto text-[#00A650]">✓</span>
              )}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
