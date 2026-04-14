import { useEffect, useRef } from 'react'

export const PARTICLE_LINK_MAX = 120
const PARTICLE_LINK_MAX_SQ = PARTICLE_LINK_MAX * PARTICLE_LINK_MAX
export const MOUSE_ATTR_R = 150
const MOUSE_ATTR_R_SQ = MOUSE_ATTR_R * MOUSE_ATTR_R

/** Palette AT — blanc réservé au thème sombre (particules) */
const PALETTE = {
  white: { r: 255, g: 255, b: 255 },
  green: { r: 0, g: 166, b: 80 },
  blue: { r: 0, g: 61, b: 165 },
  cyan: { r: 0, g: 212, b: 255 },
}

export function getIsDarkTheme() {
  return typeof document !== 'undefined' && document.documentElement.classList.contains('dark')
}

function randomRange(a, b) {
  return a + Math.random() * (b - a)
}

export function pickParticleColorKey(isDark) {
  if (!isDark) {
    const r = Math.random()
    if (r < 1 / 3) return 'green'
    if (r < 2 / 3) return 'blue'
    return 'cyan'
  }
  const r = Math.random()
  if (r < 0.7) return 'white'
  if (r < 0.8) return 'green'
  if (r < 0.9) return 'blue'
  return 'cyan'
}

export function seedParticleNetwork(w, h, minCount, isDark) {
  const scaled = Math.floor((w * h) / 8500)
  const n = Math.min(280, Math.max(minCount, scaled))
  const particles = []
  for (let i = 0; i < n; i++) {
    const tierRoll = Math.random()
    let baseR
    if (tierRoll < 0.42) {
      baseR = 0.5 + Math.random() * 1.0
    } else if (tierRoll < 0.82) {
      baseR = 1.5 + Math.random() * 1.5
    } else {
      baseR = 3 + Math.random() * 2
    }
    const hub = Math.random() < 0.12
    const pulse = Math.random() < 0.32
    const speed = 0.1 + Math.random() * 0.9
    const angle = Math.random() * Math.PI * 2

    let opacity
    if (isDark) {
      opacity = baseR < 1.2 ? 0.22 + Math.random() * 0.42 : 0.38 + Math.random() * 0.42
    } else if (baseR >= 3) {
      opacity = randomRange(0.6, 0.9)
    } else if (baseR >= 1.5) {
      opacity = randomRange(0.4, 0.7)
    } else {
      opacity = randomRange(0.25, 0.5)
    }

    particles.push({
      x: Math.random() * w,
      y: Math.random() * h,
      vx: Math.cos(angle) * speed * 0.38,
      vy: Math.sin(angle) * speed * 0.38,
      baseR,
      hub,
      pulse,
      pulsePhase: Math.random() * Math.PI * 2,
      pulseFreq: 0.018 + Math.random() * 0.038,
      colorKey: pickParticleColorKey(isDark),
      opacity,
    })
  }
  return particles
}

export function stepParticleNetwork(particles, w, h, mouse) {
  const mx = mouse?.x
  const my = mouse?.y
  for (let p = 0; p < particles.length; p++) {
    const a = particles[p]
    if (mx != null && my != null) {
      const dx = mx - a.x
      const dy = my - a.y
      const dsq = dx * dx + dy * dy
      if (dsq > 0.25 && dsq < MOUSE_ATTR_R_SQ) {
        const d = Math.sqrt(dsq)
        const t = 1 - d / MOUSE_ATTR_R
        const f = 0.055 * t
        a.vx += (dx / d) * f
        a.vy += (dy / d) * f
      }
    }
    a.x += a.vx
    a.y += a.vy
    if (a.x < 0 || a.x > w) {
      a.vx *= -1
      a.x = Math.max(0, Math.min(w, a.x))
    }
    if (a.y < 0 || a.y > h) {
      a.vy *= -1
      a.y = Math.max(0, Math.min(h, a.y))
    }
    a.vx *= 0.9988
    a.vy *= 0.9988
  }
}

