import viteConfig from "./vite.config"
import { defineConfig, mergeConfig } from "vitest/config"

export default mergeConfig(
  viteConfig,
  defineConfig({
    test: {
      name: "@atlas/frontend",
      environment: "jsdom",
      globals: true,
      css: true,
      setupFiles: ["./src/test/setup.ts"],
      include: ["src/**/__tests__/**/*.test.tsx"],
      coverage: {
        provider: "v8",
        reporter: ["text", "json-summary", "lcov"],
      },
    },
  })
)
