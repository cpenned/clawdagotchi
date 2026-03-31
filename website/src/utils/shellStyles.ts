export interface ShellStyle {
  key: string;
  name: string;
  tintColor: string;
  tintOpacity: number;
  highlightColor: string;
  shadowColor: string;
  edgeHighlight: string;
  specularIntensity: number;
  internalsOpacity: number;
  crabColor: string;
  labelColor: string;
}

/**
 * All 6 shell styles — values mirror ShellStyle.swift exactly.
 * Order matches ShellStyle.allCases.
 */
export const SHELL_STYLES: ShellStyle[] = [
  {
    key: 'clearRetro',
    name: 'Clear Retro',
    tintColor: 'rgba(217,217,217,1)',
    tintOpacity: 0.18,
    highlightColor: 'rgba(242,242,242,1)',
    shadowColor: 'rgba(153,153,153,1)',
    edgeHighlight: '#FFFFFF',
    specularIntensity: 0.50,
    internalsOpacity: 1.0,
    crabColor: 'rgba(140,140,140,1)',
    labelColor: 'rgba(255,255,255,0.50)',
  },
  {
    key: 'salmonPink',
    name: 'Salmon',
    tintColor: 'rgba(249,107,89,1)',
    tintOpacity: 0.50,
    highlightColor: 'rgba(255,140,122,1)',
    shadowColor: 'rgba(209,71,56,1)',
    edgeHighlight: 'rgba(255,217,204,1)',
    specularIntensity: 0.35,
    internalsOpacity: 0.7,
    crabColor: 'rgba(240,143,128,1)',
    labelColor: 'rgba(255,255,255,0.40)',
  },
  {
    key: 'hotPink',
    name: 'Pink',
    tintColor: 'rgba(242,77,166,1)',
    tintOpacity: 0.48,
    highlightColor: 'rgba(255,128,192,1)',
    shadowColor: 'rgba(184,38,115,1)',
    edgeHighlight: 'rgba(255,191,224,1)',
    specularIntensity: 0.38,
    internalsOpacity: 0.65,
    crabColor: 'rgba(242,115,179,1)',
    labelColor: 'rgba(255,255,255,0.45)',
  },
  {
    key: 'iceBlue',
    name: 'Ice Blue',
    tintColor: 'rgba(77,166,249,1)',
    tintOpacity: 0.45,
    highlightColor: 'rgba(128,199,255,1)',
    shadowColor: 'rgba(38,107,199,1)',
    edgeHighlight: 'rgba(217,242,255,1)',
    specularIntensity: 0.40,
    internalsOpacity: 0.75,
    crabColor: 'rgba(128,184,242,1)',
    labelColor: 'rgba(255,255,255,0.45)',
  },
  {
    key: 'frost',
    name: 'Frost',
    tintColor: 'rgba(235,235,235,1)',
    tintOpacity: 0.60,
    highlightColor: 'rgba(250,250,250,1)',
    shadowColor: 'rgba(184,184,184,1)',
    edgeHighlight: '#FFFFFF',
    specularIntensity: 0.55,
    internalsOpacity: 0.5,
    crabColor: 'rgba(178,178,178,1)',
    labelColor: 'rgba(0,0,0,0.20)',
  },
  {
    key: 'midnight',
    name: 'Midnight',
    tintColor: 'rgba(64,64,64,1)',
    tintOpacity: 0.55,
    highlightColor: 'rgba(102,102,102,1)',
    shadowColor: 'rgba(31,31,31,1)',
    edgeHighlight: 'rgba(128,128,128,1)',
    specularIntensity: 0.20,
    internalsOpacity: 0.4,
    crabColor: 'rgba(115,89,166,1)',
    labelColor: 'rgba(255,255,255,0.20)',
  },
];
