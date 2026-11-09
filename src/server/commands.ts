import { z } from "zod";
import {
  UGC_DECLINE_REASONS,
  UGC_DISPUTE_OUTCOMES,
  UGC_DISPUTE_REASONS,
  UGC_GOALS,
  UGC_NICHES,
  UGC_PLATFORMS,
  UGC_REPORT_REASONS,
  UGC_RIGHTS,
} from "../config/ugc";
import {
  acceptInvite,
  setShortlist,
  openDispute,
  decideDispute,
  UGC_DELIVERY_PROBLEMS,
  markShipped,
  confirmReceived,
  reportDeliveryProblem,
  reportBrokenLink,
  postUgcRoomMessage,
  reportRoomMessage,
  decideRoomReport,
  rejectApplication,
  applyToCampaign,
  closeCampaign,
  createCampaign,
  decideCampaign,
  decideSubmission,
  declineInvite,
  issueJoinLink,
  markPayoutPaid,
  offerHire,
  payRewardByTx,
  refundByTx,
  redeemJoinToken,
  remindInvite,
  reportLivePost,
  requestChanges,
  saveCreatorProfile,
  setCampaignPaused,
  submitVideo,
  updateCampaignText,
  withdrawToDraft,
} from "../modules/ugc/service";

const brief = {
  companyId: z.uuid(),
  productName: z.string().trim().min(1).max(120),
  productSummary: z.string().trim().min(1).max(400),
  goal: z.enum(UGC_GOALS),
  niches: z.array(z.enum(UGC_NICHES)).min(1),
  audience: z.string().trim().min(1).max(300),
  country: z.string().length(2).nullable(),
  languages: z.array(z.string()).min(1),
  mustSay: z.string().trim().min(1).max(1000),
  mustNot: z.string().trim().min(1).max(1000),
  platforms: z.array(z.enum(UGC_PLATFORMS)).min(1),
  videosWanted: z.number().int().min(1).max(30),
  bountyMinor: z.string().regex(/^\d+$/),
  deadline: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  rights: z.enum(UGC_RIGHTS),
  pitch: z.string().max(300),
  exampleUrls: z.array(z.string()).max(5),
};

