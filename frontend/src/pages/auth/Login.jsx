import { useState, useEffect, useRef, useMemo, lazy, Suspense, useId } from 'react'
import { useNavigate } from 'react-router-dom'
import { LazyMotion, domAnimation, m } from 'framer-motion'
import { useAuth } from '../../contexts/AuthContext'
import toast from 'react-hot-toast'
import { Eye, EyeOff, Loader2, Sun, Moon } from 'lucide-react'
import { FormParticlesCanvas } from '../../components/ParticlesBackground'

const MOBILE_MQ = '(max-width: 767px)'

const LoginDecor3D = lazy(() => import('../../components/auth/LoginDecor3D'))

function usePrefersReducedMotion() {
  const [reduced, setReduced] = useState(() =>
    typeof window !== 'undefined'
      ? window.matchMedia('(prefers-reduced-motion: reduce)').matches
      : false,
  )
  useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)')
    const apply = () => setReduced(mq.matches)
    apply()
    mq.addEventListener('change', apply)
    return () => mq.removeEventListener('change', apply)
  }, [])
  return reduced
}

/** Bulles larges AT — rgba comme demandé, mouvement type FloatingBubbles.jsx */
const AT_FLOAT_BUBBLES = [
  { x: 6, y: 10, size: 88, dur: 26, delay: 0, fill: 'rgba(0,212,122,0.15)' },
  { x: 72, y: 8, size: 72, dur: 30, delay: 2, fill: 'rgba(0,150,255,0.12)' },
  { x: 18, y: 58, size: 96, dur: 24, delay: 4, fill: 'rgba(0,212,122,0.15)' },
  { x: 52, y: 42, size: 64, dur: 28, delay: 1, fill: 'rgba(0,150,255,0.12)' },
  { x: 84, y: 70, size: 76, dur: 22, delay: 6, fill: 'rgba(0,212,122,0.15)' },
  { x: 34, y: 78, size: 58, dur: 32, delay: 3, fill: 'rgba(0,150,255,0.12)' },
]

/**
 * Connexion mobile : canvas (vagues AnimatedBackground + réseau type ParticleBackground,
 * 25 pts #00D47A / #0096D6, liens &lt; 100px) + bulles AT. Desktop inchangé.
 */
