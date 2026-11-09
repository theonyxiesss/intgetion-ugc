import { HttpError, logger } from "@intgetion/kit";
import type { UgcPorts } from "../ports";

export type Endpoint = { url: string; token: string };

export type RemoteConfig = {
  /** The platform answers for users, companies, billing, notifications, audit and Telegram. */
  platform: Endpoint;
  /** Crypto checkout switch (billing flag), read once at start. */
  cryptoCheckout: boolean;
  fetchImpl?: typeof fetch;
  timeoutMs?: number;
};

/**
 * Every port goes to one platform callback, `POST /api/internal/ugc/:op`
 * with `{args}`, answering `{result}` or `{error}`. An owner's 4xx keeps its
 * status and code. Over HTTP the shared-profile write runs after the UGC
 * transaction (in-process the platform passes the transaction).
 */
export function httpUgcPorts(config: RemoteConfig): UgcPorts {
  const doFetch = config.fetchImpl ?? fetch;
  const timeoutMs = config.timeoutMs ?? 10_000;
  const base = config.platform.url.replace(/\/+$/, "");

  async function call<T>(op: string, ...args: unknown[]): Promise<T> {
    const response = await doFetch(`${base}/api/internal/ugc/${op}`, {
      method: "POST",
      headers: { authorization: `Bearer ${config.platform.token}`, "content-type": "application/json" },
      body: JSON.stringify({ args }, (_k, v) => (typeof v === "bigint" ? v.toString() : v)),
      signal: AbortSignal.timeout(timeoutMs),
    });
    const json = (await response.json().catch(() => null)) as
      | { result?: T; error?: { code: string; message: string } }
      | null;
    if (!response.ok) {
      if (response.status < 500 && json?.error) {
        throw new HttpError(response.status, json.error.code, json.error.message);
      }
      throw new Error(`ugc/${op} answered ${response.status}`);
    }
    return json?.result as T;
  }
  const port =
    <F extends (...a: never[]) => unknown>(op: string) =>
    ((...args: unknown[]) => call(op, ...args)) as unknown as F;

  return {
    users: {
      // The transaction argument stays here; it cannot cross HTTP.
      writeSharedFacts: (async (userId: string, facts: unknown, mode: unknown) =>
        call("users.write-shared-facts", userId, facts, mode)) as never,
      readAccountWallet: port("users.account-wallet"),
    },
    companies: {
      findMemberRole: port("companies.member-role"),
      listMemberUserIds: port("companies.member-ids"),
      getCompaniesForUser: port("companies.for-user"),
    },
    billing: {
      cryptoCheckoutOn: () => config.cryptoCheckout,
      isSanctionedAddress: port("billing.sanctioned"),
      verifiedPayerWallet: (async (userId: string, now?: Date) =>
        call("billing.payer-wallet", userId, (now ?? new Date()).toISOString())) as never,
    },
    notify: async (type, recipientIds, payload, options) => {
      try {
        await call("notify", type, recipientIds, payload, options ?? null);
      } catch (error) {
        logger.warn({ err: error, type }, "ugc: notice failed");
      }
    },
    audit: (entry) => call("audit", entry),
    rateLimit: (bucket, subject) => call("rate-limit", bucket, subject),
    notifyPlatformOwners: (subject, text) => call("notify-owners", subject, text),
    sendTelegramLinks: (_token, chatId, text, links) => call("telegram.send-links", chatId, text, links),
  };
}