export const ugcCommand = z.discriminatedUnion("action", [
  z.object({
    action: z.literal("profile"),
    displayName: z.string().trim().min(1).max(80),
    languages: z.array(z.string()).min(1),
    platforms: z.array(z.enum(UGC_PLATFORMS)).min(1),
    niches: z.array(z.enum(UGC_NICHES)).min(1),
    country: z.string().length(2).nullable(),
    exampleUrls: z.array(z.string()).max(5),
    inviteOptIn: z.boolean(),
    status: z.enum(["active", "paused"]),
  }),
  z.object({ action: z.literal("create"), ...brief }),
  z.object({
    action: z.literal("apply"),
    campaignId: z.uuid(),
    answers: z.array(z.string().max(600)).max(3).optional(),
  }),
  z.object({
    action: z.literal("offer"),
    campaignId: z.uuid(),
    creatorId: z.uuid(),
  }),
  z.object({
    action: z.literal("accept"),
    inviteId: z.uuid(),
    termsHash: z.string().length(64).optional(),
  }),
  z.object({ action: z.literal("decline"), inviteId: z.uuid() }),
  z.object({ action: z.literal("brokenLink"), inviteId: z.uuid() }),
  z.object({
    action: z.literal("ship"),
    inviteId: z.uuid(),
    carrier: z.string().max(120),
    tracking: z.string().max(120),
    expectedDate: z.string().max(10).optional(),
  }),
  z.object({ action: z.literal("received"), inviteId: z.uuid() }),
  z.object({
    action: z.literal("deliveryProblem"),
    inviteId: z.uuid(),
    reason: z.enum(UGC_DELIVERY_PROBLEMS),
  }),
  z.object({
    action: z.literal("disputeOpen"),
    inviteId: z.uuid(),
    reason: z.enum(UGC_DISPUTE_REASONS),
    note: z.string().max(1000).optional(),
  }),
  z.object({
    action: z.literal("disputeDecide"),
    disputeId: z.uuid(),
    to: z.enum(["in_review", "resolved"]),
    outcome: z.enum(UGC_DISPUTE_OUTCOMES).optional(),
  }),
  z.object({
    action: z.literal("roomPost"),
    inviteId: z.uuid(),
    body: z.string().max(4000),
  }),
  z.object({
    action: z.literal("roomReport"),
    messageId: z.uuid(),
    reason: z.enum(UGC_REPORT_REASONS),
  }),
  z.object({
    action: z.literal("roomReportDecide"),
    reportId: z.uuid(),
    to: z.enum(["hidden", "dismissed"]),
  }),
  z.object({
    action: z.literal("reject"),
    inviteId: z.uuid(),
    reason: z.enum(UGC_DECLINE_REASONS),
  }),
  z.object({
    action: z.literal("shortlist"),
    inviteId: z.uuid(),
    on: z.boolean(),
  }),
  z.object({
    action: z.literal("submit"),
    inviteId: z.uuid(),
    url: z.string().max(500),
    hook: z.string().max(300),
  }),
  z.object({
    action: z.literal("changes"),
    inviteId: z.uuid(),
    note: z.string().max(500),
  }),
  z.object({
    action: z.literal("decide"),
    inviteId: z.uuid(),
    to: z.enum(["accepted", "rejected", "winner"]),
  }),
  z.object({
    action: z.literal("report"),
    inviteId: z.uuid(),
    liveUrl: z.string().max(500),
    views: z.number().int().min(0).max(2_000_000_000),
  }),
  z.object({ action: z.literal("remind"), inviteId: z.uuid() }),
  z.object({ action: z.literal("close"), campaignId: z.uuid() }),
  z.object({ action: z.literal("pause"), campaignId: z.uuid() }),
  z.object({ action: z.literal("resume"), campaignId: z.uuid() }),
  z.object({ action: z.literal("withdraw"), campaignId: z.uuid() }),
  z.object({
    action: z.literal("editText"),
    campaignId: z.uuid(),
    productSummary: z.string().max(400).optional(),
    pitch: z.string().max(2000).optional(),
    mustSay: z.string().max(1000).optional(),
    mustNot: z.string().max(1000).optional(),
    exampleUrls: z.array(z.string().max(500)).max(10).optional(),
    questions: z.array(z.string().max(300)).max(5).optional(),
  }),
  z.object({ action: z.literal("join"), campaignId: z.uuid() }),
  z.object({ action: z.literal("redeem"), payload: z.string().max(64) }),
  z.object({ action: z.literal("markPaid"), payoutId: z.uuid() }),
  z.object({
    action: z.literal("payoutTx"),
    payoutId: z.uuid(),
    chain: z.string().max(32),
    token: z.enum(["USDC", "USDT"]),
    txHash: z.string().max(80),
  }),
  z.object({
    action: z.literal("refundTx"),
    campaignId: z.uuid(),
    chain: z.string().max(32),
    token: z.enum(["USDC", "USDT"]),
    txHash: z.string().max(80),
  }),
  z.object({
    action: z.literal("moderate"),
    campaignId: z.uuid(),
    to: z.enum(["open", "rejected"]),
  }),
]);

/** The person, as the platform signed them in (role decides admin steps). */
export type UgcActor = { id: string; platformRole: string };

/**
 * Writes for creative tests: one command per call, as the platform's
 * `POST /api/ugc` took them. The same functions serve the bot (D457).
 */
