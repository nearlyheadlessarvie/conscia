export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      colors: {
        primary: { DEFAULT: '#1A237E', light: '#C5CAE9', dark: '#0D1547' },
        secondary: { DEFAULT: '#FFB300', light: '#FFE082', dark: '#FF8F00' },
        devil: { DEFAULT: '#E65100', light: '#FFF8E1', accent: '#FF6D00' },
        angel: { DEFAULT: '#00838F', light: '#E0F7FA', accent: '#00BCD4' },
        income: '#4CAF50',
        expense: '#E53935',
      },
      fontFamily: {
        heading: ['Poppins', 'sans-serif'],
        body: ['Inter', 'sans-serif'],
      },
      borderRadius: {
        card: '16px',
        pill: '24px',
      },
    },
  },
  plugins: [],
};