export function drawParticleNetwork(ctx, w, h, particles, timeSec, isDark) {
  for (let i = 0; i < particles.length; i++) {
    for (let j = i + 1; j < particles.length; j++) {
      const a = particles[i]
      const b = particles[j]
      const dx = a.x - b.x
      const dy = a.y - b.y
      const distSq = dx * dx + dy * dy
      if (distSq < PARTICLE_LINK_MAX_SQ && distSq > 0) {
        const dist = Math.sqrt(distSq)
        const t = 1 - dist / PARTICLE_LINK_MAX
        if (isDark) {
          const alpha = t * 0.42
          ctx.strokeStyle = `rgba(255, 255, 255, ${alpha})`
        } else {
          const lineAlpha = Math.min(0.6, Math.max(0.3, t * 0.45 + 0.25))
          const useGreen = (i + j) % 2 === 0
          ctx.strokeStyle = useGreen
            ? `rgba(0, 166, 80, ${lineAlpha})`
            : `rgba(0, 61, 165, ${lineAlpha})`
        }
        ctx.lineWidth = 0.3 + t * 0.7
        ctx.beginPath()
        ctx.moveTo(a.x, a.y)
        ctx.lineTo(b.x, b.y)
        ctx.stroke()
      }
    }
  }

  for (let i = 0; i < particles.length; i++) {
    const p = particles[i]
    const col = PALETTE[p.colorKey]
    let r = p.baseR
    if (p.pulse) {
      r *= 1 + 0.14 * Math.sin(timeSec * (p.pulseFreq * 55) + p.pulsePhase)
    }
    if (p.hub) {
      r *= 1.22
      ctx.beginPath()
      ctx.arc(p.x, p.y, r + 2.2, 0, Math.PI * 2)
      ctx.fillStyle = `rgba(${col.r},${col.g},${col.b},${0.12 * p.opacity})`
      ctx.fill()
    }
    ctx.beginPath()
    ctx.arc(p.x, p.y, r, 0, Math.PI * 2)
    const alpha = p.opacity * (p.colorKey === 'white' ? 0.92 : 1)
    ctx.fillStyle = `rgba(${col.r},${col.g},${col.b},${alpha})`
    ctx.fill()
  }
}

/** Canvas réseau de particules — panneau droit (formulaire) desktop uniquement */
export function FormParticlesCanvas({ containerRef, reducedMotion }) {
  const canvasRef = useRef(null)
  const mouseRef = useRef({ x: null, y: null })
  const isDarkRef = useRef(getIsDarkTheme())

  useEffect(() => {
    const panel = containerRef.current
    const canvas = canvasRef.current
    if (!panel || !canvas) return
    const ctx = canvas.getContext('2d', { alpha: true })
    if (!ctx) return

    let particles = []
    let animId = 0
    let logicalW = 1
    let logicalH = 1

    const syncSize = () => {
      const r = panel.getBoundingClientRect()
      logicalW = Math.max(1, r.width)
      logicalH = Math.max(1, r.height)
      const dpr = Math.min(window.devicePixelRatio || 1, 2)
      canvas.width = Math.floor(logicalW * dpr)
      canvas.height = Math.floor(logicalH * dpr)
      canvas.style.width = `${logicalW}px`
      canvas.style.height = `${logicalH}px`
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
    }

    const reseed = () => {
      isDarkRef.current = getIsDarkTheme()
      particles = seedParticleNetwork(logicalW, logicalH, 120, isDarkRef.current)
    }

    const paintStatic = () => {
      syncSize()
      reseed()
      ctx.clearRect(0, 0, logicalW, logicalH)
      drawParticleNetwork(ctx, logicalW, logicalH, particles, 0, isDarkRef.current)
    }

    const onThemeClass = () => {
      const next = getIsDarkTheme()
      if (next === isDarkRef.current) return
      isDarkRef.current = next
      reseed()
      if (reducedMotion) {
        ctx.clearRect(0, 0, logicalW, logicalH)
        drawParticleNetwork(ctx, logicalW, logicalH, particles, 0, isDarkRef.current)
      }
    }

    const themeObserver = new MutationObserver(onThemeClass)
    themeObserver.observe(document.documentElement, { attributes: true, attributeFilter: ['class'] })

    const onMove = e => {
      const r = panel.getBoundingClientRect()
      mouseRef.current = { x: e.clientX - r.left, y: e.clientY - r.top }
    }
    const onLeave = () => {
      mouseRef.current = { x: null, y: null }
    }

    let ro = null

    if (reducedMotion) {
      paintStatic()
      ro = new ResizeObserver(() => {
        paintStatic()
      })
      ro.observe(panel)
      return () => {
        ro.disconnect()
        themeObserver.disconnect()
      }
    }

    const loop = () => {
      isDarkRef.current = getIsDarkTheme()
      ctx.clearRect(0, 0, logicalW, logicalH)
      stepParticleNetwork(particles, logicalW, logicalH, mouseRef.current)
      drawParticleNetwork(
        ctx,
        logicalW,
        logicalH,
        particles,
        performance.now() / 1000,
        isDarkRef.current,
      )
      animId = requestAnimationFrame(loop)
    }

    const onResizeObserved = () => {
      syncSize()
      reseed()
    }

    syncSize()
    reseed()
    animId = requestAnimationFrame(loop)
    panel.addEventListener('mousemove', onMove)
    panel.addEventListener('mouseleave', onLeave)
    ro = new ResizeObserver(onResizeObserved)
    ro.observe(panel)

    return () => {
      cancelAnimationFrame(animId)
      panel.removeEventListener('mousemove', onMove)
      panel.removeEventListener('mouseleave', onLeave)
      ro.disconnect()
      themeObserver.disconnect()
    }
  }, [containerRef, reducedMotion])

  return (
    <canvas
      ref={canvasRef}
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        width: '100%',
        height: '100%',
        zIndex: 0,
        pointerEvents: 'none',
      }}
      aria-hidden
    />
  )
}

