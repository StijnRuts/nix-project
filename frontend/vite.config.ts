import type { UserConfig } from "vite";
import { ViteFaviconsPlugin } from 'vite-plugin-favicon';
import vituum from 'vituum';
import nunjucks from "@vituum/vite-plugin-nunjucks";

export default {
  build: {
    rollupOptions: {
      input: ['src/pages/**/*.njk']
    },
  },
  server: {
    allowedHosts: ["myproject-dev.local"],
    port: 8001,
    strictPort: true,
  },
  plugins: [
    vituum(),
    nunjucks({
      root: './src',
    }),
    ViteFaviconsPlugin({
      logo: "./src/assets/favicon.svg",
      favicons: {
        appName: "My Project",
        appShortName: "My Project",
        appDescription: "My new website project",
        lang: "en",
        developerName: null,
        developerURL: null,
        background: "#3B88C3",
        theme_color: "#FFF",
        icons: {
          favicons: true,
          android: false,
          appleIcon: false,
          appleStartup: false,
          windows: false,
        },
      },
    }),
  ],
} satisfies UserConfig;
