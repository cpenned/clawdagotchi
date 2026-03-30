import { useState, useEffect, useRef, useCallback } from 'react'

type EyeStyle = 'normal' | 'wide' | 'squish' | 'blink'
type Message = string

const ACCENT = '#D97757'
const EYE_COLOR = '#1A1A1A'
const SCREEN_BG = '#0D0D0D'

function drawCrab(
  ctx: CanvasRenderingContext2D,
  s: number,
  eyeStyle: EyeStyle,
  legPhase: number,
  offsetY: number,
  showSunglasses: boolean
) {
  ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height)

  const ox = 0
  const oy = offsetY

  ctx.fillStyle = ACCENT

  // Antennae
  ctx.fillRect(ox + 10 * s, oy + 35 * s, 6 * s, 13 * s)
  ctx.fillRect(ox + 70 * s, oy + 35 * s, 6 * s, 13 * s)

  // Body
  ctx.beginPath()
  ctx.roundRect(ox + 16 * s, oy + 22 * s, 54 * s, 39 * s, 6 * s)
  ctx.fill()

  // Legs (animated with legPhase)
  const legXPositions = [16, 28, 52, 64]
  legXPositions.forEach((lx, i) => {
    const legBob = Math.sin(legPhase + i * 0.8) * 2 * s
    ctx.fillRect(ox + lx * s, oy + 61 * s + legBob, 6 * s, 13 * s)
  })

  // Eyes
  const eyeH = eyeStyle === 'blink' ? 1 * s : eyeStyle === 'squish' ? 3 * s : eyeStyle === 'wide' ? 9 * s : 7 * s
  const eyeYOffset = eyeStyle === 'squish' ? 2 * s : 0

  ctx.fillStyle = EYE_COLOR
  ctx.fillRect(ox + 24 * s, oy + 34 * s + eyeYOffset, 6 * s, eyeH)
  ctx.fillRect(ox + 56 * s, oy + 34 * s + eyeYOffset, 6 * s, eyeH)

  if (showSunglasses) {
    ctx.strokeStyle = '#ffffff'
    ctx.lineWidth = 1.5
    ctx.strokeRect(ox + 22 * s, oy + 32 * s, 10 * s, 11 * s)
    ctx.strokeRect(ox + 54 * s, oy + 32 * s, 10 * s, 11 * s)
    // Bridge
    ctx.beginPath()
    ctx.moveTo(ox + 32 * s, oy + 37 * s)
    ctx.lineTo(ox + 54 * s, oy + 37 * s)
    ctx.stroke()
  }
}

