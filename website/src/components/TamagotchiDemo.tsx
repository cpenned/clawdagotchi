import { useState, useEffect, useRef, useCallback } from 'react'

type EyeStyle = 'normal' | 'wide' | 'squish' | 'blink' | 'tiny'

// clearRetro ShellStyle values
const SHELL = {
  tintColor: 'rgba(217,217,217,1)',      // Color(white: 0.85)
  tintOpacity: 0.18,
  highlightColor: 'rgba(242,242,242,1)', // Color(white: 0.95)
  shadowColor: 'rgba(153,153,153,1)',    // Color(white: 0.60)
  edgeHighlight: '#FFFFFF',
  specularIntensity: 0.50,
  labelColor: 'rgba(255,255,255,0.50)',
  crabColor: 'rgba(140,140,140,1)',      // Color(white: 0.55) — clearRetro crabColor
}

const CRAB_COLOR = '#D97757'
const EYE_COLOR = '#1A1A1A'
const SCREEN_BG = '#1A1A1A'

// Simple Web Audio sounds matching macOS system sounds
let audioCtx: AudioContext | null = null
function getAudioCtx() {
  if (!audioCtx) audioCtx = new AudioContext()
  return audioCtx
}

function playSound(type: 'poke' | 'feed' | 'pet' | 'blink') {
  try {
    const ctx = getAudioCtx()
    const osc = ctx.createOscillator()
    const gain = ctx.createGain()
    osc.connect(gain)
    gain.connect(ctx.destination)
    gain.gain.value = 0.15

    switch (type) {
      case 'poke': // Frog-like chirp
        osc.type = 'square'
        osc.frequency.setValueAtTime(800, ctx.currentTime)
        osc.frequency.exponentialRampToValueAtTime(400, ctx.currentTime + 0.1)
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.15)
        osc.start(); osc.stop(ctx.currentTime + 0.15)
        break
      case 'feed': // Bottle pop
        osc.type = 'sine'
        osc.frequency.setValueAtTime(300, ctx.currentTime)
        osc.frequency.exponentialRampToValueAtTime(600, ctx.currentTime + 0.08)
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.12)
        osc.start(); osc.stop(ctx.currentTime + 0.12)
        break
      case 'pet': // Purr-like soft tone
        osc.type = 'sine'
        osc.frequency.setValueAtTime(200, ctx.currentTime)
        osc.frequency.setValueAtTime(220, ctx.currentTime + 0.1)
        osc.frequency.setValueAtTime(200, ctx.currentTime + 0.2)
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.3)
        osc.start(); osc.stop(ctx.currentTime + 0.3)
        break
      case 'blink': // Tiny tick
        osc.type = 'sine'
        osc.frequency.value = 1200
        gain.gain.value = 0.05
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.03)
        osc.start(); osc.stop(ctx.currentTime + 0.03)
        break
    }
  } catch {}
}

// Egg SVG path — matches Swift EggShape bezier exactly
// w=190, h=250, control points from Swift percentages
function eggPath(w: number, h: number): string {
  // move(0.50w, 0)
  // curve to (w, 0.52h) ctrl1=(0.80w,0) ctrl2=(w, 0.22h)
  // curve to (0.50w, h) ctrl1=(w, 0.82h) ctrl2=(0.82w, h)
  // curve to (0, 0.52h) ctrl1=(0.18w, h) ctrl2=(0, 0.82h)
  // curve to (0.50w, 0) ctrl1=(0, 0.22h) ctrl2=(0.20w, 0)
  const x0 = w * 0.50, y0 = 0
  const x1 = w, y1 = h * 0.52
  const x2 = w * 0.50, y2 = h
  const x3 = 0, y3 = h * 0.52
  return [
    `M ${x0} ${y0}`,
    `C ${w * 0.80} ${y0} ${x1} ${h * 0.22} ${x1} ${y1}`,
    `C ${x1} ${h * 0.82} ${w * 0.82} ${y2} ${x2} ${y2}`,
    `C ${w * 0.18} ${y2} ${x3} ${h * 0.82} ${x3} ${y3}`,
    `C ${x3} ${h * 0.22} ${w * 0.20} ${y0} ${x0} ${y0}`,
    'Z',
  ].join(' ')
}

