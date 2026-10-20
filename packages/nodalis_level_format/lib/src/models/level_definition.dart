import 'package:meta/meta.dart';
import 'package:nodalis_domain/nodalis_domain.dart';

/// Difficulty tier classification for handcrafted and generated levels.
enum DifficultyTier {
  introductory('introductory'),
  easy('easy'),
  medium('medium'),
  hard('hard'),
  master('master');

  final String value;
  const DifficultyTier(this.value);

  static DifficultyTier fromString(String raw) =>
      DifficultyTier.values.firstWhere(
        (e) => e.value.toLowerCase() == raw.toLowerCase(),
        orElse: () => DifficultyTier.medium,
      );
}

/// Metadata describing a puzzle level.
@immutable
final class LevelMetadata {
  final String titleKey;
  final String author;
  final DifficultyTier difficultyTier;
  final int estimatedSolveTimeSeconds;
  final int parMoves;
  final List<String> mechanics;

  const LevelMetadata({
    required this.titleKey,
    required this.author,
    required this.difficultyTier,
    required this.estimatedSolveTimeSeconds,
    required this.parMoves,
    required this.mechanics,
  });
}

/// Hint trigger condition for guided onboarding.
@immutable
final class HintTrigger {
  final String triggerCondition;
  final String semanticTextKey;
  final List<int> highlightIslandIds;

  const HintTrigger({
    required this.triggerCondition,
    required this.semanticTextKey,
    required this.highlightIslandIds,
  });
}

/// Onboarding and tutorial metadata.
@immutable
final class LevelTutorial {
  final bool hasInteractiveTutorial;
  final List<HintTrigger> hintTriggers;

  const LevelTutorial({
    required this.hasInteractiveTutorial,
    required this.hintTriggers,
  });
}

/// Level verification data calculated by the solver.
@immutable
final class LevelVerification {
  final String solutionHash;
  final bool uniquenessVerified;
  final int deductionDepth;

  const LevelVerification({
    required this.solutionHash,
    required this.uniquenessVerified,
    required this.deductionDepth,
  });
}

/// Canonical, immutable level definition model.
@immutable
final class LevelDefinition {
  final String id;
  final int version;
  final int chapterId;
  final int indexInChapter;
  final LevelMetadata metadata;
  final int gridWidth;
  final int gridHeight;
  final List<Island> islands;
  final LevelTutorial tutorial;
  final LevelVerification? verification;

  const LevelDefinition({
    required this.id,
    required this.version,
    required this.chapterId,
    required this.indexInChapter,
    required this.metadata,
    required this.gridWidth,
    required this.gridHeight,
    required this.islands,
    required this.tutorial,
    this.verification,
  });

  /// Instantiates an initial un-played [Board] for this level.
  Board toInitialBoard() => Board.initial(
        width: gridWidth,
        height: gridHeight,
        islands: islands,
      );
}
