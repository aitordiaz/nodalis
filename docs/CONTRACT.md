# Nodalis: Technical & Product Kickoff Specification
**Project:** Nodalis — Premium Logic Puzzle Game  
**Repository:** [https://github.com/aitordiaz/nodalis](https://github.com/aitordiaz/nodalis)  
**Target Platforms:** Mobile (iOS, Android) & Web (Shared Codebase)  
**Classification:** Internal Engineering Blueprint & Execution Roadmap  

---

## 1. Final Technical Choice

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                              │
│       Flutter Stable Channel (iOS / Android / Web WASM)                │
│    UI Shell: Standard Retained Widgets  │  Board: Reactive CustomPainter│
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ State bindings (Riverpod)
┌───────────────────────────────────▼────────────────────────────────────┐
│                        APPLICATION LAYER                               │
│       Session Orchestration • Undo/Redo • Progress • Settings          │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Domain ports
┌───────────────────────────────────▼────────────────────────────────────┐
│                    PUZZLE DOMAIN & ENGINE (Pure Dart)                  │
│       Zero Framework Dependencies • 100% Deterministic & Immutable     │
│   Rules Engine  │  Level Schema  │  SAT/Deduction Solver  │  Validator │
└────────────────────────────────────────────────────────────────────────┘
```

### 1.1 Architecture & Stack Decisions

*   **Language & Runtime:** Pure Dart 3 (targeting native AOT for iOS/Android and WASM/JS for Web). Dart 3's records, pattern matching, class modifiers (`sealed`, `final`, `interface`), and strict typing enable exhaustive state machines and zero-allocation value types.
*   **Engine / Framework:** **Flutter (Stable channel) without any third-party game engine** (e.g., no Flame, Unity, or Godot). A turn-based spatial logic puzzle is fundamentally an event-driven application. Game engines force an active, continuous game loop (60–120 updates/second) that wastes CPU/GPU cycles, drains battery, and degrades thermal performance while the player thinks.
*   **Rendering Model:** **Event-Driven Reactive Canvas Rendering**. 
    *   The application shell (menus, navigation, dialogs, overlays) uses standard Flutter retained-mode widgets.
    *   The puzzle board utilizes an isolated, boundary-wrapped `CustomPainter` inside a `RepaintBoundary`. Repaints occur **strictly** on state changes (node tapped, bridge extended, undo triggered) or during short, discrete micro-animations (120–180ms transitions). When idle, redraw frequency is **0 frames per second**.
*   **State Management:** **Riverpod (Pure Notifiers / Code-generation variant)**. Clean separation between domain models and UI state. Domain models remain 100% independent of Riverpod, which serves solely as the application-layer dependency injection and state-binding pipeline.
*   **Platform Strategy:** **Single Shared Codebase from Day One**. 
    *   The core domain, level format, solver, session management, and UI components compile identically across mobile and web targets.
    *   Web is treated as a continuous build target from Day 1 to prevent platform drift, but UX and performance tuning are **mobile-first** (portrait touch ergonomics, haptic feedback, native power profiles).
    *   Web deployment uses the Flutter Web **WASM compilation target** (`--wasm`) with CanvasKit/Skwasm fallback for maximum rendering fidelity.
*   **Testing Stack:**
    *   Domain/Solver: Pure `dart test` (high-speed unit, fuzzing, property-based tests).
    *   UI/Presentation: `flutter_test` (widget interaction tests), `golden_toolkit` (pixel-regression visual verification).
    *   Content Validation: Custom CLI tooling running headless in CI.

---

## 2. Repository Structure

Nodalis uses a modular multi-package monorepo powered by native **Dart/Flutter Workspaces** (Dart 3.5+). This avoids third-party tool lock-in while maintaining strict physical compilation boundaries.

### 2.1 Repository Layout

```
nodalis/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                     # PR & Push validation (format, analyze, test, lint)
│   │   ├── release-android.yml        # Build & sign Android App Bundle (AAB)
│   │   ├── release-ios.yml            # Build & sign iOS IPA (macOS runner)
│   │   ├── release-web.yml            # Build WASM web bundle & deploy artifact
│   │   └── level-validation.yml       # Nightly & PR headless validation of all level JSONs
│   ├── dependabot.yml                 # Dependency version bumps
│   └── pull_request_template.md
├── .ai/                               # Specialized AI & developer operational skills
│   └── skills/
│       ├── puzzle-domain/
│       │   └── SKILL.md
│       ├── solver-engineering/
│       │   └── SKILL.md
│       ├── mobile-performance/
│       │   └── SKILL.md
│       ├── accessibility-engineering/
│       │   └── SKILL.md
│       └── content-pipeline/
│           └── SKILL.md
├── apps/
│   └── nodalis_app/                   # Flutter application entry point
│       ├── android/
│       ├── ios/
│       ├── web/
│       ├── lib/
│       │   ├── app/                   # App shell, routing (go_router), global lifecycle
│       │   ├── presentation/          # Screens, controllers, board painter, widgets
│       │   ├── main.dart
│       │   └── main_web.dart
│       ├── test/
│       │   ├── goldens/               # Golden UI tests
│       │   └── widget/                # Screen integration & widget tests
│       └── pubspec.yaml
├── packages/
│   ├── nodalis_domain/                # Pure Dart: Rules, Invariants, Actions, Board Model
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── entities/          # Island, Bridge, Board, Coordinate
│   │   │   │   ├── rules/             # Rule checks (capacity, crossing, isolation)
│   │   │   │   ├── actions/           # Command pattern: AddBridge, RemoveBridge, Cycle
│   │   │   │   └── events/            # Domain events (BoardSolved, BridgePlaced)
│   │   │   └── nodalis_domain.dart
│   │   ├── test/                      # 100% test-covered pure Dart tests
│   │   └── pubspec.yaml
│   ├── nodalis_level_format/          # Pure Dart: JSON Schemas, Serialization, Migrations
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── models/            # LevelDefinition, ChapterDefinition, Metadata
│   │   │   │   └── parser/            # Schema validation & JSON parser
│   │   │   └── nodalis_level_format.dart
│   │   ├── test/
│   │   └── pubspec.yaml
│   ├── nodalis_solver/                # Pure Dart: Deductive & Backtracking SAT Solver
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── deduction/         # Human-like deductive strategies (for hints)
│   │   │   │   ├── search/            # Backtracking constraint solver (uniqueness)
│   │   │   │   └── validator/         # Level solvability and uniqueness verifier
│   │   │   └── nodalis_solver.dart
│   │   ├── test/
│   │   └── pubspec.yaml
│   └── nodalis_ui/                    # Shared Flutter Design System
│       ├── lib/
│       │   ├── src/
│       │   │   ├── tokens/            # Colors, Spacing, Typography, Radii
│       │   │   ├── components/        # Buttons, Modals, Sliders, Chips
│       │   │   ├── themes/            # Dark, Light, High-Contrast palettes
│       │   │   └── accessibility/     # Semantics wrappers, Screen reader helpers
│       │   └── nodalis_ui.dart
│       ├── test/
│       └── pubspec.yaml
├── tools/
│   └── nodalis_cli/                   # Developer CLI: validation, solving, benchmarking
│       ├── bin/
│       │   └── nodalis.dart
│       ├── lib/
│       └── pubspec.yaml
├── levels/
│   ├── schemas/
│   │   └── level.schema.json          # JSON Schema specification for level files
│   ├── chapter_01/                    # Handcrafted levels (JSON)
│   │   ├── 01_first_steps.json
│   │   └── ...
│   ├── chapter_02/
│   └── chapter_03/
├── docs/
│   ├── CONTRACT.md                    # This document
│   ├── ARCHITECTURE.md
│   ├── STANDARDS.md
│   ├── LEVEL_FORMAT.md
│   ├── ACCESSIBILITY.md
│   └── CI.md
├── analysis_options.yaml              # Shared strict static analysis configuration
├── pubspec.yaml                       # Workspace root pubspec
└── README.md
```

### 2.2 Top-Level Folder Constraints

| Folder | Ownership & Scope | Dependency Constraints | Forbidden Contents |
| :--- | :--- | :--- | :--- |
| `packages/nodalis_domain` | Core game rules, entities, and state transitions. | **Zero external dependencies** (standard Dart runtime only). | Never import `flutter`, `dart:ui`, storage engines, or Riverpod. |
| `packages/nodalis_level_format` | Schema parsing, data models, level serialization. | Depends only on `nodalis_domain` and serialization utils. | Never import Flutter widgets, rendering, or audio code. |
| `packages/nodalis_solver` | Proofs, solvability, uniqueness verification, hint deduction. | Depends only on `nodalis_domain` and `nodalis_level_format`. | Never import platform channels, UI widgets, or persistent storage. |
| `packages/nodalis_ui` | Visual tokens, themes, atomic components, accessibility wrappers. | Depends on `flutter`, `nodalis_domain`. | Never import app routers, business session state, or API/network code. |
| `apps/nodalis_app` | Assembly, routing, Riverpod stores, persistent storage, platform channels. | Depends on all workspace packages. | Never place direct business/puzzle logic here. |
| `tools/nodalis_cli` | Offline tooling: headless level linting, solver verification. | Depends on pure Dart packages. | Never import `flutter` (must run on lightweight headless server Dart VM). |
| `levels/` | Level content stored in canonical JSON format. | Validated against `levels/schemas/level.schema.json`. | Never store compiled binaries, engine scenes, or unchecked ad-hoc JSONs. |

---

## 3. Project Skills & Operational Disciplines

To ensure architectural consistency across development cycles and when delegating tasks to autonomous subagents or engineers, we define specialized internal capability tracks ("skills"). These skills reside in the repository under `.ai/skills/<skill-name>/SKILL.md` and serve as living operational manuals.

### 3.1 Skill Catalog

```
.ai/skills/
├── puzzle-domain/
├── solver-engineering/
├── mobile-performance/
├── battery-optimization/
├── accessibility-engineering/
├── ui-design-system/
├── level-design/
├── content-pipeline/
└── cicd-release-engineering/
```

#### Skill 1: `puzzle-domain`
*   **Purpose:** Safeguard mathematical correctness, immutability, and rule determinism.
*   **Scope:** All files in `packages/nodalis_domain`.
*   **Responsibilities:** Graph state transitions, coordinate validation, orthogonal connection checks, bridge capacity constraints, bridge crossing prevention, and game-win detection.
*   **Inputs:** Action commands (`ConnectIslands`, `CycleBridgeCount`), Board state.
*   **Outputs:** New immutable `Board` instance or deterministic `DomainFailure`.
*   **Forbidden:** Any references to Flutter, UI, rendering coordinates, or side effects.

#### Skill 2: `solver-engineering`
*   **Purpose:** Provide formal verification of level solvability, solution uniqueness ($N=1$), and step-by-step human deduction.
*   **Scope:** `packages/nodalis_solver`.
*   **Responsibilities:** Implementing constraint propagation (island saturation, empty neighbor reduction, isolation prevention) and backtracking search. Generating graded hints without revealing the full solution.
*   **Inputs:** `LevelDefinition`.
*   **Outputs:** `ValidationReport`, `SolutionTree`, `NextLogicalHint`.
*   **Forbidden:** Presentation logic, heuristic guesses that cannot be logically explained to a human player.

#### Skill 3: `mobile-performance` & `battery-optimization`
*   **Purpose:** Guarantee zero dropped frames during interaction and near-zero power draw when idle.
*   **Scope:** `packages/nodalis_ui`, `apps/nodalis_app/lib/presentation/board`.
*   **Responsibilities:** Keeping repaint loops event-driven, zero heap allocations during the `CustomPainter.paint` cycle, layout geometry caching, memory leak prevention.
*   **Inputs:** UI specs, gesture streams, device profile metrics.
*   **Outputs:** Verified frame-timeline traces (<8ms per repaint), 0 FPS idle verification.
*   **Forbidden:** Continuous animation loops (`TickerProviderStateMixin` running indefinitely), unconstrained shadow/blur effects.

#### Skill 4: `accessibility-engineering`
*   **Purpose:** Ensure Nodalis is 100% playable via screen readers, switch access, high-contrast displays, and without auditory or chromatic dependency.
*   **Scope:** `packages/nodalis_ui/lib/src/accessibility`, board semantics mappings.
*   **Responsibilities:** Full Semantics tree creation for custom canvas elements, dynamic label updates ("Island 4: 2 of 3 bridges connected"), WCAG 2.1 AAA contrast validation, focus traversal order, reduced motion hooks.
*   **Inputs:** Board geometry, gameplay state, theme tokens.
*   **Outputs:** Accessible DOM on web, accessible native tree on iOS (VoiceOver) and Android (TalkBack).
*   **Forbidden:** Relying on color as the sole indicator of completion or error.

#### Skill 5: `content-pipeline`
*   **Purpose:** Maintain level data integrity, schema migrations, and authoring workflows.
*   **Scope:** `levels/`, `packages/nodalis_level_format`, `tools/nodalis_cli`.
*   **Responsibilities:** JSON schema enforcement, level linting (detecting unreachable islands, duplicate coordinates, non-planar overlaps), difficulty tag calculation.
*   **Inputs:** Raw level authoring files.
*   **Outputs:** Canonical, validated, production-ready level assets bundled into the game.
*   **Forbidden:** Shipping any level to `main` that has not passed headless solver verification.

---

## 4. Module Boundaries & API Contracts

```
[ UI / Presentation Layer ]
       │
       ▼ (Dispatches Commands)
[ Application Layer / GameSessionNotifier ]
       │
       ├─────────────────────────────────┐
       ▼ (Pure Function)                 ▼ (Reads Metadata)
[ Domain: Board.applyAction() ]   [ LevelFormat: Parser ]
       │                                 ▲
       ▼ (Returns new state)             │ (Loads JSON)
[ Immutable BoardState ]          [ Content / Levels ]
       ▲
       │ (Verifies Invariants & Solvability)
[ Solver / Validator Engine ]
```

### 4.1 Domain Core (`packages/nodalis_domain`)

#### Core Value Objects & Entities
All domain models are immutable value objects using Dart 3 records or sealed classes.

```dart
// Coordinate in grid units (0-indexed)
typedef GridPoint = ({int x, int y});

// Bridge state between two nodes
enum BridgeCount {
  none(0),
  single(1),
  double(2);

  final int value;
  const BridgeCount(this.value);
}

// Immutable Island Entity
final class Island {
  final int id;
  final GridPoint position;
  final int requiredBridges;

  const Island({
    required this.id,
    required this.position,
    required this.requiredBridges,
  });
}

// Immutable Bridge Entity (undirected connection between two islands)
final class Bridge {
  final int islandAId;
  final int islandBId;
  final BridgeCount count;

  const Bridge({
    required this.islandAId,
    required this.islandBId,
    required this.count,
  });

  bool get isActive => count != BridgeCount.none;
}
```

#### The Immutable Board Model
```dart
final class Board {
  final int width;
  final int height;
  final Map<int, Island> islands;
  final Map<({int a, int b}), Bridge> bridges;

  const Board({
    required this.width,
    required this.height,
    required this.islands,
    required this.bridges,
  });

  /// Pure transition: applies an action and returns a new Board or DomainFailure
  Result<Board, DomainFailure> applyAction(BoardAction action) {
    return switch (action) {
      AddBridgeAction(:final fromId, :final toId) => _handleAddBridge(fromId, toId),
      CycleBridgeAction(:final fromId, :final toId) => _handleCycleBridge(fromId, toId),
      ClearIslandBridgesAction(:final islandId) => _handleClearBridges(islandId),
    };
  }

  /// Evaluates win condition:
  /// 1. Every island has exactly its required number of bridges.
  /// 2. All connected islands form a single connected component (Spanning Graph).
  /// 3. No bridges cross each other.
  bool get isSolved => RulesEngine.isBoardSolved(this);
}
```

### 4.2 Rules Engine Invariants

1.  **Orthogonality:** Bridges can only be constructed horizontally or vertically along grid axes. Diagonal connections are illegal.
2.  **Planarity (No Crossing):** A bridge between $(x_1, y)$ and $(x_2, y)$ cannot be placed if a vertical bridge between $(x, y_1)$ and $(x, y_2)$ intersects its segment.
3.  **Capacity Constraint:** The sum of bridge counts connected to an island cannot exceed its `requiredBridges` property.
4.  **No Intervening Nodes:** A bridge cannot pass through or skip over an intermediate island along the same axis.
5.  **Graph Connectedness:** The solved state must form a single connected component across all islands (verified via Disjoint-Set Union or Breadth-First Search).

---

## 5. Level Data Design

Levels are stored as human-readable, schema-validated JSON files in `levels/chapter_XX/`. This ensures clean Git diffs, supports automated validation in CI without compiling Flutter, and enables independent level design workflows.

### 5.1 Canonical Level JSON Schema

```json
{
  "$schema": "https://raw.githubusercontent.com/aitordiaz/nodalis/main/levels/schemas/level.schema.json",
  "id": "ch01_07_pinch_point",
  "version": 1,
  "chapterId": 1,
  "indexInChapter": 7,
  "metadata": {
    "titleKey": "level_01_07_title",
    "author": "Aitor Diaz",
    "difficultyTier": "introductory",
    "estimatedSolveTimeSeconds": 90,
    "parMoves": 14,
    "mechanics": ["single_bridge", "double_bridge", "isolation_rule"]
  },
  "grid": {
    "width": 7,
    "height": 9
  },
  "islands": [
    { "id": 1, "x": 1, "y": 1, "capacity": 3 },
    { "id": 2, "x": 5, "y": 1, "capacity": 2 },
    { "id": 3, "x": 1, "y": 5, "capacity": 4 },
    { "id": 4, "x": 3, "y": 5, "capacity": 1 },
    { "id": 5, "x": 5, "y": 5, "capacity": 4 },
    { "id": 6, "x": 1, "y": 8, "capacity": 2 },
    { "id": 7, "x": 5, "y": 8, "capacity": 3 }
  ],
  "tutorial": {
    "hasInteractiveTutorial": false,
    "hintTriggers": [
      {
        "triggerCondition": "idle_30_seconds",
        "semanticTextKey": "hint_01_07_corner_deduction",
        "highlightIslandIds": [1, 2]
      }
    ]
  },
  "verification": {
    "solutionHash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "uniquenessVerified": true,
    "deductionDepth": 2
  }
}
```

---

## 6. Solver and Validator Foundations

The solver module (`packages/nodalis_solver`) serves two distinct purposes:
1.  **Level Validation in CI:** Verifies that a level is mathematically sound, solvable without guessing, and possesses **strictly one unique solution** ($N=1$).
2.  **In-Game Graded Hints:** Executes human-style deductive passes to identify the next logically necessary move when the player is stuck.

---

## 7. Performance & Battery Optimization Architecture

The paramount engineering priority for Nodalis is: **consume virtually zero power while the user is thinking.**

1.  **Zero-Idle Redraw Policy (0 FPS):** Never run a continuous render loop. Tickers and timers are forbidden when the board is at rest. The `CustomPainter` repaints only on state mutations.
2.  **Bounded Micro-Animations:** Capped at 150ms. Win animation capped at 600ms, then idle at 0 FPS.
3.  **Zero-Allocation Painting Loop:** Pre-allocate all `Paint`, `Path`, and `TextStyle` objects outside the paint method.
4.  **Static Geometry Caching:** Calculate island screen coordinates and hitboxes only on layout changes.
5.  **Target Device Performance:** 60 FPS on mid-range Android (Snapdragon 680), <45MB RAM footprint, cold start < 1200ms.

---

## 8. Accessibility Architecture

1.  **Screen Reader Semantics:** VoiceOver / TalkBack tree over the puzzle canvas. Every island has explicit semantic roles, values, and actions.
2.  **Color-Blind Safety:** Never rely solely on color. Distinct shapes, glyphs, and line patterns denote status.
3.  **Touch Targets:** Minimum 48×48dp hitboxes regardless of visual node radius.
4.  **Reduced Motion:** Full support for `disableAnimations`.
5.  **Keyboard Playability:** Full arrow-key navigation and key bindings for web and desktop.

---

## 9. UI Architecture & Screen Systems

Typographic, minimal, calm layout with a dark and light theme palette. Unidirectional data flow via Riverpod. Resilient state persistence and non-punitive hint system.

---

## 10. Engineering Standards & Quality Manual

*   Strict Dart 3 analysis (`strict-casts`, `strict-inference`, `strict-raw-types`).
*   Zero warnings policy.
*   Conventional commits: `feat:`, `fix:`, `refactor:`, `perf:`, `test:`, `ci:`.
*   100% test coverage mandatory for `nodalis_domain` and `nodalis_solver`.

---

## 11. CI/CD Architecture with GitHub Actions

*   `.github/workflows/ci.yml`: PR and push checks (format, analyze, domain tests, UI tests, level validation).
*   `.github/workflows/release-web.yml`: WASM build and deployment to GitHub Pages.
*   `.github/workflows/release-android.yml`: AAB build and signing.
*   `.github/workflows/release-ios.yml`: IPA build and signing.

---

## 12. Development Roadmap

*   Phase 0: Technical Spike (Week 1)
*   Phase 1: Project Bootstrap (Week 1)
*   Phase 2: Playable Prototype (Week 2)
*   Phase 3: Core Gameplay Loop (Week 3)
*   Phase 4: Handcrafted Levels 1–10 (Week 4)
*   Phase 5: 40-Level Milestone (Weeks 5–6)
*   Phase 6: Quality & Accessibility (Week 7)
*   Phase 7: Solver & Hint Engine (Week 8)
*   Phase 8: Web WASM Release (Week 9)

---

## 13. Summary & Implementation Sign-off

This document represents the formal technical contract for Nodalis. All implementation work must adhere to the boundaries, rules, and standards defined herein.
