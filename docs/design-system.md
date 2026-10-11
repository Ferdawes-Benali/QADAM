# Qadam design system

Source of truth in code: `app/lib/core/tokens.dart` (Flutter) and the `:root` variables in `hub/static/styles.css`
(dashboard). Both use the same names and values.

## Brand

- **Logo:** the official Qadam logo (footprint + QADAM wordmark + قدم), used unmodified on light surfaces only
  (`app/assets/brand/qadam_logo.png`, `hub/static/qadam-logo.png`). Minimum width 74 px on screen. Never recoloured.
- **Colours sampled from the logo:** navy `#102D4B` (wordmark) and sky `#8DBADB` (footprint).
- **Personality:** calm, warm, precise. A warm paper background instead of clinical grey; navy for trust; sky for
  the foot; colour is reserved for meaning.

## Colour tokens

| Token | Value | Use |
| --- | --- | --- |
| navy-900 | `#102D4B` | text, brand, hardware badge |
| navy-700 | `#1F4C78` | primary actions, charts |
| sky-400 | `#8DBADB` | footprint, secondary chart series |
| sky-100 / sky-50 | `#E4EFF8` / `#F2F7FC` | selected states, info banners |
| paper | `#F7F5F1` | app background |
| line / line-strong | `#E2DED6` / `#CFC9BD` | borders |
| ink-2 / ink-3 | `#4A5B6E` / `#5F6B78` | secondary / muted text |
| ok · okBg | `#1E7A4F` · `#E4F3EA` | normal |
| watch (text) · watchFill · watchBg | `#8A5300` · `#F2A93B` · `#FFF2DA` | to watch |
| alert · alertBg | `#B42318` · `#FDE8E6` | alert, emergency |
| sim · simBg | `#475467` · `#EEF0F3` | simulation / synthetic data |

Contrast: all text tokens on their backgrounds meet WCAG AA (≥ 4.5:1); `watchFill` is used only for shapes, never text.

## Health status language

Status is always **shape + word + colour**, never colour alone (colour-blind safe):

| Level | Shape | FR | AR | Derja |
| --- | --- | --- | --- | --- |
| green | ● circle | Normal | طبيعي | لاباس |
| amber | ▲ triangle | À surveiller | يحتاج مراقبة | رد بالك |
| red | ■ square | Alerte | تنبيه | تنبيه |

Data source badge: **Capteurs réels** (navy, green dot) · **SIMULATION** (hatched grey) · **Données de démo** (dashed).

## Typography

Rubik (SIL OFL) — one family for Latin and Arabic, rounded and friendly, excellent digits.
App: display 34 / headline 26–22 / title 19–16 / body 17 (large) / 15 / small 13. Dashboard: 24 / 18 / 15 / 14 / 12.
Tabular figures for all measurements.

## Spacing, shape, elevation

4-pt scale: 4 · 8 · 12 · 16 · 24 · 32 · 48. Radii: 8 (controls), 12 (cards), 18 (sheets). No shadows on cards —
1 px warm border; a single soft shadow for modals.

## Components

Buttons (filled navy 52 dp, outlined, text) · Section card · Info banner (info / warn / alert / sim) · Level badge ·
Source badge · Metric · Empty state · Feet diagram (top view, sites as dots, hot site ringed) · Threshold bar
(ΔT vs 2.2 °C) · Confidence meter · Charts (navy line, threshold dashed red, target band green).

## Interaction rules

- Every screen has loading, empty, error and offline states.
- Critical clinician action (alert decision) in **3 steps max**: open → choose → confirm.
- Patient critical path: scan result shows *status → why → what to do → call* without scrolling past fixed advice.
- RTL: Arabic and Derja flip the layout; anatomy (feet diagram, threshold bar, charts) stays left-to-right.
- Touch targets ≥ 48 dp; body text ≥ 15 sp; phone portrait only.
