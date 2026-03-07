import { defineConfig } from "vitest/config"

export default defineConfig({
  test: {
    name: "@atlas/shared",
    environment: "node",
    globals: true,
    include: ["src/**/__tests__/**/*.test.ts"],
    coverage: {
      provider: "v8",
      reporter: ["text", "json-summary", "lcov"],
    },
  },
})
