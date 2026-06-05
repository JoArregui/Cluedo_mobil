import 'character.dart';
import 'card.dart';

enum GamePhase {
  rolling,
  moving,
  suggesting,
  refuting,
  gameOver
}

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
  final List<ClueCard> totalDeck; // Añadido para mantener la referencia a todas las cartas del CMS
  
  final int? refutingPlayerIndex; 
  final List<ClueCard>? currentSuggestion; 

  const ClueGameState({
    required this.players,
    required this.currentTurnIndex,
    required this.solution,
    required this.phase,
    required this.totalDeck, // Requerido en el constructor estructurado
    this.lastDiceRoll = const [0, 0],
    this.currentDiceResult,
    this.refutingPlayerIndex,
    this.currentSuggestion,
  });

  factory ClueGameState.initial({
    required List<ClueCard> totalDeck,
    required List<ClueCard> envelope,
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
    int? refutingPlayerIndex,
    List<ClueCard>? currentSuggestion,
  }) {
    return ClueGameState(
      players: players ?? this.players,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      solution: solution ?? this.solution,
      phase: phase ?? this.phase,
      lastDiceRoll: lastDiceRoll ?? this.lastDiceRoll,
      currentDiceResult: currentDiceResult ?? this.currentDiceResult,
      totalDeck: totalDeck ?? this.totalDeck,
      refutingPlayerIndex: refutingPlayerIndex ?? this.refutingPlayerIndex,
      currentSuggestion: currentSuggestion ?? this.currentSuggestion,
    );
  }
}