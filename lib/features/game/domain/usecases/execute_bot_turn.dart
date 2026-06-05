import 'dart:math';
import '../entities/state_game.dart';
import '../entities/bot_memory.dart';
import '../entities/clue_deck.dart';
import '../entities/card.dart';
import '../entities/position.dart';
import '../entities/board_map.dart';
import 'validate_movement.dart';

class ExecuteBotTurn {
  final ValidateMovement validateMovement;
  final BoardMap boardMap;
  final Random _random;

  ExecuteBotTurn({
    required this.validateMovement,
    this.boardMap = const BoardMap(),
  }) : _random = Random();

  /// Procesa la decisión táctica de movimiento y sospecha de un Bot inteligente
  Map<String, dynamic> call({
    required ClueGameState gameState,
    required BotMemory botMemory,
  }) {
    final bot = gameState.currentCharacter;
    final unknownCharacters = botMemory.filterUnknown(ClueDeck.characters);
    final unknownWeapons = botMemory.filterUnknown(ClueDeck.weapons);
    final unknownRooms = botMemory.filterUnknown(ClueDeck.rooms);

    // 1. Determinar habitación objetivo estratégica
    String? targetRoomId;
    if (unknownRooms.isNotEmpty) {
      targetRoomId = unknownRooms[_random.nextInt(unknownRooms.length)].id;
    }

    Position chosenPosition = bot.position;
    bool enteredRoom = false;

    // 2. Si hay dados lanzados, buscar el movimiento óptimo hacia la habitación objetivo
    if (gameState.currentDiceResult != null && targetRoomId != null) {
      final doors = boardMap.getDoorsForRoom(targetRoomId);
      
      for (var door in doors) {
        final targetPos = Position(x: door.x, y: door.y, roomId: targetRoomId);
        if (validateMovement(gameState: gameState, target: targetPos)) {
          chosenPosition = targetPos;
          enteredRoom = true;
          break;
        }
      }

      // Si no llega a la habitación, moverse por el pasillo acercándose a la puerta más cercana
      if (!enteredRoom && doors.isNotEmpty) {
        final targetDoor = doors.first;
        // Caminar en dirección a la puerta de manera básica dentro del rango de dados
        int steps = gameState.currentDiceResult!;
        int dx = (targetDoor.x - bot.position.x).sign;
        int dy = (targetDoor.y - bot.position.y).sign;

        int targetX = (bot.position.x + (dx * steps)).clamp(0, 23);
        int targetY = (bot.position.y + (dy * steps)).clamp(0, 24);
        
        final testPos = Position(x: targetX, y: targetY, roomId: null);
        if (validateMovement(gameState: gameState, target: testPos)) {
          chosenPosition = testPos;
        }
      }
    }

    // 3. Elaborar sospecha lógica si está o entró en una habitación
    Map<String, dynamic>? formulatedSuggestion;
    final currentRoomId = chosenPosition.roomId;

    if (currentRoomId != null) {
      final suspect = unknownCharacters.isNotEmpty 
          ? unknownCharacters[_random.nextInt(unknownCharacters.length)] as CharacterCard
          : ClueDeck.characters[_random.nextInt(ClueDeck.characters.length)];

      final weapon = unknownWeapons.isNotEmpty
          ? unknownWeapons[_random.nextInt(unknownWeapons.length)] as WeaponCard
          : ClueDeck.weapons[_random.nextInt(ClueDeck.weapons.length)];

      formulatedSuggestion = {
        'suspect': suspect,
        'weapon': weapon,
        'room': ClueDeck.rooms.firstWhere((r) => r.id == currentRoomId),
      };
    }

    return {
      'newPosition': chosenPosition,
      'suggestion': formulatedSuggestion,
    };
  }
}