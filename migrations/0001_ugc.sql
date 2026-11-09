-- UGC: creator profiles, campaigns and their versions, invites, submissions and
-- versions, shipments, the room, disputes, brief drafts, deposits, payouts and
-- refunds (final state of platform migrations 0051-0085 for these tables).
-- Idempotent.

CREATE TABLE IF NOT EXISTS public.creator_profiles (
    user_id uuid NOT NULL,
    display_name text NOT NULL,
    platforms text[] NOT NULL,
    niches text[] NOT NULL,
    example_urls text[] DEFAULT '{}'::text[] NOT NULL,
    invite_opt_in boolean DEFAULT false NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT creator_profiles_examples_count CHECK ((cardinality(example_urls) <= 5)),
    CONSTRAINT creator_profiles_name_len CHECK (((char_length(display_name) >= 1) AND (char_length(display_name) <= 80))),
    CONSTRAINT creator_profiles_niches_check CHECK (((cardinality(niches) >= 1) AND (niches <@ ARRAY['app'::text, 'game'::text, 'finance'::text, 'ecommerce'::text, 'education'::text, 'other'::text]))),
    CONSTRAINT creator_profiles_platforms_check CHECK (((cardinality(platforms) >= 1) AND (platforms <@ ARRAY['tiktok'::text, 'reels'::text, 'shorts'::text]))),
    CONSTRAINT creator_profiles_status_check CHECK ((status = ANY (ARRAY['active'::text, 'paused'::text])))
);

ALTER TABLE ONLY public.creator_profiles FORCE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ugc_brief_drafts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    company_id uuid,
    draft jsonb DEFAULT '{}'::jsonb NOT NULL,
    assumptions jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ugc_brief_drafts_assumptions_check CHECK ((jsonb_typeof(assumptions) = 'array'::text)),
    CONSTRAINT ugc_brief_drafts_object_check CHECK ((jsonb_typeof(draft) = 'object'::text))
);

ALTER TABLE ONLY public.ugc_brief_drafts FORCE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ugc_campaign_versions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    campaign_id uuid NOT NULL,
    version integer NOT NULL,
    changed_by uuid,
    changed_fields text[] DEFAULT '{}'::text[] NOT NULL,
    snapshot jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ugc_campaign_versions_version_check CHECK ((version >= 1))
);

ALTER TABLE ONLY public.ugc_campaign_versions FORCE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ugc_campaigns (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid NOT NULL,
    created_by uuid NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    product_name text NOT NULL,
    product_summary text NOT NULL,
    goal text NOT NULL,
    niches text[] NOT NULL,
    audience text NOT NULL,
    country text,
    languages text[] NOT NULL,
    must_say text NOT NULL,
    must_not text NOT NULL,
    platforms text[] NOT NULL,
    videos_wanted integer NOT NULL,
    bounty_minor bigint NOT NULL,
    deadline date NOT NULL,
    rights text NOT NULL,
    pitch text DEFAULT ''::text NOT NULL,
    example_urls text[] DEFAULT '{}'::text[] NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    countries text[] DEFAULT '{}'::text[] NOT NULL,
    questions text[] DEFAULT '{}'::text[] NOT NULL,
    CONSTRAINT ugc_campaigns_bounty_check CHECK (((bounty_minor >= 500) AND (bounty_minor <= 50000))),
    CONSTRAINT ugc_campaigns_countries_check CHECK ((cardinality(countries) <= 20)),
    CONSTRAINT ugc_campaigns_examples_count CHECK ((cardinality(example_urls) <= 5)),
    CONSTRAINT ugc_campaigns_goal_check CHECK ((goal = ANY (ARRAY['awareness'::text, 'installs'::text, 'purchases'::text, 'waitlist'::text]))),
    CONSTRAINT ugc_campaigns_languages_check CHECK ((((cardinality(languages) >= 1) AND (cardinality(languages) <= 5)) AND (array_to_string(languages, ','::text) ~ '^[a-z]{2}(,[a-z]{2})*$'::text))),
    CONSTRAINT ugc_campaigns_niches_check CHECK (((cardinality(niches) >= 1) AND (niches <@ ARRAY['app'::text, 'game'::text, 'finance'::text, 'ecommerce'::text, 'education'::text, 'other'::text]))),
    CONSTRAINT ugc_campaigns_pitch_len CHECK ((char_length(pitch) <= 300)),
    CONSTRAINT ugc_campaigns_platforms_check CHECK (((cardinality(platforms) >= 1) AND (platforms <@ ARRAY['tiktok'::text, 'reels'::text, 'shorts'::text]))),
    CONSTRAINT ugc_campaigns_questions_count CHECK ((cardinality(questions) <= 3)),
    CONSTRAINT ugc_campaigns_rights_check CHECK ((rights = ANY (ARRAY['organic'::text, 'ads'::text, 'whitelist'::text]))),
    CONSTRAINT ugc_campaigns_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'pending_review'::text, 'open'::text, 'paused'::text, 'closed'::text, 'rejected'::text]))),
    CONSTRAINT ugc_campaigns_videos_check CHECK (((videos_wanted >= 1) AND (videos_wanted <= 30)))
);