function LoginMobileAnimated({
  email,
  setEmail,
  password,
  setPassword,
  loading,
  error,
  showPass,
  setShowPass,
  handleSubmit,
  comptes,
  darkMode,
}) {
  const canvasRef = useRef(null)
  const floatBubbles = useMemo(() => AT_FLOAT_BUBBLES, [])
  const reducedMotion = usePrefersReducedMotion()
  const emailFieldId = useId()
  const passwordFieldId = useId()
  const loginErrorId = useId()

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d', { alpha: true })
    if (!ctx) return

    const isDark = darkMode
    const COL_GREEN = isDark
      ? { r: 0, g: 212, b: 122 }
      : { r: 0, g: 150, b: 70 }
    const COL_BLUE = isDark
      ? { r: 0, g: 150, b: 214 }
      : { r: 0, g: 80, b: 200 }
    const LINK_DIST = 100
    const LINK_DIST_SQ = LINK_DIST * LINK_DIST

    if (reducedMotion) {
      const paintStatic = () => {
        const dpr = Math.min(window.devicePixelRatio || 1, 1.5)
        const lw = window.innerWidth
        const lh = window.innerHeight
        canvas.width = Math.floor(lw * dpr)
        canvas.height = Math.floor(lh * dpr)
        canvas.style.width = `${lw}px`
        canvas.style.height = `${lh}px`
        ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
        ctx.clearRect(0, 0, lw, lh)
        const g = ctx.createLinearGradient(0, 0, 0, lh)
        g.addColorStop(0, isDark ? 'rgba(0, 26, 94, 0.4)' : 'rgba(230, 240, 255, 0.95)')
        g.addColorStop(1, isDark ? 'rgba(0, 61, 165, 0.25)' : 'rgba(0, 166, 80, 0.12)')
        ctx.fillStyle = g
        ctx.fillRect(0, 0, lw, lh)
      }
      paintStatic()
      window.addEventListener('resize', paintStatic)
      return () => window.removeEventListener('resize', paintStatic)
    }

    const waves = isDark
      ? [
          { yRatio: 0.75, color: 'rgba(0,150,214,0.10)', speed: 0.8, freq: 0.012, amp: 18 },
          { yRatio: 0.82, color: 'rgba(0,180,120,0.08)', speed: -0.6, freq: 0.016, amp: 18 },
          { yRatio: 0.9, color: 'rgba(0,120,200,0.07)', speed: 1.1, freq: 0.02, amp: 18 },
        ]
      : [
          { yRatio: 0.75, color: 'rgba(0,100,180,0.10)', speed: 0.8, freq: 0.012, amp: 18 },
          { yRatio: 0.82, color: 'rgba(0,140,100,0.08)', speed: -0.6, freq: 0.016, amp: 18 },
          { yRatio: 0.9, color: 'rgba(0,80,160,0.07)', speed: 1.1, freq: 0.02, amp: 18 },
        ]

    let animId = 0
    let t = 0
    let particles = []

    const seed = (lw, lh) => {
      particles = []
      const count = lw < 400 ? 12 : 25
      for (let i = 0; i < count; i++) {
        particles.push({
          x: Math.random() * lw,
          y: Math.random() * lh,
          vx: (Math.random() - 0.5) * 0.5,
          vy: (Math.random() - 0.5) * 0.5,
          radius: Math.random() * 2 + 1.2,
          opacity: Math.random() * 0.45 + 0.35,
          isGreen: i % 2 === 0,
        })
      }
    }

    const resize = () => {
      const dpr = Math.min(window.devicePixelRatio || 1, 1.5)
      const lw = window.innerWidth
      const lh = window.innerHeight
      canvas.width = Math.floor(lw * dpr)
      canvas.height = Math.floor(lh * dpr)
      canvas.style.width = `${lw}px`
      canvas.style.height = `${lh}px`
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
      seed(lw, lh)
    }

    const loop = () => {
      const w = window.innerWidth
      const h = window.innerHeight
      ctx.clearRect(0, 0, w, h)

      waves.forEach((wv) => {
        ctx.beginPath()
        ctx.moveTo(0, h)
        for (let x = 0; x <= w; x++) {
          ctx.lineTo(x, h * wv.yRatio + Math.sin(x * wv.freq + t * wv.speed) * wv.amp)
        }
        ctx.lineTo(w, h)
        ctx.closePath()
        ctx.fillStyle = wv.color
        ctx.fill()
      })

      particles.forEach((p) => {
        p.x += p.vx
        p.y += p.vy
        if (p.x < 0 || p.x > w) p.vx *= -1
        if (p.y < 0 || p.y > h) p.vy *= -1
      })

      for (let i = 0; i < particles.length; i++) {
        for (let j = i + 1; j < particles.length; j++) {
          const a = particles[i]
          const b = particles[j]
          const dx = a.x - b.x
          const dy = a.y - b.y
          const distSq = dx * dx + dy * dy
          if (distSq < LINK_DIST_SQ) {
            const distance = Math.sqrt(distSq)
            const alpha = (1 - distance / LINK_DIST) * 0.35
            ctx.beginPath()
            ctx.moveTo(a.x, a.y)
            ctx.lineTo(b.x, b.y)
            ctx.strokeStyle = `rgba(0, 200, 140, ${alpha * 0.5})`
            ctx.lineWidth = 0.65
            ctx.stroke()
          }
        }
      }

      particles.forEach((p) => {
        const c = p.isGreen ? COL_GREEN : COL_BLUE
        ctx.beginPath()
        ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2)
        const fillAlpha = isDark ? p.opacity : 1
        ctx.fillStyle = `rgba(${c.r},${c.g},${c.b},${fillAlpha})`
        ctx.fill()
      })

      t += 0.025
      animId = requestAnimationFrame(loop)
    }

    const onVisibility = () => {
      cancelAnimationFrame(animId)
      if (document.visibilityState === 'visible') {
        animId = requestAnimationFrame(loop)
      }
    }

    resize()
    animId = requestAnimationFrame(loop)
    window.addEventListener('resize', resize)
    document.addEventListener('visibilitychange', onVisibility)

    return () => {
      cancelAnimationFrame(animId)
      window.removeEventListener('resize', resize)
      document.removeEventListener('visibilitychange', onVisibility)
    }
  }, [darkMode, reducedMotion])

  const demoBtns = [
    { label: 'Administrateur', key: 'admin', color: '#6D28D9', bg: '#F5F3FF', border: '#DDD6FE' },
    { label: 'Validateur', key: 'validateur', color: '#1D4ED8', bg: '#EFF6FF', border: '#BFDBFE' },
    { label: 'Utilisateur', key: 'utilisateur', color: '#15803D', bg: '#F0FDF4', border: '#BBF7D0' },
    { label: 'Demandeur', key: 'demandeur', color: '#C2410C', bg: '#FFF7ED', border: '#FED7AA' },
  ]

  const mt = darkMode
    ? {
        pageBg: '#0b1220',
        cardBg: 'rgba(255,255,255,0.06)',
        cardBorder: 'rgba(255,255,255,0.12)',
        title: '#fff',
        subtitle: 'rgba(255,255,255,0.65)',
        h2: 'rgba(255,255,255,0.95)',
        hint: 'rgba(255,255,255,0.55)',
        inputBorder: 'rgba(255,255,255,0.15)',
        inputBg: 'rgba(255,255,255,0.08)',
        inputColor: '#fff',
        iconBtn: 'rgba(255,255,255,0.55)',
        sep: 'rgba(255,255,255,0.12)',
        sepLabel: 'rgba(255,255,255,0.45)',
        footerMuted: 'rgba(255,255,255,0.5)',
        footerSmall: 'rgba(255,255,255,0.45)',
        radial:
          'radial-gradient(ellipse at 20% 50%, rgba(0,61,165,0.22) 0%, transparent 60%), radial-gradient(ellipse at 80% 50%, rgba(0,166,80,0.15) 0%, transparent 60%)',
      }
    : {
        pageBg: '#f0f4ff',
        cardBg: 'rgba(255,255,255,0.92)',
        cardBorder: 'rgba(0,61,165,0.14)',
        title: '#1A1D26',
        subtitle: 'rgba(26,29,38,0.65)',
        h2: '#1A1D26',
        hint: 'rgba(26,29,38,0.55)',
        inputBorder: 'rgba(0,61,165,0.2)',
        inputBg: 'rgba(255,255,255,0.95)',
        inputColor: '#1A1D26',
        iconBtn: 'rgba(26,29,38,0.55)',
        sep: 'rgba(0,61,165,0.15)',
        sepLabel: 'rgba(26,29,38,0.45)',
        footerMuted: 'rgba(26,29,38,0.65)',
        footerSmall: 'rgba(26,29,38,0.5)',
        radial:
          'radial-gradient(ellipse at 20% 50%, rgba(0,61,165,0.12) 0%, transparent 60%), radial-gradient(ellipse at 80% 50%, rgba(0,166,80,0.08) 0%, transparent 60%)',
      }

  return (
    <div
      style={{
        minHeight: '100vh',
        background: mt.pageBg,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        position: 'relative',
        overflow: 'hidden',
        fontFamily: 'IBM Plex Sans, sans-serif',
        padding: 16,
      }}
    >
      <canvas
        ref={canvasRef}
        style={{
          position: 'fixed',
          top: 0,
          left: 0,
          width: '100vw',
          height: '100vh',
          zIndex: 0,
          pointerEvents: 'none',
        }}
        aria-hidden
      />
      <div
        className="pointer-events-none fixed inset-0 overflow-hidden"
        style={{ zIndex: 0 }}
        aria-hidden
      >
        {floatBubbles.map((b, i) => (
          <m.div
            key={i}
            style={{
              position: 'absolute',
              left: `${b.x}%`,
              top: `${b.y}%`,
              width: b.size,
              height: b.size,
              borderRadius: '50%',
              background: `radial-gradient(circle at 35% 35%, ${b.fill}, transparent 72%)`,
              border: `1px solid ${i % 2 === 0 ? 'rgba(0,212,122,0.22)' : 'rgba(0,150,255,0.2)'}`,
              willChange: reducedMotion ? undefined : 'transform',
            }}
            animate={
              reducedMotion
                ? undefined
                : {
                    y: [0, -36, 0],
                    x: [0, 14, 0],
                    scale: [1, 1.06, 1],
                  }
            }
            transition={{
              duration: reducedMotion ? 0 : b.dur,
              repeat: reducedMotion ? 0 : Infinity,
              delay: reducedMotion ? 0 : b.delay,
              ease: 'easeInOut',
            }}
          />
        ))}
      </div>
      <div
        style={{
          position: 'fixed',
          inset: 0,
          background: mt.radial,
          pointerEvents: 'none',
          zIndex: 0,
        }}
        aria-hidden
      />

      <div
        style={{
          position: 'relative',
          zIndex: 1,
          width: '100%',
          maxWidth: 440,
          background: mt.cardBg,
          backdropFilter: 'blur(20px)',
          WebkitBackdropFilter: 'blur(20px)',
          border: `1px solid ${mt.cardBorder}`,
          borderRadius: 24,
          padding: 32,
          boxShadow: darkMode ? '0 25px 50px rgba(0,0,0,0.35)' : '0 20px 40px rgba(0,61,165,0.12)',
        }}
      >
        <div style={{ textAlign: 'center', marginBottom: 24 }}>
          <img
            src="/logo-at.jpg"
            alt="Algérie Télécom"
            style={{
              height: 56,
              width: 'auto',
              objectFit: 'contain',
              borderRadius: 12,
              background: 'rgba(255,255,255,0.95)',
              padding: 4,
              marginBottom: 12,
            }}
          />
          <h1
            style={{
              color: mt.title,
              fontWeight: 800,
              fontSize: 22,
              marginBottom: 4,
            }}
          >
            AT Réservations
          </h1>
          <p style={{ color: mt.subtitle, fontSize: 13 }}>
            Algérie Télécom
          </p>
        </div>

        <h2
          style={{
            color: mt.h2,
            fontWeight: 800,
            fontSize: 20,
            marginBottom: 4,
          }}
        >
          Connexion
        </h2>
        <p style={{ color: mt.hint, fontSize: 13, marginBottom: 20 }}>
          Entrez vos identifiants Algérie Télécom
        </p>

        {error && (
          <div
            id={loginErrorId}
            role="alert"
            aria-live="assertive"
            className="rounded-[10px] border px-4 py-3 mb-4 text-[13px]"
            style={{
              background: 'rgba(254, 242, 242, 0.12)',
              borderColor: 'rgba(252, 165, 165, 0.45)',
              color: '#fecaca',
            }}
          >
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} aria-describedby={error ? loginErrorId : undefined}>
          <label htmlFor={emailFieldId} className="sr-only">
            Adresse e-mail professionnelle
          </label>
          <div style={{ position: 'relative', marginBottom: 14 }}>
            <span
              aria-hidden
              style={{
                position: 'absolute',
                left: 15,
                top: '50%',
                transform: 'translateY(-50%)',
                fontSize: 16,
                opacity: 0.75,
              }}
            >
              ✉️
            </span>
            <input
              id={emailFieldId}
              type="email"
              name="email"
              autoComplete="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              placeholder="prenom.nom@at.dz"
              required
              style={{
                width: '100%',
                borderRadius: 12,
                border: `1px solid ${mt.inputBorder}`,
                background: mt.inputBg,
                color: mt.inputColor,
                fontSize: 14,
                fontFamily: 'inherit',
                paddingLeft: 44,
                paddingRight: 12,
                minHeight: 44,
                paddingTop: 14,
                paddingBottom: 14,
                outline: 'none',
              }}
              className={
                darkMode
                  ? 'placeholder:text-[rgba(255,255,255,0.4)] focus-visible:border-[#00A650] focus-visible:ring-2 focus-visible:ring-[#00A650]/35'
                  : 'placeholder:text-[rgba(26,29,38,0.4)] focus-visible:border-[#00A650] focus-visible:ring-2 focus-visible:ring-[#00A650]/35'
              }
            />
          </div>
          <label htmlFor={passwordFieldId} className="sr-only">
            Mot de passe
          </label>
          <div style={{ position: 'relative', marginBottom: 24 }}>
            <span
              aria-hidden
              style={{
                position: 'absolute',
                left: 15,
                top: '50%',
                transform: 'translateY(-50%)',
                fontSize: 16,
                opacity: 0.75,
              }}
            >
              🔒
            </span>
            <input
              id={passwordFieldId}
              type={showPass ? 'text' : 'password'}
              name="password"
              autoComplete="current-password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              placeholder="Mot de passe"
              required
              style={{
                width: '100%',
                borderRadius: 12,
                border: `1px solid ${mt.inputBorder}`,
                background: mt.inputBg,
                color: mt.inputColor,
                fontSize: 14,
                fontFamily: 'inherit',
                paddingLeft: 44,
                paddingRight: 48,
                minHeight: 44,
                paddingTop: 14,
                paddingBottom: 14,
                outline: 'none',
              }}
              className={
                darkMode
                  ? 'placeholder:text-[rgba(255,255,255,0.4)] focus-visible:border-[#00A650] focus-visible:ring-2 focus-visible:ring-[#00A650]/35'
                  : 'placeholder:text-[rgba(26,29,38,0.4)] focus-visible:border-[#00A650] focus-visible:ring-2 focus-visible:ring-[#00A650]/35'
              }
            />
            <button
              type="button"
              onClick={() => setShowPass(!showPass)}
              aria-label={showPass ? 'Masquer le mot de passe' : 'Afficher le mot de passe'}
              className="absolute right-1 top-1/2 -translate-y-1/2 flex h-11 min-w-[44px] items-center justify-center rounded-lg bg-transparent border-0 cursor-pointer"
              style={{
                color: mt.iconBtn,
              }}
            >
              {showPass ? <EyeOff size={18} aria-hidden /> : <Eye size={18} aria-hidden />}
            </button>
          </div>
          <button
            type="submit"
            disabled={loading}
            className="min-h-[44px]"
            style={{
              width: '100%',
              padding: 15,
              borderRadius: 12,
              border: 'none',
              background: 'linear-gradient(135deg, #003DA5, #00A650)',
              color: 'white',
              fontSize: 14,
              fontWeight: 700,
              fontFamily: 'inherit',
              cursor: loading ? 'not-allowed' : 'pointer',
              opacity: loading ? 0.7 : 1,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 8,
              marginBottom: 20,
            }}
          >
            {loading ? (
              <>
                <Loader2 size={18} style={{ animation: 'spin 1s linear infinite' }} />
                Connexion...
              </>
            ) : (
              'Se connecter →'
            )}
          </button>
        </form>

        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 10,
            marginBottom: 14,
          }}
        >
          <div style={{ flex: 1, height: 1, background: mt.sep }} />
          <span
            style={{
              fontSize: 10,
              fontWeight: 600,
              color: mt.sepLabel,
              textTransform: 'uppercase',
              letterSpacing: '0.06em',
            }}
          >
            Comptes de démonstration
          </span>
          <div style={{ flex: 1, height: 1, background: mt.sep }} />
        </div>

        <div
          style={{
            display: 'grid',
            gridTemplateColumns: '1fr 1fr',
            gap: 8,
            marginBottom: 20,
          }}
        >
          {demoBtns.map(b => (
            <button
              key={b.key}
              type="button"
              aria-label={`Remplir avec le compte démo ${b.label}`}
              onClick={() => {
                setEmail(comptes[b.key].email)
                setPassword(comptes[b.key].password)
              }}
              className="min-h-[44px]"
              style={{
                padding: '10px 12px',
                borderRadius: 10,
                border: `1.5px solid ${b.border}`,
                background: b.bg,
                color: b.color,
                fontSize: 12,
                fontWeight: 600,
                fontFamily: 'inherit',
                cursor: 'pointer',
              }}
            >
              {b.label}
            </button>
          ))}
        </div>

        <p style={{ textAlign: 'center', fontSize: 11, color: mt.footerMuted, marginBottom: 16, lineHeight: 1.5 }}>
          Mot de passe démo (tous les comptes) :
          {' '}
          <strong style={{ color: darkMode ? '#7AB8FF' : '#003DA5', fontFamily: 'monospace' }}>Password@123</strong>
          <br />
          <span style={{ fontSize: 10, color: mt.footerSmall }}>Cliquez un rôle ci-dessus pour remplir email + mot de passe.</span>
        </p>
        <p style={{ textAlign: 'center', fontSize: 12, color: mt.footerSmall }}>
          Problème de connexion ?
          {' '}
          <a href="mailto:it-support@at.dz" style={{ color: darkMode ? '#4ADE80' : '#00A650', fontWeight: 600, textDecoration: 'none' }}>
            Contacter le support IT
          </a>
        </p>
      </div>
    </div>
  )
}

