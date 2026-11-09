-- Platform pieces ugc needs. CI only; the real ones live elsewhere.
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_rw') THEN CREATE ROLE app_rw; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN CREATE ROLE anon; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN CREATE ROLE authenticated; END IF;
END $$;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
GRANT USAGE ON SCHEMA public TO app_rw, anon, authenticated;

CREATE TABLE IF NOT EXISTS public.users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_uid uuid UNIQUE,
  locale text NOT NULL DEFAULT 'en',
  status text NOT NULL DEFAULT 'active',
  platform_role text NOT NULL DEFAULT 'user',
  terms_accepted_at timestamptz,
  terms_version text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text UNIQUE,
  status text NOT NULL DEFAULT 'unverified'
);

-- The shared profile, as the users module creates it (read by UGC only).
CREATE TABLE IF NOT EXISTS public.user_profiles (
  user_id uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  display_name text,
  country char(2),
  city text,
  timezone text,
  languages jsonb NOT NULL DEFAULT '[]'::jsonb,
  about text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_profiles_display_name_check
    CHECK (display_name IS NULL OR char_length(display_name) BETWEEN 1 AND 120),
  CONSTRAINT user_profiles_country_check
    CHECK (country IS NULL OR country ~ '^[A-Z]{2}$'),
  CONSTRAINT user_profiles_city_check
    CHECK (city IS NULL OR char_length(city) BETWEEN 1 AND 120),
  CONSTRAINT user_profiles_timezone_check
    CHECK (timezone IS NULL OR char_length(timezone) BETWEEN 1 AND 64),
  CONSTRAINT user_profiles_languages_check
    CHECK (jsonb_typeof(languages) = 'array'),
  CONSTRAINT user_profiles_about_check
    CHECK (about IS NULL OR char_length(about) <= 1000)
);
