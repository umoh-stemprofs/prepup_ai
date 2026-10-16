-- Migration: 0001_init.sql
-- Phase 05 — Supabase backend schema
--
-- Provisions the Postgres schema shared by the Supabase-backed sync path:
--  * profiles (one row per signed-in user, created by the auth trigger)
--  * questions (server-side question bank; seeded separately by 0002)
--  * quiz_sessions (completed attempts; client-generated uuid primary key)
--  * session_weak_areas (per-subject weak-area rollups for a session)
--  * career_requests (AI career-advisor rate limiter)
--
-- Row Level Security is enabled on every table. Guest/local sessions are
-- stored exclusively in local SQLite; the cloud tables therefore only ever
-- see authenticated rows where user_id = auth.uid().

begin;

create extension if not exists "uuid-ossp";

create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  full_name text,
  email text,
  target_exam text,
  state text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table public.questions (
  id text primary key,
  subject text not null,
  syllabus_topic text not null,
  question_text text not null,
  options jsonb not null,
  correct_option_index int not null,
  explanation text not null,
  created_at timestamptz default now()
);

create table public.quiz_sessions (
  id uuid primary key,
  user_id uuid references auth.users on delete cascade,
  subject text not null,
  score int not null,
  total_questions int not null,
  score_percentage numeric not null,
  is_pass boolean not null,
  time_spent_seconds int not null,
  completed_at timestamptz not null
);

create table public.session_weak_areas (
  id bigserial primary key,
  session_id uuid references quiz_sessions(id) on delete cascade,
  user_id uuid references auth.users on delete cascade,
  subject text not null,
  syllabus_topic text not null,
  incorrect_count int not null,
  total_count int not null
);

create table public.career_requests (
  user_id uuid references auth.users on delete cascade,
  day date not null default current_date,
  call_count int not null default 1,
  primary key (user_id, day)
);

-- Row Level Security
alter table public.profiles enable row level security;
alter table public.questions enable row level security;
alter table public.quiz_sessions enable row level security;
alter table public.session_weak_areas enable row level security;
alter table public.career_requests enable row level security;

-- questions: readable by authenticated and anonymous clients; writes only by
-- the service role during seed/data migrations.
create policy "questions_select" on public.questions
  for select using (true);

create policy "questions_insert" on public.questions
  for insert with check (false);

create policy "questions_update" on public.questions
  for update using (false);

create policy "questions_delete" on public.questions
  for delete using (false);

-- profiles: users manage only their own profile row.
create policy "profiles_select" on public.profiles
  for select using (auth.uid() = id);

create policy "profiles_insert" on public.profiles
  for insert with check (auth.uid() = id);

create policy "profiles_update" on public.profiles
  for update using (auth.uid() = id);

create policy "profiles_delete" on public.profiles
  for delete using (auth.uid() = id);

-- quiz_sessions: user-scoped. Guest/local sessions live in local SQLite, so
-- the cloud table only ever sees rows where user_id = auth.uid().
create policy "quiz_sessions_select" on public.quiz_sessions
  for select using (auth.uid() = user_id);

create policy "quiz_sessions_insert" on public.quiz_sessions
  for insert with check (auth.uid() = user_id);

create policy "quiz_sessions_update" on public.quiz_sessions
  for update using (auth.uid() = user_id);

create policy "quiz_sessions_delete" on public.quiz_sessions
  for delete using (auth.uid() = user_id);

-- session_weak_areas: user-scoped, same reasoning as quiz_sessions.
create policy "session_weak_areas_select" on public.session_weak_areas
  for select using (auth.uid() = user_id);

create policy "session_weak_areas_insert" on public.session_weak_areas
  for insert with check (auth.uid() = user_id);

create policy "session_weak_areas_update" on public.session_weak_areas
  for update using (auth.uid() = user_id);

create policy "session_weak_areas_delete" on public.session_weak_areas
  for delete using (auth.uid() = user_id);

-- career_requests: rate-limit rows are user-scoped.
create policy "career_requests_select" on public.career_requests
  for select using (auth.uid() = user_id);

create policy "career_requests_insert" on public.career_requests
  for insert with check (auth.uid() = user_id);

create policy "career_requests_update" on public.career_requests
  for update using (auth.uid() = user_id);

-- Auto-create a profile row when a new user signs up.
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

commit;
