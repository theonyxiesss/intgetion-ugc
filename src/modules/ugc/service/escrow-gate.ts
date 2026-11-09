import { validAddress } from "@intgetion/billing/engine";
import { cryptoCheckoutOn } from "../../../platform";
import { escrowRequired } from "./escrow-rules";

/** The platform wallet that takes UGC budgets: the checkout's own address. */
export function campaignWalletAddress(): string | null {
  return (
    validAddress(process.env.COMPANY_WALLET_ADDRESS ?? "")?.toLowerCase() ??
    null
  );
}

/** Offers wait for a paid budget when the checkout and its wallet are on (D466). */
export function escrowOn(): boolean {
  return escrowRequired(cryptoCheckoutOn() && campaignWalletAddress() !== null);
}
