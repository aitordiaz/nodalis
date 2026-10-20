# Nodalis Engineering Standards

This manual establishes development standards, code quality gates, and workflow practices for Nodalis.

---

## 1. Code Quality & Static Analysis

*   **Dart SDK:** `^3.5.0`
*   **Analysis Options:** `analysis_options.yaml` with strict flags enabled:
    *   `strict-casts: true`
    *   `strict-inference: true`
    *   `strict-raw-types: true`
*   **Zero Warnings Policy:** All warnings and informational lints are treated as fatal errors in CI (`dart analyze --fatal-infos`).
*   **Formatting:** Enforced via `dart format --output=none --set-exit-if-changed .`

---

## 2. Git & Commit Protocol

### Branch Strategy
*   Main branch is protected: `main`.
*   Direct pushes to `main` are disallowed; changes require pull requests with passing CI checks.
*   Feature branch format:
    *   `feat/<feature-name>`
    *   `fix/<bug-name>`
    *   `perf/<optimization>`
    *   `content/<chapter-name>`

### Conventional Commits
All commit messages must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:
*   `feat(domain): implement island capacity validation`
*   `fix(ui): resolve gesture detection hit test misalignment`
*   `test(solver): add uniqueness verification tests`
*   `perf(board): eliminate object allocations in custom paint loop`
*   `ci: add nightly level validation workflow`

---

## 3. Testing Standards

*   **Domain & Solver:** 100% test coverage mandatory for `nodalis_domain` and `nodalis_solver`.
*   **Determinism Tests:** Verify that replaying a list of actions reproduces the exact board state.
*   **Property Tests:** Random legal action sequences must maintain graph invariants.
