import 'card.dart';

class BotMemory {
  final String botPlayerId;
  // Mapa que asocia cada Card ID con un booleano: true = descartada (el bot sabe quién la tiene o la tiene él)
  final Map<String, bool> checkedCards;

  BotMemory({
    required this.botPlayerId,
    Map<String, bool>? checkedCards,
  }) : checkedCards = checkedCards ?? {};

  BotMemory copyWith({Map<String, bool>? checkedCards}) {
    return BotMemory(
      botPlayerId: botPlayerId,
      checkedCards: checkedCards ?? Map.from(this.checkedCards),
    );
  }

  /// Inicializa la memoria del bot añadiendo sus propias cartas como descartadas
  void initializeWithHand(List<ClueCard> hand) {
    for (var card in hand) {
      checkedCards[card.id] = true;
    }
  }

  /// Anota en la memoria que una carta ha sido descubierta/descartada del misterio
  void markAsChecked(String cardId) {
    checkedCards[cardId] = true;
  }

  /// El bot filtra una lista de cartas y se queda solo con las que todavía son sospechosas
  List<ClueCard> filterUnknown(List<ClueCard> pool) {
    return pool.where((card) => checkedCards[card.id] != true).toList();
  }
}