export default function TamagotchiDemo() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const [eyeStyle, setEyeStyle] = useState<EyeStyle>('normal')
  const [bobOffset, setBobOffset] = useState(0)
  const [message, setMessage] = useState<Message>('')
  const [legPhase, setLegPhase] = useState(0)
  const [isWalking, setIsWalking] = useState(false)
  const [jumpOffset, setJumpOffset] = useState(0)
  const [messageVisible, setMessageVisible] = useState(false)
  const messageTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const animFrameRef = useRef<number>(0)
  const timeRef = useRef(0)

  const showMessage = useCallback((msg: string) => {
    if (messageTimerRef.current) clearTimeout(messageTimerRef.current)
    setMessage(msg)
    setMessageVisible(true)
    messageTimerRef.current = setTimeout(() => {
      setMessageVisible(false)
    }, 2000)
  }, [])

  // Idle animation loop
  useEffect(() => {
    let lastTime = 0
    const animate = (timestamp: number) => {
      const delta = timestamp - lastTime
      lastTime = timestamp
      timeRef.current += delta

      const bob = Math.sin(timeRef.current / 800) * 3
      setBobOffset(bob)

      if (isWalking) {
        setLegPhase(prev => prev + 0.15)
      }

      animFrameRef.current = requestAnimationFrame(animate)
    }
    animFrameRef.current = requestAnimationFrame(animate)
    return () => cancelAnimationFrame(animFrameRef.current)
  }, [isWalking])

  // Blink every ~3s
  useEffect(() => {
    const blinkInterval = setInterval(() => {
      setEyeStyle('blink')
      setTimeout(() => setEyeStyle('normal'), 120)
    }, 3000 + Math.random() * 1000)
    return () => clearInterval(blinkInterval)
  }, [])

  // Draw crab on canvas
  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const s = canvas.width / 86
    const totalOffsetY = bobOffset + jumpOffset - 5
    drawCrab(ctx, s, eyeStyle, legPhase, totalOffsetY, false)
  }, [eyeStyle, bobOffset, legPhase, jumpOffset])

  const handlePoke = () => {
    showMessage('hey! >_<')
    setEyeStyle('wide')
    setIsWalking(true)

    // Jump
    let frame = 0
    const jumpAnim = setInterval(() => {
      frame++
      if (frame <= 6) {
        setJumpOffset(-frame * 3.5)
      } else if (frame <= 12) {
        setJumpOffset(-(12 - frame) * 3.5)
      } else {
        setJumpOffset(0)
        clearInterval(jumpAnim)
        setIsWalking(false)
        setTimeout(() => setEyeStyle('normal'), 500)
      }
    }, 40)
  }

  const handleFeed = () => {
    showMessage('nom nom nom 🦀')
    setIsWalking(true)

    let blinks = 0
    const blinkCycle = setInterval(() => {
      setEyeStyle(prev => prev === 'blink' ? 'normal' : 'blink')
      blinks++
      if (blinks >= 8) {
        clearInterval(blinkCycle)
        setEyeStyle('normal')
        setIsWalking(false)
      }
    }, 200)
  }

  const handlePet = () => {
    showMessage('~ happy ~')
    setEyeStyle('squish')
    setTimeout(() => setEyeStyle('normal'), 1500)
  }

  const levelDots = 4

  return (
    <div className="flex justify-center">
      {/* macOS fake window */}
      <div style={{
        background: '#1A1A1A',
        borderRadius: 12,
        boxShadow: '0 32px 80px rgba(0,0,0,0.6), 0 0 0 1px rgba(255,255,255,0.08)',
        overflow: 'hidden',
        width: 360,
        userSelect: 'none',
      }}>
        {/* Titlebar */}
        <div style={{
          background: '#2A2A2A',
          padding: '10px 16px',
          display: 'flex',
          alignItems: 'center',
          gap: 8,
          borderBottom: '1px solid rgba(255,255,255,0.06)',
        }}>
          <div style={{ display: 'flex', gap: 6 }}>
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#FF5F57' }} />
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#FFBD2E' }} />
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#28C840' }} />
          </div>
          <span style={{
            flex: 1,
            textAlign: 'center',
            fontSize: 12,
            color: 'rgba(255,255,255,0.4)',
            fontFamily: "'JetBrains Mono', monospace",
            marginLeft: -38,
          }}>Clawdagotchi</span>
        </div>

        {/* Window content */}
        <div style={{ padding: 24, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20 }}>
          {/* Egg shell */}
          <div style={{
            width: 200,
            height: 240,
            borderRadius: '50% 50% 50% 50% / 60% 60% 40% 40%',
            background: 'linear-gradient(160deg, rgba(217,119,87,0.15) 0%, rgba(217,119,87,0.05) 100%)',
            border: '1px solid rgba(255,255,255,0.12)',
            boxShadow: '0 8px 32px rgba(0,0,0,0.4)',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '16px 12px',
            gap: 10,
          }}>
            {/* LCD Screen */}
            <div style={{
              width: '100%',
              flex: 1,
              background: SCREEN_BG,
              borderRadius: 10,
              border: '1px solid rgba(255,255,255,0.08)',
              padding: '10px 12px',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 6,
              overflow: 'hidden',
              position: 'relative',
            }}>
              {/* Name + status */}
              <div style={{ display: 'flex', justifyContent: 'space-between', width: '100%', alignItems: 'center' }}>
                <span style={{ fontFamily: "'JetBrains Mono', monospace", fontSize: 10, color: ACCENT, fontWeight: 700 }}>Tom</span>
                <span style={{ fontSize: 9, color: 'rgba(255,255,255,0.3)' }}>LV 4</span>
              </div>

              {/* Level dots */}
              <div style={{ display: 'flex', gap: 3 }}>
                {Array.from({ length: 8 }).map((_, i) => (
                  <div key={i} style={{
                    width: 6, height: 6,
                    borderRadius: '50%',
                    background: i < levelDots ? ACCENT : 'rgba(255,255,255,0.1)',
                  }} />
                ))}
              </div>

              {/* Canvas */}
              <canvas
                ref={canvasRef}
                width={120}
                height={100}
                style={{ imageRendering: 'pixelated' }}
              />

              {/* Message */}
              <div style={{
                fontSize: 10,
                color: ACCENT,
                fontFamily: "'JetBrains Mono', monospace",
                height: 14,
                opacity: messageVisible ? 1 : 0,
                transition: 'opacity 0.3s',
                textAlign: 'center',
              }}>
                {message}
              </div>

              {/* Status */}
              <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                <span style={{ fontSize: 8, color: 'rgba(255,255,255,0.25)' }}>🍖 ████░</span>
                <span style={{ fontSize: 8, color: 'rgba(255,255,255,0.25)' }}>💛 ███░░</span>
              </div>
            </div>

            {/* Buttons */}
            <div style={{ display: 'flex', gap: 12 }}>
              {[
                { label: '👉', title: 'Poke', onClick: handlePoke },
                { label: '🍖', title: 'Feed', onClick: handleFeed },
                { label: '✋', title: 'Pet', onClick: handlePet },
              ].map(btn => (
                <button
                  key={btn.title}
                  title={btn.title}
                  onClick={btn.onClick}
                  style={{
                    width: 36,
                    height: 36,
                    borderRadius: '50%',
                    background: 'rgba(255,255,255,0.05)',
                    border: '1px solid rgba(255,255,255,0.1)',
                    cursor: 'pointer',
                    fontSize: 16,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    transition: 'background 0.15s',
                  }}
                  onMouseEnter={e => (e.currentTarget.style.background = 'rgba(217,119,87,0.2)')}
                  onMouseLeave={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.05)')}
                >
                  {btn.label}
                </button>
              ))}
            </div>
          </div>

          {/* Caption */}
          <p style={{ fontSize: 11, color: 'rgba(255,255,255,0.3)', margin: 0, fontFamily: 'system-ui, sans-serif', textAlign: 'center' }}>
            Try poking, feeding, or petting your crab
          </p>
        </div>
      </div>
    </div>
  )
}
