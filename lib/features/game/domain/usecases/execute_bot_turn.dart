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
    required ClueGameState state,
    required BotMemory botMemory,
  }) {
    final bot = state.currentCharacter;
    final unknownCharacters = botMemory.filterUnknown(ClueDeck.characters);
    final unknownWeapons = botMemory.filterUnknown(ClueDeck.weapons);
    final unknownRooms = botMemory.filterUnknown(ClueDeck.rooms);

    // 1. Determinar habitación objetivo estratégica
    String? targetRoomId;
    if (unknownRooms.isNotEmpty) {
      targetRoomId = unknownRooms[_random.nextInt(unknownRooms.length)].id;
    }

    Position chosenPosition = bot.position;
    bool moved = false;

    // 2. Si hay dados lanzados, mover exactamente la cantidad de pasos indicada
    //    pero permitir entrar a una habitación antes de agotar los pasos
    if (state.currentDiceResult != null) {
      int steps = state.currentDiceResult!;
      // Preferir mover hacia una puerta de la habitación objetivo si existe
      List<Position>? targetDoors;
      if (targetRoomId != null) {
        targetDoors = boardMap.getDoorsForRoom(targetRoomId);
      }

      // Dirección de movimiento: hacia una puerta objetivo o aleatoria (solo ortogonal)
      int dx = 0, dy = 0;
      if (targetDoors != null && targetDoors.isNotEmpty) {
        // Elegir una puerta al azar de las disponibles
        final door = targetDoors[_random.nextInt(targetDoors.length)];

        // Calcular dirección ortogonal hacia la puerta
        final diffX = door.x - bot.position.x;
        final diffY = door.y - bot.position.y;

        if (diffX != 0 && diffY != 0) {
          // Estamos en diagonal respecto a la puerta - elegir aleatoriamente entre x o y
          if (_random.nextBool()) {
            dx = diffX.sign;
            dy = 0;
          } else {
            dx = 0;
            dy = diffY.sign;
          }
        } else if (diffX != 0) {
          // Solo diferencia en x
          dx = diffX.sign;
          dy = 0;
        } else if (diffY != 0) {
          // Solo diferencia en y
          dx = 0;
          dy = diffY.sign;
        } else {
          // Ya estamos en la puerta - elegir dirección ortogonal aleatoria
          final directions = [
            [-1, 0], [1, 0], [0, -1], [0, 1]
          ];
          final dir = directions[_random.nextInt(4)];
          dx = dir[0];
          dy = dir[1];
        }
      } else {
        // Dirección completamente aleatoria ortogonal (no quedarse quieto)
        final directions = [
          [-1, 0], [1, 0], [0, -1], [0, 1]
        ];
        final dir = directions[_random.nextInt(4)];
        dx = dir[0];
        dy = dir[1];
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
        final isOccupied = state.players.any((p) =>
            !p.isEliminated &&
            p.position.roomId == null &&
            p.position.x == nx &&
            p.position.y == ny);
        if (isOccupied) {
          valid = false;
          break;
        }

        // Mover a la nueva posición
        pos = npos;

        // Verificar si hemos llegado a una puerta de cualquier habitación
        final isDoor = _isDoorAt(pos.x, pos.y, boardMap);
        if (isDoor) {
          // Entrar a la habitación estableciendo roomId
          // Necesitamos determinar a qué habitación pertenece esta puerta
          final enteredRoomId = _getRoomIdForDoor(pos.x, pos.y, boardMap);
          if (enteredRoomId != null) {
            chosenPosition = Position(x: pos.x, y: pos.y, roomId: enteredRoomId);
          } else {
            // Por seguridad, si no encontramos la habitación, quedamos en el pasillo
            chosenPosition = pos;
          }
          moved = true;
          break; // Detener movimiento al entrar a la habitación
        }
      }

      // Si salimos del bucle por agotar pasos y aún no hemos entrado a una habitación,
      // la posición final está en el pasillo (o quizás en una puerta pero no la detectamos?)
      if (valid && !moved) {
        // Aún estamos en la posición inicial o en una posición intermedia sin haber entrado a habitación
        chosenPosition = pos;
        moved = true;
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

  /// Verifica si la posición (x,y) es una puerta de cualquier habitación.
  bool _isDoorAt(int x, int y, BoardMap boardMap) {
    // Recorrer todas las habitaciones y ver si (x,y) está en sus puertas
    for (final room in ClueDeck.rooms) {
      final doors = boardMap.getDoorsForRoom(room.id);
      if (doors.any((d) => d.x == x && d.y == y)) {
        return true;
      }
    }
    return false;
  }

  /// Devuelve el ID de la habitación cuya puerta está en (x,y), o null si no es una puerta.
  String? _getRoomIdForDoor(int x, int y, BoardMap boardMap) {
    for (final room in ClueDeck.rooms) {
      final doors = boardMap.getDoorsForRoom(room.id);
      if (doors.any((d) => d.x == x && d.y == y)) {
        return room.id;
      }
    }
    return null;
  }
}