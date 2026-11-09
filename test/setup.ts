import { beforeAll } from "vitest";

// Every test file starts with harmless ports. Loaded in beforeAll, after the
// file's own vi.mock calls, so no module is loaded here ahead of its mocks.
beforeAll(async () => {
  const support = await import("../src/test-support");
  support.useTestPorts();
});
