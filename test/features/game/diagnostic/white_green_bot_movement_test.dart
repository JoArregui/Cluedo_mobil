// Tests que reproducen exactamente el bug del usuario: WHITE y GREEN no se
// mueven visualmente cuando llega su turno.
//
// Hipótesis: el bot está calculando una posición elegida que es igual a su
// posición START, o el path calculado por MovementService es [start] (longitud 1),
// lo que en JS produce "sin animación" y el token se queda quieto.

import 'package:cluedo_mobil/features/game/domain/entities/board_map.dart';
import 'package:cluedo_mobil/features/game/domain/entities/bot_memory.dart';
import 'package:cluedo_mobil/features/game/domain/entities/card.dart';
import 'package:cluedo_mobil/features/game/domain/entities/character.dart';
import 'package:cluedo_mobil/features/game/domain/entities/position.dart';
import 'package:cluedo_mobil/features/game/domain/entities/state_game.dart';
import 'package:cluedo_mobil/features/game/domain/entities/tile_type.dart';
import 'package:cluedo_mobil/features/game/domain/usecases/execute_bot_turn.dart';
import 'package:cluedo_mobil/features/game/domain/usecases/validate_movement.dart';
import 'package:cluedo_mobil/features/game/presentation/bloc/movement_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const boardMap = BoardMap();
  const validateMovement = ValidateMovement(boardMap: boardMap);
  final movementService = MovementService(boardMap: boardMap);
  final executeBotTurn = ExecuteBotTurn(
    validateMovement: validateMovement,
    boardMap: boardMap,
  );

  PlayerCharacter player(String id, Position position, {bool isBot = true}) {
    return PlayerCharacter(
      isBot: isBot,
      position: position,
      hand: const [],
      card: CharacterCard(id: id, nameEs: id, nameEn: id, hexColor: '#FF0000'),
    );
  }

  ClueGameState gameState({
    required List<PlayerCharacter> players,
    required int currentTurnIndex,
    required int? dice,
    GamePhase phase = GamePhase.moving,
  }) {
    return ClueGameState(
      players: players,
      currentTurnIndex: currentTurnIndex,
      solution: const CaseSolution(
        character: CharacterCard(id: 'mustard', nameEs: 'M', nameEn: 'M', hexColor: '#FFD700'),
        weapon: WeaponCard(id: 'revolver', nameEs: 'R', nameEn: 'R'),
        room: RoomCard(id: 'hall', nameEs: 'H', nameEn: 'H'),
      ),
      phase: phase,
      currentDiceResult: dice,
      totalDeck: const [],
      clueDeck: const [],
      boardMap: boardMap,
      weaponPositions: const {},
    );
  }

  group('Bug: WHITE no se mueve desde START', () {
    test('Bot WHITE: elige posición y comprueba que la posición CAMBIA', () {
      final whiteStart = BoardMap.characterStartPositions['white']!;
      final others = [
        player('scarlett', BoardMap.characterStartPositions['scarlett']!, isBot: false),
        player('mustard', BoardMap.characterStartPositions['mustard']!),
        player('green', BoardMap.characterStartPositions['green']!),
        player('peacock', BoardMap.characterStartPositions['peacock']!),
        player('plum', BoardMap.characterStartPositions['plum']!),
      ];
      final whiteIdx = 1; // orden clockwise: scarlett(0), mustard(1), white(2), green(3), peacock(4), plum(5)

      for (int dice = 2; dice <= 12; dice++) {
        final state = gameState(
          players: others,
          currentTurnIndex: whiteIdx,
          dice: dice,
        );

        final mem = BotMemory(botPlayerId: 'white');
        final result = executeBotTurn.call(state: state, botMemory: mem);
        final chosen = result['newPosition'] as Position;
        final start = state.players[whiteIdx].position;

        final changed = !(chosen.x == start.x && chosen.y == start.y && chosen.roomId == start.roomId);
        print('WHITE dice=$dice: start=$start → chosen=$chosen (changed=$changed)');
        expect(changed, isTrue,
            reason: 'WHITE con dado=$dice debe CAMBIAR de posición desde $start. '
                'chosen=$chosen es igual. Esto es exactamente el bug reportado.');
      }
    });
  });

  group('Bug: GREEN no se mueve desde START', () {
    test('Bot GREEN: elige posición y comprueba que la posición CAMBIA', () {
      final greenStart = BoardMap.characterStartPositions['green']!;
      final others = [
        player('scarlett', BoardMap.characterStartPositions['scarlett']!, isBot: false),
        player('mustard', BoardMap.characterStartPositions['mustard']!),
        player('white', BoardMap.characterStartPositions['white']!),
        player('green', greenStart),
        player('peacock', BoardMap.characterStartPositions['peacock']!),
        player('plum', BoardMap.characterStartPositions['plum']!),
      ];
      final greenIdx = 3;

      for (int dice = 2; dice <= 12; dice++) {
        final state = gameState(
          players: others,
          currentTurnIndex: greenIdx,
          dice: dice,
        );

        final mem = BotMemory(botPlayerId: 'green');
        final result = executeBotTurn.call(state: state, botMemory: mem);
        final chosen = result['newPosition'] as Position;
        final start = state.players[greenIdx].position;

        final changed = !(chosen.x == start.x && chosen.y == start.y && chosen.roomId == start.roomId);
        print('GREEN dice=$dice: start=$start → chosen=$chosen (changed=$changed)');
        expect(changed, isTrue,
            reason: 'GREEN con dado=$dice debe CAMBIAR de posición desde $start. '
                'chosen=$chosen es igual. Esto es exactamente el bug reportado.');
      }
    });
  });

  group('Validación: posición final del bot debe tener un path válido', () {
    test('WHITE: para cada dado posible (2-12), el path al destino elegido debe ser ≥2', () {
      final others = [
        player('scarlett', BoardMap.characterStartPositions['scarlett']!, isBot: false),
        player('mustard', BoardMap.characterStartPositions['mustard']!),
        player('white', BoardMap.characterStartPositions['white']!),
        player('green', BoardMap.characterStartPositions['green']!),
        player('peacock', BoardMap.characterStartPositions['peacock']!),
        player('plum', BoardMap.characterStartPositions['plum']!),
      ];
      final whiteIdx = 2;

      for (int dice = 2; dice <= 12; dice++) {
        final state = gameState(
          players: others,
          currentTurnIndex: whiteIdx,
          dice: dice,
        );

        final mem = BotMemory(botPlayerId: 'white');
        final result = executeBotTurn.call(state: state, botMemory: mem);
        final chosen = result['newPosition'] as Position;
        final start = state.players[whiteIdx].position;

        if (chosen.x == start.x && chosen.y == start.y && chosen.roomId == start.roomId) {
          print('WHITE dice=$dice: NO SE MUEVE — start=$start == chosen=$chosen');
          continue;
        }

        final path = movementService.calculateMovementPath(
          start,
          chosen,
          state,
          maxSteps: dice,
        );
        print('WHITE dice=$dice: start=$start → chosen=$chosen, path length=${path.length}');
        expect(path.length, greaterThanOrEqualTo(2),
            reason: 'WHITE dado=$dice: el path de $start a $chosen debe tener al menos origen+destino. '
                'Tiene longitud ${path.length}. Esto causa que el token NO se mueva en pantalla.');
      }
    });

    test('GREEN: para cada dado posible (2-12), el path al destino elegido debe ser ≥2', () {
      final others = [
        player('scarlett', BoardMap.characterStartPositions['scarlett']!, isBot: false),
        player('mustard', BoardMap.characterStartPositions['mustard']!),
        player('white', BoardMap.characterStartPositions['white']!),
        player('green', BoardMap.characterStartPositions['green']!),
        player('peacock', BoardMap.characterStartPositions['peacock']!),
        player('plum', BoardMap.characterStartPositions['plum']!),
      ];
      final greenIdx = 3;

      for (int dice = 2; dice <= 12; dice++) {
        final state = gameState(
          players: others,
          currentTurnIndex: greenIdx,
          dice: dice,
        );

        final mem = BotMemory(botPlayerId: 'green');
        final result = executeBotTurn.call(state: state, botMemory: mem);
        final chosen = result['newPosition'] as Position;
        final start = state.players[greenIdx].position;

        if (chosen.x == start.x && chosen.y == start.y && chosen.roomId == start.roomId) {
          print('GREEN dice=$dice: NO SE MUEVE — start=$start == chosen=$chosen');
          continue;
        }

        final path = movementService.calculateMovementPath(
          start,
          chosen,
          state,
          maxSteps: dice,
        );
        print('GREEN dice=$dice: start=$start → chosen=$chosen, path length=${path.length}');
        expect(path.length, greaterThanOrEqualTo(2),
            reason: 'GREEN dado=$dice: el path de $start a $chosen debe tener al menos origen+destino. '
                'Tiene longitud ${path.length}. Esto causa que el token NO se mueva en pantalla.');
      }
    });
  });

  group('Análisis: vecindad de START de WHITE y GREEN', () {
    test('WHITE (23,15): qué casillas puede alcanzar el bot con cada dado (1-12)', () {
      final start = BoardMap.characterStartPositions['white']!; // (23,15)
      final state = gameState(
        players: [player('white', start, isBot: false)],
        currentTurnIndex: 0,
        dice: 1,
      );

      for (final dice in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]) {
        final s2 = state.copyWith(currentDiceResult: dice);
        final reachable = <String>{};
        for (int x = 0; x < boardMap.columns; x++) {
          for (int y = 0; y < boardMap.rows; y++) {
            final t = boardMap.getTileType(x, y);
            if (t == TileType.walkway) {
              if (validateMovement(gameState: s2, target: Position(x: x, y: y))) {
                reachable.add('$x,$y');
              }
            }
          }
        }
        print('WHITE dado=$dice: ${reachable.length} casillas alcanzables');
        final sorted = reachable.toList()..sort();
        if (reachable.length <= 30) {
          print('   $sorted');
        }
      }
    });

    test('GREEN (9,24): qué casillas puede alcanzar el bot con cada dado (1-12)', () {
      final start = BoardMap.characterStartPositions['green']!; // (9,24)
      final state = gameState(
        players: [player('green', start, isBot: false)],
        currentTurnIndex: 0,
        dice: 1,
      );

      for (final dice in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]) {
        final s2 = state.copyWith(currentDiceResult: dice);
        final reachable = <String>{};
        for (int x = 0; x < boardMap.columns; x++) {
          for (int y = 0; y < boardMap.rows; y++) {
            final t = boardMap.getTileType(x, y);
            if (t == TileType.walkway) {
              if (validateMovement(gameState: s2, target: Position(x: x, y: y))) {
                reachable.add('$x,$y');
              }
            }
          }
        }
        print('GREEN dado=$dice: ${reachable.length} casillas alcanzables');
        final sorted = reachable.toList()..sort();
        if (reachable.length <= 30) {
          print('   $sorted');
        }
      }
    });
  });
}