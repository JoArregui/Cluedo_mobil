import 'character.dart';
import 'card.dart';
import 'board_map.dart';
import 'position.dart';

enum GamePhase { rolling, moving, suggesting, refuting, narrative, gameOver }

class CaseSolution {
  final CharacterCard character;
  final WeaponCard weapon;
  final RoomCard room;

  const CaseSolution({
    required this.character,
    required this.weapon,
    required this.room,
  });
}

class ClueGameState {
  final List<PlayerCharacter> players;
  final int currentTurnIndex;
  final CaseSolution solution;
  final GamePhase phase;
  final List<int> lastDiceRoll;
  final int? currentDiceResult;
  final List<ClueCard> totalDeck;
  final List<ClueCard> clueDeck;
  final int? refutingPlayerIndex;
  final List<ClueCard>? currentSuggestion;
  final BoardMap boardMap;
  final RoomCard? currentRoomForNarrative;
  final Map<String, Position> weaponPositions;

  const ClueGameState({
    required this.players,
    required this.currentTurnIndex,
    required this.solution,
    required this.phase,
    required this.totalDeck,
    required this.clueDeck,
    required this.boardMap,
    this.lastDiceRoll = const [0, 0],
    this.currentDiceResult,
    this.refutingPlayerIndex,
    this.currentSuggestion,
    this.currentRoomForNarrative,
    required this.weaponPositions,
  });

  factory ClueGameState.initial({
    required List<ClueCard> totalDeck,
    required List<ClueCard> clueDeck,
    required List<ClueCard> envelope,
    required BoardMap boardMap, // Añadido
    required Map<String, Position> weaponPositions,
  }) {
    final character = envelope.firstWhere((c) => c.type == CardType.character) as CharacterCard;
    final weapon = envelope.firstWhere((c) => c.type == CardType.weapon) as WeaponCard;
    final room = envelope.firstWhere((c) => c.type == CardType.room) as RoomCard;

    return ClueGameState(
      players: const [],
      currentTurnIndex: 0,
      solution: CaseSolution(character: character, weapon: weapon, room: room),
      phase: GamePhase.rolling,
      totalDeck: totalDeck,
      clueDeck: clueDeck,
      boardMap: boardMap,
      weaponPositions: weaponPositions,
    );
  }

  PlayerCharacter get currentCharacter => players[currentTurnIndex];

  ClueGameState copyWith({
    List<PlayerCharacter>? players,
    int? currentTurnIndex,
    CaseSolution? solution,
    GamePhase? phase,
    List<int>? lastDiceRoll,
    int? currentDiceResult,
    List<ClueCard>? totalDeck,
    List<ClueCard>? clueDeck,
    int? refutingPlayerIndex,
    List<ClueCard>? currentSuggestion,
    BoardMap? boardMap,
    Map<String, Position>? weaponPositions,
    RoomCard? currentRoomForNarrative,
  }) {
    return ClueGameState(
      players: players ?? this.players,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      solution: solution ?? this.solution,
      phase: phase ?? this.phase,
      lastDiceRoll: lastDiceRoll ?? this.lastDiceRoll,
      currentDiceResult: currentDiceResult ?? this.currentDiceResult,
      totalDeck: totalDeck ?? this.totalDeck,
      clueDeck: clueDeck ?? this.clueDeck,
      refutingPlayerIndex: refutingPlayerIndex ?? this.refutingPlayerIndex,
      currentSuggestion: currentSuggestion ?? this.currentSuggestion,
      boardMap: boardMap ?? this.boardMap,
      weaponPositions: weaponPositions ?? this.weaponPositions,
      currentRoomForNarrative: currentRoomForNarrative ?? this.currentRoomForNarrative,
    );
  }
}