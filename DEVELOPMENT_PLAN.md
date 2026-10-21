# PrepUp AI — Development Plan

Phased build plan for the STEM Festival 2026 exam-prep app.
Each task is intentionally small: one task = one execution unit that can be completed and verified in a single session without exhausting context.

**Version 2 — revised after full audit.** Fixes applied:

| Break | Fix applied | Where |
| --- | --- | --- |
| 1. Offline review had no explanations | `local_questions` gains an `explanation` column (PRD amendment AM-2) | Phase 06 |
| 2. Sync queue couldn't carry cloud fields / retried into duplicates | `pending_sync_results` extended with `session_uuid` PK + `user_id` + `weak_areas` JSON; flush is idempotent (AM-3) | Phases 06, 13 |
| 3. Sync phase ordered before its dependencies | Remote Data Layer and Offline Sync phases swapped | Phases 12 → 13 |
| 4. Timer paused on dispose (cheatable) and drifted when backgrounded | Wall-clock deadline `examEndsAt`; never pauses; auto-submit on resume past deadline | Phase 08 |
| 5. Login wall would break zero-data promise | Guest-first auth; sign-in only on demand (AM-5) | Phase 07 |
| 6. Three copies of question bank would drift | JSON asset = single source of truth + committed generator script | Phases 04, 05, 12 |
| 7. Stitch has no Flutter export; no design phase existed | New Phase 01: design in Stitch → exports in repo → hand-written Flutter in UI phases | Phase 01 |
| 8. Career Advisor unprotected DeepSeek spend | Edge Function requires session + `career_requests` daily counter (10/user/day → 429) | Phases 05, 15 |

Minor fixes: state dropdown (7.4), Practice-mode semantics defined (9.2), widget tests moved next to their UI phases (9.5, 10.6, 11.3; Phase 17 = integration only), shuffled-question snapshot rule for review (10.3), injectable Supabase init for tests (7.1), PRD amendment record (5.6).

## Locked Decisions

| # | Decision |
| --- | --- |
| D1 | **All subjects**, not just 3. Seed bank covers the full WAEC/JAMB list (Mathematics, English Language, Physics, Chemistry, Biology, Economics, Geography, Government, Literature-in-English, Further Mathematics). Minimum 50 questions total, at least 5 per subject. |
| D2 | **DeepSeek API is never called from Flutter.** The app invokes a Supabase Edge Function; the function holds `DEEPSEEK_API_KEY` as a Supabase secret and calls `https://api.deepseek.com/v1/chat/completions`. |
| D3 | State management: **Provider** (lightest option the PRD lists). |
| D4 | Offline-first: SQLite is the primary question source; Supabase is the sync/auth layer. |
| D5 | Package manager: `flutter pub get`; keep existing `pubspec.yaml` and lints. |
| D6 | **Guest-first auth.** App opens usable with no account; sign-in requested only when the student taps Cloud Sync, Cloud History, or AI Career Advisor. |
| D7 | **Wall-clock exam deadline.** `examEndsAt` fixed at start; remaining time always derived from the clock; navigation/backgrounding never pauses it. |
| D8 | **`assets/questions.json` is the single source of truth** for questions; SQL and SQLite copies are machine-generated from it. |
| D9 | **Stitch = design only.** Google Stitch exports HTML/CSS, screenshots, and `DESIGN.md` — no Flutter. All Flutter widgets are hand-written from those exports. |

## PRD Amendments (recorded in `docs/prd_amendments.md` at 5.6)

- **AM-1:** PRD REQ-3.1 says "50 questions across 3 subjects" → replaced by D1 (all 10 subjects).
- **AM-2:** PRD §4.2 `local_questions` gains `explanation TEXT` (offline review screen needs it).
- **AM-3:** PRD §4.2 `pending_sync_results` extended: `session_uuid` (client PK), `user_id`, `weak_areas` JSON — required by `session_weak_areas` sync and duplicate-proof retries.
- **AM-4:** New `career_requests` table (rate limiting for the AI endpoint).
- **AM-5:** Auth is guest-first (D6); PRD REQ-1.x still satisfied — profile rows are created on signup.

## Target Folder Structure

