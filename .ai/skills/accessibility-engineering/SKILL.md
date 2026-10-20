---
name: accessibility-engineering
description: Ensure first-class screen reader support, WCAG AAA contrast, and multi-channel sensory design.
version: 1.0.0
---

# Accessibility Engineering Skill

## 1. Domain Ownership & Boundaries
- **Primary Packages:** `packages/nodalis_ui/lib/src/accessibility`, board semantics wrappers.
- **Direct Upstream Dependencies:** `nodalis_domain`.
- **Direct Downstream Consumers:** `nodalis_app` presentation layer.

## 2. Hard Architectural Invariants
1. **Never Encode State Exclusively by Color:** Every visual status change (satisfied capacity, invalid move, selected node) must also be conveyed through shape, pattern, icon, tactile feedback, or screen reader announcements.
2. **Minimum Touch Targets:** Interactive island regions must meet or exceed **48×48dp** (WCAG 2.5.5 / 2.5.8), regardless of visual node radius.
3. **Screen Reader Parity:** The puzzle canvas must provide an accessible `Semantics` tree for TalkBack (Android), VoiceOver (iOS/macOS), and Web screen readers.
4. **Reduced Motion:** If `MediaQuery.disableAnimations` is true, all movement transitions must instantly jump to their target state with 0ms duration.
5. **Full Keyboard Playability:** Arrow navigation, Space/Enter selection, and numeric bridge setting must allow 100% of the game to be played without a mouse or touch screen.

## 3. Operational Recipes & Code Patterns
- Generate dynamic semantic labels: `"Island at row {r}, column {c}. Target: {target} bridges. {current} connected."`
- Use live region announcements (`SemanticsService.announce`) for move confirmations and rejections.
- Maintain WCAG 2.1 AAA contrast for critical typography and WCAG AA for game elements.

## 4. Verification & Testing Checklist
- [ ] TalkBack / VoiceOver test: Navigate and solve Chapter 1 Level 1 eyes-free.
- [ ] Keyboard navigation test: Complete level using only keyboard controls.
- [ ] High contrast mode verified with automated contrast analyzer.
