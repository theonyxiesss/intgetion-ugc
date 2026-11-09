import { z, ZodError } from "zod";
import { HttpError, httpErrorResponse, notFound, reportError, validationError } from "@intgetion/kit";
import * as ugc from "../modules/ugc/service";
import { ugcPorts } from "../ports";
import { isUuid, requireServiceToken } from "./auth";
import { runUgcCommand, type UgcActor } from "./commands";

export type AppConfig = {
  serviceToken: string;
  /** Telegram bot token for the `/start` deep link; absent turns it off. */
  telegramToken?: string;
};

const MAX_JSON = 64 * 1024;

const draftPatch = z
  .object({
    draftId: z.uuid().optional(),
    companyId: z.uuid().optional(),
    patch: z.record(z.string(), z.unknown()),
    assumptions: z.array(z.string().max(300)).max(20).optional(),
  })
  .strict();
const draftAction = z.discriminatedUnion("action", [
  z.object({ action: z.literal("confirm"), draftId: z.uuid().optional() }).strict(),
  z.object({ action: z.literal("reset"), draftId: z.uuid().optional() }).strict(),
]);
const confirmBody = z.object({ txHash: z.string().max(100).optional() });

async function readBody(request: Request): Promise<unknown> {
  const text = await request.text();
  if (text.length > MAX_JSON) throw new HttpError(413, "PAYLOAD_TOO_LARGE", "Body too large");
  try {
    return text ? JSON.parse(text) : {};
  } catch {
    throw validationError([{ path: [], message: "invalid_json" }]);
  }
}
const parsed = async <T>(request: Request, schema: z.ZodType<T>) => schema.parse(await readBody(request));

/** The platform signs the person in; `x-user-role: admin` marks a platform admin. */
function actor(request: Request): UgcActor {
  const id = request.headers.get("x-user-id");
  if (!id) throw new HttpError(401, "UNAUTHENTICATED", "Sign in first");
  if (!isUuid(id)) throw validationError({ header: "x-user-id" });
  return { id, platformRole: request.headers.get("x-user-role") === "admin" ? "admin" : "user" };
}
const isAdmin = (request: Request) => actor(request).platformRole === "admin";

function id(value: string | undefined): string {
  if (!value || !isUuid(value)) throw notFound();
  return value;
}

/** bigint money values travel as strings, as on the platform. */
function json(body: unknown, status = 200): Response {
  return new Response(
    JSON.stringify(body, (_key, value) => (typeof value === "bigint" ? value.toString() : value)),
    { status, headers: { "content-type": "application/json", "cache-control": "no-store" } },
  );
}

type Route = {
  method: string;
  pattern: RegExp;
  run: (request: Request, params: string[], url: URL, config: AppConfig) => Promise<Response>;
};

