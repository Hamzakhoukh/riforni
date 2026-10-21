# 📐 Riforni Design System & AI Governance Rules

> **IMPORTANT FOR ALL AI ASSISTANTS & DEVELOPERS:**
> These rules are **STRICT & MANDATORY**. Any change that violates the design system, introduces conflicting color palettes, or changes the language will be rejected.

---

## 🎨 1. Single Source of Truth: `lib/theme.dart`
Every single screen, widget, modal, and component **MUST** use tokens from `AppTheme`:
* **Primary Brand Color**: `AppTheme.primary` (`#2563EB` - Electric Cobalt Blue)
  - Used for: Primary buttons, active tabs, highlights, links, focus borders.
  - **FORBIDDEN**: Do NOT use terracotta, brown, orange, purple, or any other color as primary.
* **Canvas Background**: `AppTheme.bgCanvas` (`#F8FAFC` - Slate 50)
  - Used for: `Scaffold.backgroundColor` on every single screen.
* **Surface Background**: `AppTheme.bgSurface` (`#FFFFFF` - Pure White)
  - Used for: Cards, bottom sheets, dialogs, inputs.
* **Borders**:
  - `AppTheme.borderSubtle` (`#E2E8F0` - Slate 200) for standard card borders.
  - `AppTheme.borderMuted` (`#F1F5F9` - Slate 100) for inner dividers.
* **Typography & Text Colors**:
  - `AppTheme.textMain` (`#0F172A` - Slate 900) for titles and primary labels.
  - `AppTheme.textSecondary` (`#475569` - Slate 600) for subtitles and descriptions.
  - `AppTheme.textMuted` (`#94A3B8` - Slate 400) for hints and captions.
  - Font family is strictly **Plus Jakarta Sans** (`GoogleFonts.plusJakartaSans`).

---

## 🟢 2. Semantic Status Colors (Only Use These)
Do not invent random hex colors. Use the official semantic tokens:
* **WhatsApp**: `AppTheme.whatsappGreen` (`#25D366`)
* **Success / Inviato**: `AppTheme.statusSuccess` (`#10B981`)
* **Warning / Da confermare**: `AppTheme.statusWarning` (`#F59E0B`)
* **Danger / Elimina / Annullato**: `AppTheme.statusDanger` (`#EF4444`)

---

## 🇮🇹 3. Language & Tone: 100% Italian
* All user-facing UI text, buttons, alerts, snackbars, and dialogues **MUST BE IN ITALIAN**.
* No language switchers, no English strings, no French strings, no Arabic strings in the UI.
* Keep copy natural, professional, and tailored for Italian restaurant chefs & owners.

---

## 🧩 4. Component Standards
* **Buttons**:
  - Primary button: `ElevatedButton` with `backgroundColor: AppTheme.primary`, min-height 52-56px, `borderRadius: BorderRadius.circular(16)`.
  - Secondary/Outlined: `OutlinedButton` with `borderSide: BorderSide(color: AppTheme.borderSubtle)`, height 46-48px, `borderRadius: BorderRadius.circular(14)`.
* **Cards**:
  - `color: Colors.white`, `borderRadius: BorderRadius.circular(16-20)`, `border: Border.all(color: AppTheme.borderSubtle)`, `boxShadow: AppTheme.cardShadow`.
* **AppBars**:
  - Transparent or `AppTheme.bgCanvas`, `elevation: 0`, `scrolledUnderElevation: 0`, title in `FontWeight.w800`.
* **Bottom Sheets**:
  - Top rounded corners `Radius.circular(24-28)`, white background, safe area padding.

---

## 🚫 5. Strictly Prohibited
1. ❌ **NO hardcoded hex colors** in individual screens (e.g. `Color(0xFF...)` without using `AppTheme`).
2. ❌ **NO multiple competing color themes** (e.g., mixing orange/terracotta buttons on one page and blue on another).
3. ❌ **NO visual regressions**: Before proposing or committing any screen edit, verify that it matches the existing styling of the rest of the app.
