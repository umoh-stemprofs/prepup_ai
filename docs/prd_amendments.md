# PrepUp AI — PRD Amendments

This document records product decisions that amend the original PRD. Each
amendment is referenced by later phases in the development plan so the team
can trace why a feature, table, or flow exists.

## AM-1 — Full 10-subject question bank coverage

The initial PRD scoped a smaller question set. The app now ships a full
10-subject offline question bank covering:

- Mathematics
- English Language
- Physics
- Chemistry
- Biology
- Economics
- Geography
- Government
- Literature-in-English
- Further Mathematics

This drives the subject list in `lib/core/constants.dart` and the seeded
question bank in `assets/questions.json`. The seed is the single source of
truth for question content; the Supabase `questions` table is populated from
it by `tool/generate_seed_sql.dart`.

## AM-2 — Explanations added for offline review

Every seeded question includes a non-empty explanation. This supported the
offline review experience, so the explanation is part of the canonical
question schema in both `assets/questions.json` and the Supabase
`questions.explanation` column.

## AM-3 — Client-generated session UUID for idempotent sync

Completed quiz sessions use a client-generated UUID as the primary key on
`quiz_sessions.id`. This makes sync retries idempotent: enqueueing the same
local session twice results in an upsert instead of a duplicate row.

The model field is `QuizSession.sessionUuid`, mapped to the Postgres column
`quiz_sessions.id` during sync.

## AM-4 — AI career-advisor rate limiting

The AI career advisor endpoint is protected by a rate limiter backed by the
`career_requests` table. One row is tracked per user per day, with a call
counter used to enforce the per-user daily limit.

## AM-5 — Guest-first authentication

The app opens in a guest mode with no account required. Registration is
requested only when the user attempts a feature that needs cloud sync or the
AI career advisor. Local SQLite practice features work immediately in guest
mode without waiting for Supabase configuration.

This affects the offline/cloud boundary for `quiz_sessions` and
`session_weak_areas`: local guest sessions are stored in SQLite and only
synced to the cloud after authentication, when `user_id = auth.uid()`.
