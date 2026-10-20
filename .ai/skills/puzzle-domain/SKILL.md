---
name: puzzle-domain
description: Safeguard mathematical correctness, immutability, and deterministic rules for Nodalis.
version: 1.0.0
---

# Puzzle Domain Skill

## 1. Domain Ownership & Boundaries
- **Primary Packages:** `packages/nodalis_domain`
- **Direct Upstream Dependencies:** Standard Dart SDK only (zero external libraries).
- **Direct Downstream Consumers:** `nodalis_level_format`, `nodalis_solver`, `nodalis_ui`, `nodalis_app`.

## 2. Hard Architectural Invariants
1. **Zero External Frameworks:** Never import `package:flutter`, `dart:ui`, `flutter_riverpod`, or any I/O library in `nodalis_domain`.
2. **Immutable State Transitions:** Every move transition must be pure: `Board.applyAction(BoardAction) -> Result<Board, DomainFailure>`.
3. **Deterministic Evaluation:** Hashi invariants (orthogonal connectivity, capacity checks, planar non-crossing, single connected component) must evaluate deterministically without side effects or stochastic RNG.
4. **Canonical Key Normalization:** Undirected bridges between islands $A$ and $B$ must always normalize key ordering such that `islandAId < islandBId`.

## 3. Operational Recipes & Code Patterns
- Always use `Result<T, DomainFailure>` instead of throwing runtime exceptions for user gameplay actions.
- Use pattern matching on sealed classes (`BoardAction`, `DomainFailure`) to guarantee exhaustive branch handling.
- Verify connected components using BFS/DFS across active bridge endpoints.

## 4. Verification & Testing Checklist
- [ ] 100% test coverage on all entities and rules engine methods.
- [ ] Property tests verifying that replaying a valid move list reproduces identical board hash.
- [ ] Zero linter warnings with strict inference and strict casts enabled.
