/**
 * Returns the SVG path data for the egg shape used by TamagotchiView.
 * Bezier curves match the Swift EggShape implementation exactly.
 */
export function eggPath(w: number, h: number): string {
  const x0 = w * 0.5, y0 = 0;
  const x1 = w,       y1 = h * 0.52;
  const x2 = w * 0.5, y2 = h;
  const x3 = 0,       y3 = h * 0.52;
  return [
    `M ${x0} ${y0}`,
    `C ${w * 0.8} ${y0} ${x1} ${h * 0.22} ${x1} ${y1}`,
    `C ${x1} ${h * 0.82} ${w * 0.82} ${y2} ${x2} ${y2}`,
    `C ${w * 0.18} ${y2} ${x3} ${h * 0.82} ${x3} ${y3}`,
    `C ${x3} ${h * 0.22} ${w * 0.2} ${y0} ${x0} ${y0}`,
    'Z',
  ].join(' ');
}
