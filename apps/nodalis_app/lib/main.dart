import 'package:flutter/material.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';
import 'package:nodalis_ui/nodalis_ui.dart';
import 'presentation/screens/gameplay_screen.dart';
import 'session/game_session.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NodalisApp());
}

class NodalisApp extends StatefulWidget {
  const NodalisApp({super.key});

  @override
  State<NodalisApp> createState() => _NodalisAppState();
}

class _NodalisAppState extends State<NodalisApp> {
  bool _isDark = false;
  late final GameSession _session;

  @override
  void initState() {
    super.initState();
    final level = LevelParser.parseJson(_defaultLevelJson);
    _session = GameSession(level: level);
  }

  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = _isDark ? NodalisThemeData.dark : NodalisThemeData.light;

    return NodalisTheme(
      data: themeData,
      child: MaterialApp(
        title: 'Nodalis',
        debugShowCheckedModeBanner: false,
        theme: themeData.toMaterialTheme(),
        home: GameplayScreen(
          session: _session,
          onToggleTheme: _toggleTheme,
          isDark: _isDark,
        ),
      ),
    );
  }

  static const _defaultLevelJson = '''
{
  "\$schema": "../schemas/level.schema.json",
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
''';
}
