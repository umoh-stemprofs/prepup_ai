-- Migration: 0003_saved_careers.sql
-- Phase 09 — cloud target for bookmarked STEM careers.
--
-- NOTE: public.career_requests from 0001 is the AI career-advisor RATE LIMITER
-- (user_id, day, call_count) used by Phase 15. It holds no career data, so
-- saved careers get their own table instead of corrupting that counter.
--
-- The client writes locally first and syncs here when a session exists and the
-- device is online. (user_id, career_title) is unique so re-saving the same
-- role from an offline queue updates the row instead of duplicating it.

begin;

create table public.saved_careers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  career_title text not null,
  summary text not null default '',
  required_subjects jsonb not null default '[]'::jsonb,
  match_percentage int not null default 0,
  saved_at timestamptz not null default now(),
  unique (user_id, career_title)
);

alter table public.saved_careers enable row level security;

-- Same user-scoped policy shape as quiz_sessions/session_weak_areas.
create policy "saved_careers_select" on public.saved_careers
  for select using (auth.uid() = user_id);

create policy "saved_careers_insert" on public.saved_careers
  for insert with check (auth.uid() = user_id);

create policy "saved_careers_update" on public.saved_careers
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "saved_careers_delete" on public.saved_careers
  for delete using (auth.uid() = user_id);

create index saved_careers_user_saved_at_idx
  on public.saved_careers (user_id, saved_at desc);

commit;