```
design/            # Stitch exports: one folder per screen + tokens.md + INVENTORY.md
tool/              # generate_seed_sql.dart (JSON → SQL)
docs/              # prd_amendments.md, technical report, demo script
lib/
  core/            # theme, constants, supabase config, connectivity
  models/          # question, session, weak_area, career_result
  data/
    local/         # sqflite helper, repositories, seed loader
    remote/        # auth, questions, sessions, profiles, career
  providers/       # auth, quiz, results, career
  screens/
    auth/ dashboard/ quiz/ results/ analytics/ career/
  widgets/         # timer bar, cards, option tiles
assets/
  questions.json   # SSOT seed bank (all subjects)
supabase/
  migrations/      # 0001_init.sql, 0002_seed_questions.sql (generated)
  functions/career-advisor/index.ts
test/
```

---

## Phase 01 — Design with Stitch

- [x] **1.1** Create `design/README.md` documenting the workflow: design screen in Stitch → export HTML/CSS → save a screenshot PNG → note design rules in `DESIGN.md` → files go in `design/<screen-name>/`. (Prompt library included.)
- [x] **1.2** Design and export the core screens: login, register, dashboard, exam setup, exam, results, weak areas, AI career advisor. HTML/CSS exports + PNG screenshots saved under `design/`.
- [ ] **1.3** Extract design tokens (colors, font family and sizes, spacing scale, corner radii, button styles) from the exports into `design/tokens.md`.
- [x] **1.4** Create `design/INVENTORY.md`: table mapping every app screen → its design folder → the phase that builds it (09, 10, 11, 14).
- [x] **1.5** Verify: every screen needed by Phases 09–11 and 14 has an export; no design work is left only "in Stitch".

## Phase 02 — Project Foundation

- [x] **2.1** Update `pubspec.yaml`: add `supabase_flutter`, `sqflite`, `path`, `provider`, `http`, `connectivity_plus`; register `assets/questions.json`; run `flutter pub get`.
- [x] **2.2** Create the folder skeleton under `lib/` with placeholder files.
- [x] **2.3** Create `lib/core/constants.dart`: 10 subjects (D1), WAEC/JAMB, timer presets 15/30/60 min, pass mark 50%, exam modes (timed/practice), **36 states + FCT list for the register dropdown**.
- [x] **2.4** Create `lib/core/theme.dart` from `design/tokens.md`: Material 3 `ColorScheme`, exam-readable `TextTheme`, shared card/button themes.
- [x] **2.5** Replace `lib/main.dart` with the app shell: `MaterialApp` (theme, placeholder home), provider root ready for later providers.
- [ ] **2.6** Verify: `flutter analyze` clean; app runs showing the placeholder home.

## Phase 03 — Data Models

- [x] **3.1** Create `lib/models/question.dart`: `id`, `subject`, `syllabusTopic`, `questionText`, `options`, `correctOptionIndex`, `explanation`; `fromJson`/`toJson`/`toMap`/`fromMap`.
- [x] **3.2** Add `Question.shuffleOptions()`: shuffles options while correctly remapping `correctOptionIndex`; pure and unit-testable.
- [x] **3.3** Create `lib/models/quiz_session.dart`: **`sessionUuid` (client-generated — becomes the cloud `quiz_sessions.id`, makes retries duplicate-proof, AM-3)** + score fields + converters.
- [x] **3.4** Create `lib/models/weak_area.dart`: `subject`, `syllabusTopic`, `incorrectCount`, `totalCount` + converters.
- [x] **3.5** Create `lib/models/career_result.dart`: `careerTitle`, `summary`, `requiredSubjects` + tolerant `fromJson`.
- [ ] **3.6** Verify: `flutter analyze` clean.

## Phase 04 — Question Seed Bank (All Subjects) + Generator

- [x] **4.1** Create `assets/questions.json` (schema: `id, subject, syllabus_topic, question_text, options[4], correct_option_index, explanation`). Batch 1: 10 Mathematics + 10 English Language, syllabus topics labeled.
- [x] **4.2** Batch 2: 5 Physics + 5 Chemistry with explanations.
- [x] **4.3** Batch 3: 5 Biology + 5 Economics.
- [x] **4.4** Batch 4: 5 Geography + 5 Government.
- [x] **4.5** Batch 5: 5 Literature-in-English + 5 Further Mathematics (total ≥ 60 across all 10 subjects).
- [x] **4.6** Validate the JSON with a throwaway script: valid JSON, exactly 4 options each, `correct_option_index` in 0–3, every subject in `constants.dart` present, `explanation` non-empty.
- [x] **4.7** Create `tool/generate_seed_sql.dart` (D8): reads `assets/questions.json`, writes `supabase/migrations/0002_seed_questions.sql`; run it and commit the output. Rerun whenever the JSON changes — never hand-edit the SQL.

