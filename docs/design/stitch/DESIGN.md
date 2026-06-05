# Design System: Picko 拾影

## 1. Visual Theme & Atmosphere

Picko is a calm Apple-ecosystem photo-decision tool, not a storage-cleanup alarm.
The interface should feel like a private review desk for memory curation: precise,
quiet, trustworthy, and visually warm without becoming decorative.

- **Density:** Daily App Balanced, 5/10. Every screen should support repeated review
  decisions without feeling sparse or ceremonial.
- **Variance:** Offset Asymmetric, 6/10. Use confident asymmetric whitespace, staggered
  media crops, and non-equal content blocks. Avoid chaotic collage layouts.
- **Motion:** Fluid Native, 5/10. Motion should feel weighty and reassuring, never
  theatrical. Review actions may have soft directional transitions, but no bouncing
  attention tricks.

The core product thesis is **keep-first, not delete-first**. UI language, hierarchy,
and color must guide users toward choosing what to keep, with pre-delete actions
presented as reversible review states.

## 2. Color Palette & Roles

Use the Heritage Core palette already captured from Stitch. Keep the palette
consistent across iOS, iPadOS, and macOS screens.

- **Alabaster Canvas** (`#F9F9F7`) — Primary app background. Soft, warm, and
  paper-like; never replace with pure white page chrome.
- **Pure Surface** (`#FFFFFF`) — Cards, rows, inspector panels, modal interiors.
- **Low Surface** (`#F4F4F2`) — Secondary containers, thumbnail fallback wells,
  quiet grouped areas.
- **Container Surface** (`#EEEEEC`) — Segmented controls, neutral pills, nested
  rows, and non-primary action backgrounds.
- **High Surface** (`#E2E3E1`) — Pressed neutral buttons, disabled containers, and
  subtle separation inside cards.
- **Ink Charcoal** (`#1A1C1B`) — Primary text. Never use pure black.
- **Secondary Ink** (`#42474B`) — Metadata, descriptions, helper text, footnotes.
- **Whisper Outline** (`#C2C7CC`) — 1px borders, separators, thumbnail strokes.
- **Midnight Teal** (`#1A3A4A`) — Primary navigation, strong panels, primary action
  fill, selected tab tint.
- **Deep Teal** (`#002434`) — Highest emphasis panels, text over gold accents,
  active-state depth.
- **Soft Teal** (`#C7E7FC`) — Icon wells, selected soft states, primary fill text.
- **Harvest Gold** (`#D4AF37`) — The single accent color. Use for suggested keep,
  recommendation badges, selected keep states, and review confidence.
- **Gold Soft** (`#FED65B`) — Accent fill where Harvest Gold needs brighter legibility.
- **Safety Coral** (`#E88D67`) — Destructive/safety semantic only. It is not a
  decorative accent. Use for pre-delete basket warnings, reversible deletion states,
  and confirmation boundaries.
- **Destructive Red** (`#BA1A1A`) — Error text and irreversible danger emphasis only.

**Color bans:** no neon gradients, no purple/blue AI glow, no pure black, no
oversaturated accents, no random warm/cool gray mixing.

## 3. Typography Rules

- **Display:** Manrope or Satoshi. Use controlled scale, strong weight, and tight but
  not negative tracking. Headlines should feel deliberate, not loud.
- **Body:** Manrope or Satoshi. Minimum 14px on compact surfaces and 16px for reading
  paragraphs. Keep body copy under 65 characters per line.
- **Mono:** JetBrains Mono. Use for counts, byte sizes, dates, benchmark evidence,
  keyboard shortcuts, and compact metadata.
- **Native fallback:** If custom fonts are unavailable, use system rounded for UI
  and system monospaced for metadata. Preserve the same hierarchy.
- **Dashboard rule:** Software UI must stay sans-serif. Do not introduce serif fonts.

Typography should communicate confidence through color and weight, not oversized
hero text. Compact panels, inspectors, and cards must use compact type; reserve
large type for true page-level statements.

## 4. Component Stylings

* **Primary buttons:** Midnight Teal fill, Soft Teal text, 10-14px radius depending
  on platform density. Active state translates down 1px and slightly deepens color.
  No glow shadows.
* **Secondary buttons:** Pure Surface or Container Surface fill, Whisper Outline
  border, Midnight Teal text. Use for restore, skip, undo, and non-destructive tools.