const WELCOME_FEATURES = [
  { icon: '🚀', title: 'Gestion des missions', desc: 'Ordres de mission en quelques clics' },
  { icon: '📊', title: 'Suivi en temps réel', desc: 'Tableaux de bord interactifs' },
  { icon: '✅', title: 'Validation simplifiée', desc: 'Circuit de validation rapide' },
  { icon: '🔐', title: 'Espace sécurisé', desc: 'Réservé aux agents AT' },
]

function CircuitSVGOverlay() {
  return (
    <svg
      viewBox="0 0 500 600"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', zIndex: 2, pointerEvents: 'none', opacity: 0.18 }}
      aria-hidden
    >
      <m.path
        d="M50 100 L150 100 L150 200 L250 200 L250 150 L350 150"
        stroke="#52FF8A" strokeWidth="1.5" strokeLinecap="round"
        initial={{ pathLength: 0 }} animate={{ pathLength: 1 }}
        transition={{ duration: 2.5, delay: 0.5, ease: [0.22, 1, 0.36, 1] }}
      />
      <m.path
        d="M400 50 L400 180 L300 180 L300 300 L200 300"
        stroke="#00A650" strokeWidth="1" strokeLinecap="round"
        initial={{ pathLength: 0 }} animate={{ pathLength: 1 }}
        transition={{ duration: 2, delay: 1, ease: [0.22, 1, 0.36, 1] }}
      />
      <m.path
        d="M80 400 L180 400 L180 350 L280 350 L280 450 L380 450"
        stroke="#52FF8A" strokeWidth="1.5" strokeLinecap="round"
        initial={{ pathLength: 0 }} animate={{ pathLength: 1 }}
        transition={{ duration: 2.5, delay: 1.5, ease: [0.22, 1, 0.36, 1] }}
      />
      <m.path
        d="M450 300 L350 300 L350 500 L200 500 L200 550"
        stroke="#0096D6" strokeWidth="1" strokeLinecap="round"
        initial={{ pathLength: 0 }} animate={{ pathLength: 1 }}
        transition={{ duration: 2, delay: 2, ease: [0.22, 1, 0.36, 1] }}
      />
      <m.path
        d="M100 550 L100 480 L220 480 L220 420 L350 420"
        stroke="#00A650" strokeWidth="1.5" strokeLinecap="round"
        initial={{ pathLength: 0 }} animate={{ pathLength: 1 }}
        transition={{ duration: 2, delay: 2.5, ease: [0.22, 1, 0.36, 1] }}
      />
      {[[150, 100], [250, 200], [350, 150], [300, 300], [400, 180], [180, 400], [280, 350], [380, 450], [350, 500], [220, 480]].map(([cx, cy], i) => (
        <m.circle
          key={i} cx={cx} cy={cy} r="3" fill="#52FF8A"
          initial={{ scale: 0, opacity: 0 }}
          animate={{ scale: [0, 1.5, 1], opacity: [0, 1, 0.8] }}
          transition={{ duration: 0.4, delay: 1 + i * 0.25 }}
        />
      ))}
      <m.circle
        cx="250" cy="300" r="60" stroke="#52FF8A" strokeWidth="0.5" fill="none"
        initial={{ scale: 0, opacity: 0 }}
        animate={{ scale: [1, 1.3, 1], opacity: [0.15, 0.05, 0.15] }}
        transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut' }}
      />
      <m.circle
        cx="250" cy="300" r="100" stroke="#0096D6" strokeWidth="0.3" fill="none"
        initial={{ scale: 0, opacity: 0 }}
        animate={{ scale: [1, 1.2, 1], opacity: [0.1, 0.03, 0.1] }}
        transition={{ duration: 5, repeat: Infinity, ease: 'easeInOut', delay: 1 }}
      />
    </svg>
  )
}

