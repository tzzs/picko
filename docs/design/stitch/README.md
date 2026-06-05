# Picko Stitch Design Source

This directory captures the Google Stitch design source used for the first Picko iOS UI restyle.

## Project

- Stitch project: `11449372107524085271`
- Title: `Picko 拾影：照片整理助手`
- Device: Mobile
- Design system: `Heritage Core`
- Last read through Stitch MCP: 2026-06-05

## Design System

- Background: Alabaster off-white `#F9F9F7`
- Primary: Midnight teal `#1A3A4A`
- Primary deep: `#002434`
- Keep/accent: Harvest gold `#D4AF37`
- Basket/accent: Muted coral `#E88D67`
- Surface: `#FFFFFF`
- Surface low: `#F4F4F2`
- Outline: `#C2C7CC`
- Intended fonts: Manrope for UI, JetBrains Mono for metadata labels.

The SwiftUI implementation maps these into `Sources/PickoApp/PickoDesignTokens.swift`.
Bundled custom fonts are not included yet, so the app uses system rounded and monospaced faces as the native fallback.

## Stitch Generation Rules

Use `DESIGN.md` in this directory as the semantic design-system prompt when asking
Google Stitch to generate new Picko screens. It expands the Heritage Core palette
into agent-friendly rules for atmosphere, typography, layout, motion, components,
and banned generic UI patterns.

## Screen Exports

The downloaded HTML exports in `export/` are implementation references, not app code:

- `home-zh.html`
- `single-review-zh.html`
- `similar-groups-zh.html`
- `basket-zh.html`

SwiftUI remains the production UI source. Do not import Stitch HTML into the app target.

## Implementation Scope

This pass applies the Stitch visual language to the existing iOS MVP flow:

- Home dashboard
- Single photo review
- Similar group review
- Pre-delete basket

It preserves the existing native `TabView`, navigation titles, model actions, Photos confirmation boundary, and test-facing accessibility labels.
