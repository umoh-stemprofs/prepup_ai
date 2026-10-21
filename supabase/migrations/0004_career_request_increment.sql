-- Migration: 0004_career_request_increment.sql
-- Phase 15.2 — atomic daily counter for the AI career-advisor rate limiter.
--
-- The Edge Function needs "increment and return the new count" as one
-- operation so concurrent requests cannot race past the limit. SECURITY
-- DEFINER + a strict signature keep it callable only with a uuid argument;
-- the function itself re-derives the day and the row shape, so clients cannot
-- write arbitrary rows through it.

begin;

create or replace function public.increment_career_request(p_user_id uuid)
returns int
language sql
security definer
set search_path = public
as $$
  insert into public.career_requests (user_id, day, call_count)
  values (p_user_id, current_date, 1)
  on conflict (user_id, day)
  do update set call_count = public.career_requests.call_count + 1
  returning call_count;
$$;

-- Only the service role (Edge Function) may call it; students never can.
revoke execute on function public.increment_career_request(uuid) from public, anon, authenticated;

commit;
