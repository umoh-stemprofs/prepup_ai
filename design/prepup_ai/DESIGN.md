---
name: PrepUp AI
colors:
  surface: '#f8f9fa'
  surface-dim: '#d9dadb'
  surface-bright: '#f8f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f5'
  surface-container: '#edeeef'
  surface-container-high: '#e7e8e9'
  surface-container-highest: '#e1e3e4'
  on-surface: '#191c1d'
  on-surface-variant: '#434655'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#737686'
  outline-variant: '#c3c6d7'
  surface-tint: '#0053db'
  primary: '#004ac6'
  on-primary: '#ffffff'
  primary-container: '#2563eb'
  on-primary-container: '#eeefff'
  inverse-primary: '#b4c5ff'
  secondary: '#006e2d'
  on-secondary: '#ffffff'
  secondary-container: '#7cf994'
  on-secondary-container: '#007230'
  tertiary: '#824500'
  on-tertiary: '#ffffff'
  tertiary-container: '#a65900'
  on-tertiary-container: '#ffede1'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#003ea8'
  secondary-fixed: '#7ffc97'
  secondary-fixed-dim: '#62df7d'
  on-secondary-fixed: '#002109'
  on-secondary-fixed-variant: '#005320'
  tertiary-fixed: '#ffdcc3'
  tertiary-fixed-dim: '#ffb77d'
  on-tertiary-fixed: '#2f1500'
  on-tertiary-fixed-variant: '#6e3900'
  background: '#f8f9fa'
  on-background: '#191c1d'
  surface-variant: '#e1e3e4'
typography:
  headline-xl:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '800'
    lineHeight: 36px
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '800'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 32px
  body-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 28px
  label-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '700'
    lineHeight: 24px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1.5rem
  margin: 1rem
  space-xs: 0.5rem
  space-sm: 1rem
  space-md: 1.5rem
  space-lg: 2rem
  space-xl: 3rem
---

## Brand & Style

This design system is built for Nigerian secondary school students preparing for WAEC and JAMB. The brand personality is encouraging, dependable, and intensely focused on clarity. The visual language utilizes a clean, accessible **Minimalism** framework designed to eliminate cognitive fatigue during long study sessions.

Every interface element prioritizes legibility, high contrast, and frictionless interaction to support students across varying device types and network conditions.

## Colors

The color palette is anchored by a commanding Royal Blue for primary actions and key navigation elements, set against a near-white canvas to maximize text readability. 

- **Primary (#2563EB):** Actionable items, primary states, and focal points.
- **Background (#F8F9FA):** Canvas foundation ensuring optimal eye comfort.
- **Cards (#FFFFFF with #E2E8F0 borders):** Content containers structured with low-contrast structural outlines.
- **Success (#16A34A):** Correct answers, completed milestones, and positive reinforcement.
- **Warning (#D97706):** Timers, alerts, and cautionary notices.
- **Error (#DC2626):** Incorrect answers and destructive actions.
- **Text (#111111):** Maximum contrast typography for effortless scanning.

## Typography

Typography scales are calibrated specifically for high legibility, favoring oversized weights and generous tracking. Headings demand attention with extra-bold weights, while body text uses heavy weights (700) paired with an expansive 1.6 line height to prevent reading fatigue during intensive exam prep.

## Layout & Spacing

A fluid grid system governs the layout, maintaining generous outer margins and breathing room around interactive elements to prevent accidental taps on mobile viewports. Spacing tokens follow a predictable scale to maintain rhythm across practice tests, dashboard screens, and explanation views. Content reflows cleanly from multi-column desktop layouts to single-column vertical stacks on mobile devices.

## Elevation & Depth

Visual hierarchy is established primarily through clean, low-contrast outlines rather than complex shadows. Cards feature crisp 2px borders in `#E2E8F0` against the `#F8F9FA` background. Interactive states rely on clear color shifts and elevation changes to instantly communicate touch targets without adding visual noise.

## Shapes

The shape language utilizes friendly, rounded corners across all interactive components and containers. Buttons feature a generous 16px radius, while cards and input fields maintain consistent, approachable curves that soften the interface and reduce cognitive friction.

## Components

### Buttons
Buttons are massive, prominent touch targets with a 60px height and 16px border radius, ensuring high accessibility for mobile users. Primary buttons use Royal Blue with high-contrast white text.

### Cards
Question containers and study modules are housed in white cards featuring a 2px `#E2E8F0` solid border and 16px rounded corners, ensuring distinct separation from the canvas background.

### Input Fields & Checkboxes
Form controls feature large touch areas, high-contrast labels, and clear active states. Checkboxes and radio buttons for exam questions are oversized with clear visual selection indicators.

### Additional Components
- **Progress Trackers:** High-visibility linear indicators tracking WAEC/JAMB syllabus completion.
- **Timer Badges:** Prominent warning-colored countdown components for mock exams.
- **Feedback Banners:** Instant success/error alert components with bold icons for immediate question grading.