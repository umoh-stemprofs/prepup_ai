# Screen Inventory — task 1.5 checklist

One row per screen. Tick "Exported?" when `design/<folder>/code.html` **and** a
PNG screenshot both exist (this repo's Stitch exports use `code.html` plus a
screen-named PNG, not `index.html`/`screen.png`).

| # | Screen | Export folder | Built in phase | Exported? |
| --- | --- | --- | --- | --- |
| 1 | Login | `design/login/` (`code.html`, `login.png`) | 07 | ☑ |
| 2 | Register | `design/register/` (`code.html`, `register.png`) | 07 | ☑ |
| 3 | Dashboard | `design/dashboard/` (`code.html`, `screen.png`) | 11 | ☑ |
| 4 | Exam Setup | `design/exam-setup/` (`code.html`, `exam-setup.png`) | 09 | ☑ |
| 5 | Exam in Progress | `design/exam/` (`code.html`, `exam.png`) | 09 | ☑ |
| 6 | Results | `design/results/` (`code.html`, `results.png`) | 10 | ☑ |
| 7 | Weak Areas | `design/weak-areas/` (`code.html`, `weak-areas.png`) | 10 | ☑ |
| 8 | AI Career Advisor | `design/career/` (`code.html`, `career.png`) | 14 | ☑ |

**Verification (task 1.5):** every screen needed by Phases 07, 09, 10, 11 and
14 has an export — no design work is left only "in Stitch". The one design
gap is `design/tokens.md` (task 1.3), which was never extracted; the Flutter
theme in `lib/core/theme.dart` was hand-written from the exports instead.

**Optional (not required):** Profile screen — no Stitch export; built directly
from the dashboard design language in `lib/screens/profile/profile_screen.dart`.
The logo has a screenshot-only folder at `design/logo/` (`screen.png`).
