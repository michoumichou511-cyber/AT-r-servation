/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      spacing: {
        '18': '4.5rem',
        '22': '5.5rem',
      },
      boxShadow: {
        'at-card': '0 8px 24px rgba(0, 61, 165, 0.08)',
        'at-card-lg': '0 20px 40px rgba(0, 61, 165, 0.12)',
        'at-elevated': '0 4px 14px rgba(26, 29, 38, 0.08)',
        'at-glow-green': '0 0 20px rgba(0, 166, 80, 0.15), 0 8px 32px rgba(0, 166, 80, 0.1)',
        'at-glow-blue': '0 0 20px rgba(0, 61, 165, 0.15), 0 8px 32px rgba(0, 61, 165, 0.1)',
        'at-inset': 'inset 0 2px 4px rgba(0, 0, 0, 0.04)',
        'at-soft': '0 1px 3px rgba(0, 0, 0, 0.04), 0 4px 12px rgba(0, 0, 0, 0.03)',
      },
      colors: {
        'at-green':       '#00A650',
        'at-green-dark':  '#007A3A',
        'at-green-light': '#E6F7EE',
        'at-blue':        '#003DA5',
        'at-blue-dark':   '#002580',
        'at-blue-light':  '#E6EDF8',
        'at-surface':     '#F8FAFB',
        'at-surface-dark':'#141727',
      },
      fontFamily: {
        sans: ['IBM Plex Sans', 'sans-serif'],
        mono: ['IBM Plex Mono', 'monospace'],
      },
      borderRadius: {
        'at': '16px',
        'at-lg': '20px',
        'at-xl': '24px',
      },
      transitionTimingFunction: {
        'at-spring': 'cubic-bezier(0.34, 1.56, 0.64, 1)',
        'at-smooth': 'cubic-bezier(0.25, 0.1, 0.25, 1)',
      },
      keyframes: {
        'at-fade-up': {
          '0%': { opacity: '0', transform: 'translateY(8px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        'at-scale-in': {
          '0%': { opacity: '0', transform: 'scale(0.95)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
        'at-slide-in-right': {
          '0%': { opacity: '0', transform: 'translateX(12px)' },
          '100%': { opacity: '1', transform: 'translateX(0)' },
        },
        'at-count-up': {
          '0%': { opacity: '0', transform: 'translateY(10px) scale(0.9)' },
          '60%': { transform: 'translateY(-2px) scale(1.02)' },
          '100%': { opacity: '1', transform: 'translateY(0) scale(1)' },
        },
      },
      animation: {
        'at-fade-up': 'at-fade-up 0.4s ease-out forwards',
        'at-scale-in': 'at-scale-in 0.3s ease-out forwards',
        'at-slide-in-right': 'at-slide-in-right 0.35s ease-out forwards',
        'at-count-up': 'at-count-up 0.5s ease-out forwards',
      },
    },
  },
  plugins: [],
}