export async function runUgcCommand(user: UgcActor, raw: unknown): Promise<unknown> {
  {
    const input = ugcCommand.parse(raw);
    const id = user.id;
    if (input.action === "profile") {
      const { action, ...profile } = input;
      void action;
      return await saveCreatorProfile(id, profile);
    }
    if (input.action === "create") {
      const { action, bountyMinor, ...rest } = input;
      void action;
      return await createCampaign(id, { ...rest, bountyMinor: BigInt(bountyMinor) });
    }
    if (input.action === "apply") {
      return await applyToCampaign(id, input.campaignId, input.answers);
    }
    if (input.action === "offer") {
      return await offerHire(id, input.campaignId, input.creatorId);
    }
    if (input.action === "accept") {
      return await acceptInvite(id, input.inviteId, input.termsHash);
    }
    if (input.action === "roomReport") {
      return await reportRoomMessage(id, input.messageId, input.reason);
    }
    if (input.action === "roomReportDecide") {
      return await decideRoomReport({
          adminId: id,
          isAdmin: user.platformRole === "admin",
          reportId: input.reportId,
          to: input.to,
        });
    }
    if (input.action === "brokenLink") {
      return await reportBrokenLink(id, input.inviteId);
    }
    if (input.action === "ship") {
      return await markShipped(id, input.inviteId, {
          carrier: input.carrier,
          tracking: input.tracking,
          expectedDate: input.expectedDate ?? null,
        });
    }
    if (input.action === "received") {
      return await confirmReceived(id, input.inviteId);
    }
    if (input.action === "deliveryProblem") {
      return await reportDeliveryProblem(id, input.inviteId, input.reason);
    }
    if (input.action === "disputeOpen") {
      return await openDispute(id, input.inviteId, input.reason, input.note ?? "");
    }
    if (input.action === "disputeDecide") {
      return await decideDispute({
          adminId: id,
          isAdmin: user.platformRole === "admin",
          disputeId: input.disputeId,
          to: input.to,
          outcome: input.outcome,
        });
    }
    if (input.action === "roomPost") {
      return await postUgcRoomMessage(id, input.inviteId, input.body);
    }
    if (input.action === "reject") {
      return await rejectApplication(id, input.inviteId, input.reason);
    }
    if (input.action === "shortlist") {
      return await setShortlist(id, input.inviteId, input.on);
    }
    if (input.action === "decline") {
      return await declineInvite(id, input.inviteId);
    }
    if (input.action === "submit") {
      return await submitVideo(id, input.inviteId, input.url, input.hook);
    }
    if (input.action === "changes") {
      return await requestChanges(id, input.inviteId, input.note);
    }
    if (input.action === "decide") {
      return await decideSubmission(id, input.inviteId, input.to);
    }
    if (input.action === "report") {
      return await reportLivePost(id, input.inviteId, input.liveUrl, input.views);
    }
    if (input.action === "remind") {
      return await remindInvite(id, input.inviteId);
    }
    if (input.action === "close") {
      return await closeCampaign(id, input.campaignId);
    }
    // D512: pause, resume, back to the draft, and text changes.
    if (input.action === "pause" || input.action === "resume") {
      return await setCampaignPaused(id, input.campaignId, input.action === "pause");
    }
    if (input.action === "withdraw") {
      const result = await withdrawToDraft(id, input.campaignId);
      return { ...result, redirect: "/campaigns/new" };
    }
    if (input.action === "editText") {
      const { action, campaignId, ...patch } = input;
      void action;
      return await updateCampaignText(id, campaignId, patch);
    }
    if (input.action === "join") {
      return await issueJoinLink(id, input.campaignId);
    }
    if (input.action === "redeem") {
      return await redeemJoinToken(id, input.payload);
    }
    if (input.action === "markPaid") {
      return await markPayoutPaid({
          adminId: id,
          isAdmin: user.platformRole === "admin",
          payoutId: input.payoutId,
        });
    }
    if (input.action === "payoutTx") {
      return await payRewardByTx({
          adminId: id,
          isAdmin: user.platformRole === "admin",
          payoutId: input.payoutId,
          tx: { chain: input.chain, token: input.token, txHash: input.txHash },
        });
    }
    if (input.action === "refundTx") {
      return await refundByTx({
          adminId: id,
          isAdmin: user.platformRole === "admin",
          campaignId: input.campaignId,
          tx: { chain: input.chain, token: input.token, txHash: input.txHash },
        });
    }
    return await decideCampaign({
        adminId: id,
        isAdmin: user.platformRole === "admin",
        campaignId: input.campaignId,
        to: input.to,
      });
  }
}