// Build crab as SVG rects — avoids foreignObject/canvas scaling bugs on mobile
function CrabSVG({ eyeStyle, legPhase, bobY, showSunglasses, x, y, w, h }: {
  eyeStyle: EyeStyle
  legPhase: number
  bobY: number
  showSunglasses: boolean
  x: number
  y: number
  w: number
  h: number
}) {
  // Swift: viewW=86, viewH=80, crabOffsetX=10, crabOffsetY=22
  const viewW = 86, viewH = 80
  const scale = h / viewH
  const xOff = x + (w - viewW * scale) / 2 + 10 * scale
  const yOff = y + (h - viewH * scale) / 2 + 22 * scale + bobY

  const rects: { x: number; y: number; w: number; h: number; fill: string }[] = []
  function r(rx: number, ry: number, rw: number, rh: number, fill: string) {
    rects.push({ x: xOff + rx * scale, y: yOff + ry * scale, w: rw * scale, h: rh * scale, fill })
  }

  // Antennae
  r(0, 13, 6, 13, CRAB_COLOR)
  r(60, 13, 6, 13, CRAB_COLOR)

  // Legs
  const legOffsets: number[][] = [
    [3, -3, 3, -3],
    [0, 0, 0, 0],
    [-3, 3, -3, 3],
    [0, 0, 0, 0],
  ]
  const phase = legOffsets[legPhase % 4]
  const legXs = [6, 18, 42, 54]
  legXs.forEach((lx, i) => {
    r(lx, 39, 6, 13 + phase[i], CRAB_COLOR)
  })

  // Body
  r(6, 0, 54, 39, CRAB_COLOR)

  // Eyes
  const leftEyeX = 14, rightEyeX = 46, eyeY = 12
  if (eyeStyle === 'blink') {
    r(leftEyeX, eyeY + 3, 6, 2, EYE_COLOR)
    r(rightEyeX, eyeY + 3, 6, 2, EYE_COLOR)
  } else if (eyeStyle === 'wide') {
    r(leftEyeX - 1, eyeY - 1, 8, 9, EYE_COLOR)
    r(rightEyeX - 1, eyeY - 1, 8, 9, EYE_COLOR)
  } else if (eyeStyle === 'tiny') {
    r(leftEyeX + 1, eyeY + 2, 4, 4, EYE_COLOR)
    r(rightEyeX + 1, eyeY + 2, 4, 4, EYE_COLOR)
  } else if (eyeStyle !== 'squish') {
    r(leftEyeX, eyeY, 6, 7, EYE_COLOR)
    r(rightEyeX, eyeY, 6, 7, EYE_COLOR)
  }

  // Squish chevrons
  const squishLines = eyeStyle === 'squish' ? (() => {
    const lcx = xOff + (leftEyeX + 3) * scale
    const rcx = xOff + (rightEyeX + 3) * scale
    const cy = yOff + (eyeY + 3.5) * scale
    const armH = 8 * scale
    const reachW = 5 * scale
    return (
      <>
        <polyline points={`${lcx - reachW / 2},${cy - armH / 2} ${lcx + reachW / 2},${cy} ${lcx - reachW / 2},${cy + armH / 2}`} fill="none" stroke={EYE_COLOR} strokeWidth={2 * scale} strokeLinecap="round" strokeLinejoin="round" />
        <polyline points={`${rcx + reachW / 2},${cy - armH / 2} ${rcx - reachW / 2},${cy} ${rcx + reachW / 2},${cy + armH / 2}`} fill="none" stroke={EYE_COLOR} strokeWidth={2 * scale} strokeLinecap="round" strokeLinejoin="round" />
      </>
    )
  })() : null

  // Sunglasses
  const sunglasses = showSunglasses ? (
    <>
      <rect x={xOff + 11 * scale} y={yOff + 9 * scale} width={14 * scale} height={10 * scale} fill="none" stroke="#ffffff" strokeWidth={1.5 * scale} />
      <rect x={xOff + 43 * scale} y={yOff + 9 * scale} width={14 * scale} height={10 * scale} fill="none" stroke="#ffffff" strokeWidth={1.5 * scale} />
      <rect x={xOff + 25 * scale} y={yOff + 13 * scale} width={18 * scale} height={2 * scale} fill="#ffffff" />
    </>
  ) : null

  return (
    <g style={{ shapeRendering: 'crispEdges' }}>
      {rects.map((rect, i) => (
        <rect key={i} x={rect.x} y={rect.y} width={rect.w} height={rect.h} fill={rect.fill} />
      ))}
      {squishLines}
      {sunglasses}
    </g>
  )
}

