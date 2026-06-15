import 'dart:math';
import '../entities/state_game.dart';
import '../entities/bot_memory.dart';
import '../entities/clue_deck.dart';
import '../entities/card.dart';
import '../entities/position.dart';
import '../entities/board_map.dart';
import '../entities/tile_type.dart';
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

    // 2. Si hay dados lanzados, mover exactamente la cantidad de pasos indicada
    if (gameState.currentDiceResult != null) {
      int steps = gameState.currentDiceResult!;
      // Preferir mover hacia una puerta de la habitación objetivo si existe
      List<Position>? targetDoors;
      if (targetRoomId != null) {
        targetDoors = boardMap.getDoorsForRoom(targetRoomId);
      }

      // Intentar hasta 5 direcciones diferentes para usar exactamente los pasos
      bool moved = false;
      for (int attempt = 0; attempt < 5 && !moved; attempt++) {
        int dx, dy;
        if (targetDoors != null && targetDoors.isNotEmpty) {
          // Elegir una puerta al azar de las disponibles
          final door = targetDoors[_random.nextInt(targetDoors.length)];
          dx = (door.x - bot.position.x).sign;
          dy = (door.y - bot.position.y).sign;
          // Si ya estamos en la puerta, elegir dirección aleatoria
          if (dx == 0 && dy == 0) {
            dx = [_random.nextBool() ? -1 : 1, 0][_random.nextInt(2)];
            dy = dx == 0 ? [_random.nextBool() ? -1 : 1, 0][_random.nextInt(2)] : 0;
          }
        } else {
          // Dirección completamente aleatoria (no quedarse quieto)
          dx = [_random.nextBool() ? -1 : 1, 0][_random.nextInt(2)];
          dy = dx == 0 ? [_random.nextBool() ? -1 : 1, 0][_random.nextInt(2)] : 0;
        }

        Position pos = bot.position;
        bool valid = true;
        for (int i = 0; i < steps; i++) {
          final nx = pos.x + dx;
          final ny = pos.y + dy;
          final npos = Position(x: nx, y: ny, roomId: null);
          // Verificar límites
          if (nx < 0 || nx >= boardMap.columns || ny < 0 || ny >= boardMap.rows) {
            valid = false;
            break;
          }
          // Verificar que no sea pared
          final tileType = boardMap.getTileType(nx, ny);
          if (tileType == TileType.wall) {
            valid = false;
            break;
          }
          // Verificar que no esté ocupada por otro jugador (solo en pasillos)
          final isOccupied = gameState.players.any((p) =>
              !p.isEliminated &&
              p.position.roomId == null &&
              p.position.x == nx &&
              p.position.y == ny);
          if (isOccupied) {
            valid = false;
            break;
          }
          pos = npos;
        }
        if (valid) {
          chosenPosition = pos;
          moved = true;
          // Verificar si entró a una habitación (si la posición final tiene roomId != null)
          // En nuestro movimiento paso a paso, mantuvimos roomId null; para entrar a habitación
          // necesitamos que el último paso sea a una puerta y luego entrar.
          // Simplificamos: si la posición final es una puerta de alguna habitación, consideramos entrada.
          if (targetDoors != null) {
            final isDoor = targetDoors.any((d) => d.x == pos.x && d.y == pos.y);
            if (isDoor) {
              // Entrar a la habitación estableciendo roomId
              chosenPosition = Position(x: pos.x, y: pos.y, roomId: targetRoomId);
            }
          }
        }
      }
      // Si no se pudo mover en ninguna dirección, quedarse en posición (pero al menos intentamos)
      if (!moved) {
        chosenPosition = bot.position;
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