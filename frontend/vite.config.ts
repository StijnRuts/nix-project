import type { UserConfig } from "vite";
import unpluginFavicons from "@anolilab/unplugin-favicons/vite";
import nunjucks from "@vituum/vite-plugin-nunjucks";

import fs from "fs/promises";
import path from "path";

export default {
  root: "src",
  build: {
    outDir: "../dist",
    emptyOutDir: true,
    rollupOptions: {
      input: ["index.njk.html", "error.njk"],
    },
  },
  plugins: [
    unpluginFavicons({
      logo: "./src/favicon.svg",
      outputPath: "assets/favicons",
      favicons: {
        path: "/assets/favicons",
        appName: "My Project",
        appShortName: "My Project",
        appDescription: "My new project",
        lang: "en",
        developerName: null,
        developerURL: null,
        background: "#ddd",
        theme_color: "#333",
        icons: {
          favicons: true,
          android: true,
          appleIcon: true,
          appleStartup: false,
          windows: false,
          yandex: false,
        },
      },
    }),
    nunjucks(),
    {
      name: "rename-njk-html",
      closeBundle: async () => {
        const dist = path.resolve("dist");
        const files = await fs.readdir(dist);

        for (const file of files) {
          if (file.endsWith(".njk.html")) {
            const newName = file.replace(".njk.html", ".html");
            await fs.rename(path.join(dist, file), path.join(dist, newName));
          }
        }
      },
    },
  ],
  server: {
    allowedHosts: ["myproject-dev.local"],
    port: 8001,
    strictPort: true,
  },
} satisfies UserConfig;
