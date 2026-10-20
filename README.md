# Nodalis

> A modern, premium, calm logic puzzle game designed for focused problem-solving, exceptional performance, and battery efficiency across mobile and web.

[![CI](https://github.com/aitordiaz/nodalis/actions/workflows/ci.yml/badge.svg)](https://github.com/aitordiaz/nodalis/actions/workflows/ci.yml)

---

## Technical & Product Blueprint

Nodalis is engineered as an event-driven, accessible, zero-idle-power puzzle application.
For full details on architecture, engineering standards, and roadmap, see:

*   📖 [**Technical & Product Contract**](docs/CONTRACT.md)
*   🏛️ [**Architecture & Module Boundaries**](docs/ARCHITECTURE.md)
*   📐 [**Level Format Specification**](docs/LEVEL_FORMAT.md)
*   ♿ [**Accessibility Blueprint**](docs/ACCESSIBILITY.md)
*   🚀 [**CI/CD & GitHub Actions**](docs/CI.md)

---

## Workspace Structure

The project is structured as a native multi-package Dart/Flutter monorepo:

*   `apps/nodalis_app`: Flutter application entry point (iOS, Android, Web WASM).
*   `packages/nodalis_domain`: Pure Dart core rules, board entities, immutable state engine.
*   `packages/nodalis_level_format`: Pure Dart schema, serialization, and migration tools.
*   `packages/nodalis_solver`: Constraint satisfaction, uniqueness verification, and hint deduction.
*   `packages/nodalis_ui`: Design tokens, themes, canvas renderers, accessibility semantics.
*   `tools/nodalis_cli`: Offline developer CLI for level linting and solver benchmarking.
*   `levels/`: Handcrafted level definitions in canonical JSON format.
*   `.ai/skills/`: Operational skill guidelines for autonomous agents and engineers.

---

## Development Prerequisites

*   **Dart SDK:** `^3.5.0`
*   **Flutter SDK:** `>=3.24.0` (Stable channel)

### Quick Start

```bash
# Bootstrap workspace dependencies
flutter pub get

# Run all static checks & tests locally
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```
