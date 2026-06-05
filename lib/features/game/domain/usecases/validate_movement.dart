import '../entities/position.dart';
import '../entities/state_game.dart';
import '../entities/board_map.dart';
import '../entities/tile_type.dart';

class ValidateMovement {
  final BoardMap boardMap;

  const ValidateMovement({this.boardMap = const BoardMap()});

  bool call({
    required ClueGameState gameState,
    required Position target,
  }) {
    final start = gameState.currentCharacter.position;
    final maxSteps = gameState.currentDiceResult;

    if (maxSteps == null) return false;

    final targetTileType = boardMap.getTileType(target.x, target.y);
    if (targetTileType == TileType.wall) return false;

    if (start.x == target.x && start.y == target.y && start.roomId == target.roomId) {
      return false;
    }

    if (target.roomId != null) {
      return _canEnterRoom(start, target, maxSteps, gameState);
    }

    return _calculateShortestPath(start, target, maxSteps, gameState);
  }

  bool _calculateShortestPath(Position start, Position target, int maxSteps, ClueGameState gameState) {
    final List<List<int>> directions = [
      [0, 1], [0, -1], [1, 0], [-1, 0]
    ];

    final Set<String> visited = {'${start.x},${start.y}'};
    final List<Map<String, dynamic>> queue = [
      {'x': start.x, 'y': start.y, 'steps': 0}
    ];

    // Mapeo de posiciones ocupadas por otros jugadores en pasillos (bloqueos tácticos)
    final Set<String> occupiedTiles = gameState.players
        .where((p) => p.position.roomId == null)
        .map((p) => '${p.position.x},${p.position.y}')
        .toSet();

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final int cx = current['x'];
      final int cy = current['y'];
      final int steps = current['steps'];

      if (cx == target.x && cy == target.y) {
        return steps <= maxSteps;
      }

      if (steps >= maxSteps) continue;

      for (var dir in directions) {
        final nx = cx + dir[0];
        final ny = cy + dir[1];
        final key = '$nx,$ny';

        if (nx >= 0 && nx < boardMap.columns && ny >= 0 && ny < boardMap.rows) {
          final type = boardMap.getTileType(nx, ny);
          
          // No se puede atravesar paredes ni pasar por encima de casillas ocupadas por rivales en los pasillos
          if (type != TileType.wall && type != TileType.room && !visited.contains(key) && !occupiedTiles.contains(key)) {
            visited.add(key);
            queue.add({'x': nx, 'y': ny, 'steps': steps + 1});
          }
        }
      }
    }

    return false;
  }

  bool _canEnterRoom(Position start, Position target, int maxSteps, ClueGameState gameState) {
    final doors = boardMap.getDoorsForRoom(target.roomId!);
    
    for (var door in doors) {
      if (start.x == door.x && start.y == door.y) {
        return true; 
      }

      final stepsToDoor = _getDistanceToDoor(start, door, maxSteps, gameState);
      if (stepsToDoor != -1 && (stepsToDoor + 1) <= maxSteps) {
        return true; 
      }
    }

    return false;
  }

  int _getDistanceToDoor(Position start, Position door, int maxSteps, ClueGameState gameState) {
    final List<List<int>> directions = [[0, 1], [0, -1], [1, 0], [-1, 0]];
    final Set<String> visited = {'${start.x},${start.y}'};
    final List<Map<String, dynamic>> queue = [{'x': start.x, 'y': start.y, 'steps': 0}];

    final Set<String> occupiedTiles = gameState.players
        .where((p) => p.position.roomId == null)
        .map((p) => '${p.position.x},${p.position.y}')
        .toSet();

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final int cx = current['x'];
      final int cy = current['y'];
      final int steps = current['steps'];

      if (cx == door.x && cy == door.y) {
        return steps;
      }

      if (steps >= maxSteps) continue;

      for (var dir in directions) {
        final nx = cx + dir[0];
        final ny = cy + dir[1];
        final key = '$nx,$ny';

        if (nx >= 0 && nx < boardMap.columns && ny >= 0 && ny < boardMap.rows) {
          final type = boardMap.getTileType(nx, ny);
          if (type != TileType.wall && type != TileType.room && !visited.contains(key) && !occupiedTiles.contains(key)) {
            visited.add(key);
            queue.add({'x': nx, 'y': ny, 'steps': steps + 1});
          }
        }
      }
    }
    return -1;
  }
}