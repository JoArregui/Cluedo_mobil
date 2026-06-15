import 'package:cluedo_mobil/features/game/domain/entities/position.dart';
import '../../domain/entities/state_game.dart';
import '../../domain/entities/tile_type.dart';
import '../../domain/entities/board_map.dart';

/// Servicio responsable de manejar la lógica de movimiento de los personajes en el tablero, incluyendo validación de movimientos y cálculo de caminos.
class MovementService {
  final BoardMap _boardMap;

  MovementService({required BoardMap boardMap}) : _boardMap = boardMap;

  List<Position> calculateMovementPath(Position start, Position end, ClueGameState gameState, {int? maxSteps}) {
    // Si el destino es una habitación, necesitamos encontrar un camino hasta una puerta de esa habitación
    final String? roomId = end.roomId;
    if (roomId != null) {
      // Obtener todas las puertas de la habitación destino
      final List<Position> doors = _boardMap.getDoorsForRoom(roomId);

      if (doors.isEmpty) {
        // No hay puertas 
        return [start, end];
      }

      // Encontrar el camino más corto hasta cualquiera de las puertas
      List<Position>? bestPathToDoor;
      int bestPathLength = 999;

      for (final door in doors) {
        final pathToDoor = _findHallwayPath(start, door, gameState);
        if (pathToDoor.length < bestPathLength) {
          bestPathLength = pathToDoor.length;
          bestPathToDoor = pathToDoor;
        }
      }

      if (bestPathToDoor == null) {
        // No se puede llegar a ninguna puerta
        return [start, end]; // Esto será manejado como inválido en el Bloc
      }

      // El camino final es el camino hasta la puerta + la posición de la habitación
      // Nota: La posición de la habitación tiene las mismas coordenadas x,y que la puerta, pero con roomId establecido
      final entrancePosition = Position(x: bestPathToDoor.last.x, y: bestPathToDoor.last.y, roomId: roomId);
      return [...bestPathToDoor, entrancePosition];
    } else {
      // Movimiento en pasillos
      return _findHallwayPath(start, end, gameState, maxSteps: maxSteps);
    }
  }

  List<Position> _findHallwayPath(Position start, Position end, ClueGameState gameState, {int? maxSteps}) {
    final queue = <List<Position>>[];
    final visited = <String>{};

    queue.add([start]);
    visited.add('${start.x},${start.y}');

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;

      // Si llegamos al destino, devolvemos el camino
      if (current.x == end.x && current.y == end.y) {
        return path;
      }

      // Si tenemos un límite de pasos y lo superamos, no continuamos este camino
      if (maxSteps != null && path.length - 1 >= maxSteps) {
        continue;
      }

      final neighbors = [
        Position(x: current.x, y: current.y + 1),
        Position(x: current.x, y: current.y - 1),
        Position(x: current.x + 1, y: current.y),
        Position(x: current.x - 1, y: current.y),
      ];

      for (final neighbor in neighbors) {
        // Verificar límites del tablero (asumiendo 24x25 basado en el código existente)
        if (neighbor.x < 0 || neighbor.x >= 24 || neighbor.y < 0 || neighbor.y >= 25) {
          continue;
        }

        final tileType = _boardMap.getTileType(neighbor.x, neighbor.y);
        if (tileType == TileType.wall || tileType == TileType.room) {
          continue;
        }

        // Verificar si el tile está ocupado por otro jugador (solo en pasillos, no en rooms)
        // Nota: Como estamos calculando un camino en pasillos, ignoramos las positions con roomId != null
        final isOccupied = gameState.players.any((p) =>
          !p.isEliminated &&
          p.position.roomId == null &&
          p.position.x == neighbor.x &&
          p.position.y == neighbor.y);
        if (isOccupied) {
          continue;
        }

        final key = '${neighbor.x},${neighbor.y}';
        if (!visited.contains(key)) {
          visited.add(key);
          final newPath = [...path, neighbor];
          queue.add(newPath);
        }
      }
    }

    // Si no se encuentra un camino, devolvemos el camino más largo posible dentro del límite de pasos
    // O simplemente [start, end] si no hay límite (aunque esto podría llevar a movimientos inválidos)
    if (maxSteps != null) {
      // Encontrar el nodo visitado más cercano al destino
      // Por simplicidad, devolvemos [start, start] si no hay movimiento posible
      return [start];
    }

    // Si no hay límite de pasos, devolvemos camino directo (no debería pasar en juego válido)
    return [start, end];
  }
}