function useMouseParallax(strength = 1) {
  const [offset, setOffset] = useState({ x: 0, y: 0 })
  useEffect(() => {
    const onMove = (e) => {
      const cx = window.innerWidth / 2
      const cy = window.innerHeight / 2
      setOffset({
        x: ((e.clientX - cx) / cx) * 12 * strength,
        y: ((e.clientY - cy) / cy) * 8 * strength,
      })
    }
    window.addEventListener('mousemove', onMove)
    return () => window.removeEventListener('mousemove', onMove)
  }, [strength])
  return offset
}

function FallingParticles() {
  const particles = useMemo(() => {
    const items = []
    for (let i = 0; i < 18; i++) {
      items.push({
        left: `${5 + Math.random() * 90}%`,
        size: 2 + Math.random() * 4,
        duration: 6 + Math.random() * 8,
        delay: Math.random() * 10,
        opacity: 0.15 + Math.random() * 0.25,
        color: i % 3 === 0 ? '#52FF8A' : i % 3 === 1 ? '#00A650' : '#0096D6',
      })
    }
    return items
  }, [])

  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 3, pointerEvents: 'none', overflow: 'hidden' }} aria-hidden>
      <style>{`
        @keyframes fallDown {
          0% { transform: translateY(-20px) scale(1); opacity: 0; }
          10% { opacity: var(--p-opacity); }
          90% { opacity: var(--p-opacity); }
          100% { transform: translateY(calc(100vh + 20px)) scale(0.5); opacity: 0; }
        }
        @keyframes sway {
          0%, 100% { transform: translateX(0); }
          50% { transform: translateX(20px); }
        }
      `}</style>
      {particles.map((p, i) => (
        <div
          key={i}
          style={{
            position: 'absolute',
            left: p.left,
            top: -20,
            width: p.size,
            height: p.size,
            borderRadius: '50%',
            background: p.color,
            boxShadow: `0 0 ${p.size * 2}px ${p.color}`,
            '--p-opacity': p.opacity,
            animation: `fallDown ${p.duration}s ${p.delay}s linear infinite, sway ${3 + Math.random() * 2}s ${p.delay}s ease-in-out infinite`,
          }}
        />
      ))}
    </div>
  )
}

function FlowingOrbs() {
  return (
    <svg
      viewBox="0 0 500 600"
      style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', zIndex: 4, pointerEvents: 'none' }}
      aria-hidden
    >
      <defs>
        <filter id="orbGlow">
          <feGaussianBlur stdDeviation="3" result="blur" />
          <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
        </filter>
        <path id="orb-path-1" d="M0 100 Q125 50 250 150 T500 100" />
        <path id="orb-path-2" d="M500 300 Q375 200 250 350 T0 300" />
        <path id="orb-path-3" d="M50 500 Q200 400 350 500 T500 450" />
      </defs>
      <circle r="4" fill="#52FF8A" filter="url(#orbGlow)" opacity="0.6">
        <animateMotion dur="7s" repeatCount="indefinite" rotate="auto">
          <mpath xlinkHref="#orb-path-1" />
        </animateMotion>
      </circle>
      <circle r="3" fill="#00A650" filter="url(#orbGlow)" opacity="0.5">
        <animateMotion dur="9s" repeatCount="indefinite" rotate="auto" begin="2s">
          <mpath xlinkHref="#orb-path-2" />
        </animateMotion>
      </circle>
      <circle r="3.5" fill="#0096D6" filter="url(#orbGlow)" opacity="0.4">
        <animateMotion dur="11s" repeatCount="indefinite" rotate="auto" begin="4s">
          <mpath xlinkHref="#orb-path-3" />
        </animateMotion>
      </circle>
      <circle r="2" fill="#52FF8A" filter="url(#orbGlow)" opacity="0.3">
        <animateMotion dur="6s" repeatCount="indefinite" rotate="auto" begin="1s">
          <mpath xlinkHref="#orb-path-1" />
        </animateMotion>
      </circle>
      <circle r="2.5" fill="#00A650" filter="url(#orbGlow)" opacity="0.35">
        <animateMotion dur="8s" repeatCount="indefinite" rotate="auto" begin="5s">
          <mpath xlinkHref="#orb-path-2" />
        </animateMotion>
      </circle>
    </svg>
  )
}

function CharReveal({ text, delay = 0, className, style }) {
  return (
    <span className={className} style={{ display: 'inline-flex', flexWrap: 'wrap', ...style }}>
      {text.split('').map((char, i) => (
        <m.span
          key={i}
          initial={{ opacity: 0, y: 40, filter: 'blur(10px)' }}
          animate={{ opacity: 1, y: 0, filter: 'blur(0px)' }}
          transition={{ duration: 0.45, delay: delay + i * 0.06, ease: [0.22, 1, 0.36, 1] }}
          style={{ display: 'inline-block', whiteSpace: char === ' ' ? 'pre' : undefined }}
        >
          {char}
        </m.span>
      ))}
    </span>
  )
}

