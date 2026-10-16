# PrepUp AI — Design Workflow (Phase 01)

Every UI design for PrepUp AI is generated with **Google Stitch**, then handed off here as HTML/CSS + screenshots. Stitch does **not** export Flutter/Dart (decision D9) — Flutter widgets are hand-written from these exports in Phases 09, 10, 11, and 14.

## How it works (per screen)

1. Open **one** Stitch project/conversation so the style stays consistent. Paste **Block 1 — Style Prompt** once at the start.
2. Paste one screen prompt from Block 2 (Login → Register → Dashboard → Exam Setup → Exam → Results → Weak Areas → Career).
3. Refine conversationally until happy ("bigger buttons", "make the timer red", "more spacing").
4. Export from Stitch: **HTML/CSS** code and a **PNG screenshot**.
5. Save them here: `design/<screen>/index.html` and `design/<screen>/screen.png`.
6. Tick the row in `INVENTORY.md`. After all 8 rows are ticked, extract colors/spacing/typography into `tokens.md` (task 1.3) — that file feeds `lib/core/theme.dart` in Phase 02.
7. If Stitch offers a `DESIGN.md` export, save it as `design/DESIGN.md`.

## Conventions

- One folder per screen, kebab-case, exactly as named in `INVENTORY.md`.
- Mobile portrait **360×800** (Android), for every screen.
- Exports are **reference material only** — never added to the app as runtime assets.
- Behavior (timers, taps, navigation) lives in Flutter, not in the HTML export — don't ask Stitch for interactivity.

---

## Block 1 — Style Prompt (paste once, at project start)

```text
Google Stitch design project for "PrepUp AI" — a mobile exam-preparation app helping Nigerian secondary school students practice for WAEC and JAMB. Offline-first, used on low-end Android phones.

Design every screen in mobile portrait, 360×800 px.

Design language (apply consistently to ALL screens):
- Material 3 inspired, clean, confident, uncluttered; must feel fast and simple
- Primary color: indigo blue #3F51B5; background #F5F7FA; cards white with 16px radius and soft shadow
- Font: Inter or Roboto. Question text 18px+, dark #1A1A2E on white, high contrast, 1.5 line height (students read under exam pressure)
- State colors: success green #2E7D32, error red #C62828, warning amber #F9A825
- Every button at least 48px tall; primary actions full-width; large touch targets
- Bottom navigation on app screens: Home, Practice, AI Advisor, Profile (icon + label)
- Simple line icons, no photos, no lorem ipsum — use realistic Nigerian names and WAEC/JAMB subjects (Mathematics, English, Physics, Chemistry, Biology, Economics, Geography, Government, Literature, Further Maths)
- English, plain wording a teenager reads quickly

Screens to design, one at a time: Login, Register, Dashboard, Exam Setup, Exam in Progress, Results, Weak Areas, AI Career Advisor.
```

## Block 2 — Screen Prompts (paste one at a time)

### 1 — Login (`design/login/`)

```text
Screen: Login for PrepUp AI, following the project design language.
- Top: PrepUp AI logo mark + name, tagline "Pass WAEC & JAMB with practice"
- Fields: Email, Password (with show/hide eye icon)
- Primary full-width button: "Sign in"
- Text link: "New here? Create an account"
- Secondary text button: "Skip — use the app offline" (guest mode, important)
- Small "Forgot password?" link
- Centered, generous spacing. Second variant: inline error state "Wrong email or password" under the field.
```

### 2 — Register (`design/register/`)

```text
Screen: Create account for PrepUp AI.
- Fields: Full name, Email, Password
- "Target exam" two-pill segmented control: WAEC | JAMB (JAMB selected)
- "School state" dropdown showing "Rivers State" (list of Nigerian states)
- Primary button "Create account"; link "I already have an account — Sign in"
- Short note: "Your profile helps us tailor your questions."
- Second variant: validation state (red border + "Enter your email" on the email field).
```

### 3 — Dashboard (`design/dashboard/`)

