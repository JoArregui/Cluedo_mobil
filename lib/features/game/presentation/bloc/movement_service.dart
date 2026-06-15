import 'package:cluedo_mobil/features/game/domain/entities/position.dart';
import '../../domain/entities/state_game.dart';
import '../../domain/entities/tile_type.dart';
import '../../domain/entities/board_map.dart';

/// Service responsible for movement calculation and pathfinding.
class MovementService {
  final BoardMap _boardMap;

  MovementService({required BoardMap boardMap}) : _boardMap = boardMap;

  List<Position> calculateMovementPath(Position start, Position end, ClueGameState gameState) {
    if (end.roomId != null) {
      return [start, end];
    } else {
      return _findHallwayPath(start, end, gameState);
    }
  }

  List<Position> _findHallwayPath(Position start, Position end, ClueGameState gameState) {
    final queue = <List<Position>>[];
    final visited = <String>{};

    queue.add([start]);
    visited.add('${start.x},${start.y}');

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;

      if (current.x == end.x && current.y == end.y) {
        return path;
      }

      final neighbors = [
        Position(x: current.x, y: current.y + 1),
        Position(x: current.x, y: current.y - 1),
        Position(x: current.x + 1, y: current.y),
        Position(x: current.x - 1, y: current.y),
      ];

      for (final neighbor in neighbors) {
        if (neighbor.x < 0 || neighbor.x >= 24 || neighbor.y < 0 || neighbor.y >= 25) {
          continue;
        }

        final tileType = _boardMap.getTileType(neighbor.x, neighbor.y);
        if (tileType == TileType.wall) {
          continue;
        }

        // Check if the tile is occupied by another player (only in hallways, not in rooms)
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

    // If no path found, return direct start to end (should not happen in valid game)
    return [start, end];
  }
}