function NetworkParticleCanvas() {
  const canvasRef = useRef(null)
  const mouseRef = useRef({ x: -9999, y: -9999 })
  const reducedMotion = usePrefersReducedMotion()

  useEffect(() => {
    if (reducedMotion) return
    const canvas = canvasRef.current
    if (!canvas) return
    const parent = canvas.parentElement
    if (!parent) return
    const ctx = canvas.getContext('2d', { alpha: true })
    if (!ctx) return

    let animId = 0
    let particles = []
    let t = 0
    const COUNT = 50
    const LINK_DIST = 110
    const MOUSE_R = 140

    const COLS = [
      { r: 0, g: 166, b: 80 },
      { r: 0, g: 100, b: 200 },
      { r: 82, g: 255, b: 138 },
      { r: 0, g: 150, b: 214 },
    ]

    const seed = (w, h) => {
      particles = []
      for (let i = 0; i < COUNT; i++) {
        const c = COLS[i % COLS.length]
        particles.push({
          x: Math.random() * w, y: Math.random() * h,
          vx: (Math.random() - 0.5) * 0.35, vy: (Math.random() - 0.5) * 0.35,
          r: Math.random() * 2 + 1, c,
          op: Math.random() * 0.4 + 0.25,
          ph: Math.random() * Math.PI * 2,
        })
      }
    }

    const resize = () => {
      const rect = parent.getBoundingClientRect()
      const dpr = Math.min(window.devicePixelRatio || 1, 2)
      canvas.width = Math.floor(rect.width * dpr)
      canvas.height = Math.floor(rect.height * dpr)
      canvas.style.width = `${rect.width}px`
      canvas.style.height = `${rect.height}px`
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
      seed(rect.width, rect.height)
    }

    const onMove = (e) => {
      const rect = parent.getBoundingClientRect()
      mouseRef.current = { x: e.clientX - rect.left, y: e.clientY - rect.top }
    }
    const onLeave = () => { mouseRef.current = { x: -9999, y: -9999 } }

    const loop = () => {
      const rect = parent.getBoundingClientRect()
      const w = rect.width, h = rect.height
      ctx.clearRect(0, 0, w, h)
      const mx = mouseRef.current.x, my = mouseRef.current.y
      t += 0.015

      particles.forEach(p => {
        const dx = p.x - mx, dy = p.y - my
        const d = Math.sqrt(dx * dx + dy * dy)
        if (d < MOUSE_R && d > 1) {
          const f = (MOUSE_R - d) / MOUSE_R * 0.02
          p.vx += (dx / d) * f
          p.vy += (dy / d) * f
        }
        p.x += p.vx; p.y += p.vy
        p.vx *= 0.998; p.vy *= 0.998
        if (p.x < 0 || p.x > w) p.vx *= -1
        if (p.y < 0 || p.y > h) p.vy *= -1
        p.x = Math.max(0, Math.min(w, p.x))
        p.y = Math.max(0, Math.min(h, p.y))
      })

      for (let i = 0; i < particles.length; i++) {
        for (let j = i + 1; j < particles.length; j++) {
          const a = particles[i], b = particles[j]
          const dx = a.x - b.x, dy = a.y - b.y
          const dist = Math.sqrt(dx * dx + dy * dy)
          if (dist < LINK_DIST) {
            const alpha = (1 - dist / LINK_DIST) * 0.22
            ctx.beginPath()
            ctx.moveTo(a.x, a.y)
            ctx.lineTo(b.x, b.y)
            ctx.strokeStyle = `rgba(82, 255, 138, ${alpha})`
            ctx.lineWidth = 0.6
            ctx.stroke()
          }
        }
      }

      particles.forEach(p => {
        const pulse = 1 + Math.sin(t * 2 + p.ph) * 0.25
        const radius = p.r * pulse
        const g = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, radius * 5)
        g.addColorStop(0, `rgba(${p.c.r},${p.c.g},${p.c.b},${p.op * 0.2})`)
        g.addColorStop(1, 'transparent')
        ctx.beginPath()
        ctx.arc(p.x, p.y, radius * 5, 0, Math.PI * 2)
        ctx.fillStyle = g
        ctx.fill()
        ctx.beginPath()
        ctx.arc(p.x, p.y, radius, 0, Math.PI * 2)
        ctx.fillStyle = `rgba(${p.c.r},${p.c.g},${p.c.b},${p.op * 0.8})`
        ctx.fill()
      })

      animId = requestAnimationFrame(loop)
    }

    resize()
    animId = requestAnimationFrame(loop)
    parent.addEventListener('mousemove', onMove)
    parent.addEventListener('mouseleave', onLeave)
    window.addEventListener('resize', resize)
    const onVis = () => {
      cancelAnimationFrame(animId)
      if (document.visibilityState === 'visible') animId = requestAnimationFrame(loop)
    }
    document.addEventListener('visibilitychange', onVis)

    return () => {
      cancelAnimationFrame(animId)
      parent.removeEventListener('mousemove', onMove)
      parent.removeEventListener('mouseleave', onLeave)
      window.removeEventListener('resize', resize)
      document.removeEventListener('visibilitychange', onVis)
    }
  }, [reducedMotion])

  if (reducedMotion) return null
  return <canvas ref={canvasRef} style={{ position: 'absolute', inset: 0, zIndex: 2 }} aria-hidden />
}

function TelecomDishSVG() {
  return (
    <svg
      viewBox="0 0 220 200"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      style={{ position: 'absolute', right: 20, top: 20, width: 180, zIndex: 2, pointerEvents: 'none', opacity: 0.85 }}
      aria-hidden
    >
      <defs>
        <filter id="sig-glow">
          <feGaussianBlur stdDeviation="3" result="blur" />
          <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
        </filter>
      </defs>

      <g transform="translate(110,130)">
        {/* Réflecteur parabolique — vue 3/4 */}
        <m.path
          d="M-70 10 C-65 -45 -30 -80 0 -85 C30 -80 65 -45 70 10"
          stroke="rgba(255,255,255,0.8)" strokeWidth="2" fill="rgba(255,255,255,0.06)" strokeLinecap="round"
          initial={{ pathLength: 0, opacity: 0 }}
          animate={{ pathLength: 1, opacity: 1 }}
          transition={{ duration: 1.5, delay: 0.3, ease: [0.22, 1, 0.36, 1] }}
        />
        {/* Bord bas (ellipse perspective) */}
        <m.ellipse
          cx="0" cy="10" rx="70" ry="18"
          stroke="rgba(255,255,255,0.5)" strokeWidth="1.5" fill="none"
          initial={{ pathLength: 0 }}
          animate={{ pathLength: 1 }}
          transition={{ duration: 1.2, delay: 0.6, ease: [0.22, 1, 0.36, 1] }}
        />
        {/* Nervures internes du réflecteur */}
        <m.path d="M0 10 L0 -85" stroke="rgba(255,255,255,0.2)" strokeWidth="0.8"
          initial={{ pathLength: 0 }} animate={{ pathLength: 1 }} transition={{ duration: 0.8, delay: 1 }} />
        <m.path d="M-35 10 L-15 -78" stroke="rgba(255,255,255,0.15)" strokeWidth="0.6"
          initial={{ pathLength: 0 }} animate={{ pathLength: 1 }} transition={{ duration: 0.8, delay: 1.1 }} />
        <m.path d="M35 10 L15 -78" stroke="rgba(255,255,255,0.15)" strokeWidth="0.6"
          initial={{ pathLength: 0 }} animate={{ pathLength: 1 }} transition={{ duration: 0.8, delay: 1.2 }} />

        {/* Bras de support vers le LNB */}
        <m.line x1="-50" y1="0" x2="0" y2="-55" stroke="rgba(255,255,255,0.5)" strokeWidth="1.2"
          initial={{ pathLength: 0 }} animate={{ pathLength: 1 }} transition={{ duration: 0.8, delay: 1.4 }} />
        <m.line x1="50" y1="0" x2="0" y2="-55" stroke="rgba(255,255,255,0.5)" strokeWidth="1.2"
          initial={{ pathLength: 0 }} animate={{ pathLength: 1 }} transition={{ duration: 0.8, delay: 1.5 }} />

        {/* Tête LNB (récepteur) */}
        <m.rect x="-4" y="-62" width="8" height="14" rx="2"
          fill="rgba(255,255,255,0.7)" stroke="rgba(255,255,255,0.9)" strokeWidth="1"
          initial={{ scale: 0 }} animate={{ scale: 1 }} transition={{ duration: 0.4, delay: 1.8 }} />

        {/* Point lumineux du LNB */}
        <m.circle cx="0" cy="-55" r="3" fill="#52FF8A" filter="url(#sig-glow)"
          initial={{ scale: 0 }} animate={{ scale: [0, 1.3, 1] }} transition={{ duration: 0.5, delay: 2 }} />

        {/* Pied court */}
        <m.line x1="0" y1="28" x2="0" y2="50" stroke="rgba(255,255,255,0.6)" strokeWidth="2.5" strokeLinecap="round"
          initial={{ pathLength: 0 }} animate={{ pathLength: 1 }} transition={{ duration: 0.5, delay: 1.6 }} />
        {/* Base */}
        <m.path d="M-18 50 L18 50" stroke="rgba(255,255,255,0.5)" strokeWidth="2.5" strokeLinecap="round"
          initial={{ pathLength: 0 }} animate={{ pathLength: 1 }} transition={{ duration: 0.4, delay: 1.9 }} />
        <m.path d="M-12 50 L-16 56 M12 50 L16 56" stroke="rgba(255,255,255,0.35)" strokeWidth="1.5" strokeLinecap="round"
          initial={{ pathLength: 0 }} animate={{ pathLength: 1 }} transition={{ duration: 0.3, delay: 2.1 }} />
      </g>

      {/* Ondes signal émises vers le haut-gauche */}
      <g transform="translate(110,75)">
        {[0, 1, 2, 3].map(i => (
          <m.path
            key={i}
            d={`M${-10 - i * 14},${5 + i * 5} A${18 + i * 14},${18 + i * 14} 0 0,1 ${10 + i * 14},${5 + i * 5}`}
            stroke="#52FF8A" strokeWidth={1.8 - i * 0.3} fill="none" strokeLinecap="round"
            filter="url(#sig-glow)"
            initial={{ pathLength: 0, opacity: 0 }}
            animate={{ pathLength: [0, 1, 0], opacity: [0, 0.9 - i * 0.18, 0] }}
            transition={{ duration: 1.8, delay: 2.5 + i * 0.35, repeat: Infinity, repeatDelay: 2 }}
          />
        ))}
      </g>
    </svg>
  )
}