```text
Screen: Home dashboard with bottom navigation (Home active).
- Header: "Good morning, Amaka" + subtitle "Rivers State · JAMB"; sync icon top-right with badge "2"
- Offline banner: "2 results waiting to back up" with "Sign in" action
- Three full-width action cards with icons: "Take Timed Exam" (stopwatch), "Offline Practice Set" (wifi-off), "AI Career Advisor" (sparkles)
- Section "Recent tests": two history cards — subject, big "72%", date, PASS green / FAIL red chip
- Second variant: empty state with small illustration + "No tests yet — start your first practice!"
```

### 4 — Exam Setup (`design/exam-setup/`)

```text
Screen: Start an exam.
- Title "Start your exam"
- "Subject" chip grid: All Subjects (selected), Mathematics, English Language, Physics, Chemistry, Biology, Economics, Geography, Government, Literature-in-English, Further Mathematics
- "Questions" segmented control: 10 | 20 | 50 (20 selected)
- "Mode": two selectable cards — "Timed exam" with duration pills 15 / 30 / 60 min (stopwatch icon, selected) and "Practice" (no timer, relaxed pace)
- Full-width primary button "Start exam" pinned at the bottom
```

### 5 — Exam in Progress (`design/exam/`)

```text
Screen: Active exam, focus mode, NO bottom navigation.
- Top bar: "Chemistry · Organic Reactions" small label; countdown "24:15" large, with thin linear progress bar underneath (second artboard variant: "00:42" in warning red)
- Progress row: "Question 7 of 20" left, "7 answered · 13 left" right
- White question card: a realistic chemistry multiple-choice question with 4 options A–D as full-width rows; one option selected (indigo border + light indigo fill)
- Bottom bar: "Previous" outlined button, "Next" filled button, "Submit exam" text button
- Third small artboard: "Submit exam?" confirmation dialog — "13 questions unanswered — submit anyway?"
```

### 6 — Results (`design/results/`)

```text
Screen: Exam result.
- Big circular score ring showing 72% centered, green PASS chip below it, "Chemistry · 20 questions" caption
- Stats row cards: "Score 14/20", "Time 21:32", "Top 20%"
- "Weak areas found: 3" preview with rows like "Organic Reactions — 25%"
- Primary button "Review answers", secondary "Back to home"
- Second variant: FAIL state — 42%, red ring, red FAIL chip, encouraging wording.
```

### 7 — Weak Areas (`design/weak-areas/`)

```text
Screen: Weak areas to review.
- Title "Weak Areas to Review", subtitle "Topics to focus your revision"
- Grouped by subject with section headers
- Each row: topic name, accuracy bar, right-count and percent — examples: "Organic Reactions · 1/4 Correct (25%)" with red bar; "Stoichiometry · 3/4 Correct (75%)" amber; "Algebra · 9/10 Correct (90%)" green
- Color rule: red below 50%, amber 50–74%, green 75% and above
- Full-width bottom button "Practice these topics"
```

### 8 — AI Career Advisor (`design/career/`)

```text
Screen: AI Career Advisor, bottom navigation (AI Advisor active).
- Intro: "Answer 5 quick questions to discover careers that fit you."
- 1) "Where do you like to work?" chips: Indoors · Outdoors · Offshore · Anywhere
- 2) "How do you solve problems?" chips: Analytical · Creative · Hands-on
- 3) "Which industry excites you?" chips: Energy · Agriculture · Tech · Health · Finance
- 4) "Favourite subjects" multi-select: Mathematics, Physics, Chemistry, Biology, Economics, English (three selected)
- 5) "Kind of job you want" chips: Build things · Lead teams · Research · Start a business
- Full-width button "Find my careers" with sparkle icon; loading variant "Thinking…"
- Second artboard — result state: career card "Subsea Corrosion Engineer" + summary paragraph, then "Subjects you need in WAEC/JAMB" badges: Physics, Mathematics, Chemistry; button "Save this career path".
```