/**
 * 6 vagues sinusoïdales (mobile) — dessinées en premier dans la boucle, avant particules.
 * Double sinus : sin + 0.4*sin(1.7x). Couleurs : vert / bleu AT, cyan, blanc (spec).
 */
const WAVE_STROKE_COLORS = [
  'rgba(0, 166, 80, 0.20)',
  'rgba(255, 255, 255, 0.12)',
  'rgba(0, 61, 165, 0.18)',
  'rgba(0, 212, 255, 0.15)',
  'rgba(0, 166, 80, 0.12)',
  'rgba(255, 255, 255, 0.08)',
]

class Wave {
  constructor(index) {
    this.index = index
    this.amplitude = 40 + index * 8
    this.freq = 0.004 + index * 0.0008
    this.speed = 0.006 + index * 0.0016
    this.lineWidth = 1.5 + (index % 3) * 0.5
    this.strokeColor = WAVE_STROKE_COLORS[index]
  }

  yBase(h) {
    return h * (0.15 + this.index * 0.17)
  }

  sampleY(x, t, h) {
    const f = this.freq
    const phase = t * this.speed * 100
    return (
      this.yBase(h) +
      this.amplitude *
        (Math.sin(x * f + phase) + 0.4 * Math.sin(1.7 * x * f + phase * 0.9))
    )
  }

  draw(ctx, w, h, t) {
    const yTop = this.yBase(h)
    const g = ctx.createLinearGradient(0, yTop, 0, h)
    g.addColorStop(0, this.strokeColor)
    g.addColorStop(1, 'rgba(0, 0, 0, 0)')

    ctx.beginPath()
    ctx.moveTo(0, this.sampleY(0, t, h))
    for (let x = 1; x <= w; x++) {
      ctx.lineTo(x, this.sampleY(x, t, h))
    }
    ctx.lineTo(w, h)
    ctx.lineTo(0, h)
    ctx.closePath()
    ctx.fillStyle = g
    ctx.fill()

    ctx.beginPath()
    ctx.moveTo(0, this.sampleY(0, t, h))
    for (let x = 1; x <= w; x++) {
      ctx.lineTo(x, this.sampleY(x, t, h))
    }
    ctx.strokeStyle = this.strokeColor
    ctx.lineWidth = this.lineWidth
    ctx.lineJoin = 'round'
    ctx.stroke()
  }
}

