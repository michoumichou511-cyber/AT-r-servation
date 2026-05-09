import { useEffect, useRef } from 'react'

export default function FloatingBubbles({ count = 8 }) {
  const canvasRef = useRef(null)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    let animId
    let W = window.innerWidth
    let H = window.innerHeight
    canvas.width = W
    canvas.height = H

    const resize = () => {
      W = window.innerWidth
      H = window.innerHeight
      canvas.width = W
      canvas.height = H
    }
    window.addEventListener('resize', resize)

    const particles = Array.from({ length: count * 5 }, () => ({
      x: Math.random() * W,
      y: Math.random() * H,
      r: Math.random() * 3 + 1,
      dx: (Math.random() - 0.5) * 0.4,
      dy: (Math.random() - 0.5) * 0.4,
      color: Math.random() > 0.5 ? '#00A650' : '#003DA5',
    }))

    const draw = () => {
      ctx.clearRect(0, 0, W, H)

      // Lignes entre particules proches
      for (let i = 0; i < particles.length; i++) {
        for (let j = i + 1; j < particles.length; j++) {
          const dx = particles[i].x - particles[j].x
          const dy = particles[i].y - particles[j].y
          const dist = Math.sqrt(dx * dx + dy * dy)
          if (dist < 120) {
            ctx.beginPath()
            ctx.strokeStyle = `rgba(0, 166, 80, ${1 - dist / 120})`
            ctx.lineWidth = 0.5
            ctx.moveTo(particles[i].x, particles[i].y)
            ctx.lineTo(particles[j].x, particles[j].y)
            ctx.stroke()
          }
        }
      }

      // Points
      particles.forEach(p => {
        ctx.beginPath()
        ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2)
        ctx.fillStyle = p.color
        ctx.globalAlpha = 0.7
        ctx.fill()
        ctx.globalAlpha = 1
        p.x += p.dx
        p.y += p.dy
        if (p.x < 0 || p.x > W) p.dx *= -1
        if (p.y < 0 || p.y > H) p.dy *= -1
      })

      // Vagues en bas
      const time = Date.now() / 3000
      for (let w = 0; w < 3; w++) {
        ctx.beginPath()
        ctx.moveTo(0, H)
        for (let x = 0; x <= W; x += 5) {
          const y = H - 60 - w * 30 + 
            Math.sin(x / 200 + time + w) * 20
          ctx.lineTo(x, y)
        }
        ctx.lineTo(W, H)
        ctx.closePath()
        ctx.fillStyle = `rgba(176, 210, 230, ${0.15 - w * 0.04})`
        ctx.fill()
      }

      animId = requestAnimationFrame(draw)
    }

    const onVisibilityChange = () => {
      if (document.hidden) {
        cancelAnimationFrame(animId)
      } else {
        animId = requestAnimationFrame(draw)
      }
    }
    document.addEventListener('visibilitychange', onVisibilityChange)

    draw()
    return () => {
      cancelAnimationFrame(animId)
      window.removeEventListener('resize', resize)
      document.removeEventListener('visibilitychange', onVisibilityChange)
    }
  }, [count])

  return (
    <canvas
      ref={canvasRef}
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        width: '100%',
        height: '100%',
        zIndex: 0,
        pointerEvents: 'none',
        willChange: 'transform',
      }}
    />
  )
}
