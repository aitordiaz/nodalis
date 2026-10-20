# Nodalis Architecture & Module Boundaries

This document defines the architectural boundaries, dependency rules, and module contracts for Nodalis.

---

## 1. Clean Hexagonal Thinking for Games

```
┌────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                   │
│   Flutter Shell • Canvas Painter • Accessibility Tree  │
└───────────────────────────┬────────────────────────────┘
                            │ Dispatches Commands / Subscribes
┌───────────────────────────▼────────────────────────────┐
│                    APPLICATION LAYER                   │
│   GameSessionNotifier • Command History • Persistence  │
└───────────────────────────┬────────────────────────────┘
                            │ Calls Pure Functions
┌───────────────────────────▼────────────────────────────┐
│                      DOMAIN CORE                       │
│    Board • Island • Bridge • RulesEngine • Failures    │
└────────────────────────────────────────────────────────┘
```

### Dependency Rules:
1. **Domain Core (`nodalis_domain`):**
   - Pure Dart only.
   - Zero framework dependencies.
   - Exposes immutable entities and pure transition functions.
2. **Level Format (`nodalis_level_format`):**
   - Depends only on `nodalis_domain`.
   - Handles schema validation and JSON serialization.
3. **Solver & Validator (`nodalis_solver`):**
   - Depends on `nodalis_domain` and `nodalis_level_format`.
   - Executes constraint satisfaction and uniqueness proofs.
4. **UI Design System (`nodalis_ui`):**
   - Reusable widgets, typography, themes, canvas painters.
5. **App Shell (`nodalis_app`):**
   - The concrete assembly combining Riverpod, storage, routing, and platform channels.

---

## 2. Determinism & Immutability

All puzzle states are modeled as immutable value objects:
```dart
Result<Board, DomainFailure> newBoard = currentBoard.applyAction(
  CycleBridgeAction(fromId: 1, toId: 2),
);
```

Undo/Redo is implemented via the Command Pattern, recording action records in a history stack rather than cloning the entire application state.
