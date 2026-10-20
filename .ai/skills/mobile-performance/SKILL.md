---
name: mobile-performance
description: Optimize runtime frame pacing, memory allocation, and zero-idle battery consumption.
version: 1.0.0
---

# Mobile Performance & Battery Optimization Skill

## 1. Domain Ownership & Boundaries
- **Primary Packages:** `packages/nodalis_ui`, `apps/nodalis_app/lib/presentation/board`
- **Direct Upstream Dependencies:** `nodalis_domain`.
- **Direct Downstream Consumers:** Mobile (iOS/Android) and Web runtime shells.

## 2. Hard Architectural Invariants
1. **0 FPS Idle Rule:** When the player is not actively touching the screen or watching an animated transition, frame rate must be exactly **0 FPS**. No continuous tickers, infinite ambient particle loops, or unthrottled redraw callbacks.
2. **Zero Allocation in Paint Loops:** The `CustomPainter.paint(Canvas, Size)` method must allocate **0 objects** on the heap. All `Paint`, `Path`, and `TextPainter` instances must be allocated once and cached in state.
3. **Bound Animation Durations:**
   - Bridge placement feedback: max 150ms.
   - Undo/Redo rollback: max 100ms.
   - Level completion wave: max 600ms, followed by immediate return to idle.
4. **Isolate Heavy Operations:** Level parsing and solver hint generation must execute on background threads/isolates if board size exceeds 12x12 or duration exceeds 16ms.

## 3. Operational Recipes & Code Patterns
- Wrap the board canvas in `RepaintBoundary` to decouple board painting from navigation and UI chrome.
- Implement `CustomPainter.shouldRepaint` with strict reference equality checks on immutable ViewModels.
- Cache layout coordinates (island center offsets and hitboxes) on size changes in `LayoutBuilder`.

## 4. Verification & Testing Checklist
- [ ] DevTools Performance Profile: Raster thread time < 8ms during dragging on mid-range hardware.
- [ ] 0 frames scheduled during 30 seconds of board idle.
- [ ] Memory footprint remains steady (< 45MB) over 30 minutes of continuous gameplay.
