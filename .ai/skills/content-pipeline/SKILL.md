---
name: content-pipeline
description: Manage level schema enforcement, level authoring, and automated headless CI validation.
version: 1.0.0
---

# Content Pipeline Skill

## 1. Domain Ownership & Boundaries
- **Primary Packages:** `levels/`, `packages/nodalis_level_format`, `tools/nodalis_cli`.
- **Direct Upstream Dependencies:** `nodalis_domain`.
- **Direct Downstream Consumers:** CI automation, game asset bundle.

## 2. Hard Architectural Invariants
1. **Canonical JSON Storage:** Handcrafted levels are authored and saved exclusively in `levels/chapter_XX/` adhering to `levels/schemas/level.schema.json`.
2. **Pre-Merge Validation:** No level file may be merged into `main` without passing `dart run tools/nodalis_cli/bin/nodalis.dart validate-all`.
3. **Immutability & Stability:** Schema updates must be backwards-compatible or introduce explicit incremented schema versions.
4. **Metadata Completeness:** Every level must specify difficulty tier, estimated solve time, par moves, and mechanic tags.

## 3. Operational Recipes & Code Patterns
- Use `tools/nodalis_cli` to validate syntax, duplicate coordinates, out-of-bounds nodes, and graph solvability.
- When creating new chapters, increment the chapter index and verify difficulty pacing.

## 4. Verification & Testing Checklist
- [ ] Schema validation passes on all JSON files.
- [ ] No duplicate island positions or IDs.
- [ ] All levels have valid solution hashes.
