import type { Plugin } from "vite"
import { defineConfig } from "vitest/config"

function resolveRelativeJavaScriptImports(): Plugin {
  return {
    name: "atlas-backend-relative-js-imports",
    enforce: "pre",
    async resolveId(source, importer, options) {
      if (!importer || !source.startsWith(".") || !source.endsWith(".js")) {
        return null
      }

      const resolved = await this.resolve(
        `${source.slice(0, -3)}.ts`,
        importer,
        {
          ...options,
          skipSelf: true,
        }
      )

      return resolved ?? null
    },
  }
}

export default defineConfig({
  plugins: [resolveRelativeJavaScriptImports()],
  resolve: {
    conditions: ["bun", "import", "module", "default"],
  },
  test: {
    name: "@atlas/backend",
    environment: "node",
    globals: true,
    setupFiles: ["./src/test/setup.ts"],
    include: ["src/**/__tests__/**/*.test.ts"],
    coverage: {
      provider: "v8",
      reporter: ["text", "json-summary", "lcov"],
    },
  },
})