## Phase 05 — Supabase Backend (Schema)

- [x] **5.1** Create `supabase/migrations/0001_init.sql`: UUID extension, `profiles`, `questions`, `quiz_sessions`, `session_weak_areas` exactly per PRD §4.1 (cloud schema unchanged).
- [x] **5.2** Add RLS: users select/insert/update/delete **only their own** `profiles`, `quiz_sessions`, `session_weak_areas`; `questions` readable by all authenticated users, writable only by service role; `career_requests` readable/insertable only for own `user_id`.
- [x] **5.3** Add `handle_new_user` trigger auto-inserting a `profiles` row on signup (REQ-1.2).
- [x] **5.4** Add the **`career_requests(user_id UUID, day DATE, call_count INT, PRIMARY KEY(user_id, day))`** table (AM-4, used by Phase 15).
- [x] **5.5** `supabase/migrations/0002_seed_questions.sql` is the **generated output of 4.7** — verify it exists in the repo; regenerate, don't hand-edit, if questions change.
- [x] **5.6** Create `docs/prd_amendments.md` with AM-1…AM-5 so the submitted PRD and the app don't contradict each other.
- [ ] **5.7** Mark as pending: applying both migrations needs a live Supabase project (external blocker — do not fake it).

## Phase 06 — Local SQLite Offline DB

- [x] **6.1** Create `lib/data/local/database_helper.dart`: creates all tables in one transaction — `local_questions` (**with `explanation TEXT`, AM-2**), `local_quiz_sessions`, `local_weak_areas` (history display), and `pending_sync_results` (**AM-3: `session_uuid TEXT PRIMARY KEY, user_id TEXT, score fields, weak_areas TEXT /*JSON*/, completed_at TEXT`** — replaces the narrower PRD §4.2 version).
- [x] **6.2** Create `lib/data/local/question_local_repository.dart`: `getAll()`, `getBySubject()`, `getRandom(count, subject?)` — parameterized SQL only.
- [x] **6.3** Create `lib/data/local/seed_loader.dart`: on first launch, if `local_questions` is empty, insert everything from `assets/questions.json` (including explanations) in one transaction.
- [x] **6.4** Create `lib/data/local/pending_sync_repository.dart`: `enqueue()` **upserts by `session_uuid` (enqueuing the same session twice = one row)**, `getUnsynced()`, `remove(sessionUuid)`.
- [x] **6.5** Test: seed into a test DB → ≥ 50 rows, all 10 subjects, `explanation` populated, double-enqueue of one uuid yields exactly 1 row.

## Phase 07 — Authentication (Guest-First, D6)

- [x] **7.1** Create `lib/core/supabase_service.dart` with **injectable init**: `SupabaseService.init()` reads `SUPABASE_URL`/`SUPABASE_ANON_KEY` from `String.fromEnvironment` and is only called in `main()` — widget tests never initialize a real client (testability fix).
- [x] **7.2** Create `lib/data/remote/auth_repository.dart`: `signUp`, `signIn`, `signOut`, `currentUser`, auth-state stream.
- [x] **7.3** Create `lib/screens/auth/login_screen.dart`: email/password, validation, error snackbars.
- [x] **7.4** Create `lib/screens/auth/register_screen.dart`: full name, email, password, target exam dropdown (WAEC/JAMB), **school-state dropdown from the 36-states + FCT list (2.3)**.
- [x] **7.5** Create `lib/providers/auth_provider.dart` **guest-first**: app opens straight to the dashboard with no account; `requireSignIn(reason)` launches the auth flow only from Sync / Cloud History / AI Advisor entry points; real sessions persist across launches.
- [ ] **7.6** Verify: analyze clean; mocked-client unit tests for auth state transitions; live Supabase test deferred until keys exist (report as blocked, not passed).

## Phase 08 — Quiz Engine (Core Logic)

