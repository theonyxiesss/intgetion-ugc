import { pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";
import { writeSharedFacts as realSharedFacts } from "@intgetion/users";
import { setUgcPorts, type AuditEntry, type UgcPorts } from "./ports";

export type TestWorld = {
  ports: UgcPorts;
  notices: { type: string; to: readonly string[]; payload: unknown }[];
  audit: AuditEntry[];
  ownerMail: { subject: string; text: string }[];
  /** company id → member user id → role */
  members: Map<string, Map<string, string>>;
  companyNames: Map<string, string>;
  payoutWallets: Map<string, string>;
  payerWallets: Map<string, { address: string; chainId: number }>;
  sanctioned: Set<string>;
  sharedFacts: { userId: string; facts: unknown; mode: unknown }[];
};

/**
 * Harmless ports for tests: no companies, no wallets, the checkout switch
 * read from env as billing does. Tests add members, wallets and sanctions.
 */
export function useTestPorts(overrides: Partial<UgcPorts> = {}): TestWorld {
  const world: Omit<TestWorld, "ports"> = {
    notices: [],
    audit: [],
    ownerMail: [],
    members: new Map(),
    companyNames: new Map(),
    payoutWallets: new Map(),
    payerWallets: new Map(),
    sanctioned: new Set(),
    sharedFacts: [],
  };
  const ports: UgcPorts = {
    users: {
      writeSharedFacts: (async (userId: string, facts: unknown, mode: unknown) => {
        world.sharedFacts.push({ userId, facts, mode });
      }) as never,
      readAccountWallet: (async (userId: string) => {
        const address = world.payoutWallets.get(userId);
        return address ? { address, chainId: 8453, verifiedAt: "2030-01-01T00:00:00Z" } : null;
      }) as never,
    },
    companies: {
      findMemberRole: (async (companyId: string, userId: string) =>
        world.members.get(companyId)?.get(userId) ?? null) as never,
      listMemberUserIds: (async (companyId: string) => [...(world.members.get(companyId)?.keys() ?? [])]) as never,
      getCompaniesForUser: (async (userId: string) =>
        [...world.members.entries()]
          .filter(([, members]) => members.has(userId))
          .map(([id]) => ({ id, name: world.companyNames.get(id) ?? "Company" }))) as never,
    },
    billing: {
      cryptoCheckoutOn: () =>
        process.env.BILLING_ENABLED === "true" && process.env.BILLING_CRYPTO_PROVIDER === "walletconnect",
      isSanctionedAddress: (async (address: string) => world.sanctioned.has(address.toLowerCase())) as never,
      verifiedPayerWallet: (async (userId: string) => world.payerWallets.get(userId) ?? null) as never,
    },
    notify: async (type, to, payload) => {
      world.notices.push({ type, to, payload });
    },
    audit: async (entry) => {
      world.audit.push(entry);
    },
    rateLimit: async () => {},
    notifyPlatformOwners: async (subject, text) => {
      world.ownerMail.push({ subject, text });
    },
    sendTelegramLinks: async () => {},
    ...overrides,
  };
  setUgcPorts(ports);
  return { ...world, ports };
}

export function addMember(world: TestWorld, companyId: string, userId: string, role = "owner", name = "Company") {
  if (!world.members.has(companyId)) world.members.set(companyId, new Map());
  world.members.get(companyId)!.set(userId, role);
  world.companyNames.set(companyId, name);
}

/** The platform users table, as tests insert into it (test stub columns). */
export const users = pgTable("users", {
  id: uuid("id").primaryKey().defaultRandom(),
  authUid: uuid("auth_uid"),
  locale: text("locale").notNull().default("en"),
  status: text("status").notNull().default("active"),
  platformRole: text("platform_role").notNull().default("user"),
  termsAcceptedAt: timestamp("terms_accepted_at", { withTimezone: true }),
  termsVersion: text("terms_version"),
});

/**
 * For integration tests: the users module writes country and languages to
 * user_profiles in the same database, as it will on the platform.
 */
export function useDbPorts(): TestWorld {
  const world = useTestPorts();
  world.ports.users.writeSharedFacts = realSharedFacts;
  return world;
}
