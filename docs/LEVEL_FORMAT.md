# Nodalis Level Format Specification

Nodalis levels are stored as canonical, human-readable JSON files in `levels/chapter_XX/` validated against `levels/schemas/level.schema.json`.

---

## 1. Schema Overview

Each level file conforms to the following structure:

```json
{
  "$schema": "../schemas/level.schema.json",
  "id": "ch01_01_first_steps",
  "version": 1,
  "chapterId": 1,
  "indexInChapter": 1,
  "metadata": {
    "titleKey": "level_01_01_title",
    "author": "Aitor Diaz",
    "difficultyTier": "introductory",
    "estimatedSolveTimeSeconds": 30,
    "parMoves": 2,
    "mechanics": ["single_bridge"]
  },
  "grid": {
    "width": 5,
    "height": 5
  },
  "islands": [
    { "id": 1, "x": 1, "y": 2, "capacity": 1 },
    { "id": 2, "x": 3, "y": 2, "capacity": 1 }
  ],
  "tutorial": {
    "hasInteractiveTutorial": true,
    "hintTriggers": [
      {
        "triggerCondition": "on_start",
        "semanticTextKey": "tutorial_drag_to_connect",
        "highlightIslandIds": [1, 2]
      }
    ]
  },
  "verification": {
    "solutionHash": "d5e89a23f4b67e1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a",
    "uniquenessVerified": true,
    "deductionDepth": 1
  }
}
```

---

## 2. Validation Rules

1. **Grid Coordinates:** Island `x` must be in `0 <= x < grid.width` and `y` in `0 <= y < grid.height`.
2. **No Duplicate Positions:** Two islands cannot share the same `(x, y)` coordinate.
3. **No Duplicate IDs:** Island IDs must be unique positive integers.
4. **Capacity:** Island `capacity` must be between 1 and 8.
5. **Solvability & Uniqueness:** Every level must have exactly one unique solution verified by the solver before release.
