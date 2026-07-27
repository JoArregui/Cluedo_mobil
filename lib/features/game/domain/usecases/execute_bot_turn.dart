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
    //    pero permitir entrar a una habitación antes de agotar los pasos.
    // IMPORTANTE: a diferencia del código anterior (que fijaba UNA dirección
    // al inicio), aquí elegimos dirección en CADA paso para permitir al bot
    // doblar esquinas y esquivar paredes. Esto evita que el bot se quede
    // quieto cuando su dirección inicial choca contra un borde (p.ej. WHITE
    // en (23,15) o GREEN en (9,24)).
    if (state.currentDiceResult != null) {
      int steps = state.currentDiceResult!;
      // Preferir moverse hacia una puerta de la habitación objetivo si existe.
      // Puede haber varias puertas; elegimos la MÁS CERCANA como referencia
      // (pero seguimos recalculando la dirección en cada paso).
      Position? targetDoor;
      if (targetRoomId != null) {
        final doors = boardMap.getDoorsForRoom(targetRoomId);
        if (doors.isNotEmpty) {
          // Encontrar la puerta más cercana (distancia Manhattan) al bot.
          Position best = doors.first;
          int bestDist = _manhattan(bot.position, best);
          for (int i = 1; i < doors.length; i++) {
            final d = _manhattan(bot.position, doors[i]);
            if (d < bestDist) {
              best = doors[i];
              bestDist = d;
            }
          }
          targetDoor = best;
        }
      }

      Position pos = bot.position;
      int consumedSteps = 0;
      while (consumedSteps < steps) {
        // Elegir dirección válida priorizando moverse hacia targetDoor.
        final dir = _chooseNextDirection(
          pos: pos,
          target: targetDoor,
          state: state,
        );
        final dx = dir[0];
        final dy = dir[1];

        // Si _chooseNextDirection devuelve (0,0), no hay movimiento posible:
        // el bot está completamente bloqueado. Salimos.
        if (dx == 0 && dy == 0) break;

        final nx = pos.x + dx;
        final ny = pos.y + dy;

        // Mover
        pos = Position(x: nx, y: ny, roomId: null);
        consumedSteps++;

        // Verificar si hemos llegado a una puerta de cualquier habitación.
        final enteredRoomId = _getRoomIdForDoor(pos.x, pos.y, boardMap);
        if (enteredRoomId != null) {
          chosenPosition = Position(
            x: pos.x,
            y: pos.y,
            roomId: enteredRoomId,
          );
          moved = true;
          break; // Entramos a una habitación: terminamos el movimiento.
        }
      }

      // Si agotamos los pasos sin entrar a una habitación, registrar la posición final.
      if (!moved) {
        chosenPosition = pos;
        moved = true;
      }
    }

    // 3. GARANTÍA FINAL: si por alguna razón el bot no se movió (no había
    //    dados, todos los vecinos estaban ocupados/bloqueados), aseguramos
    //    que chosenPosition sea al menos una casilla walkway válida adyacente.
    //    Si no hay ni siquiera un vecino válido, mantenemos la posición actual.
    if (!moved || _samePosition(chosenPosition, bot.position)) {
      final fallback = _findAnyValidNeighbor(bot.position, state);
      if (fallback != null) {
        chosenPosition = fallback;
      } else {
        chosenPosition = bot.position;
      }
    }

    // 4. Elaborar sospecha lógica si está o entró en una habitación.
    // IMPORTANTE: NO en todas las tiradas se entra en habitación. Si el bot
    // se queda en pasillo, NO debe sugerir (solo pasa al siguiente turno).
    // Solo si terminó en una habitación, debe decidir: sugerir, acusar o pasar.
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

  /// Elige la siguiente dirección ortogonal válida. Prioriza moverse hacia
  /// `target` (si existe) sin chocar con paredes, bordes ni otros jugadores.
  /// Si todas las direcciones están bloqueadas, devuelve [0, 0] (sin movimiento).
  List<int> _chooseNextDirection({
    required Position pos,
    required Position? target,
    required ClueGameState state,
  }) {
    final candidates = <List<int>>[
      [-1, 0], [1, 0], [0, -1], [0, 1]
    ];
    candidates.shuffle(_random);

    List<int>? best;
    int bestScore = -1;

    for (final dir in candidates) {
      final nx = pos.x + dir[0];
      final ny = pos.y + dir[1];

      if (!_isStepWalkable(pos.x, pos.y, nx, ny, state)) continue;

      int score = 1; // baseline: cualquier paso válido cuenta.
      if (target != null) {
        // Puntos extra por moverse hacia target (menor distancia Manhattan).
        final distNow = _manhattan(pos, target);
        final distAfter = _manhattan(Position(x: nx, y: ny), target);
        if (distAfter < distNow) {
          score += 10; // acercarse cuenta más.
        } else if (distAfter == distNow) {
          score += 1; // no acercarse pero válido: aceptable.
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = dir;
      }
    }

    return best ?? [0, 0];
  }

  /// Verifica si la casilla (nx, ny) es un paso válido desde (posX, posY).
  /// Devuelve true si: dentro del grid, no es pared, no está ocupada por
  /// otro jugador en pasillo, y NO es una habitación (no se entra por la
  /// fuerza: solo se entra si es una doorway detectada en el bucle principal).
  bool _isStepWalkable(int posX, int posY, int nx, int ny, ClueGameState state) {
    if (nx < 0 || nx >= boardMap.columns || ny < 0 || ny >= boardMap.rows) {
      return false;
    }
    final tileType = boardMap.getTileType(nx, ny);
    if (tileType == TileType.wall || tileType == TileType.room) return false;

    final isOccupied = state.players.any((p) =>
        !p.isEliminated &&
        p.position.roomId == null &&
        p.position.x == nx &&
        p.position.y == ny);
    if (isOccupied) return false;

    // Evitamos también las casillas marcadas como inaccessibleZone
    // (getTileType ya filtra _inaccessibleZones como wall, así que este
    // chequeo es redundante pero seguro).
    return true;
  }

  /// Busca cualquier vecino walkway válido. Útil como fallback cuando el
  /// bot no pudo moverse por su lógica principal.
  Position? _findAnyValidNeighbor(Position from, ClueGameState state) {
    final candidates = <List<int>>[
      [-1, 0], [1, 0], [0, -1], [0, 1]
    ];
    candidates.shuffle(_random);
    for (final dir in candidates) {
      final nx = from.x + dir[0];
      final ny = from.y + dir[1];
      if (_isStepWalkable(from.x, from.y, nx, ny, state)) {
        return Position(x: nx, y: ny);
      }
    }
    return null;
  }

  /// Distancia Manhattan entre dos posiciones.
  int _manhattan(Position a, Position b) {
    return (a.x - b.x).abs() + (a.y - b.y).abs();
  }

  /// Compara si dos posiciones son la misma casilla (incluyendo roomId).
  bool _samePosition(Position a, Position b) {
    return a.x == b.x && a.y == b.y && a.roomId == b.roomId;
  }

  /// Verifica si la posición (x,y) es una puerta de cualquier habitación.
  bool _isDoorAt(int x, int y, BoardMap boardMap) {
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