import { defineConfig } from 'vite'
import { viteSingleFile } from 'vite-plugin-singlefile'

// One self-contained dist/index.html (JS, CSS and fonts inlined) so the deck
// opens from a USB stick or a classroom PC without internet.
export default defineConfig({
  base: './',
  plugins: [viteSingleFile()],
  build: {
    target: 'es2022',
    assetsInlineLimit: 100_000_000,
    cssCodeSplit: false,
    chunkSizeWarningLimit: 4000,
  },
  server: { port: 5178, strictPort: true },
  preview: { port: 5179, strictPort: true },
})