const routes: Route[] = [
  // Every write, one command per call (as `POST /api/ugc`).
  {
    method: "POST",
    pattern: /^\/v1\/commands$/,
    run: async (request) => {
      const who = actor(request);
      return json(await runUgcCommand(who, await readBody(request)));
    },
  },
  // Brief drafts (D492).
  {
    method: "GET",
    pattern: /^\/v1\/brief-draft$/,
    run: async (request, _p, url) =>
      json(await ugc.readBriefDraft(actor(request).id, url.searchParams.get("id") ?? undefined)),
  },
  {
    method: "PATCH",
    pattern: /^\/v1\/brief-draft$/,
    run: async (request) => {
      const who = actor(request);
      return json(await ugc.patchBriefDraft(who.id, await parsed(request, draftPatch)));
    },
  },
  {
    method: "POST",
    pattern: /^\/v1\/brief-draft$/,
    run: async (request) => {
      const who = actor(request);
      const input = await parsed(request, draftAction);
      return input.action === "reset"
        ? json(await ugc.resetBriefDraft(who.id, input.draftId))
        : json(await ugc.confirmBriefDraft(who.id, input.draftId), 201);
    },
  },
  // Budget deposits (D466); the platform applied the billing rate limits before.
  {
    method: "POST",
    pattern: /^\/v1\/campaigns\/([^/]+)\/deposit$/,
    run: async (request, [campaignId]) => {
      const who = actor(request);
      await ugcPorts().rateLimit("billingOrder", who.id);
      return json(await ugc.createCampaignDeposit(who.id, id(campaignId), await readBody(request)));
    },
  },
  {
    method: "GET",
    pattern: /^\/v1\/deposits\/([^/]+)$/,
    run: async (request, [depositId]) => json(await ugc.refreshCampaignDeposit(actor(request).id, id(depositId))),
  },
  {
    method: "POST",
    pattern: /^\/v1\/deposits\/([^/]+)\/confirm$/,
    run: async (request, [depositId]) => {
      const who = actor(request);
      const body = await parsed(request, confirmBody);
      await ugcPorts().rateLimit("billingConfirm", who.id);
      return json(await ugc.confirmCampaignDeposit(who.id, id(depositId), body.txHash));
    },
  },
  // Reads for the pages.
  {
    method: "GET",
    pattern: /^\/v1\/campaigns$/,
    run: async (request) => json({ items: await ugc.listMyCampaigns(actor(request).id) }),
  },
  {
    method: "GET",
    pattern: /^\/v1\/campaigns\/open$/,
    run: async (request) => json({ items: await ugc.listOpenCampaigns(actor(request).id) }),
  },
  {
    method: "GET",
    pattern: /^\/v1\/campaigns\/([^/]+)$/,
    run: async (request, [campaignId]) => json(await ugc.readCampaign(actor(request).id, id(campaignId))),
  },
  {
    method: "GET",
    pattern: /^\/v1\/invites$/,
    run: async (request) => json({ items: await ugc.listMyInvites(actor(request).id) }),
  },
  {
    method: "GET",
    pattern: /^\/v1\/workspace$/,
    run: async (request) => json(await ugc.getCreatorWorkspace(actor(request).id)),
  },
  {
    method: "GET",
    pattern: /^\/v1\/creator-profile$/,
    run: async (request) => json({ profile: await ugc.getOwnCreatorProfile(actor(request).id) }),
  },
  {
    method: "GET",
    pattern: /^\/v1\/rooms\/([^/]+)$/,
    run: async (request, [inviteId]) => json(await ugc.getUgcRoom(actor(request).id, id(inviteId))),
  },
  {
    method: "POST",
    pattern: /^\/v1\/rooms\/([^/]+)\/read$/,
    run: async (request, [inviteId]) => json(await ugc.markUgcRoomRead(actor(request).id, id(inviteId))),
  },
  {
    method: "GET",
    pattern: /^\/v1\/price-guide$/,
    run: async (_request, _p, url) =>
      json(
        await ugc.ugcPriceGuide({
          niche: url.searchParams.get("niche") ?? undefined,
          platform: url.searchParams.get("platform") ?? undefined,
        }),
      ),
  },
  // Admin queues (the platform passes the role).
  {
    method: "GET",
    pattern: /^\/v1\/admin\/(review|disputes|room-reports|payouts)$/,
    run: async (request, [queue]) => {
      const admin = isAdmin(request);
      const items =
        queue === "review"
          ? await ugc.listReviewQueue(admin)
          : queue === "disputes"
            ? await ugc.listDisputeQueue(admin)
            : queue === "room-reports"
              ? await ugc.listRoomReportQueue(admin)
              : await ugc.listOwedPayouts(admin);
      return json({ items });
    },
  },
  // Telegram `/start` for a creative test (the platform's webhook hands it over).
  {
    method: "POST",
    pattern: /^\/v1\/telegram\/start$/,
    run: async (request, _p, _u, config) => {
      if (!config.telegramToken) throw new HttpError(503, "TELEGRAM_OFF", "Telegram is not configured");
      return json({ handled: await ugc.handleUgcTelegramStart(config.telegramToken, await readBody(request)) });
    },
  },
  // Cron: deadlines, deposit rechecks, the room sweep.
  {
    method: "POST",
    pattern: /^\/v1\/tasks\/run$/,
    run: async () =>
      json({
        deadlines: await ugc.noteDeadlines(),
        deposits: await ugc.recheckCampaignDeposits(),
        rooms: await ugc.sweepRoomMessages(),
      }),
  },
];

export function toResponse(error: unknown): Response {
  if (error instanceof HttpError) return httpErrorResponse(error);
  if (error instanceof ZodError) return httpErrorResponse(validationError(error.issues));
  reportError(error, "ugc-service");
  return Response.json({ error: { code: "INTERNAL", message: "Internal error" } }, { status: 500 });
}

export function createApp(config: AppConfig) {
  return async function handle(request: Request): Promise<Response> {
    const url = new URL(request.url);
    try {
      if (request.method === "GET" && url.pathname === "/health") return Response.json({ ok: true });
      requireServiceToken(request, config.serviceToken);
      for (const route of routes) {
        if (route.method !== request.method) continue;
        const match = route.pattern.exec(url.pathname);
        if (!match) continue;
        return await route.run(request, match.slice(1), url, config);
      }
      throw notFound();
    } catch (error) {
      return toResponse(error);
    }
  };
}
