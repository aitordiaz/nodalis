# Nodalis CI/CD Documentation

Nodalis uses GitHub Actions as its sole CI/CD engine.

---

## 1. Local Parity Checks

Before opening a pull request, run the exact suite executed in CI:

```bash
# Format check
dart format --output=none --set-exit-if-changed .

# Static analyzer
dart analyze --fatal-infos

# Unit tests
dart test packages/nodalis_domain packages/nodalis_level_format

# Level validation
dart run tools/nodalis_cli/bin/nodalis.dart validate-all --dir=levels/
```

---

## 2. GitHub Actions Workflows

*   `.github/workflows/ci.yml`: Runs on PRs and pushes to `main`. Executes static analysis, unit tests, and level verification.
*   `.github/workflows/level-validation.yml`: Runs nightly at 03:00 UTC and on changes to `levels/**` to prevent content regressions.
*   `.github/workflows/release-web.yml`: Builds Flutter Web WASM and deploys to GitHub Pages.
