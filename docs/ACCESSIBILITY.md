# Nodalis Accessibility Blueprint

Accessibility is an architectural priority in Nodalis, not a post-launch add-on.

---

## 1. Core Principles

1.  **Multi-Channel Status Signaling:** Never encode puzzle status solely through color. Island saturation and bridge counts are visually represented by geometric shapes, distinct outlines, and numeric labels, alongside haptic and acoustic feedback.
2.  **Screen Reader Parity:** The puzzle board canvas is covered by an accessible `Semantics` widget tree. Every island announces its coordinates, capacity, and current connection status.
3.  **Motor Ergonomics:** Every interactive island has a minimum touch target area of **48×48dp** (WCAG 2.5.5 / 2.5.8), with configurable snap thresholds.
4.  **Reduced Motion Support:** When system animations are disabled, transitions execute instantly (0ms) without jarring motion.
5.  **Full Keyboard Playability:** Full navigation and solving capabilities via arrow keys, Space/Enter, and number keys.