ALTER TABLE ONLY public.ugc_campaigns FORCE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ugc_deposits (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    campaign_id uuid NOT NULL,
    payer_user_id uuid,
    chain text NOT NULL,
    token text NOT NULL,
    token_contract text NOT NULL,
    recipient text NOT NULL,
    payer_address text NOT NULL,
    amount_minor bigint NOT NULL,
    token_amount numeric(30,0) NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    reason text,
    tx_hash text,
    expires_at timestamp with time zone NOT NULL,
    confirmed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ugc_deposits_amount_check CHECK (((amount_minor >= 500) AND (amount_minor <= 1500000))),
    CONSTRAINT ugc_deposits_payer_check CHECK ((payer_address ~ '^0x[0-9a-f]{40}$'::text)),
    CONSTRAINT ugc_deposits_recipient_check CHECK ((recipient ~ '^0x[0-9a-f]{40}$'::text)),
    CONSTRAINT ugc_deposits_status_check CHECK ((status = ANY (ARRAY['open'::text, 'submitted'::text, 'confirmed'::text, 'failed'::text, 'frozen'::text]))),
    CONSTRAINT ugc_deposits_token_check CHECK ((token = ANY (ARRAY['USDC'::text, 'USDT'::text]))),
    CONSTRAINT ugc_deposits_tx_check CHECK (((tx_hash IS NULL) OR (tx_hash ~ '^0x[0-9a-f]{64}$'::text)))
);

ALTER TABLE ONLY public.ugc_deposits FORCE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ugc_disputes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invite_id uuid NOT NULL,
    opened_by uuid,
    side text NOT NULL,
    reason text NOT NULL,
    note text DEFAULT ''::text NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    outcome text,
    resolved_by uuid,
    resolved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ugc_disputes_note_check CHECK ((char_length(note) <= 500)),
    CONSTRAINT ugc_disputes_outcome_check CHECK (((outcome IS NULL) OR (outcome = ANY (ARRAY['company'::text, 'creator'::text, 'agreed'::text, 'dismissed'::text])))),
    CONSTRAINT ugc_disputes_reason_check CHECK ((reason = ANY (ARRAY['no_response'::text, 'quality'::text, 'payment'::text, 'link'::text, 'other'::text]))),
    CONSTRAINT ugc_disputes_resolved_check CHECK (((status = 'resolved'::text) = (outcome IS NOT NULL))),
    CONSTRAINT ugc_disputes_side_check CHECK ((side = ANY (ARRAY['company'::text, 'creator'::text]))),
    CONSTRAINT ugc_disputes_status_check CHECK ((status = ANY (ARRAY['open'::text, 'in_review'::text, 'resolved'::text])))
);

ALTER TABLE ONLY public.ugc_disputes FORCE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ugc_invites (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    campaign_id uuid NOT NULL,
    creator_user_id uuid NOT NULL,
    status text NOT NULL,
    bounty_minor bigint,
    rights text,
    pitch text DEFAULT ''::text NOT NULL,
    reminders smallint DEFAULT 0 NOT NULL,
    revision_used boolean DEFAULT false NOT NULL,
    offered_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deadline_noted boolean DEFAULT false NOT NULL,
    terms jsonb,
    terms_hash text,
    agreed_hash text,
    agreed_at timestamp with time zone,
    shortlisted boolean DEFAULT false NOT NULL,
    answers text[] DEFAULT '{}'::text[] NOT NULL,
    decline_reason text,
    CONSTRAINT ugc_invites_decline_reason_check CHECK (((decline_reason IS NULL) OR (decline_reason = ANY (ARRAY['not_fit'::text, 'filled'::text, 'other'::text])))),
    CONSTRAINT ugc_invites_reminders_check CHECK (((reminders >= 0) AND (reminders <= 1))),
    CONSTRAINT ugc_invites_rights_check CHECK (((rights IS NULL) OR (rights = ANY (ARRAY['organic'::text, 'ads'::text, 'whitelist'::text])))),
    CONSTRAINT ugc_invites_status_check CHECK ((status = ANY (ARRAY['applied'::text, 'offered'::text, 'hired'::text, 'declined'::text, 'expired'::text, 'withdrawn'::text])))
);

ALTER TABLE ONLY public.ugc_invites FORCE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ugc_join_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    campaign_id uuid NOT NULL,
    token_hash text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.ugc_join_tokens FORCE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ugc_payouts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    submission_id uuid NOT NULL,
    invite_id uuid NOT NULL,
    amount_minor bigint NOT NULL,
    status text NOT NULL,
    paid_at timestamp with time zone,
    paid_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    chain text,
    token text,
    recipient text,
    tx_hash text,
    CONSTRAINT ugc_payouts_amount_check CHECK (((amount_minor >= 500) AND (amount_minor <= 50000))),
    CONSTRAINT ugc_payouts_paid_pair CHECK ((((status = 'owed'::text) AND (paid_at IS NULL) AND (paid_by IS NULL)) OR ((status = 'paid'::text) AND (paid_at IS NOT NULL) AND (paid_by IS NOT NULL)))),
    CONSTRAINT ugc_payouts_status_check CHECK ((status = ANY (ARRAY['owed'::text, 'paid'::text]))),
    CONSTRAINT ugc_payouts_tx_check CHECK (((tx_hash IS NULL) OR ((status = 'paid'::text) AND (tx_hash ~ '^0x[0-9a-f]{64}$'::text) AND (chain IS NOT NULL) AND (token = ANY (ARRAY['USDC'::text, 'USDT'::text])) AND (recipient ~ '^0x[0-9a-f]{40}$'::text))))
);