- [x] **8.1** Create `lib/providers/quiz_provider.dart`: shuffled question snapshot, current index, selected answers, answered count, mode (timed/practice).
- [x] **8.2** **Wall-clock deadline (D7):** `examEndsAt = start + duration`; `remaining = examEndsAt - now` computed every tick **and on every app resume** via `WidgetsBindingObserver`; if already past `examEndsAt` on resume → auto-submit immediately; navigation/backgrounding never pauses the clock; leaving the quiz screen only cancels the UI ticker — the provider keeps the exam alive.
- [x] **8.3** Auto-submit at `00:00` (timed mode): freeze inputs → evaluate → log session. Practice mode has no deadline, manual submit only.
- [x] **8.4** Scoring: correct/incorrect counts, `scorePercentage`, pass ≥ 50%, `timeSpentSeconds`.
- [x] **8.5** Weak-area diagnostic: group misses by `subject` + `syllabusTopic`, compute accuracy per topic, return `List<WeakArea>` sorted worst-first.
- [x] **8.6** Quit rule: pressing back mid-exam shows "Quit exam?" — quitting **discards** the attempt (timer cancelled); minimizing/backgrounding does **not** stop the clock.
- [x] **8.7** Tests: shuffle preserves the correct index across 100 runs; deadline math incl. resume-past-deadline auto-submit; score math; weak-area grouping (1/4 correct → 25%).

## Phase 09 — Quiz UI

- [x] **9.1** Create `lib/widgets/countdown_timer_bar.dart`: `mm:ss` + progress, red under 60 s (reads `remaining` from 8.2 — never its own clock).
- [x] **9.2** Create `lib/screens/quiz/quiz_setup_screen.dart`: subject (incl. "All Subjects"), question count, mode — **Timed Exam (15/30/60 min, auto-submit) vs Practice (untimed, manual submit, same analytics)**.
- [x] **9.3** Create `lib/screens/quiz/quiz_screen.dart`: question card, 4 option tiles, answered/unanswered counter, next/previous, taps disabled after auto-submit.
- [x] **9.4** Create `lib/screens/quiz/confirm_submit_dialog.dart`: "Submit exam?" with answered-count summary.
- [x] **9.5** Widget tests (moved here from the old Phase 16): select an option, force the deadline to expire → inputs frozen and navigation to results happens.
- [ ] **9.6** Verify on emulator: run a 1-minute 5-question timed quiz, let it hit `00:00`, confirm freeze + navigation; then run Practice mode untimed.

## Phase 10 — Results & Weak Area Analytics

- [x] **10.1** Create `lib/screens/results/result_screen.dart`: score, percentage, metrics cards ("Correct" and "Wrong"), pass/fail badge, and per-question review with explanations. Make tapping the "Wrong" stat card navigate directly to weak_areas_screen.dart.
- [x] **10.2** Create `lib/screens/analytics/weak_areas_screen.dart`: "Weak Areas to Review" list — e.g. *"Chemistry: Organic Reactions — 1/4 Correct (25%)"* — with an accuracy bar per topic.
- [x] **10.3** Create `lib/providers/results_provider.dart`: builds `QuizSession` (with fresh `sessionUuid`) + `List<WeakArea>` from the **quiz provider's shuffled snapshot — review must never re-query the DB** (re-query would mismatch options and `correct_option_index`).
- [x] **10.4** On completion: persist session + weak areas into `local_quiz_sessions`/`local_weak_areas` (history) **and enqueue the sync envelope into `pending_sync_results`** (always local; network never involved here).
- [x] **10.5** Local history read path for the dashboard (recent sessions, worst topics).
- [x] **10.6** Widget tests: result screen renders score/percentage/pass state; weak-area list formats "1/4 Correct (25%)".
- [ ] **10.7** Verify: finish a quiz end-to-end; analytics matches hand-computed topic accuracies.

## Phase 11 — Dashboard & Navigation

- [x] **11.1** Create `lib/screens/dashboard/dashboard_screen.dart`: quick-start cards — **Take Timed Exam, Offline Practice Set (→ 9.2 practice mode), AI Career Advisor** — plus recent history cards from 10.5, empty states included.
- [x] **11.2** Create the bottom navigation shell (Dashboard / Practice / Career / Profile) wiring all routes, including the guest-first sign-in entry points (7.5).
- [x] **11.3** Widget tests: dashboard renders the three quick-start cards, shows the empty-history state for a new user, and shows the pending-sync badge count (badge logic itself lands in 13.4).
- [ ] **11.4** Verify: every tab renders on a phone-sized and a tablet-sized emulator; no layout overflow; every screen in `design/INVENTORY.md` is now reachable.

## Phase 12 — Remote Data Layer

*(Moved ahead of sync — it was the dependency that broke the old order.)*

