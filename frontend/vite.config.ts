import type { UserConfig } from "vite";

export default {
  root: "src",
  build: {
    outDir: "../dist",
  },
  server: {
    allowedHosts: ["myproject-dev.local"],
    port: 8001,
    strictPort: true,
  },
} satisfies UserConfig;
