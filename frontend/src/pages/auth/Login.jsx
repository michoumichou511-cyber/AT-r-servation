import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../../contexts/AuthContext'
import toast from 'react-hot-toast'
import { Eye, EyeOff, Loader2 } from 'lucide-react'
import AnimatedBalls from '../../components/Dashboard/AnimatedBalls'
import Particles from '../../components/Dashboard/Particles'
import FloatingBubbles from '../../components/Common/FloatingBubbles'

const MOBILE_MQ = '(max-width: 767px)'

/**
 * Connexion mobile uniquement : fond sombre + AnimatedBalls + Particles + FloatingBubbles
 * (aucun canvas). Le bureau utilise le layout d’origine ci-dessous.
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
}) {
  const demoBtns = [
    { label: 'Administrateur', key: 'admin', color: '#6D28D9', bg: '#F5F3FF', border: '#DDD6FE' },
    { label: 'Validateur', key: 'validateur', color: '#1D4ED8', bg: '#EFF6FF', border: '#BFDBFE' },
    { label: 'Utilisateur', key: 'utilisateur', color: '#15803D', bg: '#F0FDF4', border: '#BBF7D0' },
    { label: 'Demandeur', key: 'demandeur', color: '#C2410C', bg: '#FFF7ED', border: '#FED7AA' },
  ]

  return (
    <div
      style={{
        minHeight: '100vh',
        background: '#0F1117',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        position: 'relative',
        overflow: 'hidden',
        fontFamily: 'IBM Plex Sans, sans-serif',
        padding: 16,
      }}
    >
      <div
        style={{ position: 'fixed', inset: 0, zIndex: 0, pointerEvents: 'none' }}
        aria-hidden
      >
        <FloatingBubbles count={8} />
        <div style={{ position: 'absolute', inset: 0 }}>
          <AnimatedBalls />
        </div>
        <div style={{ position: 'absolute', inset: 0 }}>
          <Particles />
        </div>
      </div>
      <div
        style={{
          position: 'fixed',
          inset: 0,
          background:
            'radial-gradient(ellipse at 20% 50%, rgba(0,61,165,0.3) 0%, transparent 60%), radial-gradient(ellipse at 80% 50%, rgba(0,166,80,0.2) 0%, transparent 60%)',
          pointerEvents: 'none',
          zIndex: 1,
        }}
        aria-hidden
      />

      <div
        style={{
          position: 'relative',
          zIndex: 10,
          width: '100%',
          maxWidth: 440,
          background: 'rgba(255,255,255,0.06)',
          backdropFilter: 'blur(20px)',
          WebkitBackdropFilter: 'blur(20px)',
          border: '1px solid rgba(255,255,255,0.12)',
          borderRadius: 24,
          padding: 32,
          boxShadow: '0 25px 50px rgba(0,0,0,0.35)',
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
              color: '#fff',
              fontWeight: 800,
              fontSize: 22,
              marginBottom: 4,
            }}
          >
            AT Réservations
          </h1>
          <p style={{ color: 'rgba(255,255,255,0.65)', fontSize: 13 }}>
            Algérie Télécom
          </p>
        </div>

        <h2
          style={{
            color: 'rgba(255,255,255,0.95)',
            fontWeight: 800,
            fontSize: 20,
            marginBottom: 4,
          }}
        >
          Connexion
        </h2>
        <p style={{ color: 'rgba(255,255,255,0.55)', fontSize: 13, marginBottom: 20 }}>
          Entrez vos identifiants Algérie Télécom
        </p>

        {error && (
          <div
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

        <form onSubmit={handleSubmit}>
          <div style={{ position: 'relative', marginBottom: 14 }}>
            <span
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
              type="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              placeholder="prenom.nom@at.dz"
              required
              style={{
                width: '100%',
                borderRadius: 12,
                border: '1px solid rgba(255,255,255,0.15)',
                background: 'rgba(255,255,255,0.08)',
                color: '#fff',
                fontSize: 14,
                fontFamily: 'inherit',
                paddingLeft: 44,
                paddingRight: 12,
                paddingTop: 14,
                paddingBottom: 14,
                outline: 'none',
              }}
              className="placeholder:text-[rgba(255,255,255,0.4)] focus:border-[#00A650]"
            />
          </div>
          <div style={{ position: 'relative', marginBottom: 24 }}>
            <span
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
              type={showPass ? 'text' : 'password'}
              value={password}
              onChange={e => setPassword(e.target.value)}
              placeholder="Mot de passe"
              required
              style={{
                width: '100%',
                borderRadius: 12,
                border: '1px solid rgba(255,255,255,0.15)',
                background: 'rgba(255,255,255,0.08)',
                color: '#fff',
                fontSize: 14,
                fontFamily: 'inherit',
                paddingLeft: 44,
                paddingRight: 44,
                paddingTop: 14,
                paddingBottom: 14,
                outline: 'none',
              }}
              className="placeholder:text-[rgba(255,255,255,0.4)] focus:border-[#00A650]"
            />
            <button
              type="button"
              onClick={() => setShowPass(!showPass)}
              style={{
                position: 'absolute',
                right: 14,
                top: '50%',
                transform: 'translateY(-50%)',
                background: 'none',
                border: 'none',
                cursor: 'pointer',
                color: 'rgba(255,255,255,0.55)',
              }}
            >
              {showPass ? <EyeOff size={18} /> : <Eye size={18} />}
            </button>
          </div>
          <button
            type="submit"
            disabled={loading}
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
          <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,0.12)' }} />
          <span
            style={{
              fontSize: 10,
              fontWeight: 600,
              color: 'rgba(255,255,255,0.45)',
              textTransform: 'uppercase',
              letterSpacing: '0.06em',
            }}
          >
            Comptes de démonstration
          </span>
          <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,0.12)' }} />
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
              onClick={() => {
                setEmail(comptes[b.key].email)
                setPassword(comptes[b.key].password)
              }}
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

        <p style={{ textAlign: 'center', fontSize: 11, color: 'rgba(255,255,255,0.5)', marginBottom: 16, lineHeight: 1.5 }}>
          Mot de passe démo (tous les comptes) :
          {' '}
          <strong style={{ color: '#7AB8FF', fontFamily: 'monospace' }}>Password@123</strong>
          <br />
          <span style={{ fontSize: 10 }}>Cliquez un rôle ci-dessus pour remplir email + mot de passe.</span>
        </p>
        <p style={{ textAlign: 'center', fontSize: 12, color: 'rgba(255,255,255,0.45)' }}>
          Problème de connexion ?
          {' '}
          <a href="mailto:it-support@at.dz" style={{ color: '#4ADE80', fontWeight: 600, textDecoration: 'none' }}>
            Contacter le support IT
          </a>
        </p>
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
  const { login } = useAuth()
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
          import.meta.env.VITE_API_URL || 'http://127.0.0.1:8000/api'
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

  if (isMobile) {
    return (
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
      />
    )
  }

  return (
    <div
      style={{
        display: 'flex',
        height: '100vh',
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
        className="hidden md:flex"
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

        {/* Texte central */}
        <div
          style={{
            position: 'relative',
            zIndex: 10,
          }}
        >
          <div
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: 6,
              padding: '4px 12px',
              background: 'rgba(255,255,255,0.1)',
              border: '1px solid rgba(255,255,255,0.2)',
              borderRadius: 20,
              marginBottom: 16,
            }}
          >
            <div
              style={{
                width: 7,
                height: 7,
                borderRadius: '50%',
                background: '#52FF8A',
              }}
            />
            <span
              style={{
                fontSize: 10,
                fontWeight: 600,
                color: 'rgba(255,255,255,0.85)',
                letterSpacing: '0.08em',
                textTransform: 'uppercase',
              }}
            >
              Espace employé
            </span>
          </div>

          <h1
            style={{
              fontSize: 32,
              fontWeight: 800,
              color: 'white',
              lineHeight: 1.25,
              marginBottom: 12,
            }}
          >
            Bienvenue sur
            <br />
            votre{' '}
            <span style={{ color: '#52FF8A' }}>
              espace de travail.
            </span>
          </h1>

          <p
            style={{
              fontSize: 13,
              color: 'rgba(255,255,255,0.6)',
              lineHeight: 1.7,
              maxWidth: 280,
            }}
          >
            Plateforme sécurisée de gestion des missions réservée aux agents Algérie Télécom.
          </p>
        </div>

        {/* Bloc accès sécurisé */}
        <div
          style={{
            background: 'rgba(255,255,255,0.08)',
            border: '1px solid rgba(255,255,255,0.12)',
            borderRadius: 14,
            padding: 16,
            position: 'relative',
            zIndex: 10,
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
        className="flex flex-1 flex-col justify-center px-10 py-12 sm:px-12 max-w-[520px] bg-white dark:bg-[#1A1D2E] transition-colors"
        style={{
          display: 'flex',
          flexDirection: 'column',
        }}
      >
        <h1 className="text-[28px] font-extrabold text-[#1A1D26] dark:text-white mb-1">
          Connexion
        </h1>
        <p className="text-[13px] text-[#9AA0AE] dark:text-gray-400 mb-8">
          Entrez vos identifiants Algérie Télécom
        </p>

        {error && (
          <div
            className="rounded-[10px] border px-4 py-3 mb-4 text-[13px] bg-[#FEF2F2] border-[#FECACA] border-l-4 border-l-[#EF4444] text-[#B91C1C] dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-200 dark:border-l-red-500"
          >
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          {/* Email */}
          <div
            style={{
              position: 'relative',
              marginBottom: 14,
            }}
          >
            <span
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
              type="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              placeholder="prenom.nom@at.dz"
              required
              className="w-full rounded-xl border-2 border-[#EAECF0] dark:border-gray-600 text-[13px] text-[#1A1D26] dark:text-white outline-none font-inherit pl-11 pr-3.5 py-3.5 dark:placeholder:text-gray-500"
              style={{
                background: 'var(--input-bg, #F8F9FC)',
                fontFamily: 'inherit',
              }}
            />
          </div>

          {/* Password */}
          <div
            style={{
              position: 'relative',
              marginBottom: 24,
            }}
          >
            <span
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
              type={showPass ? 'text' : 'password'}
              value={password}
              onChange={e => setPassword(e.target.value)}
              placeholder="Mot de passe"
              required
              className="w-full rounded-xl border-2 border-[#EAECF0] dark:border-gray-600 text-[13px] text-[#1A1D26] dark:text-white outline-none font-inherit px-11 py-3.5 dark:placeholder:text-gray-500"
              style={{
                background: 'var(--input-bg, #F8F9FC)',
                fontFamily: 'inherit',
              }}
            />
            <button
              type="button"
              onClick={() => setShowPass(!showPass)}
              style={{
                position: 'absolute',
                right: 14,
                top: '50%',
                transform: 'translateY(-50%)',
                background: 'none',
                border: 'none',
                cursor: 'pointer',
                color: '#C0C5D0',
              }}
            >
              {showPass ? <EyeOff size={18} /> : <Eye size={18} />}
            </button>
          </div>

          {/* Bouton connexion */}
          <button
            type="submit"
            disabled={loading}
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
          </button>
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
          <div className="flex-1 h-px bg-[#EAECF0] dark:bg-gray-600" />
          <span
            className="text-[10px] font-semibold text-[#C0C5D0] dark:text-gray-500 uppercase tracking-wider whitespace-nowrap"
          >
            Comptes de démonstration
          </span>
          <div className="flex-1 h-px bg-[#EAECF0] dark:bg-gray-600" />
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
            <button
              key={b.key}
              type="button"
              onClick={() => {
                setEmail(comptes[b.key].email)
                setPassword(comptes[b.key].password)
              }}
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

        <p className="text-center text-[11px] text-[#9AA0AE] dark:text-gray-400 mb-4 leading-snug">
          Mot de passe démo (tous les comptes) :
          {' '}
          <strong className="text-[#003DA5] dark:text-[#7AB8FF] font-mono">
            Password@123
          </strong>
          <br />
          <span className="text-[10px] text-[#C0C5D0] dark:text-gray-500">
            Cliquez un rôle ci-dessus pour remplir email + mot de passe.
          </span>
        </p>

        <p className="text-center text-xs text-[#C0C5D0] dark:text-gray-500">
          Problème de connexion ?{' '}
          <a
            href="mailto:it-support@at.dz"
            className="text-[#00A650] dark:text-[#4ADE80] font-semibold no-underline"
          >
            Contacter le support IT
          </a>
        </p>
      </div>
    </div>
  )
}