// Simple SVG icons matching SF Symbols appearance
function ForkKnifeIcon() {
  return (
    <svg width="8" height="8" viewBox="0 0 10 10" fill="none">
      <line x1="2" y1="1" x2="2" y2="6" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" />
      <path d="M1 1 C1 3 3 3 3 5" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" fill="none" />
      <line x1="2" y1="6" x2="2" y2="9" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" />
      <line x1="7" y1="1" x2="7" y2="9" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" />
      <path d="M5.5 1 L5.5 4 L8.5 4 L8.5 1" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round" fill="none" />
    </svg>
  )
}

function HeartIcon() {
  return (
    <svg width="8" height="8" viewBox="0 0 10 10" fill="currentColor">
      <path d="M5 8.5 C5 8.5 1 5.5 1 3 C1 1.5 2.2 1 3.2 1 C4 1 4.7 1.4 5 2 C5.3 1.4 6 1 6.8 1 C7.8 1 9 1.5 9 3 C9 5.5 5 8.5 5 8.5Z" />
    </svg>
  )
}

export default function TamagotchiDemo() {
  const [eyeStyle, setEyeStyle] = useState<EyeStyle>('normal')
  const [bobOffset, setBobOffset] = useState(0)
  const [message, setMessage] = useState('')
  const [legPhase, setLegPhase] = useState(0)
  const [isWalking, setIsWalking] = useState(false)
  const [jumpOffset, setJumpOffset] = useState(0)
  const [messageVisible, setMessageVisible] = useState(false)
  const messageTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const animFrameRef = useRef<number>(0)
  const timeRef = useRef(0)
  const legTimerRef = useRef<ReturnType<typeof setInterval> | null>(null)

  const level = 4
  const hunger = 4
  const happiness = 3

  const showMessage = useCallback((msg: string) => {
    if (messageTimerRef.current) clearTimeout(messageTimerRef.current)
    setMessage(msg)
    setMessageVisible(true)
    messageTimerRef.current = setTimeout(() => setMessageVisible(false), 2000)
  }, [])

  // Bob animation loop
  useEffect(() => {
    let lastTime = 0
    const animate = (timestamp: number) => {
      const delta = timestamp - lastTime
      lastTime = timestamp
      timeRef.current += delta
      const bob = Math.sin(timeRef.current / 800) * 3
      setBobOffset(bob)
      animFrameRef.current = requestAnimationFrame(animate)
    }
    animFrameRef.current = requestAnimationFrame(animate)
    return () => cancelAnimationFrame(animFrameRef.current)
  }, [])

  // Leg animation — 4-phase cycle at 150ms intervals (matching Swift Timer 0.15s)
  useEffect(() => {
    if (isWalking) {
      legTimerRef.current = setInterval(() => {
        setLegPhase(prev => (prev + 1) % 4)
      }, 150)
    } else {
      if (legTimerRef.current) clearInterval(legTimerRef.current)
      setLegPhase(0)
    }
    return () => { if (legTimerRef.current) clearInterval(legTimerRef.current) }
  }, [isWalking])

  // Blink every ~3s
  useEffect(() => {
    const blinkInterval = setInterval(() => {
      setEyeStyle('blink')
      setTimeout(() => setEyeStyle('normal'), 120)
    }, 3000 + Math.random() * 1000)
    return () => clearInterval(blinkInterval)
  }, [])

  // (crab is now pure SVG — no canvas needed)

  const handlePoke = () => {
    playSound('poke')
    showMessage('hey! >_<')
    setEyeStyle('wide')
    setIsWalking(true)

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
    playSound('feed')
    showMessage('nom nom nom')
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
    playSound('pet')
    showMessage('~ happy ~')
    setEyeStyle('squish')
    setIsWalking(true)
    setTimeout(() => {
      setEyeStyle('normal')
      setIsWalking(false)
    }, 1500)
  }

  const EGG_W = 190
  const EGG_H = 250
  const SCREEN_W = 110
  const SCREEN_H = 90
  const PADDING = 50

  const eggD = eggPath(EGG_W, EGG_H)

  // Specular highlight arc — match Swift: center=(cx+15, cy+40), radius=55, 200..260deg
  // In egg SVG coords (0,0 at top-left of egg):
  const specCx = EGG_W / 2 + 15
  const specCy = EGG_H / 2 + 40
  const specR = 55
  const deg200 = (200 * Math.PI) / 180
  const deg260 = (260 * Math.PI) / 180
  const specX1 = specCx + specR * Math.cos(deg200)
  const specY1 = specCy + specR * Math.sin(deg200)
  const specX2 = specCx + specR * Math.cos(deg260)
  const specY2 = specCy + specR * Math.sin(deg260)
  // Glow arc (slightly different angles)
  const deg205 = (205 * Math.PI) / 180
  const deg255 = (255 * Math.PI) / 180
  const glowX1 = specCx + specR * Math.cos(deg205)
  const glowY1 = specCy + specR * Math.sin(deg205)
  const glowX2 = specCx + specR * Math.cos(deg255)
  const glowY2 = specCy + specR * Math.sin(deg255)

  // Screen center offset inside egg (Swift offset y: -24 from center)
  // In egg-local coords, center is (EGG_W/2, EGG_H/2), screen at offset y=-24
  const screenX = (EGG_W - SCREEN_W) / 2
  const screenY = EGG_H / 2 - SCREEN_H / 2 - 24

  // Brand label y — Swift: offset(y: -(eggHeight * 0.24)) from center
  const labelY = EGG_H / 2 - EGG_H * 0.24

  // Screw positions (Swift: dx = screenWidth/2+14, dy=screenHeight/2+12, offsetY=-24)
  const sdx = SCREEN_W / 2 + 14
  const sdy = SCREEN_H / 2 + 12
  const soy = -24
  const screws = [
    [EGG_W / 2 - sdx, EGG_H / 2 + soy - sdy],
    [EGG_W / 2 + sdx, EGG_H / 2 + soy - sdy],
    [EGG_W / 2 - sdx, EGG_H / 2 + soy + sdy],
    [EGG_W / 2 + sdx, EGG_H / 2 + soy + sdy],
  ]

  // Bezel outer (screenWidth+16 x screenHeight+14)
  const bezelOuterW = SCREEN_W + 16
  const bezelOuterH = SCREEN_H + 14
  const bezelOuterX = (EGG_W - bezelOuterW) / 2
  const bezelOuterY = EGG_H / 2 - bezelOuterH / 2 - 24

  const bezelInnerW = SCREEN_W + 8
  const bezelInnerH = SCREEN_H + 6
  const bezelInnerX = (EGG_W - bezelInnerW) / 2
  const bezelInnerY = EGG_H / 2 - bezelInnerH / 2 - 24

  // Button positions (Swift: HStack spacing=14, offset y = eggHeight/2 - 46)
  const btnY = EGG_H / 2 - 46
  const btnCenterX = EGG_W / 2
  const btnSize = 18
  const btnSpacing = 14 + btnSize
  const btnPositions = [
    btnCenterX - btnSpacing,
    btnCenterX,
    btnCenterX + btnSpacing,
  ]
  const btnActions = [handlePoke, handleFeed, handlePet]
  const btnTitles = ['Poke', 'Feed', 'Pet']

  const [hoveredBtn, setHoveredBtn] = useState<number | null>(null)
  const [pressedBtn, setPressedBtn] = useState<number | null>(null)

  return (
    <div className="flex justify-center">
      {/* macOS fake window */}
      <div style={{
        background: '#1A1A1A',
        borderRadius: 12,
        boxShadow: '0 32px 80px rgba(0,0,0,0.6), 0 0 0 1px rgba(255,255,255,0.08)',
        overflow: 'hidden',
        width: '100%',
        maxWidth: 360,
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

          {/* Egg SVG — all layers as SVG */}
          <svg
            width={EGG_W + PADDING * 2}
            height={EGG_H + PADDING * 2}
            viewBox={`${-PADDING} ${-PADDING} ${EGG_W + PADDING * 2} ${EGG_H + PADDING * 2}`}
            style={{ overflow: 'visible', display: 'block' }}
          >
            <defs>
              {/* Clip path to egg shape */}
              <clipPath id="eggClip">
                <path d={eggD} />
              </clipPath>
              <clipPath id="eggClipSmall">
                <path d={eggPath(EGG_W - 6, EGG_H - 6)} transform={`translate(3, 3)`} />
              </clipPath>

              {/* Translucent shell gradient: top-left highlight → center tint → bottom-right shadow */}
              <linearGradient id="shellGrad" x1="0" y1="0" x2="1" y2="1">
                <stop offset="0%" stopColor="#FF8C7A" stopOpacity={0.60} />
                <stop offset="50%" stopColor="#F86B59" stopOpacity={0.50} />
                <stop offset="100%" stopColor="#D14838" stopOpacity={0.55} />
              </linearGradient>

              {/* Bezel outer gradient */}
              <linearGradient id="bezelGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#2E2E2E" />
                <stop offset="100%" stopColor="#1A1A1A" />
              </linearGradient>

              {/* Bezel inner shadow */}
              <linearGradient id="bezelInnerGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="rgba(0,0,0,0.70)" />
                <stop offset="100%" stopColor="rgba(0,0,0,0.35)" />
              </linearGradient>

              {/* Screen inner top shadow */}
              <linearGradient id="screenTopShadow" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="rgba(0,0,0,0.35)" />
                <stop offset="25%" stopColor="rgba(0,0,0,0)" />
              </linearGradient>

              {/* Edge refraction gradient */}
              <linearGradient id="edgeGrad" x1="0" y1="0" x2="1" y2="1">
                <stop offset="0%" stopColor="rgba(255,255,255,0.75)" />
                <stop offset="18%" stopColor="rgba(255,255,255,0.30)" />
                <stop offset="45%" stopColor="rgba(255,255,255,0)" />
                <stop offset="72%" stopColor="rgba(255,255,255,0)" />
                <stop offset="100%" stopColor="rgba(255,217,204,0.22)" />
              </linearGradient>

              {/* Button gradient */}
              <linearGradient id="btnGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#404040" />
                <stop offset="100%" stopColor="#242424" />
              </linearGradient>
              <linearGradient id="btnGradHover" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#604040" />
                <stop offset="100%" stopColor="#3C2020" />
              </linearGradient>
              <linearGradient id="btnGradPress" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#303030" />
                <stop offset="100%" stopColor="#1A1A1A" />
              </linearGradient>
            </defs>

            {/* Layer 1: Drop shadow */}
            <path
              d={eggD}
              fill="rgba(0,0,0,0.45)"
              transform="translate(0, 8)"
              style={{ filter: 'blur(18px)' }}
            />

            {/* Layer 2: Internal cavity */}
            <path
              d={eggPath(EGG_W - 6, EGG_H - 6)}
              transform="translate(3, 3)"
              fill="#0F0F0F"
            />

            {/* Layer 3: Translucent shell */}
            <path d={eggD} fill="url(#shellGrad)" />

            {/* Layer 4: Edge refraction stroke */}
            <path
              d={eggD}
              fill="none"
              stroke="url(#edgeGrad)"
              strokeWidth="2"
            />

            {/* Layer 5: Thin white edge stroke */}
            <path
              d={eggD}
              fill="none"
              stroke="rgba(255,255,255,0.30)"
              strokeWidth="1"
            />

            {/* Layer 6: Specular highlight arc (glow behind) */}
            <path
              d={`M ${glowX1} ${glowY1} A ${specR} ${specR} 0 0 1 ${glowX2} ${glowY2}`}
              fill="none"
              stroke={`rgba(255,255,255,${0.35 * 0.2})`}
              strokeWidth="20"
              strokeLinecap="round"
            />
            {/* Main specular arc */}
            <path
              d={`M ${specX1} ${specY1} A ${specR} ${specR} 0 0 1 ${specX2} ${specY2}`}
              fill="none"
              stroke={`rgba(255,255,255,${0.35 * 0.6})`}
              strokeWidth="8"
              strokeLinecap="round"
            />

            {/* Brand label */}
            <text
              x={EGG_W / 2}
              y={labelY}
              textAnchor="middle"
              dominantBaseline="middle"
              fontSize="7"
              fontWeight="900"
              fontFamily="'JetBrains Mono', monospace"
              letterSpacing="2"
              fill={SHELL.labelColor}
              style={{ userSelect: 'none' }}
            >
              CLAWDAGOTCHI
            </text>

            {/* Screw dots */}
            {screws.map(([sx, sy], i) => (
              <g key={i}>
                <circle cx={sx} cy={sy} r={2} fill="#595959" />
                <rect x={sx - 1.5} y={sy - 0.25} width={3} height={0.5} fill="#333" />
                <rect x={sx - 0.25} y={sy - 1.5} width={0.5} height={3} fill="#333" />
              </g>
            ))}

            {/* Screen bezel outer */}
            <rect
              x={bezelOuterX}
              y={bezelOuterY}
              width={bezelOuterW}
              height={bezelOuterH}
              rx={10}
              ry={10}
              fill="url(#bezelGrad)"
            />

            {/* Screen bezel inner shadow */}
            <rect
              x={bezelInnerX}
              y={bezelInnerY}
              width={bezelInnerW}
              height={bezelInnerH}
              rx={8}
              ry={8}
              fill="url(#bezelInnerGrad)"
            />

            {/* Gasket ring */}
            <rect
              x={screenX - 1}
              y={screenY - 1}
              width={SCREEN_W + 2}
              height={SCREEN_H + 2}
              rx={6}
              ry={6}
              fill="none"
              stroke="rgba(0,0,0,0.8)"
              strokeWidth="0.5"
            />

            {/* LCD screen background */}
            <rect
              x={screenX}
              y={screenY}
              width={SCREEN_W}
              height={SCREEN_H}
              rx={5}
              ry={5}
              fill={SCREEN_BG}
            />

            {/* Screen inner top shadow */}
            <rect
              x={screenX}
              y={screenY}
              width={SCREEN_W}
              height={SCREEN_H}
              rx={5}
              ry={5}
              fill="url(#screenTopShadow)"
            />

            {/* Status bar — fork/knife + dots | name | heart + dots */}
            {/* Positioned at y: screenY + 10 (offset -(screenH/2-10) from screen center) */}
            <g transform={`translate(${screenX + 5}, ${screenY + 10})`}>
              {/* Left: food icon + 5 dots */}
              <g fill="rgba(255,255,255,0.4)">
                {/* fork/knife simple: two vertical lines */}
                <rect x={0} y={-3} width={1} height={7} />
                <rect x={2} y={-3} width={1} height={7} />
                <rect x={0} y={-3} width={3} height={2} />
              </g>
              {/* Food dots */}
              {Array.from({ length: 5 }).map((_, i) => (
                <circle
                  key={i}
                  cx={6 + i * 5}
                  cy={0}
                  r={1.5}
                  fill={i < hunger ? 'rgba(255,255,255,0.6)' : 'rgba(255,255,255,0.12)'}
                />
              ))}

              {/* Center: pet name */}
              <text
                x={SCREEN_W / 2 - 5}
                y={1}
                textAnchor="middle"
                dominantBaseline="middle"
                fontSize="5"
                fontWeight="700"
                fontFamily="'JetBrains Mono', monospace"
                fill="rgba(255,255,255,0.5)"
              >
                Claude
              </text>

              {/* Right: heart icon + 5 dots */}
              {Array.from({ length: 5 }).map((_, i) => (
                <circle
                  key={i}
                  cx={SCREEN_W - 10 - 5 - (4 - i) * 5}
                  cy={0}
                  r={1.5}
                  fill={i < happiness ? 'rgba(255,255,255,0.6)' : 'rgba(255,255,255,0.12)'}
                />
              ))}
              {/* Heart icon (simple) */}
              <path
                d={`M ${SCREEN_W - 10} -2.5 C${SCREEN_W - 10} -4 ${SCREEN_W - 8} -4 ${SCREEN_W - 9} -2.5 C${SCREEN_W - 9} -4 ${SCREEN_W - 7} -4 ${SCREEN_W - 7} -2.5 C${SCREEN_W - 7} 0 ${SCREEN_W - 9} 2 ${SCREEN_W - 9} 2 C${SCREEN_W - 9} 2 ${SCREEN_W - 10} 1 ${SCREEN_W - 10} -2.5Z`}
                fill="rgba(255,255,255,0.4)"
              />
            </g>

            {/* Level dots — at y: screenY + 19 */}
            <g transform={`translate(${screenX + SCREEN_W / 2 - 18}, ${screenY + 19})`}>
              {Array.from({ length: 8 }).map((_, i) => (
                <circle
                  key={i}
                  cx={i * 5}
                  cy={0}
                  r={1.5}
                  fill={i < level ? 'rgba(255,255,255,0.3)' : 'rgba(255,255,255,0.06)'}
                />
              ))}
            </g>

            {/* XP progress bar — bottom of screen */}
            <rect
              x={screenX}
              y={screenY + SCREEN_H - 1}
              width={SCREEN_W * (level / 8)}
              height={1}
              fill={`${CRAB_COLOR}80`}
            />

            {/* Status text "~" at bottom of screen */}
            <text
              x={screenX + SCREEN_W / 2}
              y={screenY + SCREEN_H - 12}
              textAnchor="middle"
              dominantBaseline="middle"
              fontSize="7"
              fontFamily="'JetBrains Mono', monospace"
              fill="rgba(255,255,255,0.20)"
            >
              {messageVisible ? message : '~'}
            </text>

            {/* Crab — pure SVG rects (no foreignObject/canvas for mobile compat) */}
            <CrabSVG
              eyeStyle={eyeStyle}
              legPhase={legPhase}
              bobY={bobOffset + jumpOffset}
              showSunglasses={true}
              x={screenX}
              y={screenY + 20}
              w={SCREEN_W}
              h={SCREEN_H - 35}
            />

            {/* Buttons */}
            {btnPositions.map((bx, i) => {
              const isHovered = hoveredBtn === i
              const isPressed = pressedBtn === i
              const isCenter = i === 1
              const by = EGG_H / 2 + btnY + (isCenter ? 3 : 0)
              const gradId = isPressed ? 'btnGradPress' : isHovered ? 'btnGradHover' : 'btnGrad'
              return (
                <g
                  key={i}
                  style={{ cursor: 'pointer' }}
                  onClick={btnActions[i]}
                  onMouseEnter={() => setHoveredBtn(i)}
                  onMouseLeave={() => { setHoveredBtn(null); setPressedBtn(null) }}
                  onMouseDown={() => setPressedBtn(i)}
                  onMouseUp={() => setPressedBtn(null)}
                >
                  {/* Button title for accessibility */}
                  <title>{btnTitles[i]}</title>

                  {/* Metallic contact pad */}
                  <circle cx={bx} cy={by} r={11} fill="rgba(180,180,180,0.15)" />

                  {/* Drop shadow */}
                  <circle cx={bx} cy={by + 2} r={9.5} fill="rgba(0,0,0,0.5)" style={{ filter: 'blur(3px)' }} />

                  {/* Button body */}
                  <defs>
                    <linearGradient id={`btnG${i}`} x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor={isPressed ? '#303030' : isHovered ? '#604848' : '#404040'} />
                      <stop offset="100%" stopColor={isPressed ? '#1A1A1A' : isHovered ? '#3C2828' : '#242424'} />
                    </linearGradient>
                  </defs>
                  <circle cx={bx} cy={by} r={9} fill={`url(#btnG${i})`} />

                  {/* Hover glow */}
                  {isHovered && (
                    <circle cx={bx} cy={by} r={9} fill="rgba(249,107,89,0.25)" />
                  )}

                  {/* Top highlight */}
                  <path
                    d={`M ${bx - 6} ${by - 2} A 9 9 0 0 1 ${bx + 6} ${by - 2}`}
                    fill="none"
                    stroke="rgba(255,255,255,0.15)"
                    strokeWidth="1.5"
                    strokeLinecap="round"
                  />
                </g>
              )
            })}
          </svg>

          {/* Caption */}
          <p style={{ fontSize: 11, color: 'rgba(255,255,255,0.3)', margin: 0, fontFamily: 'system-ui, sans-serif', textAlign: 'center' }}>
            Click to poke, feed, or pet your crab
          </p>
        </div>
      </div>
    </div>
  )
}