function createWaveLayers() {
  return [new Wave(0), new Wave(1), new Wave(2), new Wave(3), new Wave(4), new Wave(5)]
}

/**
 * Fond plein écran mobile : vagues + particules (touch / souris).
 * @param {{ darkMode: boolean, reducedMotion: boolean }} props
 */
export function ParticlesBackgroundMobile({ darkMode, reducedMotion }) {
  const canvasRef = useRef(null)
  const particleMouseRef = useRef({ x: null, y: null })

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d', { alpha: true })
    if (!ctx) return

    const isDarkStatic = () => getIsDarkTheme()

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
        const dark = isDarkStatic()
        const g = ctx.createLinearGradient(0, 0, 0, lh)
        g.addColorStop(0, dark ? 'rgba(0, 26, 94, 0.4)' : 'rgba(230, 240, 255, 0.95)')
        g.addColorStop(1, dark ? 'rgba(0, 61, 165, 0.25)' : 'rgba(0, 166, 80, 0.12)')
        ctx.fillStyle = g
        ctx.fillRect(0, 0, lw, lh)
      }
      paintStatic()
      const onTheme = () => paintStatic()
      const themeObserver = new MutationObserver(onTheme)
      themeObserver.observe(document.documentElement, { attributes: true, attributeFilter: ['class'] })
      window.addEventListener('resize', paintStatic)
      return () => {
        window.removeEventListener('resize', paintStatic)
        themeObserver.disconnect()
      }
    }

    const waveLayers = createWaveLayers()

    let animId = 0
    let t = 0
    let particles = []
    let lw = window.innerWidth
    let lh = window.innerHeight

    const resize = () => {
      const dpr = Math.min(window.devicePixelRatio || 1, 1.5)
      lw = window.innerWidth
      lh = window.innerHeight
      canvas.width = Math.floor(lw * dpr)
      canvas.height = Math.floor(lh * dpr)
      canvas.style.width = `${lw}px`
      canvas.style.height = `${lh}px`
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
      const dark = getIsDarkTheme()
      particles = seedParticleNetwork(lw, lh, 80, dark)
    }

    const onTouchMove = e => {
      const touch = e.touches?.[0]
      if (touch) {
        particleMouseRef.current = { x: touch.clientX, y: touch.clientY }
      }
    }
    const onTouchEnd = () => {
      particleMouseRef.current = { x: null, y: null }
    }
    const onWinMouseMove = e => {
      particleMouseRef.current = { x: e.clientX, y: e.clientY }
    }

    const onThemeClass = () => {
      particles = seedParticleNetwork(lw, lh, 80, getIsDarkTheme())
    }
    const themeObserver = new MutationObserver(onThemeClass)
    themeObserver.observe(document.documentElement, { attributes: true, attributeFilter: ['class'] })

    const animate = () => {
      const w = lw
      const h = lh
      const dark = getIsDarkTheme()
      ctx.clearRect(0, 0, w, h)

      waveLayers.forEach(wave => wave.draw(ctx, w, h, t))

      stepParticleNetwork(particles, w, h, particleMouseRef.current)
      drawParticleNetwork(ctx, w, h, particles, performance.now() / 1000, dark)

      t += 0.025
      animId = requestAnimationFrame(animate)
    }

    const onVisibility = () => {
      cancelAnimationFrame(animId)
      if (document.visibilityState === 'visible') {
        animId = requestAnimationFrame(animate)
      }
    }

    resize()
    animId = requestAnimationFrame(animate)
    window.addEventListener('resize', resize)
    window.addEventListener('touchmove', onTouchMove, { passive: true })
    window.addEventListener('touchend', onTouchEnd)
    window.addEventListener('mousemove', onWinMouseMove)
    document.addEventListener('visibilitychange', onVisibility)

    return () => {
      cancelAnimationFrame(animId)
      window.removeEventListener('resize', resize)
      window.removeEventListener('touchmove', onTouchMove)
      window.removeEventListener('touchend', onTouchEnd)
      window.removeEventListener('mousemove', onWinMouseMove)
      document.removeEventListener('visibilitychange', onVisibility)
      themeObserver.disconnect()
    }
  }, [darkMode, reducedMotion])

  return (
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
  )
}
