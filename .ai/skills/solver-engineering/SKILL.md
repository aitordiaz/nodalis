---
name: solver-engineering
description: Implement formal verification, uniqueness proofs, and human-like deductive hint engines.
version: 1.0.0
---

# Solver Engineering Skill

## 1. Domain Ownership & Boundaries
- **Primary Packages:** `packages/nodalis_solver`
- **Direct Upstream Dependencies:** `nodalis_domain`, `nodalis_level_format`.
- **Direct Downstream Consumers:** `tools/nodalis_cli`, `nodalis_app` (hint controller).

## 2. Hard Architectural Invariants
1. **Uniqueness Proofs:** Headless level verification must guarantee $N=1$ satisfying assignments via backtracking constraint search before any level is marked production-ready.
2. **Deductive Hints:** In-game hints must never reveal arbitrary backtrack guesses. Every hint must map to an explainable human deduction rule:
   - Saturated neighbors (e.g. corner island requiring capacity 3).
   - Island remainder forced bridge.
   - Subgraph isolation prevention (avoiding premature closed circuits).
3. **Decoupled from Presentation:** Solvers run headlessly in CI and in Flutter isolates without importing UI widgets.

## 3. Operational Recipes & Code Patterns
- Use constraint propagation to reduce candidate domains prior to recursive branching.
- Sort candidate branches deterministically (e.g., lowest remaining freedom first).
- Collect telemetry during solving (search depth, branch factor) to calibrate difficulty tier tags.

## 4. Verification & Testing Checklist
- [ ] Solver correctly finds all solutions on known multi-solution puzzle fixtures.
- [ ] Solver rejects invalid or over-constrained levels.
- [ ] Solves handcrafted levels (< 15x15) in under 50ms.
