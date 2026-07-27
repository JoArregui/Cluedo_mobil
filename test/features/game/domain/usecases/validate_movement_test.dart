import 'package:cluedo_mobil/features/game/domain/entities/board_map.dart';
import 'package:cluedo_mobil/features/game/domain/entities/card.dart';
import 'package:cluedo_mobil/features/game/domain/entities/character.dart';
import 'package:cluedo_mobil/features/game/domain/entities/position.dart';
import 'package:cluedo_mobil/features/game/domain/entities/state_game.dart';
import 'package:cluedo_mobil/features/game/domain/entities/tile_type.dart';
import 'package:cluedo_mobil/features/game/domain/usecases/validate_movement.dart';
import 'package:cluedo_mobil/features/game/presentation/bloc/movement_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const boardMap = BoardMap();
  const validateMovement = ValidateMovement(boardMap: boardMap);

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

  test('rejects movement before dice are rolled', () {
    final state = gameState(
      currentPosition: const Position(x: 16, y: 0),
      dice: null,
    );

    expect(
      validateMovement(gameState: state, target: const Position(x: 16, y: 1)),
      isFalse,
    );
  });

  test('rejects targets outside the grid or on non-selectable walls', () {
    final state = gameState(
      currentPosition: const Position(x: 16, y: 0),
      dice: 6,
    );

    expect(
      validateMovement(gameState: state, target: const Position(x: 24, y: 0)),
      isFalse,
    );
    expect(
      validateMovement(gameState: state, target: const Position(x: 11, y: 10)),
      isFalse,
    );
  });

  test('allows hallway movement inside dice range', () {
    final state = gameState(
      currentPosition: const Position(x: 16, y: 0),
      dice: 3,
    );

    expect(
      validateMovement(gameState: state, target: const Position(x: 16, y: 3)),
      isTrue,
    );
  });

  test('rejects hallway movement that needs more steps than the dice', () {
    final state = gameState(
      currentPosition: const Position(x: 16, y: 0),
      dice: 2,
    );

    expect(
      validateMovement(gameState: state, target: const Position(x: 16, y: 3)),
      isFalse,
    );
  });

  test('rejects occupied hallway targets', () {
    final state = gameState(
      currentPosition: const Position(x: 16, y: 0),
      dice: 3,
      others: [player('mustard', const Position(x: 16, y: 2))],
    );

    expect(
      validateMovement(gameState: state, target: const Position(x: 16, y: 2)),
      isFalse,
    );
  });

  test('allows entering a room only through a reachable door', () {
    final state = gameState(
      currentPosition: const Position(x: 6, y: 4),
      dice: 1,
    );

    expect(
      validateMovement(
        gameState: state,
        target: const Position(x: 3, y: 2, roomId: 'study'),
      ),
      isTrue,
    );
  });

  test('allows leaving a room through its doors', () {
    final state = gameState(
      currentPosition: const Position(x: 3, y: 2, roomId: 'study'),
      dice: 2,
    );

    expect(
      validateMovement(gameState: state, target: const Position(x: 7, y: 4)),
      isTrue,
    );
  });

  test('places the token at a centered tile inside the room when entering it', () {
    final state = gameState(
      currentPosition: const Position(x: 6, y: 4),
      dice: 1,
    );
    final movementService = MovementService(boardMap: boardMap);

    final path = movementService.calculateMovementPath(
      const Position(x: 6, y: 4),
      const Position(x: 3, y: 2, roomId: 'study'),
      state,
      maxSteps: 1,
    );

    final centeredPosition = boardMap.getRoomCenterPosition('study');
    expect(path.last.x, centeredPosition!.x);
    expect(path.last.y, centeredPosition.y);
    expect(path.last.roomId, 'study');
  });

  group('Entrar habitación REQUIERE alcanzar su doorway (hueco en pared)', () {
    // Desde casilla NO-doorway → no puedes cruzar el hueco.
    // La regla obliga: (start) --distancia--> (doorway walkway) + 1 paso extra ≤ maxSteps.

    test('Desde pasillo central NO-doorway no puede entrar en hall con dado insuficiente', () {
      // (10,7) es un pasillo walkway, NO es doorway de ningún room.
      // Hall doorways son (8,2), (11,6), (12,6).
      // (10,7) a (11,6) = 2 pasos. Con dado=1 no alcanza la doorway → no entrar.
      final s = gameState(
        currentPosition: const Position(x: 10, y: 7),
        dice: 1,
      );
      final hallCenter = boardMap.getRoomCenterPosition('hall');
      expect(hallCenter, isNotNull);
      expect(
        validateMovement(gameState: s, target: hallCenter!),
        isFalse,
        reason:
            'No puede entrar a hall: llegar a (11,6) cuesta 2 pasos, dado solo 1',
      );
    });

    test('Desde casilla walkway NO-doorway, dado alto pero target habitación con puerta lejos no permite entrar si pasos no llegan', () {
      // Scarlett START (16,0), dado=5. Quiere entrar a lounge.
      // Lounge puerta más cercana es (16,3): 3 pasos → +1 cruce = 4 ≤ 5.
      // 👉 Entonces SÍ debe poder. Vamos a comprobar que el validador acepta llegando a la puerta.
      final s = gameState(
        currentPosition: const Position(x: 16, y: 0),
        dice: 5,
      );
      final loungeCenter = boardMap.getRoomCenterPosition('lounge');
      expect(
        validateMovement(gameState: s, target: loungeCenter!),
        isTrue,
        reason: 'Llegar a puerta lounge (16,3)=3 + cruce 1 = 4 ≤ 5 → sí entra',
      );
    });

    test('Scarlett (16,0) dado=2 NO puede entrar a lounge (puerta (16,3) queda a 3 > dado)',
        () {
      final s = gameState(
        currentPosition: const Position(x: 16, y: 0),
        dice: 2,
      );
      final loungeCenter = boardMap.getRoomCenterPosition('lounge');
      expect(
        validateMovement(gameState: s, target: loungeCenter!),
        isFalse,
        reason: '3 + 1 = 4 > dado 2 → no entra',
      );
    });

    test('Jugador en pasillo NO-doorway colindante a habitación, NO puede "atravesar pared"',
        () {
      // Caso extremo: la ficha está en (6,1) — walkway pegada a la habitación study
      // (study está en x:1-5, y:1-4). Está frente a study PERO no frente a su puerta
      // (la puerta está en la esquina (6,4)). No puede entrar sin dar la vuelta.
      final s = gameState(
        currentPosition: const Position(x: 6, y: 1),
        dice: 1,
      );
      final studyCenter = boardMap.getRoomCenterPosition('study');
      expect(
        validateMovement(gameState: s, target: studyCenter!),
        isFalse,
        reason: 'Está frente a pared de study, no frente al hueco de la puerta.',
      );
    });

    test('Jugador en HALL puede salir a pasillo sin necesidad de doorway (ya está dentro)',
        () {
      // Este test solo asegura no rotura: salir de habitación sí funciona.
      final s = gameState(
        currentPosition: Position(
          x: boardMap.getRoomCenterPosition('hall')!.x,
          y: boardMap.getRoomCenterPosition('hall')!.y,
          roomId: 'hall',
        ),
        dice: 3,
      );
      expect(
        validateMovement(gameState: s, target: const Position(x: 8, y: 5)),
        isTrue,
      );
    });
  });

  group('Primer movimiento desde START (borde del tablero)', () {
    // Cada ficha tiene una única salida posible HACIA EL INTERIOR de la mansión.
    // Cualquier otra dirección queda bloqueada por el borde exterior (wall).

    const List<(String, Position, Position)> startCases = [
      ('scarlett', Position(x: 16, y: 0), Position(x: 16, y: 1)),
      ('plum',     Position(x: 0,  y: 5), Position(x: 1,  y: 5)),
      ('mustard',  Position(x: 23, y: 7), Position(x: 22, y: 7)),
      ('white',    Position(x: 23, y: 15), Position(x: 22, y: 15)),
      ('green',    Position(x: 9,  y: 24), Position(x: 9,  y: 23)),
      ('peacock',  Position(x: 0,  y: 17), Position(x: 1,  y: 17)),
    ];

    for (final (id, start, inward) in startCases) {
      test('$id en START $start solo puede entrar hacia adentro a $inward', () {
        // START debe ser walkway (edge exit)
        expect(boardMap.getTileType(start.x, start.y), TileType.walkway);

        // Casilla adentro debe ser walkway (no muro, no central)
        expect(boardMap.getTileType(inward.x, inward.y), TileType.walkway);

        // Generar estado con el personaje en cuestión
        final p = PlayerCharacter(
          isBot: false,
          position: start,
          hand: const [],
          card: CharacterCard(id: id, nameEs: id, nameEn: id, hexColor: '#FF0000'),
        );
        final s = ClueGameState(
          players: [p],
          currentTurnIndex: 0,
          solution: const CaseSolution(
            character: CharacterCard(id: 'x', nameEs: 'x', nameEn: 'x', hexColor: '#000'),
            weapon: WeaponCard(id: 'y', nameEs: 'y', nameEn: 'y'),
            room: RoomCard(id: 'hall', nameEs: 'Hall', nameEn: 'Hall'),
          ),
          phase: GamePhase.moving,
          currentDiceResult: 1,
          totalDeck: const [],
          clueDeck: const [],
          boardMap: boardMap,
          weaponPositions: const {},
        );

        // ✅ Entrar hacia adentro SÍ es válido (dado=1 es suficiente)
        expect(
          validateMovement(gameState: s, target: inward),
          isTrue,
          reason: '$id debe poder mover 1 casilla hacia adentro desde START',
        );

        // ❌ Cualquier dirección HACIA FUERA del borde es inválida:
        // Probamos vecinos que sean wall o fuera del grid.
        final neighbors = [
          Position(x: start.x + 1, y: start.y),
          Position(x: start.x - 1, y: start.y),
          Position(x: start.x, y: start.y + 1),
          Position(x: start.x, y: start.y - 1),
        ];
        for (final n in neighbors) {
          if (n.x == inward.x && n.y == inward.y) continue; // saltar la buena
          final res = validateMovement(gameState: s, target: n);
          expect(res, isFalse,
              reason:
                  '$id en $start NO debe poder ir a $n (fuera/borde/wall)');
        }
      });
    }
  });
}
