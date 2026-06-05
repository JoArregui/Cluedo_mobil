import 'card.dart';
import 'position.dart';

class PlayerCharacter {
  final CharacterCard card;
  final Position position;
  final List<ClueCard> hand;
  final bool isBot;
  final bool isEliminated; // Añadido para la gestión de penalizaciones

  const PlayerCharacter({
    required this.card,
    required this.position,
    required this.hand,
    required this.isBot,
    this.isEliminated = false, // Por defecto entra activo a la mansión
  });

  PlayerCharacter copyWith({
    CharacterCard? card,
    Position? position,
    List<ClueCard>? hand,
    bool? isBot,
    bool? isEliminated,
  }) {
    return PlayerCharacter(
      card: card ?? this.card,
      position: position ?? this.position,
      hand: hand ?? this.hand,
      isBot: isBot ?? this.isBot,
      isEliminated: isEliminated ?? this.isEliminated,
    );
  }
}