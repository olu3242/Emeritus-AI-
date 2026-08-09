import { defineConfig } from "vitest/config";

export default defineConfig({
  test: { include: ["tests/**/*.test.ts"], exclude:["tests/integration/**"], coverage: { reporter: ["text", "json"] } },
});
