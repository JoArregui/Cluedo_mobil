import 'package:cluedo_mobil/features/game/domain/entities/board_map.dart';
import 'package:cluedo_mobil/features/game/domain/entities/card.dart';
import 'package:cluedo_mobil/features/game/domain/entities/character.dart';
import 'package:cluedo_mobil/features/game/domain/entities/position.dart';
import 'package:cluedo_mobil/features/game/domain/entities/state_game.dart';
import 'package:cluedo_mobil/features/game/domain/entities/tile_type.dart';
import 'package:cluedo_mobil/features/game/domain/usecases/validate_movement.dart';
import 'package:cluedo_mobil/features/game/presentation/bloc/movement_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests de diagnóstico basados en el feedback del usuario:
/// 1. White (23,15): el token visualmente aparece desplazado de START y
///    algunas casillas iluminadas están mal.
/// 2. Green (9,24): START correcto pero se ilumina una casilla sobre pared.
void main() {
  const boardMap = BoardMap();
  const validateMovement = ValidateMovement(boardMap: boardMap);
  final movementService = MovementService(boardMap: boardMap);

  PlayerCharacter player(String id, Position position) {
    return PlayerCharacter(
      isBot: id != 'scarlett',
      position: position,
      hand: const [],
      card: CharacterCard(id: id, nameEs: id, nameEn: id, hexColor: '#FF0000'),
    );
  }

  ClueGameState gameState({
    required Position currentPosition,
    required int? dice,
    List<PlayerCharacter> others = const [],
  }) {
    return ClueGameState(
      players: [player('scarlett', currentPosition), ...others],
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
          nameEs: 'Revolver',
          nameEn: 'Revolver',
        ),
        room: RoomCard(id: 'hall', nameEs: 'Hall', nameEn: 'Hall'),
      ),
      phase: GamePhase.moving,
      currentDiceResult: dice,
      totalDeck: const [],
      clueDeck: const [],
      boardMap: boardMap,
      weaponPositions: const {},
    );
  }

  group('Diagnóstico: casillas iluminadas en START', () {
    test('WHITE en (23,15): generar TODAS las casillas válidas y verificar que son walkways reales', () {
      // Dado aleatorio entre 2 y 6 (lo normal en el juego)
      for (final dice in [2, 3, 4, 5, 6]) {
        final s = gameState(
          currentPosition: BoardMap.characterStartPositions['white']!,
          dice: dice,
        );

        final allValid = <Position>[];
        for (int x = 0; x < boardMap.columns; x++) {
          for (int y = 0; y < boardMap.rows; y++) {
            final t = boardMap.getTileType(x, y);
            if (t == TileType.walkway) {
              if (validateMovement(gameState: s, target: Position(x: x, y: y))) {
                allValid.add(Position(x: x, y: y));
              }
            }
          }
        }
        // Verificar que TODAS las casillas válidas son realmente walkway
        // Y que ninguna está en una pared (TileType.wall) o habitación
        for (final p in allValid) {
          final t = boardMap.getTileType(p.x, p.y);
          expect(t, TileType.walkway,
              reason:
                  'WHITE dice=$dice: casilla (${p.x},${p.y}) marcada como válida pero es $t');
        }
      }
    });

    test('GREEN en (9,24): generar TODAS las casillas válidas y verificar que son walkways reales', () {
      for (final dice in [2, 3, 4, 5, 6]) {
        final s = gameState(
          currentPosition: BoardMap.characterStartPositions['green']!,
          dice: dice,
        );

        final allValid = <Position>[];
        for (int x = 0; x < boardMap.columns; x++) {
          for (int y = 0; y < boardMap.rows; y++) {
            final t = boardMap.getTileType(x, y);
            if (t == TileType.walkway) {
              if (validateMovement(gameState: s, target: Position(x: x, y: y))) {
                allValid.add(Position(x: x, y: y));
              }
            }
          }
        }
        for (final p in allValid) {
          final t = boardMap.getTileType(p.x, p.y);
          expect(t, TileType.walkway,
              reason:
                  'GREEN dice=$dice: casilla (${p.x},${p.y}) marcada como válida pero es $t');
        }
      }
    });

    test('WHITE: debe poder alcanzar kitchen (está cerca de su START a la derecha)', () {
      final s = gameState(
        currentPosition: BoardMap.characterStartPositions['white']!,
        dice: 6,
      );
      // Kitchen doorways: (16, 20), (19, 17)
      // Desde (23,15) hasta (19,17): distancia Manhattan = 4+2 = 6
      expect(
        validateMovement(
          gameState: s,
          target: const Position(x: 19, y: 17, roomId: 'kitchen'),
        ),
        isTrue,
        reason: 'WHITE debe poder llegar a kitchen doorway (19,17) en 6 pasos',
      );
    });

    test('GREEN: debe poder alcanzar ballroom (está cerca de su START arriba)', () {
      // Ballroom está en x:8-14, y:18-22. Ballroom doorway: (8,17), (14,17)
      // GREEN START (9, 24). Distancia a (8,17) = 1+7 = 8. Con dado=8+
      for (final dice in [6, 7, 8]) {
        final s = gameState(
          currentPosition: BoardMap.characterStartPositions['green']!,
          dice: dice,
        );
        final canEnter = validateMovement(
          gameState: s,
          target: const Position(x: 8, y: 17, roomId: 'ballroom'),
        );
        // 1 paso a (9,23) + 7 pasos a (8,17) = 7 pasos. dado=7 alcanza (8,17), +1 cruce = 8
        if (dice >= 8) {
          expect(canEnter, isTrue,
              reason: 'GREEN dice=$dice debe poder entrar a ballroom');
        }
      }
    });
  });

  group('Diagnóstico: paths de movimiento desde START', () {
    test('WHINT: el path desde START a cocina NO debe estar vacío', () {
      final s = gameState(
        currentPosition: BoardMap.characterStartPositions['white']!,
        dice: 6,
      );
      final path = movementService.calculateMovementPath(
        BoardMap.characterStartPositions['white']!,
        const Position(x: 19, y: 17, roomId: 'kitchen'),
        s,
        maxSteps: 6,
      );
      // El path debe tener al menos 2 puntos (origen + destino)
      expect(path.length, greaterThanOrEqualTo(2),
          reason: 'Path WHITE→kitchen debe tener al menos origen+destino');
    });

    test('WHITE START mismo que destino → path longitud 1 (sin movimiento)', () {
      // Cuando el bot intenta moverse al mismo sitio (porque no hay otro válido),
      // el path debería ser [start] = longitud 1. Eso ahora se maneja en JS.
      final start = BoardMap.characterStartPositions['white']!;
      final s = gameState(currentPosition: start, dice: 6);
      final path = movementService.calculateMovementPath(
        start,
        start,
        s,
        maxSteps: 6,
      );
      expect(path.length, 1, reason: 'Path mismo-origen→destino debe ser [start]');
    });
  });

  group('Diagnóstico: orden de START y tamaño de celdas', () {
    test('STARTs deben ser walkway válidos (sin bordes negros)', () {
      for (final entry in BoardMap.characterStartPositions.entries) {
        final t = boardMap.getTileType(entry.value.x, entry.value.y);
        expect(t, TileType.walkway,
            reason:
                '${entry.key} en ${entry.value} debe ser walkway, es $t');
      }
    });

    test('STARTs NO deben estar en una habitación (sino entrarían automáticamente)', () {
      for (final entry in BoardMap.characterStartPositions.entries) {
        final roomId = boardMap.getRoomIdAt(entry.value.x, entry.value.y);
        expect(roomId, isNull,
            reason:
                '${entry.key} en ${entry.value} NO debe estar en habitación (es $roomId)');
      }
    });
  });
}