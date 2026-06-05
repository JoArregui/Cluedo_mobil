import 'package:cluedo_mobil/features/game/domain/entities/board_map.dart';
import 'package:cluedo_mobil/features/game/domain/entities/card.dart';
import 'package:cluedo_mobil/features/game/domain/entities/character.dart';
import 'package:cluedo_mobil/features/game/domain/entities/position.dart';
import 'package:cluedo_mobil/features/game/domain/entities/state_game.dart';
import 'package:cluedo_mobil/features/game/domain/usecases/validate_movement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ValidateMovement validateMovement;
  late BoardMap boardMap;

  setUp(() {
    boardMap = const BoardMap();
    validateMovement = ValidateMovement(boardMap: boardMap);
  });

  // Mock de personaje adaptado a las propiedades reales de tu entidad
  PlayerCharacter createMockPlayer(Position position) {
    return PlayerCharacter(
      isBot: false,
      position: position,
      hand: const [],
      card: const CharacterCard(
        id: 'scarlet',
        nameEs: 'Srta. Amapola',
        nameEn: 'Miss Scarlet',
        hexColor: '#FF0000',
      ),
    );
  }

  // Genera una solución válida respetando la firma de CaseSolution
  CaseSolution createMockSolution() {
    return const CaseSolution(
      character: CharacterCard(id: 'mustard', nameEs: 'Coronel Rubio', nameEn: 'Colonel Mustard', hexColor: '#FFD700'),
      weapon: WeaponCard(id: 'revolver', nameEs: 'Revólver', nameEn: 'Revolver'),
      room: RoomCard(id: 'hall', nameEs: 'Vestíbulo', nameEn: 'Hall'),
    );
  }

  /// Helper corregido pasando el parámetro obligatorio 'totalDeck'
  ClueGameState createMockGameState({
    required List<PlayerCharacter> players,
    required int? currentDiceResult,
    required List<int> lastDiceRoll,
  }) {
    return ClueGameState(
      players: players,
      currentTurnIndex: 0,
      solution: createMockSolution(),
      phase: GamePhase.moving,
      currentDiceResult: currentDiceResult,
      lastDiceRoll: lastDiceRoll,
      totalDeck: const [], // Corregido: Se añade el mazo requerido por el dominio
    );
  }

  test('Debería retornar FALSE si el resultado de los dados no ha sido generado (es null)', () {
    final gameState = createMockGameState(
      players: [createMockPlayer(const Position(x: 16, y: 0, roomId: null))],
      currentDiceResult: null,
      lastDiceRoll: const [0, 0],
    );

    final result = validateMovement(
      gameState: gameState,
      target: const Position(x: 16, y: 2, roomId: null),
    );

    expect(result, false);
  });

  test('Debería retornar FALSE si la casilla destino seleccionada es un muro inaccesible', () {
    final gameState = createMockGameState(
      players: [createMockPlayer(const Position(x: 10, y: 9, roomId: null))],
      currentDiceResult: 4,
      lastDiceRoll: const [2, 2],
    );

    // Intentar mover al centro del sótano bloqueado (12, 12) definido en BoardMap
    final result = validateMovement(
      gameState: gameState,
      target: const Position(x: 12, y: 12, roomId: null),
    );

    expect(result, false);
  });

  test('Debería retornar TRUE si el destino en pasillo está dentro del rango exacto de los dados', () {
    final gameState = createMockGameState(
      players: [createMockPlayer(const Position(x: 16, y: 0, roomId: null))],
      currentDiceResult: 3,
      lastDiceRoll: const [1, 2],
    );

    final result = validateMovement(
      gameState: gameState,
      target: const Position(x: 16, y: 3, roomId: null), // Exactamente 3 pasos en línea recta por pasillo
    );

    expect(result, true);
  });

  test('Debería retornar FALSE si el destino requiere más pasos de los permitidos por los dados', () {
    final gameState = createMockGameState(
      players: [createMockPlayer(const Position(x: 16, y: 0, roomId: null))],
      currentDiceResult: 2,
      lastDiceRoll: const [1, 1],
    );

    final result = validateMovement(
      gameState: gameState,
      target: const Position(x: 16, y: 4, roomId: null), // Requiere 4 pasos, pero el dado solo da un máximo de 2
    );

    expect(result, false);
  });
}