ALTER TABLE ONLY public.ugc_payouts FORCE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ugc_refunds (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    campaign_id uuid NOT NULL,
    deposit_id uuid NOT NULL,
    amount_minor bigint NOT NULL,
    chain text NOT NULL,
    token text NOT NULL,
    recipient text NOT NULL,
    tx_hash text NOT NULL,
    refunded_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ugc_refunds_amount_check CHECK (((amount_minor >= 1) AND (amount_minor <= 1500000))),
    CONSTRAINT ugc_refunds_recipient_check CHECK ((recipient ~ '^0x[0-9a-f]{40}$'::text)),
    CONSTRAINT ugc_refunds_token_check CHECK ((token = ANY (ARRAY['USDC'::text, 'USDT'::text]))),
    CONSTRAINT ugc_refunds_tx_check CHECK ((tx_hash ~ '^0x[0-9a-f]{64}$'::text))
);

ALTER TABLE ONLY public.ugc_refunds FORCE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ugc_room_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invite_id uuid NOT NULL,
    author_id uuid,
    body text NOT NULL,
    hidden_at timestamp with time zone,
    hidden_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ugc_room_messages_body_check CHECK (((char_length(body) >= 1) AND (char_length(body) <= 2000)))
);

ALTER TABLE ONLY public.ugc_room_messages FORCE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ugc_room_reads (
    invite_id uuid NOT NULL,
    user_id uuid NOT NULL,
    read_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.ugc_room_reads FORCE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ugc_room_reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    message_id uuid NOT NULL,
    reporter_id uuid,
    reason text NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    decided_by uuid,
    decided_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ugc_room_reports_reason_check CHECK ((reason = ANY (ARRAY['spam'::text, 'abuse'::text, 'contacts'::text, 'other'::text]))),
    CONSTRAINT ugc_room_reports_status_check CHECK ((status = ANY (ARRAY['open'::text, 'hidden'::text, 'dismissed'::text])))
);

ALTER TABLE ONLY public.ugc_room_reports FORCE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ugc_shipments (
    invite_id uuid NOT NULL,
    carrier text NOT NULL,
    tracking text NOT NULL,
    expected_date date,
    shipped_at timestamp with time zone DEFAULT now() NOT NULL,
    received_at timestamp with time zone,
    problem text,
    problem_at timestamp with time zone,
    CONSTRAINT ugc_shipments_carrier_check CHECK (((char_length(carrier) >= 1) AND (char_length(carrier) <= 60))),
    CONSTRAINT ugc_shipments_problem_check CHECK (((problem IS NULL) OR (problem = ANY (ARRAY['not_arrived'::text, 'damaged'::text, 'wrong_item'::text])))),
    CONSTRAINT ugc_shipments_tracking_check CHECK (((char_length(tracking) >= 1) AND (char_length(tracking) <= 60)))
);

ALTER TABLE ONLY public.ugc_shipments FORCE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ugc_submission_versions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    submission_id uuid NOT NULL,
    version integer NOT NULL,
    url text NOT NULL,
    hook text DEFAULT ''::text NOT NULL,
    accepted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ugc_submission_versions_version_check CHECK ((version >= 1))
);

ALTER TABLE ONLY public.ugc_submission_versions FORCE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ugc_submissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invite_id uuid NOT NULL,
    url text NOT NULL,
    hook text DEFAULT ''::text NOT NULL,
    status text NOT NULL,
    change_note text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    live_url text,
    reported_views integer,
    reported_at timestamp with time zone,
    submitted_at timestamp with time zone,
    review_stage smallint DEFAULT 0 NOT NULL,
    escalated_at timestamp with time zone,
    link_reported_at timestamp with time zone,
    decided_at timestamp with time zone,
    CONSTRAINT ugc_submissions_live_url_len CHECK (((live_url IS NULL) OR (char_length(live_url) <= 500))),
    CONSTRAINT ugc_submissions_note_len CHECK ((char_length(change_note) <= 500)),
    CONSTRAINT ugc_submissions_report_pair CHECK ((((live_url IS NULL) AND (reported_views IS NULL) AND (reported_at IS NULL)) OR ((live_url IS NOT NULL) AND (reported_views IS NOT NULL) AND (reported_at IS NOT NULL)))),
    CONSTRAINT ugc_submissions_reported_views_check CHECK (((reported_views IS NULL) OR ((reported_views >= 0) AND (reported_views <= 2000000000)))),
    CONSTRAINT ugc_submissions_review_stage_check CHECK (((review_stage >= 0) AND (review_stage <= 3))),
    CONSTRAINT ugc_submissions_status_check CHECK ((status = ANY (ARRAY['submitted'::text, 'changes_requested'::text, 'accepted'::text, 'rejected'::text, 'winner'::text])))
);

