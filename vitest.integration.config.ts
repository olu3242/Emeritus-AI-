import { defineConfig } from "vitest/config";
import IntegrationSequencer from"./tests/integration/sequencer";
export default defineConfig({test:{include:["tests/integration/**/*.test.ts"],testTimeout:30000,hookTimeout:30000,pool:"forks",poolOptions:{forks:{singleFork:true}},sequence:{sequencer:IntegrationSequencer}}});
