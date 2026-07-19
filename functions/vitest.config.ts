import { defineConfig } from "vitest/config";

// The three suites share one Firestore emulator. rules.test.ts calls
// clearFirestore() between tests, which would wipe the admin-SDK suites'
// data if files ran in parallel. Force everything into a single process,
// one file at a time, so the suites never interleave.
export default defineConfig({
  test: {
    fileParallelism: false,
    pool: "forks",
    poolOptions: {
      forks: { singleFork: true },
    },
    testTimeout: 20000,
    hookTimeout: 20000,
  },
});
