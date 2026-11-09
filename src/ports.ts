/**
 * What UGC needs from other modules and the platform. Types are the owners'
 * own signatures from their packages. In-process the platform wires the real
 * functions; over HTTP see `server/remote-ports.ts`.
 */
import type * as Users from "@intgetion/users";
import type * as Companies from "@intgetion/companies";
import type * as Billing from "@intgetion/billing";

export type AuditEntry = {
  actorId: string | null;
  action: string;
  entityType: string;
  entityId?: string | null;
  diff?: unknown;
  ip?: string | null;
};

export type UgcPorts = {
  users: {
    /** Called inside the UGC transaction; an in-process adapter writes with `tx`. */
    writeSharedFacts: typeof Users.writeSharedFacts;
    readAccountWallet: typeof Users.readAccountWallet;
  };
  companies: {
    findMemberRole: typeof Companies.findMemberRole;
    listMemberUserIds: typeof Companies.listMemberUserIds;
    getCompaniesForUser: typeof Companies.getCompaniesForUser;
  };
  billing: {
    cryptoCheckoutOn: typeof Billing.cryptoCheckoutOn;
    isSanctionedAddress: typeof Billing.isSanctionedAddress;
    verifiedPayerWallet: typeof Billing.verifiedPayerWallet;
  };
  /** notifications: failures are logged, never thrown. */
  notify: (
    type: string,
    recipientIds: readonly string[],
    payload: unknown,
    options?: { email?: boolean },
  ) => Promise<void>;
  /** platform */
  audit: (entry: AuditEntry) => Promise<void>;
  /** Throws a 429 HttpError when over the limit. */
  rateLimit: (bucket: string, subject: string) => Promise<void>;
  notifyPlatformOwners: (subject: string, text: string) => Promise<void>;
  /** auth: the Telegram bot holds the token. */
  sendTelegramLinks: (token: string, chatId: number, text: string, links: { label: string; url: string }[]) => Promise<void>;
};

let ports: UgcPorts | null = null;

export function setUgcPorts(next: UgcPorts): void {
  ports = next;
}

export function ugcPorts(): UgcPorts {
  if (!ports) throw new Error("ugc ports are not configured");
  return ports;
}
