import 'package:cluedo_mobil/features/game/domain/entities/board_map.dart';
import 'package:cluedo_mobil/features/game/domain/entities/card.dart';
import 'package:cluedo_mobil/features/game/domain/entities/character.dart';
import 'package:cluedo_mobil/features/game/domain/entities/position.dart';
import 'package:cluedo_mobil/features/game/domain/entities/state_game.dart';
import 'package:cluedo_mobil/features/game/presentation/bloc/suggestion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the current room as the suggested room when making a suggestion', () {
    const boardMap = BoardMap();
    final suggestionService = SuggestionService();

    final player = PlayerCharacter(
      isBot: false,
      position: const Position(x: 3, y: 2, roomId: 'study'),
      hand: const [],
      card: CharacterCard(
        id: 'scarlett',
        nameEs: 'Scarlett',
        nameEn: 'Scarlett',
        hexColor: '#FF0000',
      ),
    );

    final gameState = ClueGameState(
      players: [player],
      currentTurnIndex: 0,
      solution: const CaseSolution(
        character: CharacterCard(
          id: 'mustard',
          nameEs: 'Mustard',
          nameEn: 'Mustard',
          hexColor: '#FFD700',
        ),
        weapon: WeaponCard(
          id: 'revolver',
          nameEs: 'Revólver',
          nameEn: 'Revolver',
        ),
        room: RoomCard(id: 'hall', nameEs: 'Hall', nameEn: 'Hall'),
      ),
      phase: GamePhase.rolling,
      totalDeck: const [],
      clueDeck: const [],
      boardMap: boardMap,
      weaponPositions: const {},
    );

    final result = suggestionService.makeSuggestion(
      state: gameState,
      suspect: const CharacterCard(
        id: 'green',
        nameEs: 'Green',
        nameEn: 'Green',
        hexColor: '#00FF00',
      ),
      weapon: const WeaponCard(
        id: 'candlestick',
        nameEs: 'Candelabro',
        nameEn: 'Candlestick',
      ),
    );

    final roomCard = result.gameState.currentSuggestion?.last;
    expect(roomCard, isNotNull);
    expect(roomCard!.id, 'study');
    expect(result.gameState.phase, GamePhase.refuting);
  });
}