* **Destructive buttons:** Safety Coral or Deep Teal warning containers with explicit
  recovery copy nearby. Destructive actions must never appear without confirmation
  context.
* **Cards:** Radius 14-24px. Use white or low-surface fills with 1px outline. Use
  elevation only when hierarchy needs it; prefer borders and spacing over shadows.
* **Photo thumbnails:** Always have stable aspect ratio and rounded corners. Empty
  thumbnail placeholders use Low Surface with muted image iconography, never gray
  skeleton blocks detached from layout dimensions.
* **Segmented controls:** Use custom capsule segments with Container Surface track
  and Pure Surface selected segment. Selected text is Midnight Teal; unselected text
  is Secondary Ink.
* **Status pills:** Use compact rounded capsules, JetBrains Mono or semibold rounded
  text, and semantic color. Keep badges short.
* **Inspectors:** Dense but quiet. Use label/value rows, compact shortcut chips, and
  custom action buttons. Avoid default bordered system buttons inside designed panels.
* **Loaders:** Use layout-matching skeleton or composed loading panels. Generic
  circular spinners are allowed only as small inline progress indicators beside
  meaningful loading copy.
* **Empty states:** Use composed icon wells, a clear next action, and privacy-safe
  explanatory copy. Never show only "No data".
* **Error states:** Inline, readable, and recoverable. Error text uses Destructive
  Red, with a nearby safe next step.

## 5. Layout Principles

Use grid-first native layouts that respect platform expectations.

- iOS starts with direct task cards and bottom navigation. The first viewport should
  always reveal a real task: Home, single review, similar groups, or basket state.
- macOS uses a native workbench: sidebar, central review surface, and inspector.
  Keep the desktop density useful for keyboard-driven review.
- Avoid generic three-equal-card rows. Metrics may be compact capsules, but workflow
  cards should vary in width, height, color weight, or placement.
- No overlapping text, controls, or media. Every element gets its own spatial zone.
- Contain content with comfortable page padding: 20-24px mobile, 24-32px desktop.
- Use stable dimensions for thumbnails, boards, segmented controls, bottom bars, and
  inspectors so selection states never shift the layout.
- Mobile collapse is single-column under 768px. No horizontal overflow.
- Touch targets are at least 44px. Desktop click targets should remain visibly
  aligned and easy to scan.

## 6. Motion & Interaction

- Use spring physics for review actions: `stiffness: 100`, `damping: 20`.
- Animate via transform and opacity only. Never animate top, left, width, or height.
- Review actions should imply direction: keep can lift or settle upward; pre-delete
  can settle downward into the basket. Keep the movement short and calm.
- Lists and grids should appear with subtle staggered reveals, not instant dumps.
- Active components may have restrained micro-loops: soft shimmer on loading rows,
  gentle pulse on selected recommendations, or tiny opacity breathing on active
  evidence states. No bouncing arrows or decorative loops.
- Haptics, where available, should reinforce decisions: light for selection, medium
  for keep, warning for final Photos confirmation.

## 7. Anti-Patterns (Banned)

- No emojis anywhere.
- No Inter font.
- No generic serif fonts.
- No pure black (`#000000`).
- No neon or outer-glow shadows.
- No purple/blue AI gradient aesthetic.
- No oversaturated accents.
- No excessive gradient text.
- No custom mouse cursors.
- No overlapping elements.
- No generic three-column equal feature rows.
- No fake round proof numbers like `99.99%` or `50%`.
- No generic placeholder brands or people names.
- No AI copywriting clichés such as "Elevate", "Seamless", "Unleash", or "Next-Gen".
- No filler UI text such as "Scroll to explore", "Swipe down", bouncing chevrons, or
  scroll arrows.
- No broken external image links. Use real app thumbnails, local fixtures, generated
  placeholders, or deterministic placeholder assets.
- No delete-first language such as "clean junk" as the primary framing. Use keep,
  review, restore, and confirm.

## 8. Stitch Prompting Notes

When generating new Stitch screens for Picko, explicitly request:

1. Heritage Core palette with Alabaster Canvas, Midnight Teal, Harvest Gold, and
   Safety Coral as defined above.
2. Keep-first photo decision language.
3. Native Apple app surfaces, not a marketing landing page.
4. Stable photo thumbnail grids and reversible pre-delete basket states.
5. No generic cards-only dashboard. Use task hierarchy, media surfaces, and review
   controls that match iOS and macOS workflows.
