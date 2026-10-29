# Design System Master File

> **LOGIC:** When building a specific page, first check `design-system/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file.
> If not, strictly follow the rules below.

---

**Project:** DevOps Learning Platform
**Generated:** 2026-10-24 23:26:41
**Category:** SaaS (General)

---

## Global Rules

### Color Palette

| Role | Hex | CSS Variable |
|------|-----|--------------|
| Primary — Deep Burgundy | `#3B1F24` | `--color-primary` |
| Secondary — Muted Burgundy | `#60343D` | `--color-secondary` |
| Accent — Dusty Rose Burgundy | `#82535D` | `--color-accent` |
| Light Accent — Soft Rose | `#B88A91` | `--color-light-accent` |
| Subtle Highlight — Pale Blush | `#E7D4D7` | `--color-subtle-highlight` |
| Main Background | `#FFFFFF` | `--color-background` |
| Alternate Background | `#FCF8F9` | `--color-background-alt` |
| Elevated Cards | `#FFFFFF` | `--color-surface` |
| Borders | `#E8DDE0` | `--border-default` |
| Primary Text | `#171521` | `--color-text` |
| Secondary Text | `#454252` | `--color-text-muted` |
| Subtle Text | `#797587` | `--color-text-subtle` |

**Color Notes:** Premium White + Deep Burgundy brand identity featuring clean white and pale-blush surfaces, deep burgundy interactive controls, subtle pinkish borders, and dark readable typography.

### Typography

- **Heading Font:** Space Grotesk
- **Body Font:** DM Sans
- **Mood:** tech, startup, modern, innovative, bold, futuristic
- **Google Fonts:** [Space Grotesk + DM Sans](https://fonts.google.com/share?selection.family=DM+Sans:wght@400;500;700|Space+Grotesk:wght@400;500;600;700)

**CSS Import:**
```css
@import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;700&family=Space+Grotesk:wght@400;500;600;700&display=swap');
```

### Spacing Variables

| Token | Value | Usage |
|-------|-------|-------|
| `--space-xs` | `4px` / `0.25rem` | Tight gaps |
| `--space-sm` | `8px` / `0.5rem` | Icon gaps, inline spacing |
| `--space-md` | `16px` / `1rem` | Standard padding |
| `--space-lg` | `24px` / `1.5rem` | Section padding |
| `--space-xl` | `32px` / `2rem` | Large gaps |
| `--space-2xl` | `48px` / `3rem` | Section margins |
| `--space-3xl` | `64px` / `4rem` | Hero padding |

### Shadow Depths

| Level | Value | Usage |
|-------|-------|-------|
| `--shadow-sm` | `0 1px 3px rgba(59, 31, 36, 0.04)` | Subtle lift |
| `--shadow-md` | `0 4px 16px -2px rgba(59, 31, 36, 0.05)` | Cards, buttons |
| `--shadow-lg` | `0 10px 25px -4px rgba(59, 31, 36, 0.08)` | Modals, dropdowns |
| `--shadow-xl` | `0 20px 35px -5px rgba(59, 31, 36, 0.12)` | Hero elements, featured cards |

---

## Component Specs

### Buttons

```css
/* Primary Button */
.btn-primary {
  background: #3B1F24;
  color: #FFFFFF;
  border: 1px solid #3B1F24;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: 600;
  box-shadow: 0 4px 14px rgba(59, 31, 36, 0.2);
  transition: all 200ms ease;
  cursor: pointer;
}

.btn-primary:hover {
  background: #60343D;
  border-color: #60343D;
  box-shadow: 0 6px 20px rgba(96, 52, 61, 0.3);
  transform: translateY(-1px);
}

/* Secondary Button */
.btn-secondary {
  background: #FFFFFF;
  color: #171521;
  border: 1px solid #E8DDE0;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: 600;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  transition: all 200ms ease;
  cursor: pointer;
}

.btn-secondary:hover {
  background: #FCF8F9;
  color: #3B1F24;
  border-color: #B88A91;
  transform: translateY(-1px);
}
```

### Cards

```css
.card {
  background: #FFFFFF;
  border: 1px solid #E8DDE0;
  border-radius: 12px;
  padding: 24px;
  box-shadow: var(--shadow-md);
  transition: all 200ms ease;
  cursor: pointer;
}

.card:hover {
  border-color: #B88A91;
  box-shadow: var(--shadow-lg), 0 0 15px -3px rgba(96, 52, 61, 0.1);
  transform: translateY(-2px);
}
```

### Inputs

```css
.input {
  background: #FFFFFF;
  color: #171521;
  padding: 12px 16px;
  border: 1px solid #E8DDE0;
  border-radius: 8px;
  font-size: 16px;
  transition: border-color 200ms ease, box-shadow 200ms ease;
}

.input:focus {
  border-color: #82535D;
  outline: none;
  box-shadow: 0 0 0 3px rgba(130, 83, 93, 0.2);
}
```

### Modals

```css
.modal-overlay {
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
}

.modal {
  background: white;
  border-radius: 16px;
  padding: 32px;
  box-shadow: var(--shadow-xl);
  max-width: 500px;
  width: 90%;
}
```

---

## Style Guidelines

**Style:** Glassmorphism

**Keywords:** Frosted glass, transparent, blurred background, layered, vibrant background, light source, depth, multi-layer

**Best For:** Modern SaaS, financial dashboards, high-end corporate, lifestyle apps, modal overlays, navigation

**Key Effects:** Backdrop blur (10-20px), subtle border (1px solid rgba white 0.2), light reflection, Z-depth

### Page Pattern

**Pattern Name:** App Store Style Landing

- **Conversion Strategy:** Show real screenshots. Include ratings (4.5+ stars). QR code for mobile. Platform-specific CTAs.
- **CTA Placement:** Download buttons prominent (App Store + Play Store) throughout
- **Section Order:** 1. Hero with device mockup, 2. Screenshots carousel, 3. Features with icons, 4. Reviews/ratings, 5. Download CTAs

---

## Anti-Patterns (Do NOT Use)

- ❌ Excessive animation
- ❌ Dark mode by default

### Additional Forbidden Patterns

- ❌ **Emojis as icons** — Use SVG icons (Heroicons, Lucide, Simple Icons)
- ❌ **Missing cursor:pointer** — All clickable elements must have cursor:pointer
- ❌ **Layout-shifting hovers** — Avoid scale transforms that shift layout
- ❌ **Low contrast text** — Maintain 4.5:1 minimum contrast ratio
- ❌ **Instant state changes** — Always use transitions (150-300ms)
- ❌ **Invisible focus states** — Focus states must be visible for a11y

---

## Pre-Delivery Checklist

Before delivering any UI code, verify:

- [ ] No emojis used as icons (use SVG instead)
- [ ] All icons from consistent icon set (Heroicons/Lucide)
- [ ] `cursor-pointer` on all clickable elements
- [ ] Hover states with smooth transitions (150-300ms)
- [ ] Light mode: text contrast 4.5:1 minimum
- [ ] Focus states visible for keyboard navigation
- [ ] `prefers-reduced-motion` respected
- [ ] Responsive: 375px, 768px, 1024px, 1440px
- [ ] No content hidden behind fixed navbars
- [ ] No horizontal scroll on mobile
