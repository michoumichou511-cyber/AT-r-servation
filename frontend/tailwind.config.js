/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        'at-green':       '#00A650',
        'at-green-dark':  '#007A3A',
        'at-green-light': '#E6F7EE',
        'at-blue':        '#003DA5',
        'at-blue-dark':   '#002580',
        'at-blue-light':  '#E6EDF8',
      },
      fontFamily: {
        sans: ['IBM Plex Sans', 'sans-serif'],
        mono: ['IBM Plex Mono', 'monospace'],
      },
    },
  },
  plugins: [],
}
