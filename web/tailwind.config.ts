import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        primary: { DEFAULT: '#A8442C', dark: '#8B3623' },
        charcoal: '#2B2D3D',
        accent: '#E8A33D',
        surface: '#FFFFFF',
        'surface-tint': '#FBEEE8',
        scaffold: '#FCFAF8',
        'text-muted': '#6B6F7A',
        success: '#2E7D52',
        error: '#C0392B',
        warning: '#E8A33D',
        border: '#E7E5E2',
      },
      fontFamily: {
        heading: ['Lora', 'serif'],
        body: ['Inter', 'sans-serif'],
      },
      borderRadius: {
        card: '12px',
        pill: '24px',
      },
    },
  },
  plugins: [],
};

export default config;
