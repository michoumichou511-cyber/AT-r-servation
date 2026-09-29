import { useState, useEffect, useRef, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { AnimatePresence, motion } from 'framer-motion'
import { Clock, LogOut } from 'lucide-react'
import { useAuth } from '../../contexts/AuthContext'

const IDLE_MS = 25 * 60 * 1000
const WARN_MS = 5 * 60 * 1000

export default function SessionTimeout() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const [showWarning, setShowWarning] = useState(false)
  const [remaining, setRemaining] = useState(WARN_MS)
  const idleTimer = useRef(null)
  const warnTimer = useRef(null)
  const countdownRef = useRef(null)

  const resetTimers = useCallback(() => {
    setShowWarning(false)
    clearTimeout(idleTimer.current)
    clearTimeout(warnTimer.current)
    clearInterval(countdownRef.current)

    idleTimer.current = setTimeout(() => {
      setShowWarning(true)
      setRemaining(WARN_MS)
      const start = Date.now()
      countdownRef.current = setInterval(() => {
        const elapsed = Date.now() - start
        const left = WARN_MS - elapsed
        if (left <= 0) {
          clearInterval(countdownRef.current)
          setShowWarning(false)
          logout()
          navigate('/login')
        } else {
          setRemaining(left)
        }
      }, 1000)
    }, IDLE_MS)
  }, [logout, navigate])

  useEffect(() => {
    if (!user) return

    const events = ['mousedown', 'keydown', 'scroll', 'touchstart']
    const onActivity = () => {
      if (!showWarning) resetTimers()
    }

    events.forEach((e) => document.addEventListener(e, onActivity, { passive: true }))
    resetTimers()

    return () => {
      events.forEach((e) => document.removeEventListener(e, onActivity))
      clearTimeout(idleTimer.current)
      clearTimeout(warnTimer.current)
      clearInterval(countdownRef.current)
    }
  }, [user, resetTimers, showWarning])

  const stayConnected = () => {
    resetTimers()
  }

  const doLogout = () => {
    clearInterval(countdownRef.current)
    setShowWarning(false)
    logout()
    navigate('/login')
  }

  const minutes = Math.floor(remaining / 60000)
  const seconds = Math.floor((remaining % 60000) / 1000)

  if (!user) return null

  return (
    <AnimatePresence>
      {showWarning && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-[999999] flex items-center justify-center"
          style={{ background: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(6px)' }}
        >
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.9, opacity: 0 }}
            className="bg-white dark:bg-[#1E2235] rounded-2xl shadow-2xl border border-gray-200 dark:border-gray-700 p-8 max-w-sm w-full mx-4 text-center"
          >
            <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center">
              <Clock size={32} className="text-amber-500" />
            </div>

            <h2 className="text-lg font-bold text-gray-800 dark:text-gray-100 mb-2">
              Session bientôt expirée
            </h2>
            <p className="text-sm text-gray-500 dark:text-gray-400 mb-4">
              Votre session expirera dans
            </p>

            <div className="text-3xl font-mono font-bold text-amber-500 mb-6">
              {String(minutes).padStart(2, '0')}:{String(seconds).padStart(2, '0')}
            </div>

            <div className="flex gap-3">
              <button
                type="button"
                onClick={doLogout}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl border border-gray-200 dark:border-gray-600 text-gray-600 dark:text-gray-300 text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
              >
                <LogOut size={16} />
                Déconnexion
              </button>
              <button
                type="button"
                onClick={stayConnected}
                className="flex-1 px-4 py-2.5 rounded-xl bg-[#00A650] text-white text-sm font-bold hover:bg-[#008C43] transition-colors"
              >
                Rester connecté
              </button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