ALTER TABLE ONLY public.ugc_submissions FORCE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'creator_profiles_pkey') THEN
    ALTER TABLE public.creator_profiles ADD CONSTRAINT creator_profiles_pkey PRIMARY KEY (user_id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_brief_drafts_pkey') THEN
    ALTER TABLE public.ugc_brief_drafts ADD CONSTRAINT ugc_brief_drafts_pkey PRIMARY KEY (id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_brief_drafts_user_id_key') THEN
    ALTER TABLE public.ugc_brief_drafts ADD CONSTRAINT ugc_brief_drafts_user_id_key UNIQUE (user_id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_campaign_versions_key') THEN
    ALTER TABLE public.ugc_campaign_versions ADD CONSTRAINT ugc_campaign_versions_key UNIQUE (campaign_id, version);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_campaign_versions_pkey') THEN
    ALTER TABLE public.ugc_campaign_versions ADD CONSTRAINT ugc_campaign_versions_pkey PRIMARY KEY (id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_campaigns_pkey') THEN
    ALTER TABLE public.ugc_campaigns ADD CONSTRAINT ugc_campaigns_pkey PRIMARY KEY (id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_deposits_pkey') THEN
    ALTER TABLE public.ugc_deposits ADD CONSTRAINT ugc_deposits_pkey PRIMARY KEY (id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_disputes_pkey') THEN
    ALTER TABLE public.ugc_disputes ADD CONSTRAINT ugc_disputes_pkey PRIMARY KEY (id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_invites_campaign_creator_key') THEN
    ALTER TABLE public.ugc_invites ADD CONSTRAINT ugc_invites_campaign_creator_key UNIQUE (campaign_id, creator_user_id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_invites_pkey') THEN
    ALTER TABLE public.ugc_invites ADD CONSTRAINT ugc_invites_pkey PRIMARY KEY (id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_join_tokens_hash_key') THEN
    ALTER TABLE public.ugc_join_tokens ADD CONSTRAINT ugc_join_tokens_hash_key UNIQUE (token_hash);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_join_tokens_pkey') THEN
    ALTER TABLE public.ugc_join_tokens ADD CONSTRAINT ugc_join_tokens_pkey PRIMARY KEY (id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_payouts_pkey') THEN
    ALTER TABLE public.ugc_payouts ADD CONSTRAINT ugc_payouts_pkey PRIMARY KEY (id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_payouts_submission_key') THEN
    ALTER TABLE public.ugc_payouts ADD CONSTRAINT ugc_payouts_submission_key UNIQUE (submission_id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_refunds_campaign_key') THEN
    ALTER TABLE public.ugc_refunds ADD CONSTRAINT ugc_refunds_campaign_key UNIQUE (campaign_id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_refunds_pkey') THEN
    ALTER TABLE public.ugc_refunds ADD CONSTRAINT ugc_refunds_pkey PRIMARY KEY (id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_refunds_tx_key') THEN
    ALTER TABLE public.ugc_refunds ADD CONSTRAINT ugc_refunds_tx_key UNIQUE (chain, tx_hash);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_room_messages_pkey') THEN
    ALTER TABLE public.ugc_room_messages ADD CONSTRAINT ugc_room_messages_pkey PRIMARY KEY (id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_room_reads_pkey') THEN
    ALTER TABLE public.ugc_room_reads ADD CONSTRAINT ugc_room_reads_pkey PRIMARY KEY (invite_id, user_id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_room_reports_pkey') THEN
    ALTER TABLE public.ugc_room_reports ADD CONSTRAINT ugc_room_reports_pkey PRIMARY KEY (id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_room_reports_unique') THEN
    ALTER TABLE public.ugc_room_reports ADD CONSTRAINT ugc_room_reports_unique UNIQUE (message_id, reporter_id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_shipments_pkey') THEN
    ALTER TABLE public.ugc_shipments ADD CONSTRAINT ugc_shipments_pkey PRIMARY KEY (invite_id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_submission_versions_key') THEN
    ALTER TABLE public.ugc_submission_versions ADD CONSTRAINT ugc_submission_versions_key UNIQUE (submission_id, version);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_submission_versions_pkey') THEN
    ALTER TABLE public.ugc_submission_versions ADD CONSTRAINT ugc_submission_versions_pkey PRIMARY KEY (id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_submissions_invite_key') THEN
    ALTER TABLE public.ugc_submissions ADD CONSTRAINT ugc_submissions_invite_key UNIQUE (invite_id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_submissions_pkey') THEN
    ALTER TABLE public.ugc_submissions ADD CONSTRAINT ugc_submissions_pkey PRIMARY KEY (id);
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS ugc_brief_drafts_user_updated_idx ON public.ugc_brief_drafts USING btree (user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS ugc_campaigns_company_idx ON public.ugc_campaigns USING btree (company_id, status);

CREATE INDEX IF NOT EXISTS ugc_campaigns_open_idx ON public.ugc_campaigns USING btree (status, deadline);

CREATE INDEX IF NOT EXISTS ugc_deposits_campaign_idx ON public.ugc_deposits USING btree (campaign_id, created_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS ugc_deposits_paid_idx ON public.ugc_deposits USING btree (campaign_id) WHERE (status = 'confirmed'::text);

CREATE INDEX IF NOT EXISTS ugc_deposits_submitted_idx ON public.ugc_deposits USING btree (created_at) WHERE (status = 'submitted'::text);

CREATE UNIQUE INDEX IF NOT EXISTS ugc_deposits_tx_idx ON public.ugc_deposits USING btree (chain, tx_hash) WHERE (status = 'confirmed'::text);

CREATE UNIQUE INDEX IF NOT EXISTS ugc_disputes_one_unresolved_idx ON public.ugc_disputes USING btree (invite_id) WHERE (status <> 'resolved'::text);

CREATE INDEX IF NOT EXISTS ugc_disputes_status_idx ON public.ugc_disputes USING btree (status, created_at);

CREATE INDEX IF NOT EXISTS ugc_invites_creator_idx ON public.ugc_invites USING btree (creator_user_id, status);

CREATE INDEX IF NOT EXISTS ugc_join_tokens_campaign_idx ON public.ugc_join_tokens USING btree (campaign_id);

CREATE UNIQUE INDEX IF NOT EXISTS ugc_payouts_tx_idx ON public.ugc_payouts USING btree (chain, tx_hash) WHERE (tx_hash IS NOT NULL);

CREATE INDEX IF NOT EXISTS ugc_room_messages_invite_idx ON public.ugc_room_messages USING btree (invite_id, created_at);

CREATE INDEX IF NOT EXISTS ugc_room_reports_status_idx ON public.ugc_room_reports USING btree (status, created_at);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'creator_profiles_user_id_fkey') THEN
    ALTER TABLE public.creator_profiles ADD CONSTRAINT creator_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_brief_drafts_company_id_fkey') THEN
    ALTER TABLE public.ugc_brief_drafts ADD CONSTRAINT ugc_brief_drafts_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_brief_drafts_user_id_fkey') THEN
    ALTER TABLE public.ugc_brief_drafts ADD CONSTRAINT ugc_brief_drafts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_campaign_versions_campaign_id_fkey') THEN
    ALTER TABLE public.ugc_campaign_versions ADD CONSTRAINT ugc_campaign_versions_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.ugc_campaigns(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_campaign_versions_changed_by_fkey') THEN
    ALTER TABLE public.ugc_campaign_versions ADD CONSTRAINT ugc_campaign_versions_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.users(id) ON DELETE SET NULL;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_campaigns_company_id_fkey') THEN
    ALTER TABLE public.ugc_campaigns ADD CONSTRAINT ugc_campaigns_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_campaigns_created_by_fkey') THEN
    ALTER TABLE public.ugc_campaigns ADD CONSTRAINT ugc_campaigns_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE RESTRICT;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_deposits_campaign_id_fkey') THEN
    ALTER TABLE public.ugc_deposits ADD CONSTRAINT ugc_deposits_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.ugc_campaigns(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_deposits_payer_user_id_fkey') THEN
    ALTER TABLE public.ugc_deposits ADD CONSTRAINT ugc_deposits_payer_user_id_fkey FOREIGN KEY (payer_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_disputes_invite_id_fkey') THEN
    ALTER TABLE public.ugc_disputes ADD CONSTRAINT ugc_disputes_invite_id_fkey FOREIGN KEY (invite_id) REFERENCES public.ugc_invites(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_disputes_opened_by_fkey') THEN
    ALTER TABLE public.ugc_disputes ADD CONSTRAINT ugc_disputes_opened_by_fkey FOREIGN KEY (opened_by) REFERENCES public.users(id) ON DELETE SET NULL;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_disputes_resolved_by_fkey') THEN
    ALTER TABLE public.ugc_disputes ADD CONSTRAINT ugc_disputes_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.users(id) ON DELETE SET NULL;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_invites_campaign_id_fkey') THEN
    ALTER TABLE public.ugc_invites ADD CONSTRAINT ugc_invites_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.ugc_campaigns(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_invites_creator_user_id_fkey') THEN
    ALTER TABLE public.ugc_invites ADD CONSTRAINT ugc_invites_creator_user_id_fkey FOREIGN KEY (creator_user_id) REFERENCES public.users(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_join_tokens_campaign_id_fkey') THEN
    ALTER TABLE public.ugc_join_tokens ADD CONSTRAINT ugc_join_tokens_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.ugc_campaigns(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_payouts_invite_id_fkey') THEN
    ALTER TABLE public.ugc_payouts ADD CONSTRAINT ugc_payouts_invite_id_fkey FOREIGN KEY (invite_id) REFERENCES public.ugc_invites(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_payouts_paid_by_fkey') THEN
    ALTER TABLE public.ugc_payouts ADD CONSTRAINT ugc_payouts_paid_by_fkey FOREIGN KEY (paid_by) REFERENCES public.users(id) ON DELETE RESTRICT;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_payouts_submission_id_fkey') THEN
    ALTER TABLE public.ugc_payouts ADD CONSTRAINT ugc_payouts_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES public.ugc_submissions(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_refunds_campaign_id_fkey') THEN
    ALTER TABLE public.ugc_refunds ADD CONSTRAINT ugc_refunds_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.ugc_campaigns(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_refunds_deposit_id_fkey') THEN
    ALTER TABLE public.ugc_refunds ADD CONSTRAINT ugc_refunds_deposit_id_fkey FOREIGN KEY (deposit_id) REFERENCES public.ugc_deposits(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_refunds_refunded_by_fkey') THEN
    ALTER TABLE public.ugc_refunds ADD CONSTRAINT ugc_refunds_refunded_by_fkey FOREIGN KEY (refunded_by) REFERENCES public.users(id) ON DELETE RESTRICT;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_room_messages_author_id_fkey') THEN
    ALTER TABLE public.ugc_room_messages ADD CONSTRAINT ugc_room_messages_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE SET NULL;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_room_messages_hidden_by_fkey') THEN
    ALTER TABLE public.ugc_room_messages ADD CONSTRAINT ugc_room_messages_hidden_by_fkey FOREIGN KEY (hidden_by) REFERENCES public.users(id) ON DELETE SET NULL;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_room_messages_invite_id_fkey') THEN
    ALTER TABLE public.ugc_room_messages ADD CONSTRAINT ugc_room_messages_invite_id_fkey FOREIGN KEY (invite_id) REFERENCES public.ugc_invites(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_room_reads_invite_id_fkey') THEN
    ALTER TABLE public.ugc_room_reads ADD CONSTRAINT ugc_room_reads_invite_id_fkey FOREIGN KEY (invite_id) REFERENCES public.ugc_invites(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_room_reads_user_id_fkey') THEN
    ALTER TABLE public.ugc_room_reads ADD CONSTRAINT ugc_room_reads_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_room_reports_decided_by_fkey') THEN
    ALTER TABLE public.ugc_room_reports ADD CONSTRAINT ugc_room_reports_decided_by_fkey FOREIGN KEY (decided_by) REFERENCES public.users(id) ON DELETE SET NULL;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_room_reports_message_id_fkey') THEN
    ALTER TABLE public.ugc_room_reports ADD CONSTRAINT ugc_room_reports_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.ugc_room_messages(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_room_reports_reporter_id_fkey') THEN
    ALTER TABLE public.ugc_room_reports ADD CONSTRAINT ugc_room_reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.users(id) ON DELETE SET NULL;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_shipments_invite_id_fkey') THEN
    ALTER TABLE public.ugc_shipments ADD CONSTRAINT ugc_shipments_invite_id_fkey FOREIGN KEY (invite_id) REFERENCES public.ugc_invites(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_submission_versions_submission_id_fkey') THEN
    ALTER TABLE public.ugc_submission_versions ADD CONSTRAINT ugc_submission_versions_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES public.ugc_submissions(id) ON DELETE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ugc_submissions_invite_id_fkey') THEN
    ALTER TABLE public.ugc_submissions ADD CONSTRAINT ugc_submissions_invite_id_fkey FOREIGN KEY (invite_id) REFERENCES public.ugc_invites(id) ON DELETE CASCADE;
  END IF;
END
$$;

ALTER TABLE public.creator_profiles ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'creator_profiles' AND policyname = 'creator_profiles_anon_deny') THEN
    CREATE POLICY creator_profiles_anon_deny ON public.creator_profiles TO anon USING (false) WITH CHECK (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'creator_profiles' AND policyname = 'creator_profiles_app_rw_all') THEN
    CREATE POLICY creator_profiles_app_rw_all ON public.creator_profiles TO app_rw USING (true) WITH CHECK (true);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'creator_profiles' AND policyname = 'creator_profiles_authenticated_deny') THEN
    CREATE POLICY creator_profiles_authenticated_deny ON public.creator_profiles TO authenticated USING (false) WITH CHECK (false);
  END IF;
END
$$;

ALTER TABLE public.ugc_brief_drafts ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_brief_drafts' AND policyname = 'ugc_brief_drafts_anon_deny') THEN
    CREATE POLICY ugc_brief_drafts_anon_deny ON public.ugc_brief_drafts TO anon USING (false) WITH CHECK (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_brief_drafts' AND policyname = 'ugc_brief_drafts_app_rw_all') THEN
    CREATE POLICY ugc_brief_drafts_app_rw_all ON public.ugc_brief_drafts TO app_rw USING (true) WITH CHECK (true);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_brief_drafts' AND policyname = 'ugc_brief_drafts_authenticated_deny') THEN
    CREATE POLICY ugc_brief_drafts_authenticated_deny ON public.ugc_brief_drafts TO authenticated USING (false) WITH CHECK (false);
  END IF;
END
$$;

ALTER TABLE public.ugc_campaign_versions ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_campaign_versions' AND policyname = 'ugc_campaign_versions_anon_deny') THEN
    CREATE POLICY ugc_campaign_versions_anon_deny ON public.ugc_campaign_versions TO anon USING (false) WITH CHECK (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_campaign_versions' AND policyname = 'ugc_campaign_versions_app_rw_all') THEN
    CREATE POLICY ugc_campaign_versions_app_rw_all ON public.ugc_campaign_versions TO app_rw USING (true) WITH CHECK (true);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_campaign_versions' AND policyname = 'ugc_campaign_versions_authenticated_deny') THEN
    CREATE POLICY ugc_campaign_versions_authenticated_deny ON public.ugc_campaign_versions TO authenticated USING (false) WITH CHECK (false);
  END IF;
END
$$;

ALTER TABLE public.ugc_campaigns ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_campaigns' AND policyname = 'ugc_campaigns_anon_deny') THEN
    CREATE POLICY ugc_campaigns_anon_deny ON public.ugc_campaigns TO anon USING (false) WITH CHECK (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_campaigns' AND policyname = 'ugc_campaigns_app_rw_all') THEN
    CREATE POLICY ugc_campaigns_app_rw_all ON public.ugc_campaigns TO app_rw USING (true) WITH CHECK (true);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_campaigns' AND policyname = 'ugc_campaigns_authenticated_deny') THEN
    CREATE POLICY ugc_campaigns_authenticated_deny ON public.ugc_campaigns TO authenticated USING (false) WITH CHECK (false);
  END IF;
END
$$;

ALTER TABLE public.ugc_deposits ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_deposits' AND policyname = 'ugc_deposits_anon_deny') THEN
    CREATE POLICY ugc_deposits_anon_deny ON public.ugc_deposits TO anon USING (false) WITH CHECK (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_deposits' AND policyname = 'ugc_deposits_app_rw_all') THEN
    CREATE POLICY ugc_deposits_app_rw_all ON public.ugc_deposits TO app_rw USING (true) WITH CHECK (true);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_deposits' AND policyname = 'ugc_deposits_authenticated_deny') THEN
    CREATE POLICY ugc_deposits_authenticated_deny ON public.ugc_deposits TO authenticated USING (false) WITH CHECK (false);
  END IF;
END
$$;

ALTER TABLE public.ugc_disputes ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_disputes' AND policyname = 'ugc_disputes_anon_deny') THEN
    CREATE POLICY ugc_disputes_anon_deny ON public.ugc_disputes TO anon USING (false) WITH CHECK (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_disputes' AND policyname = 'ugc_disputes_app_rw_all') THEN
    CREATE POLICY ugc_disputes_app_rw_all ON public.ugc_disputes TO app_rw USING (true) WITH CHECK (true);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_disputes' AND policyname = 'ugc_disputes_authenticated_deny') THEN
    CREATE POLICY ugc_disputes_authenticated_deny ON public.ugc_disputes TO authenticated USING (false) WITH CHECK (false);
  END IF;
END
$$;

ALTER TABLE public.ugc_invites ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_invites' AND policyname = 'ugc_invites_anon_deny') THEN
    CREATE POLICY ugc_invites_anon_deny ON public.ugc_invites TO anon USING (false) WITH CHECK (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_invites' AND policyname = 'ugc_invites_app_rw_all') THEN
    CREATE POLICY ugc_invites_app_rw_all ON public.ugc_invites TO app_rw USING (true) WITH CHECK (true);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_invites' AND policyname = 'ugc_invites_authenticated_deny') THEN
    CREATE POLICY ugc_invites_authenticated_deny ON public.ugc_invites TO authenticated USING (false) WITH CHECK (false);
  END IF;
END
$$;

ALTER TABLE public.ugc_join_tokens ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_join_tokens' AND policyname = 'ugc_join_tokens_anon_deny') THEN
    CREATE POLICY ugc_join_tokens_anon_deny ON public.ugc_join_tokens TO anon USING (false) WITH CHECK (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_join_tokens' AND policyname = 'ugc_join_tokens_app_rw_all') THEN
    CREATE POLICY ugc_join_tokens_app_rw_all ON public.ugc_join_tokens TO app_rw USING (true) WITH CHECK (true);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_join_tokens' AND policyname = 'ugc_join_tokens_authenticated_deny') THEN
    CREATE POLICY ugc_join_tokens_authenticated_deny ON public.ugc_join_tokens TO authenticated USING (false) WITH CHECK (false);
  END IF;
END
$$;

ALTER TABLE public.ugc_payouts ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_payouts' AND policyname = 'ugc_payouts_anon_deny') THEN
    CREATE POLICY ugc_payouts_anon_deny ON public.ugc_payouts TO anon USING (false) WITH CHECK (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_payouts' AND policyname = 'ugc_payouts_app_rw_all') THEN
    CREATE POLICY ugc_payouts_app_rw_all ON public.ugc_payouts TO app_rw USING (true) WITH CHECK (true);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_payouts' AND policyname = 'ugc_payouts_authenticated_deny') THEN
    CREATE POLICY ugc_payouts_authenticated_deny ON public.ugc_payouts TO authenticated USING (false) WITH CHECK (false);
  END IF;
END
$$;

ALTER TABLE public.ugc_refunds ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_refunds' AND policyname = 'ugc_refunds_anon_deny') THEN
    CREATE POLICY ugc_refunds_anon_deny ON public.ugc_refunds TO anon USING (false) WITH CHECK (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_refunds' AND policyname = 'ugc_refunds_app_rw_all') THEN
    CREATE POLICY ugc_refunds_app_rw_all ON public.ugc_refunds TO app_rw USING (true) WITH CHECK (true);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_refunds' AND policyname = 'ugc_refunds_authenticated_deny') THEN
    CREATE POLICY ugc_refunds_authenticated_deny ON public.ugc_refunds TO authenticated USING (false) WITH CHECK (false);
  END IF;
END
$$;

ALTER TABLE public.ugc_room_messages ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_room_messages' AND policyname = 'ugc_room_messages_anon_deny') THEN
    CREATE POLICY ugc_room_messages_anon_deny ON public.ugc_room_messages TO anon USING (false) WITH CHECK (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_room_messages' AND policyname = 'ugc_room_messages_app_rw_all') THEN
    CREATE POLICY ugc_room_messages_app_rw_all ON public.ugc_room_messages TO app_rw USING (true) WITH CHECK (true);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_room_messages' AND policyname = 'ugc_room_messages_authenticated_deny') THEN
    CREATE POLICY ugc_room_messages_authenticated_deny ON public.ugc_room_messages TO authenticated USING (false) WITH CHECK (false);
  END IF;
END
$$;

ALTER TABLE public.ugc_room_reads ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_room_reads' AND policyname = 'ugc_room_reads_anon_deny') THEN
    CREATE POLICY ugc_room_reads_anon_deny ON public.ugc_room_reads TO anon USING (false) WITH CHECK (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_room_reads' AND policyname = 'ugc_room_reads_app_rw_all') THEN
    CREATE POLICY ugc_room_reads_app_rw_all ON public.ugc_room_reads TO app_rw USING (true) WITH CHECK (true);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_room_reads' AND policyname = 'ugc_room_reads_authenticated_deny') THEN
    CREATE POLICY ugc_room_reads_authenticated_deny ON public.ugc_room_reads TO authenticated USING (false) WITH CHECK (false);
  END IF;
END
$$;

ALTER TABLE public.ugc_room_reports ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_room_reports' AND policyname = 'ugc_room_reports_anon_deny') THEN
    CREATE POLICY ugc_room_reports_anon_deny ON public.ugc_room_reports TO anon USING (false) WITH CHECK (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_room_reports' AND policyname = 'ugc_room_reports_app_rw_all') THEN
    CREATE POLICY ugc_room_reports_app_rw_all ON public.ugc_room_reports TO app_rw USING (true) WITH CHECK (true);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_room_reports' AND policyname = 'ugc_room_reports_authenticated_deny') THEN
    CREATE POLICY ugc_room_reports_authenticated_deny ON public.ugc_room_reports TO authenticated USING (false) WITH CHECK (false);
  END IF;
END
$$;

ALTER TABLE public.ugc_shipments ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_shipments' AND policyname = 'ugc_shipments_anon_deny') THEN
    CREATE POLICY ugc_shipments_anon_deny ON public.ugc_shipments TO anon USING (false) WITH CHECK (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_shipments' AND policyname = 'ugc_shipments_app_rw_all') THEN
    CREATE POLICY ugc_shipments_app_rw_all ON public.ugc_shipments TO app_rw USING (true) WITH CHECK (true);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_shipments' AND policyname = 'ugc_shipments_authenticated_deny') THEN
    CREATE POLICY ugc_shipments_authenticated_deny ON public.ugc_shipments TO authenticated USING (false) WITH CHECK (false);
  END IF;
END
$$;

ALTER TABLE public.ugc_submission_versions ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_submission_versions' AND policyname = 'ugc_submission_versions_anon_deny') THEN
    CREATE POLICY ugc_submission_versions_anon_deny ON public.ugc_submission_versions TO anon USING (false) WITH CHECK (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_submission_versions' AND policyname = 'ugc_submission_versions_app_rw_all') THEN
    CREATE POLICY ugc_submission_versions_app_rw_all ON public.ugc_submission_versions TO app_rw USING (true) WITH CHECK (true);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_submission_versions' AND policyname = 'ugc_submission_versions_authenticated_deny') THEN
    CREATE POLICY ugc_submission_versions_authenticated_deny ON public.ugc_submission_versions TO authenticated USING (false) WITH CHECK (false);
  END IF;
END
$$;

ALTER TABLE public.ugc_submissions ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_submissions' AND policyname = 'ugc_submissions_anon_deny') THEN
    CREATE POLICY ugc_submissions_anon_deny ON public.ugc_submissions TO anon USING (false) WITH CHECK (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_submissions' AND policyname = 'ugc_submissions_app_rw_all') THEN
    CREATE POLICY ugc_submissions_app_rw_all ON public.ugc_submissions TO app_rw USING (true) WITH CHECK (true);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ugc_submissions' AND policyname = 'ugc_submissions_authenticated_deny') THEN
    CREATE POLICY ugc_submissions_authenticated_deny ON public.ugc_submissions TO authenticated USING (false) WITH CHECK (false);
  END IF;
END
$$;

-- Table rights for the app role, as on the platform.
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.creator_profiles TO app_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ugc_brief_drafts TO app_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ugc_campaign_versions TO app_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ugc_campaigns TO app_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ugc_deposits TO app_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ugc_disputes TO app_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ugc_invites TO app_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ugc_join_tokens TO app_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ugc_payouts TO app_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ugc_refunds TO app_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ugc_room_messages TO app_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ugc_room_reads TO app_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ugc_room_reports TO app_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ugc_shipments TO app_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ugc_submission_versions TO app_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ugc_submissions TO app_rw;
