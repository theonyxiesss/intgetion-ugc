import { describe, expect, it, vi } from "vitest";
import { createApp } from "./app";
import { httpUgcPorts } from "./remote-ports";

const token = "test-token";
const app = createApp({ serviceToken: token });
const user = "11111111-1111-4111-8111-111111111111";
const auth = { authorization: `Bearer ${token}` };
const call = (path: string, init: RequestInit = {}) => app(new Request(`http://ugc${path}`, init));

describe("ugc http", () => {
  it("serves health without a token and refuses a missing one", async () => {
    expect((await call("/health")).status).toBe(200);
    expect((await call("/v1/campaigns")).status).toBe(401);
  });
  it("needs the person and a known command", async () => {
    expect((await call("/v1/commands", { method: "POST", headers: auth, body: "{}" })).status).toBe(401);
    const headers = { ...auth, "x-user-id": user };
    const bad = await call("/v1/commands", { method: "POST", headers, body: JSON.stringify({ action: "steal" }) });
    expect(bad.status).toBe(400);
    expect((await call("/v1/commands", { method: "POST", headers, body: "{bad" })).status).toBe(400);
  });
  it("keeps admin queues for admins and answers 404 for bad ids and routes", async () => {
    const headers = { ...auth, "x-user-id": user };
    expect((await call("/v1/admin/review", { headers })).status).toBe(404);
    expect((await call("/v1/campaigns/nope", { headers })).status).toBe(404);
    expect((await call("/v1/telegram/start", { method: "POST", headers: auth, body: "{}" })).status).toBe(503);
    expect((await call("/v1/nothing", { headers: auth })).status).toBe(404);
  });
});

describe("remote ports", () => {
  it("sends args, keeps an owner's 4xx and swallows notice failures", async () => {
    const fetchImpl = vi.fn(async (url: string | URL | Request, init?: RequestInit) => {
      const op = String(url).split("/").pop();
      const { args } = JSON.parse(String(init?.body)) as { args: unknown[] };
      if (op === "companies.member-role") return Response.json({ result: args[1] === user ? "owner" : null });
      if (op === "rate-limit") return Response.json({ error: { code: "RATE_LIMITED", message: "slow" } }, { status: 429 });
      return new Response("down", { status: 503 });
    });
    const ports = httpUgcPorts({
      platform: { url: "http://p/", token: "t" },
      cryptoCheckout: true,
      fetchImpl: fetchImpl as typeof fetch,
    });
    expect(await ports.companies.findMemberRole("c", user)).toBe("owner");
    expect(String(fetchImpl.mock.calls[0]?.[0])).toBe("http://p/api/internal/ugc/companies.member-role");
    await expect(ports.rateLimit("report", user)).rejects.toMatchObject({ status: 429 });
    await expect(ports.audit({ actorId: user, action: "a", entityType: "x" })).rejects.toThrow("503");
    await expect(ports.notify("x", [user], {})).resolves.toBeUndefined();
    expect(ports.billing.cryptoCheckoutOn()).toBe(true);
  });
});