function LoginWelcomeOverlay() {
  const [featureIdx, setFeatureIdx] = useState(0)
  const parallax = useMouseParallax(1)

  useEffect(() => {
    const timer = setInterval(() => setFeatureIdx(i => (i + 1) % WELCOME_FEATURES.length), 4000)
    return () => clearInterval(timer)
  }, [])

  return (
    <div style={{ position: 'relative', zIndex: 10, flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', transform: `translate(${parallax.x}px, ${parallax.y}px)`, transition: 'transform 0.15s ease-out' }}>
      <m.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ duration: 0.5, delay: 0.2 }}>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, padding: '5px 14px', background: 'rgba(255,255,255,0.08)', border: '1px solid rgba(255,255,255,0.15)', borderRadius: 20, marginBottom: 24 }}>
          <div style={{ width: 7, height: 7, borderRadius: '50%', background: '#52FF8A', boxShadow: '0 0 10px rgba(82,255,138,0.6)' }} />
          <span style={{ fontSize: 10, fontWeight: 600, color: 'rgba(255,255,255,0.8)', letterSpacing: '0.08em', textTransform: 'uppercase' }}>
            Direction des Systèmes d'Information
          </span>
        </div>
      </m.div>

      <div style={{ marginBottom: 8 }}>
        <CharReveal
          text="Bienvenue"
          delay={0.4}
          style={{ fontSize: 46, fontWeight: 800, color: 'white', lineHeight: 1.1 }}
        />
      </div>

      <m.div
        initial={{ opacity: 0, clipPath: 'inset(0 100% 0 0)' }}
        animate={{ opacity: 1, clipPath: 'inset(0 0% 0 0)' }}
        transition={{ duration: 0.8, delay: 1.1, ease: [0.22, 1, 0.36, 1] }}
        style={{ marginBottom: 20, display: 'flex', alignItems: 'center', gap: 8 }}
      >
        <span style={{ fontSize: 20, fontWeight: 500, color: 'rgba(255,255,255,0.85)' }}>
          sur <strong style={{ fontWeight: 700 }}>AT Réservations</strong>
        </span>
        <m.span
          animate={{ opacity: [1, 0] }}
          transition={{ duration: 0.7, repeat: Infinity, repeatType: 'reverse' }}
          style={{ display: 'inline-block', width: 2, height: 22, background: '#52FF8A', borderRadius: 1 }}
        />
      </m.div>

      <m.div
        initial={{ scaleX: 0 }}
        animate={{ scaleX: 1 }}
        transition={{ duration: 1, delay: 1.4, ease: [0.22, 1, 0.36, 1] }}
        style={{ width: 80, height: 3, background: 'linear-gradient(90deg, #52FF8A, #00A650)', borderRadius: 2, marginBottom: 16, transformOrigin: 'left' }}
      />

      <m.p
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 1.6 }}
        style={{ color: 'rgba(255,255,255,0.6)', fontSize: 13, lineHeight: 1.7, marginBottom: 24, maxWidth: 340 }}
      >
        Votre plateforme de gestion des missions et déplacements professionnels au sein d'Algérie Télécom
      </m.p>

      <div style={{ position: 'relative', minHeight: 64, marginBottom: 14 }}>
        {WELCOME_FEATURES.map((f, i) => (
          <m.div
            key={i}
            initial={false}
            animate={{
              opacity: i === featureIdx ? 1 : 0,
              x: i === featureIdx ? 0 : 40,
              scale: i === featureIdx ? 1 : 0.9,
            }}
            transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
            style={{
              position: i === 0 ? 'relative' : 'absolute',
              top: 0, left: 0, right: 0,
              display: 'flex', alignItems: 'center', gap: 14,
              background: 'rgba(255,255,255,0.06)',
              backdropFilter: 'blur(16px)',
              WebkitBackdropFilter: 'blur(16px)',
              border: '1px solid rgba(255,255,255,0.1)',
              borderRadius: 12,
              padding: '12px 16px',
              pointerEvents: i === featureIdx ? 'auto' : 'none',
            }}
          >
            <span style={{ fontSize: 22, flexShrink: 0 }}>{f.icon}</span>
            <div>
              <div style={{ color: 'white', fontWeight: 700, fontSize: 13 }}>{f.title}</div>
              <div style={{ color: 'rgba(255,255,255,0.5)', fontSize: 11, marginTop: 1 }}>{f.desc}</div>
            </div>
          </m.div>
        ))}
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        {WELCOME_FEATURES.map((_, i) => (
          <button
            key={i}
            type="button"
            onClick={() => setFeatureIdx(i)}
            aria-label={`Fonctionnalité ${i + 1}`}
            style={{
              position: 'relative',
              width: i === featureIdx ? 32 : 8,
              height: 8,
              borderRadius: 4,
              border: 'none',
              cursor: 'pointer',
              background: i === featureIdx ? '#52FF8A' : 'rgba(255,255,255,0.2)',
              boxShadow: i === featureIdx ? '0 0 14px rgba(82,255,138,0.5)' : 'none',
              transition: 'all 0.4s cubic-bezier(0.22, 1, 0.36, 1)',
              overflow: 'hidden',
            }}
          >
            {i === featureIdx && (
              <m.div
                key={featureIdx}
                initial={{ scaleX: 0 }}
                animate={{ scaleX: 1 }}
                transition={{ duration: 4, ease: 'linear' }}
                style={{
                  position: 'absolute', inset: 0,
                  background: 'rgba(255,255,255,0.3)',
                  borderRadius: 4,
                  transformOrigin: 'left',
                }}
              />
            )}
          </button>
        ))}
      </div>
    </div>
  )
}

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [showPass, setShowPass] = useState(false)
  const { login, darkMode, toggleDarkMode } = useAuth()
  const navigate = useNavigate()

  const comptes = {
    admin: { email: 'admin@at.dz', password: 'Password@123' },
    validateur: { email: 'validateur@at.dz', password: 'Password@123' },
    utilisateur: { email: 'user@at.dz', password: 'Password@123' },
    demandeur: { email: 'demandeur@at.dz', password: 'Password@123' },
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      await login(email, password)
      toast.success('Connexion réussie !')
      navigate('/')
    } catch (err) {
      if (!err.response) {
        const apiBase =
          import.meta.env.VITE_API_URL || 'https://backend-production-170c.up.railway.app/api'
        const apiLooksLocal = /localhost|127\.0\.0\.1/.test(apiBase)
        if (import.meta.env.PROD && apiLooksLocal) {
          setError(
            'Déploiement : définissez VITE_API_URL sur Vercel (URL Railway + /api), redéployez, et FRONTEND_URL côté Railway pour le CORS. Voir frontend/README.md.',
          )
        } else {
          setError(
            'Serveur injoignable. Lancez l’API : `php artisan serve` (port 8000) et vérifiez l’URL dans api.js.',
          )
        }
      } else {
        setError(
          err.response?.data?.message
            ?? err.response?.data?.errors?.email?.[0]
            ?? 'Email ou mot de passe incorrect',
        )
      }
    } finally {
      setLoading(false)
    }
  }

  const [isMobile, setIsMobile] = useState(
    () => typeof window !== 'undefined' && window.matchMedia(MOBILE_MQ).matches,
  )

  useEffect(() => {
    const mq = window.matchMedia(MOBILE_MQ)
    const apply = () => setIsMobile(mq.matches)
    apply()
    mq.addEventListener('change', apply)
    return () => mq.removeEventListener('change', apply)
  }, [])

  const reducedMotion = usePrefersReducedMotion()
  const rightPanelRef = useRef(null)
  const desktopEmailId = useId()
  const desktopPasswordId = useId()
  const desktopFormErrorId = useId()

  const themeToggle = (
    <m.button
      type="button"
      onClick={toggleDarkMode}
      whileTap={reducedMotion ? undefined : { rotate: 180 }}
      transition={{ duration: 0.3 }}
      className="fixed top-4 right-4 z-[100] inline-flex h-11 min-w-[44px] items-center justify-center rounded-xl p-2 text-gray-500 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-white/10 transition-colors"
      aria-label={darkMode ? 'Passer en mode clair' : 'Passer en mode sombre'}
    >
      {darkMode ? <Sun size={18} /> : <Moon size={18} />}
    </m.button>
  )

  if (isMobile) {
    return (
      <LazyMotion features={domAnimation}>
        <>
        {themeToggle}
        <LoginMobileAnimated
          email={email}
          setEmail={setEmail}
          password={password}
          setPassword={setPassword}
          loading={loading}
          error={error}
          showPass={showPass}
          setShowPass={setShowPass}
          handleSubmit={handleSubmit}
          comptes={comptes}
          darkMode={darkMode}
        />
        </>
      </LazyMotion>
    )
  }

  return (
    <LazyMotion features={domAnimation}>
    <>
      {themeToggle}
      <div
        style={{
          display: 'flex',
          height: '100vh',
          overflow: 'hidden',
          fontFamily: 'IBM Plex Sans, sans-serif',
        }}
      >
      {/* ═══ GAUCHE ═══ */}
      <div
        style={{
          flex: 1,
          background: '#001a5e',
          position: 'relative',
          overflow: 'hidden',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          padding: 40,
        }}
        className="hidden md:flex overflow-hidden relative"
      >
        <video
          autoPlay
          muted
          loop
          playsInline
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            width: '100%',
            height: '100%',
            objectFit: 'cover',
            zIndex: 0,
            filter: 'brightness(0.65)',
          }}
        >
          <source src="/videos/logo-at.mp4" type="video/mp4" />
        </video>
        <div
          style={{
            position: 'absolute',
            inset: 0,
            background: `linear-gradient(160deg, rgba(0,26,94,0.82) 0%, rgba(0,61,165,0.72) 45%, rgba(0,166,80,0.65) 100%)`,
            zIndex: 1,
            pointerEvents: 'none',
          }}
        />

        {!reducedMotion && <TelecomDishSVG />}

        {/* Cercle déco haut droite */}
        <div
          style={{
            position: 'absolute',
            width: 300,
            height: 300,
            borderRadius: '50%',
            background: 'rgba(255,255,255,0.05)',
            top: -80,
            right: -80,
            zIndex: 2,
            pointerEvents: 'none',
          }}
        />

        {/* Cercle déco bas gauche */}
        <div
          style={{
            position: 'absolute',
            width: 200,
            height: 200,
            borderRadius: '50%',
            background: 'rgba(255,255,255,0.05)',
            bottom: -60,
            left: -40,
            zIndex: 2,
            pointerEvents: 'none',
          }}
        />

        {/* Logo + nom */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 12,
            position: 'relative',
            zIndex: 10,
          }}
        >
          <img
            src="/logo-at.jpg"
            alt="Algérie Télécom"
            style={{
              height: 56,
              width: 'auto',
              objectFit: 'contain',
              borderRadius: 12,
              background: 'white',
              padding: 4,
            }}
          />
          <div>
            <div
              style={{
                color: 'white',
                fontWeight: 700,
                fontSize: 16,
              }}
            >
              AT Réservations
            </div>
            <div
              style={{
                color: 'rgba(255,255,255,0.6)',
                fontSize: 12,
              }}
            >
              Algérie Télécom
            </div>
          </div>
        </div>

        {/* Interactive particle network overlay */}
        <NetworkParticleCanvas />
        <CircuitSVGOverlay />
        <FallingParticles />
        <FlowingOrbs />

        {/* Welcome overlay with animated text */}
        <LoginWelcomeOverlay />

        {/* Bloc accès sécurisé */}
        <div
          className="backdrop-blur-sm max-w-xs"
          style={{
            background: 'rgba(255,255,255,0.08)',
            border: '1px solid rgba(255,255,255,0.12)',
            borderRadius: 14,
            padding: 16,
            position: 'relative',
            zIndex: 10,
            marginTop: 'auto',
          }}
        >
          <p
            style={{
              fontSize: 10,
              fontWeight: 600,
              color: 'rgba(255,255,255,0.4)',
              textTransform: 'uppercase',
              letterSpacing: '0.08em',
              marginBottom: 10,
            }}
          >
            Accès sécurisé
          </p>
          {[
            { icon: '🔐', text: 'Connexion avec votre email @at.dz' },
            { icon: '🏢', text: 'Réservé aux agents Algérie Télécom' },
            { icon: '📞', text: 'Support IT : it-support@at.dz' },
          ].map((item, i) => (
            <div
              key={i}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 8,
                fontSize: 12,
                color: 'rgba(255,255,255,0.75)',
                marginBottom: i < 2 ? 8 : 0,
              }}
            >
              <span>{item.icon}</span>
              <span>{item.text}</span>
            </div>
          ))}
        </div>
      </div>

      {/* ═══ DROITE ═══ */}
      <div
        ref={rightPanelRef}
        className="flex flex-1 flex-col justify-center px-10 py-12 sm:px-12 max-w-[520px] transition-colors"
        style={{
          display: 'flex',
          flexDirection: 'column',
          position: 'relative',
          overflow: 'hidden',
          background: darkMode ? '#0b1220' : '#ffffff',
        }}
      >
        <FormParticlesCanvas containerRef={rightPanelRef} reducedMotion={reducedMotion} />
        <m.div
          className="flex flex-col flex-1 w-full min-h-0"
          style={{
            position: 'relative',
            zIndex: 1,
            ...(darkMode
              ? {
                  background: 'rgba(15,25,45,0.95)',
                  borderRadius: 16,
                  padding: '28px 24px',
                }
              : {}),
          }}
          initial={reducedMotion ? false : { opacity: 0, y: 14 }}
          animate={reducedMotion ? false : { opacity: 1, y: 0 }}
          transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
        >
        <h1
          className={`text-[28px] font-extrabold mb-1 ${
            darkMode ? 'text-white' : 'text-[#1A1D26]'
          }`}
        >
          Connexion
        </h1>
        <p
          className={`text-[13px] mb-8 ${
            darkMode ? 'text-gray-300' : 'text-[#9AA0AE]'
          }`}
        >
          Entrez vos identifiants Algérie Télécom
        </p>

        {error && (
          <div
            id={desktopFormErrorId}
            role="alert"
            aria-live="assertive"
            className={`rounded-[10px] border px-4 py-3 mb-4 text-[13px] border-l-4 ${
              darkMode
                ? 'bg-red-950/40 border-red-800/60 text-red-200 border-l-red-500'
                : 'bg-[#FEF2F2] border-[#FECACA] border-l-[#EF4444] text-[#B91C1C]'
            }`}
          >
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} aria-describedby={error ? desktopFormErrorId : undefined}>
          <label htmlFor={desktopEmailId} className="sr-only">
            Adresse e-mail professionnelle
          </label>
          {/* Email */}
          <div
            style={{
              position: 'relative',
              marginBottom: 14,
            }}
          >
            <span
              aria-hidden
              style={{
                position: 'absolute',
                left: 15,
                top: '50%',
                transform: 'translateY(-50%)',
                fontSize: 16,
                color: '#C0C5D0',
              }}
            >
              ✉️
            </span>
            <input
              id={desktopEmailId}
              name="email"
              type="email"
              autoComplete="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              placeholder="prenom.nom@at.dz"
              required
              className={`min-h-[44px] w-full rounded-xl border-2 text-[13px] outline-none font-inherit pl-11 pr-3.5 py-3.5 focus-visible:ring-2 focus-visible:ring-[#00A650]/40 ${
                darkMode
                  ? 'border-[rgba(255,255,255,0.1)] text-white placeholder:text-gray-500 bg-[rgba(255,255,255,0.06)]'
                  : 'border-[#EAECF0] text-[#1A1D26] bg-[#F8F9FC] placeholder:text-gray-400'
              }`}
              style={{
                fontFamily: 'inherit',
              }}
            />
          </div>

          <label htmlFor={desktopPasswordId} className="sr-only">
            Mot de passe
          </label>
          {/* Password */}
          <div
            style={{
              position: 'relative',
              marginBottom: 24,
            }}
          >
            <span
              aria-hidden
              style={{
                position: 'absolute',
                left: 15,
                top: '50%',
                transform: 'translateY(-50%)',
                fontSize: 16,
                color: '#C0C5D0',
              }}
            >
              🔒
            </span>
            <input
              id={desktopPasswordId}
              name="password"
              type={showPass ? 'text' : 'password'}
              autoComplete="current-password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              placeholder="Mot de passe"
              required
              className={`min-h-[44px] w-full rounded-xl border-2 text-[13px] outline-none font-inherit px-11 py-3.5 focus-visible:ring-2 focus-visible:ring-[#00A650]/40 ${
                darkMode
                  ? 'border-[rgba(255,255,255,0.1)] text-white placeholder:text-gray-500 bg-[rgba(255,255,255,0.06)]'
                  : 'border-[#EAECF0] text-[#1A1D26] bg-[#F8F9FC] placeholder:text-gray-400'
              }`}
              style={{
                fontFamily: 'inherit',
              }}
            />
            <button
              type="button"
              onClick={() => setShowPass(!showPass)}
              aria-label={showPass ? 'Masquer le mot de passe' : 'Afficher le mot de passe'}
              className="absolute right-1 top-1/2 -translate-y-1/2 flex h-11 min-w-[44px] items-center justify-center rounded-lg border-0 bg-transparent cursor-pointer"
              style={{
                color: darkMode ? 'rgba(255,255,255,0.55)' : '#C0C5D0',
              }}
            >
              {showPass ? <EyeOff size={18} aria-hidden /> : <Eye size={18} aria-hidden />}
            </button>
          </div>

          {/* Bouton connexion */}
          <m.button
            type="submit"
            disabled={loading}
            whileHover={reducedMotion || loading ? undefined : { scale: 1.01 }}
            whileTap={reducedMotion || loading ? undefined : { scale: 0.99 }}
            className="min-h-[44px]"
            style={{
              width: '100%',
              padding: 15,
              borderRadius: 12,
              border: 'none',
              background: 'linear-gradient(135deg, #00A650, #003DA5)',
              color: 'white',
              fontSize: 14,
              fontWeight: 700,
              fontFamily: 'inherit',
              cursor: loading ? 'not-allowed' : 'pointer',
              opacity: loading ? 0.7 : 1,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 8,
              marginBottom: 20,
            }}
          >
            {loading ? (
              <>
                <Loader2 size={18} style={{ animation: 'spin 1s linear infinite' }} />
                Connexion...
              </>
            ) : (
              'Se connecter →'
            )}
          </m.button>
        </form>

        {/* Séparateur */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 10,
            marginBottom: 14,
          }}
        >
          <div
            className="flex-1 h-px"
            style={{ background: darkMode ? 'rgba(255,255,255,0.12)' : '#EAECF0' }}
          />
          <span
            className={`text-[10px] font-semibold uppercase tracking-wider whitespace-nowrap ${
              darkMode ? 'text-gray-500' : 'text-[#C0C5D0]'
            }`}
          >
            Comptes de démonstration
          </span>
          <div
            className="flex-1 h-px"
            style={{ background: darkMode ? 'rgba(255,255,255,0.12)' : '#EAECF0' }}
          />
        </div>

        {/* Boutons démo */}
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: '1fr 1fr',
            gap: 8,
            marginBottom: 20,
          }}
        >
          {[
            { label: 'Administrateur', key: 'admin', color: '#6D28D9', bg: '#F5F3FF', border: '#DDD6FE' },
            { label: 'Validateur', key: 'validateur', color: '#1D4ED8', bg: '#EFF6FF', border: '#BFDBFE' },
            { label: 'Utilisateur', key: 'utilisateur', color: '#15803D', bg: '#F0FDF4', border: '#BBF7D0' },
            { label: 'Demandeur', key: 'demandeur', color: '#C2410C', bg: '#FFF7ED', border: '#FED7AA' },
          ].map(b => (
            <m.button
              key={b.key}
              type="button"
              aria-label={`Remplir avec le compte démo ${b.label}`}
              onClick={() => {
                setEmail(comptes[b.key].email)
                setPassword(comptes[b.key].password)
              }}
              whileHover={reducedMotion ? undefined : { scale: 1.02 }}
              whileTap={reducedMotion ? undefined : { scale: 0.98 }}
              className="min-h-[44px]"
              style={{
                padding: '10px 12px',
                borderRadius: 10,
                border: `1.5px solid ${b.border}`,
                background: b.bg,
                color: b.color,
                fontSize: 12,
                fontWeight: 600,
                fontFamily: 'inherit',
                cursor: 'pointer',
              }}
            >
              {b.label}
            </m.button>
          ))}
        </div>

        <p
          className={`text-center text-[11px] mb-4 leading-snug ${
            darkMode ? 'text-gray-400' : 'text-[#9AA0AE]'
          }`}
        >
          Mot de passe démo (tous les comptes) :
          {' '}
          <strong
            className={`font-mono ${darkMode ? 'text-[#7AB8FF]' : 'text-[#003DA5]'}`}
          >
            Password@123
          </strong>
          <br />
          <span
            className={`text-[10px] ${darkMode ? 'text-gray-500' : 'text-[#C0C5D0]'}`}
          >
            Cliquez un rôle ci-dessus pour remplir email + mot de passe.
          </span>
        </p>

        <p
          className={`text-center text-xs ${darkMode ? 'text-gray-500' : 'text-[#C0C5D0]'}`}
        >
          Problème de connexion ?{' '}
          <a
            href="mailto:it-support@at.dz"
            className={`font-semibold no-underline ${
              darkMode ? 'text-[#4ADE80]' : 'text-[#00A650]'
            }`}
          >
            Contacter le support IT
          </a>
        </p>
        </m.div>
      </div>
    </div>
    </>
    </LazyMotion>
  )
}
