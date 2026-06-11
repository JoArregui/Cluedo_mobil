import 'package:cluedo_mobil/features/game/domain/entities/board_map.dart';
import 'package:cluedo_mobil/features/game/domain/entities/bot_memory.dart';
import 'package:cluedo_mobil/features/game/domain/entities/card.dart';
import 'package:cluedo_mobil/features/game/domain/entities/character.dart';
import 'package:cluedo_mobil/features/game/domain/entities/position.dart';
import 'package:cluedo_mobil/features/game/domain/entities/state_game.dart';
import 'package:cluedo_mobil/features/game/domain/usecases/execute_bot_turn.dart';
import 'package:cluedo_mobil/features/game/domain/usecases/validate_movement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ExecuteBotTurn executeBotTurn;
  late ValidateMovement validateMovement;
  late BoardMap boardMap;
  late BotMemory botMemory;

  setUp(() {
    boardMap = const BoardMap();
    validateMovement = ValidateMovement(boardMap: boardMap);
    botMemory = BotMemory(botPlayerId: 'bot-1');
    executeBotTurn = ExecuteBotTurn(
      validateMovement: validateMovement,
      boardMap: boardMap,
    );
  });

  // Helper para crear un personaje mock
  PlayerCharacter createMockPlayer({
    String id = 'scarlet',
    String nameEs = 'Srta. Amapola',
    String nameEn = 'Miss Scarlet',
    String hexColor = '#FF0000',
    required Position position,
    bool isBot = true,
    List<ClueCard> hand = const [],
  }) {
    return PlayerCharacter(
      isBot: isBot,
      position: position,
      hand: hand,
      card: CharacterCard(
        id: id,
        nameEs: nameEs,
        nameEn: nameEn,
        hexColor: hexColor,
      ),
    );
  }

  // Helper para crear una solución mock
  CaseSolution createMockSolution() {
    return const CaseSolution(
      character: CharacterCard(id: 'mustard', nameEs: 'Coronel Rubio', nameEn: 'Colonel Mustard', hexColor: '#FFD700'),
      weapon: WeaponCard(id: 'revolver', nameEs: 'Revólver', nameEn: 'Revolver'),
      room: RoomCard(id: 'hall', nameEs: 'Vestíbulo', nameEn: 'Hall'),
    );
  }

  // Helper para crear un estado de juego mock
  ClueGameState createMockGameState({
    required List<PlayerCharacter> players,
    required int? currentDiceResult,
    required List<int> lastDiceRoll,
    GamePhase phase = GamePhase.moving,
    BoardMap? boardMap,
    Map<String, Position> weaponPositions = const {},
    List<ClueCardClass> clueDeck = const [],
  }) {
    return ClueGameState(
      players: players,
      currentTurnIndex: 0,
      solution: createMockSolution(),
      phase: phase,
      currentDiceResult: currentDiceResult,
      lastDiceRoll: lastDiceRoll,
      totalDeck: const [],
      boardMap: boardMap ?? const BoardMap(),
      weaponPositions: weaponPositions,
      clueDeck: clueDeck,
    );
  }

  group('ExecuteBotTurn - Lógica de Movimiento', () {
    test('Debería retornar una posición válida cuando tenga dados lanzados', () {
      // Configurar estado: bot en posición cualquiera
      final botPosition = Position(x: 10, y: 0, roomId: null);
      final diceResult = 4; // Algun valor de dados
      final lastRoll = [2, 2];

      final gameState = createMockGameState(
        players: [createMockPlayer(position: botPosition, isBot: true)],
        currentDiceResult: diceResult,
        lastDiceRoll: lastRoll,
      );

      // Configurar memoria del bot: limpiar para que tenga opciones
      botMemory.checkedCards.clear();

      final result = executeBotTurn.call(
        gameState: gameState,
        botMemory: botMemory,
      );

      // Verificar que retorna una posición (no nula)
      expect(result['newPosition'], isNotNull);
      expect(result['newPosition'], isA<Position>());

      // La posición debería estar dentro de los límites del tablero
      final newPosition = result['newPosition'] as Position;
      expect(newPosition.x, greaterThanOrEqualTo(0));
      expect(newPosition.x, lessThanOrEqualTo(23));
      expect(newPosition.y, greaterThanOrEqualTo(0));
      expect(newPosition.y, lessThanOrEqualTo(24));

      // Nota: No verificamos que se mueva en una dirección específica porque
      // la selección de habitación objetivo es aleatoria
    });

    test('Debería permanecer en posición si no tiene dados lanzados', () {
      final botPosition = Position(x: 5, y: 5, roomId: null);
      final gameState = createMockGameState(
        players: [createMockPlayer(position: botPosition, isBot: true)],
        currentDiceResult: null, // Sin dados
        lastDiceRoll: [0, 0],
        phase: GamePhase.rolling, // En fase de rolling pero sin dado
      );

      final result = executeBotTurn.call(
        gameState: gameState,
        botMemory: botMemory,
      );

      // Debe permanecer en la misma posición
      final newPosition = result['newPosition'] as Position;
      expect(newPosition.x, equals(botPosition.x));
      expect(newPosition.y, equals(botPosition.y));
    });
  });

  group('ExecuteBotTurn - Lógica de Sospecha', () {
    test('Debería formular una sospecha cuando esté en una habitación', () {
      final roomPosition = Position(x: -8, y: 8, roomId: 'study'); // Dentro de study
      final gameState = createMockGameState(
        players: [createMockPlayer(position: roomPosition, isBot: true)],
        currentDiceResult: null,
        lastDiceRoll: [0, 0],
        phase: GamePhase.suggesting, // Después de entrar a habitación
      );

      // Configurar memoria del bot: algunas cartas desconocidas
      botMemory.checkedCards.clear();
      // Hacer que algunas cartas sean conocidas para que filterUnknown funcione predeciblemente
      botMemory.markAsChecked('mustard'); // Conocer al señor Coronel Rubio
      botMemory.markAsChecked('revolver'); // Conocer el revólver

      final result = executeBotTurn.call(
        gameState: gameState,
        botMemory: botMemory,
      );

      // Debe haber formular una sospecha
      expect(result['suggestion'], isNotNull);
      final suggestion = result['suggestion'] as Map<String, dynamic>;
      expect(suggestion['suspect'], isNotNull);
      expect(suggestion['weapon'], isNotNull);
      expect(suggestion['room'], isNotNull);

      // La habitación debería ser study (porque está ahí)
      expect((suggestion['room'] as RoomCard).id, equals('study'));

      // El sospecha y arma no deberían ser las conocidas (mustard, revolver)
      final suspect = suggestion['suspect'] as CharacterCard;
      final weapon = suggestion['weapon'] as WeaponCard;
      expect(suspect.id, isNot(equals('mustard')));
      expect(weapon.id, isNot(equals('revolver')));
    });

    test('No debería formular sospecha cuando esté en pasillo', () {
      final hallwayPosition = Position(x: 0, y: 0, roomId: null); // En pasillo
      final gameState = createMockGameState(
        players: [createMockPlayer(position: hallwayPosition, isBot: true)],
        currentDiceResult: null,
        lastDiceRoll: [0, 0],
        phase: GamePhase.moving, // En fase de movimiento
      );

      final result = executeBotTurn.call(
        gameState: gameState,
        botMemory: botMemory,
      );

      // No debería formular sospecha (null)
      expect(result['suggestion'], isNull);
    });
  });
}