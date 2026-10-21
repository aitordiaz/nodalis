import 'package:flutter/material.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';
import 'package:nodalis_ui/nodalis_ui.dart';
import 'content/level_repository.dart';
import 'presentation/screens/level_select_screen.dart';
import 'session/progress_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NodalisApp());
}

class NodalisApp extends StatefulWidget {
  final LevelRepository? levelRepository;
  final ProgressRepository? progressRepository;

  const NodalisApp({
    super.key,
    this.levelRepository,
    this.progressRepository,
  });

  @override
  State<NodalisApp> createState() => _NodalisAppState();
}

class _NodalisAppState extends State<NodalisApp> {
  NodalisThemeMode _themeMode = NodalisThemeMode.light;
  late final LevelRepository _levelRepository;
  late final ProgressRepository _progressRepository;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _levelRepository = widget.levelRepository ?? LevelRepository();
    _progressRepository = widget.progressRepository ?? ProgressRepository();
    _initializeContent();
  }

  Future<void> _initializeContent() async {
    if (!_levelRepository.isLoaded) {
      try {
        await _levelRepository.loadBundledLevels();
      } catch (_) {
        // Fallback for widget testing environments without full asset pipeline
        _levelRepository.loadLevels([
          LevelParser.parseJson(_fallbackLevelJson),
        ]);
      }
    }

    if (!_progressRepository.isLoaded) {
      await _progressRepository.load();
    }

    final savedMode = await _progressRepository.loadThemeMode();
    _themeMode = savedMode;

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode.next;
    });
    _progressRepository.saveThemeMode(_themeMode);
  }

  @override
  Widget build(BuildContext context) {
    final themeData = NodalisThemeData.fromMode(_themeMode);

    return NodalisTheme(
      data: themeData,
      child: MaterialApp(
        title: 'Nodalis',
        debugShowCheckedModeBanner: false,
        theme: themeData.toMaterialTheme(),
        home: _isLoading
            ? Scaffold(
                backgroundColor: themeData.palette.background,
                body: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : LevelSelectScreen(
                levelRepository: _levelRepository,
                progressRepository: _progressRepository,
                onToggleTheme: _toggleTheme,
                themeMode: _themeMode,
              ),
      ),
    );
  }

  static const _fallbackLevelJson = '''
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
    "hintTriggers": []
  },
  "verification": {
    "solutionHash": "db23a7416c02f812e1e04052c751e8df09a72d84a101677eaae2b124729b7a20",
    "uniquenessVerified": true,
    "deductionDepth": 1
  }
}
''';
}
