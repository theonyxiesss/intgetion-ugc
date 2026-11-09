# intgetion-ugc

UGC creative tests of the INTGETION platform as a standalone service:
creator profiles, campaign briefs and their drafts and versions, invites and
applications, shortlists and questions, submissions and their versions,
shipments, the room between a company and a creator, disputes, the review
clock, crypto escrow (budget deposits, reward payouts by transaction,
refunds of the rest) and the assistant's UGC tools. Not connected to the
platform yet; it is integrated later through a separate branch and PR. The
pages (`ui/`) stay in the platform.

- Package `@intgetion/ugc`, HTTP service on port `4160`.
- Depends by git tag on `@intgetion/kit` v0.3.1, `@intgetion/billing` v0.2.0
  (`./engine`: chains, transfer checks, payment status), and for types and
  read-only tables on users v0.1.1, companies v0.1.1 and notifications v0.1.1.
- Owns `creator_profiles` and 15 `ugc_*` tables (migration `0001_ugc.sql`,
  the final state of platform migrations 0051–0085 for them, with the
  `app_rw` grants; tracker `ugc_schema_migrations`). `./db` exports their
  definitions for read-only use.
- Reads only, outside its tables: `users.status` (blocked people) and
  `user_profiles` (country and languages, through `@intgetion/users/db`).

## Ports (`src/ports.ts`)

Types are the owners' own signatures. `src/platform.ts` keeps the names the
code used.

- users: `writeSharedFacts` (in the UGC transaction in-process),
  `readAccountWallet` (the creator's proven payout address);
- companies: member role, member ids, companies of a person;
- billing: checkout switch, sanctions, the member's verified payer wallet;
- notifications, platform audit, rate limits, mail to platform owners,
  Telegram links.

Over HTTP every port goes to one platform callback,
`POST /api/internal/ugc/:op` with `{args}`, answering `{result}` or `{error}`.

## HTTP

Every route except `/health` needs `authorization: Bearer $UGC_SERVICE_TOKEN`.
The platform signs the person in and passes them in `x-user-id`;
`x-user-role: admin` marks a platform admin for the admin steps.

| Method | Path | Does |
| --- | --- | --- |
| POST | `/v1/commands` | every write, `{action, ...}` as `POST /api/ugc` took them (profile, create, apply, offer, accept, submit, decide, ship, dispute, room, payouts, moderate, ...) |
| GET / PATCH / POST | `/v1/brief-draft` | read, patch, `{action: confirm\|reset}` |
| POST | `/v1/campaigns/:id/deposit` | start a budget deposit |
| GET | `/v1/deposits/:id` | refresh a deposit |
| POST | `/v1/deposits/:id/confirm` | `{txHash}` |
| GET | `/v1/campaigns`, `/v1/campaigns/open`, `/v1/campaigns/:id` | the company's tests, open tests for a creator, one test |
| GET | `/v1/invites`, `/v1/workspace`, `/v1/creator-profile` | the creator's side |
| GET / POST | `/v1/rooms/:inviteId`, `/v1/rooms/:inviteId/read` | the room |
| GET | `/v1/price-guide?niche&platform` | reward guide |
| GET | `/v1/admin/review\|disputes\|room-reports\|payouts` | admin queues |
| POST | `/v1/telegram/start` | a `/start` deep link for a test |
| POST | `/v1/tasks/run` | cron: deadlines, deposit rechecks, room sweep |

Errors: `{error: {code, message, details}}`. Money in minor units travels as
strings.

## Run

```bash
cp .env.example .env
npm ci
npm run migrate
npm start
```

## Tests

Unit tests run without a database (with the in-memory store). Integration
tests run when `DATABASE_URL` is set, on a database prepared as in CI:
`test/sql/pre/*.sql`, then `npm run migrate`. Other modules are stand-ins
(`src/test-support.ts`); the shared profile is written by the users module's
own function. Wallet proofs and the rule against changing a wallet while a
reward is owed are tested in the users and billing modules.
