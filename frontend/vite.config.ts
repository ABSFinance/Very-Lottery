import react from "@vitejs/plugin-react";
import tailwind from "tailwindcss";
import { defineConfig } from "vite";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  base: "./",
  css: {
    postcss: {
      plugins: [tailwind()],
    },
  },
  define: {
    global: 'globalThis',
    // 환경 변수를 브라우저에 주입
    'process.env': process.env,
  },
  resolve: {
    alias: {
      // 필요한 폴리필들
      crypto: 'crypto-browserify',
      buffer: 'buffer',
      util: 'util',
    },
  },
  optimizeDeps: {
    esbuildOptions: {
      define: {
        global: 'globalThis',
      },
    },
    include: [
      'buffer',
      'crypto-browserify',
      'util',
    ],
  },
  build: {
    rollupOptions: {
      external: [],
    },
  },
  server: {
    headers: {
      'Cross-Origin-Opener-Policy': 'unsafe-none',
      'Cross-Origin-Embedder-Policy': 'unsafe-none',
      'Cross-Origin-Resource-Policy': 'cross-origin'
    },
    cors: true
  }
})