- [x] **12.1** Create `lib/data/remote/question_remote_repository.dart`: fetch the cloud bank and merge **insert-missing-only (`ON CONFLICT DO NOTHING` on id) — never overwrites local rows** (D8 drift protection).
- [x] **12.2** Create `lib/data/remote/session_remote_repository.dart`: insert a session using **its client `session_uuid` as the cloud `quiz_sessions.id`** (idempotent), plus its weak-area rows; read history scoped to `auth.currentUser` only.
- [x] **12.3** Create `lib/data/remote/profile_repository.dart`: fetch/update `profiles`.
- [x] **12.4** Create `lib/data/remote/career_remote_repository.dart`: `supabase.functions.invoke('career-advisor', body)` → `CareerResult`, mapping 401/429/5xx to friendly error states (function itself is deployed in Phase 15).
- [ ] **12.5** Verify: analyze clean; every query parameterized; every user id read from `auth.currentUser`, never from UI input.

## Phase 13 — Offline Sync Queue

*(Now runs after Phase 12 — dependency order fixed.)*

- [x] **13.1** Create `lib/core/connectivity_helper.dart` wrapping `connectivity_plus`: `isOnline` stream (treated as a hint; failures fall through to retry).
- [x] **13.2** Create `lib/data/remote/sync_service.dart`: `flushPending()` — runs only when **authenticated AND online**; for each queued row: insert `quiz_sessions` with `id = session_uuid` (`ON CONFLICT DO NOTHING`), then replace that session's `session_weak_areas` rows (delete-then-insert → idempotent), then remove the local row **only after confirmed success**; `user_id` attached at flush time from the current session.
- [ ] **13.3** Trigger rules: flush on connectivity-up event, on app start, and after sign-in; guest rows stay queued (they are safe — they live on the phone).
- [ ] **13.4** Add the pending-count badge to the dashboard: "N results waiting — sign in to back up" (drives D6's sync prompt).
- [ ] **13.5** Test: airplane-mode quiz → row queued → network restored → row appears in Supabase with its weak areas → queue emptied; kill the app mid-flush and restart → **no duplicate session**.

## Phase 14 — AI Career Advisor UI

- [x] **14.1** Create `lib/screens/career/career_screen.dart`: the **5 preference inputs** (work environment, problem-solving style, industry interest, favourite subjects, preferred kind of work) as chips/dropdowns, styled from the Phase 01 design.
- [x] **14.2** Create `lib/screens/career/career_result_view.dart`: career title, summary, required WAEC/JAMB subjects as badges (REQ-2.4).
- [ ] **14.3** Create `lib/providers/career_provider.dart`: validate inputs → call 12.4 → expose loading/error/result states; 30 s timeout, friendly retry UI; **gated behind `requireSignIn(reason: 'AI Career Advisor')` (D6 + Phase 15 rate limit needs a user id)**.
- [ ] **14.4** Verify: analyze clean; UI renders with a mocked `CareerResult` before the backend exists.

## Phase 15 — Supabase Edge Function (DeepSeek Proxy)

- [x] **15.1** Create `supabase/functions/career-advisor/index.ts`: `serve` handler — CORS preflight, `POST` only, requires a valid Supabase JWT (reject 401 otherwise).
- [x] **15.2** **Rate limit (AM-4):** read the caller's `user_id`, look up today's row in `career_requests`; if `call_count >= 10` return **429**; otherwise increment (atomic `INSERT ... ON CONFLICT DO UPDATE SET call_count = call_count + 1`).
- [x] **15.3** Build the DeepSeek prompt: system message forces strict JSON `{career, summary, required_subjects[]}` from the 5 inputs; `JSON.parse` + field validation; one retry on malformed output; 502 on failure; `max_tokens` capped; user input only in `messages`, key never echoed.
- [x] **15.4** Call `https://api.deepseek.com/v1/chat/completions` with `Deno.env.get("DEEPSEEK_API_KEY")`; document deploy commands (`supabase secrets set DEEPSEEK_API_KEY=...`, `supabase functions deploy career-advisor`).
- [ ] **15.5** Test locally with `supabase functions serve`: 401 unauthenticated, 429 over the daily limit, 500 missing key, 200 + valid JSON happy path.

## Phase 16 — Hardening & Polish

- [ ] **16.1** Empty/error/loading states everywhere: no history, no questions, network down, sign-in required, Edge Function failure, rate-limited.
- [ ] **16.2** Responsive pass against the Phase 01 designs: `LayoutBuilder` breakpoints for ≤360 dp phones and tablets; check 2–3 emulator sizes for overflow.
- [ ] **16.3** Accessibility: ≥4.5:1 contrast, ≥48 dp touch targets, semantic labels on quiz options and the timer.
- [ ] **16.4** Performance: quiz start < 500 ms from SQLite; timer causes no jank; seed insertion is one transaction.
- [ ] **16.5** Secret sweep: no keys in the repo, `.dart_define` file git-ignored, DeepSeek key only in Supabase secrets; remove debug prints.

## Phase 17 — Testing (integration pass)

*Unit/widget tests already live inside Phases 03–13 next to what they test; this phase only closes the loop.*

- [ ] **17.1** Run the full suite: `flutter analyze` + `flutter test` both clean; fix failures at their source (never delete or weaken tests).
- [ ] **17.2** Integration smoke test (`integration_test/`): launch → offline 5-question quiz → result screen → pending-sync row created.
- [ ] **17.3** Sync integration test: online flush → verify rows in local fake/Supabase → restart app → no duplicates.
- [ ] **17.4** Record the exact verify commands in README so a reviewer can reproduce.

## Phase 18 — Release & Submission Package

- [ ] **18.1** Android config: application id, label "PrepUp AI", min SDK, signing config; `flutter build apk --release` installs on a physical device.
- [ ] **18.2** Rewrite `README.md`: problem statement, architecture, setup (Supabase project, env vars, migrations, edge function deploy), screenshots, verify commands.
- [ ] **18.3** Write `docs/technical_report.md`: rubric alignment table (PRD §6), schema docs + PRD amendments, offline-sync design, AI proxy + rate-limit design.
- [ ] **18.4** Final rubric self-score against the 100-point table; note any remaining gaps.
- [ ] **18.5** Record the 5–7 min demo script (`docs/demo_script.md`): offline exam, timer auto-submit, weak areas, AI career advisor.

---

## External Blockers (need user input when reached)

| Blocker | Phase | What's needed |
| --- | --- | --- |
| Supabase project URL + anon key | 05, 07 | Create project, apply migrations, supply keys via `--dart-define` |
| `DEEPSEEK_API_KEY` | 15 | User sets it as a Supabase secret (never in chat/repo) |
| Android signing keystore | 18 | Release APK signing credentials |
| Stitch exports | 01 | User designs/exports screens into `design/` (can trail behind if needed) |

## Execution Rule

Work top-to-bottom, **one checkbox at a time**: implement → `flutter analyze` (and the phase's tests) → mark complete → next. Do not start a phase before the previous one's verification passes. Re-run `tool/generate_seed_sql.dart` whenever `assets/questions.json` changes (D8).


---

## Status Notes — checkbox audit (2026-10-21)

Checkboxes above were reconciled against the actual code in `lib/`, `test/`,
`supabase/`, `design/` and `assets/` on this date. Implementation tasks with
code evidence are ticked. Tasks that need a running emulator, a live Supabase
project, or `flutter analyze` / `flutter test` (run by the developer per
AGENTS.md) are deliberately left unticked.

### Deliberate divergences from the original plan text

- **2.3 / 7.4:** the 36-states + FCT register dropdown and the WAEC/JAMB
  target-exam dropdown were dropped for accessibility; the decision is recorded
  in the header of `lib/core/constants.dart`. The `profiles.state` /
  `profiles.target_exam` cloud columns remain.
- **2.3:** timer presets were reduced to a single 15-minute timed exam
  (exam setup also offers untimed Practice mode).
- **7.2:** auth calls live directly in `lib/providers/auth_provider.dart`;
  no separate `auth_repository.dart` was created.
- **9.4:** the submit confirmation is the finish dialog inside
  `lib/screens/quiz/exam_screen.dart`, not a separate widget file.
- **Phase 14:** the Career Advisor currently uses deterministic on-device
  matching (`lib/providers/career_provider.dart`) with 3 inputs (work
  environment, activity preference, favourite subject) instead of 5
  LLM-driven inputs. It does not yet call the `career-advisor` Edge Function
  (12.4) or require sign-in — task **14.3** is the remaining wiring.

### Phase 15 note

`supabase/functions/career-advisor/index.ts` implements 15.1–15.4 (JWT check,
atomic 10/day rate limit via the new migration
`supabase/migrations/0004_career_request_increment.sql`, strict-JSON DeepSeek
call with one retry, 401/405/429/502 mapping). Deploy commands are documented
in the file header. `DEEPSEEK_API_KEY` is confirmed set on the linked project.

### Remaining work (unticked boxes)

14.3 (wire the AI advisor UI to the Edge Function), apply migrations
0001–0004 to the linked Supabase project (`supabase db push`), 15.5 function
tests, Phase 16 hardening, Phase 17 integration tests, and the whole of
Phase 18 (README is still the Flutter template; no technical report or demo
script yet).
