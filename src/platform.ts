/**
 * The names UGC code used from other modules. Calls go to ports; pure
 * pieces come straight from the owners' packages.
 */
import { ugcPorts, type AuditEntry, type UgcPorts } from "./ports";

type Args<F> = F extends (...args: infer A) => unknown ? A : never;

export { isNotificationType } from "@intgetion/notifications";

export const writeSharedFacts = (...a: Args<UgcPorts["users"]["writeSharedFacts"]>) =>
  ugcPorts().users.writeSharedFacts(...a);
export const readAccountWallet = (...a: Args<UgcPorts["users"]["readAccountWallet"]>) =>
  ugcPorts().users.readAccountWallet(...a);
export const findMemberRole = (...a: Args<UgcPorts["companies"]["findMemberRole"]>) =>
  ugcPorts().companies.findMemberRole(...a);
export const listMemberUserIds = (...a: Args<UgcPorts["companies"]["listMemberUserIds"]>) =>
  ugcPorts().companies.listMemberUserIds(...a);
export const getCompaniesForUser = (...a: Args<UgcPorts["companies"]["getCompaniesForUser"]>) =>
  ugcPorts().companies.getCompaniesForUser(...a);
export const cryptoCheckoutOn = () => ugcPorts().billing.cryptoCheckoutOn();
export const isSanctionedAddress = (...a: Args<UgcPorts["billing"]["isSanctionedAddress"]>) =>
  ugcPorts().billing.isSanctionedAddress(...a);
export const verifiedPayerWallet = (...a: Args<UgcPorts["billing"]["verifiedPayerWallet"]>) =>
  ugcPorts().billing.verifiedPayerWallet(...a);
export const safeNotify = (
  type: string,
  recipientIds: readonly string[],
  payload: unknown,
  options?: { email?: boolean },
) => ugcPorts().notify(type, recipientIds, payload, options);
export const recordAudit = (entry: AuditEntry) => ugcPorts().audit(entry);
export const enforceRateLimit = (bucket: string, subject: string) => ugcPorts().rateLimit(bucket, subject);
export const notifyPlatformOwners = (subject: string, text: string) =>
  ugcPorts().notifyPlatformOwners(subject, text);
export const sendTelegramLinks = (
  token: string,
  chatId: number,
  text: string,
  links: { label: string; url: string }[],
) => ugcPorts().sendTelegramLinks(token, chatId, text, links);
