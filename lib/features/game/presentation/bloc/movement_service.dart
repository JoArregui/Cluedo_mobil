import 'package:cluedo_mobil/features/game/domain/entities/position.dart';

import '../../domain/entities/board_map.dart';
import '../../domain/entities/state_game.dart';
import '../../domain/entities/tile_type.dart';

class MovementService {
  final BoardMap _boardMap;

  MovementService({required BoardMap boardMap}) : _boardMap = boardMap;

  List<Position> calculateMovementPath(
    Position start,
    Position end,
    ClueGameState gameState, {
    int? maxSteps,
  }) {
    if (!_boardMap.isInsideGrid(start.x, start.y) ||
        !_boardMap.isInsideGrid(end.x, end.y)) {
      return [start];
    }

    if (end.roomId != null) {
      return _pathToRoom(start, end, gameState, maxSteps: maxSteps);
    }

    return _findHallwayPath(start, end, gameState, maxSteps: maxSteps) ??
        [start];
  }

  List<Position> _pathToRoom(
    Position start,
    Position end,
    ClueGameState gameState, {
    int? maxSteps,
  }) {
    if (_boardMap.getRoomIdAt(end.x, end.y) != end.roomId) return [start];

    List<Position>? bestPath;
    for (final door in _boardMap.getDoorsForRoom(end.roomId!)) {
      final path = _findHallwayPath(start, door, gameState, maxSteps: maxSteps);
      if (path == null) continue;
      if (maxSteps != null && path.length + 1 > maxSteps + 1) continue;
      if (bestPath == null || path.length < bestPath.length) {
        bestPath = path;
      }
    }

    if (bestPath == null) return [start];

    final roomCenter = _boardMap.getRoomCenterPosition(end.roomId!);
    if (roomCenter == null) return [start];

    final entrance = Position(
      x: roomCenter.x,
      y: roomCenter.y,
      roomId: end.roomId,
    );
    return [...bestPath, entrance];
  }

  List<Position>? _findHallwayPath(
    Position start,
    Position end,
    ClueGameState gameState, {
    int? maxSteps,
  }) {
    final targetType = _boardMap.getTileType(end.x, end.y);
    if (targetType == TileType.wall || targetType == TileType.room) {
      return null;
    }

    final occupied = gameState.players
        .where((p) => p != gameState.currentCharacter)
        .where((p) => p.position.roomId == null)
        .map((p) => '${p.position.x},${p.position.y}')
        .toSet();

    if (occupied.contains('${end.x},${end.y}')) return null;

    final queue = <List<Position>>[];
    final visited = <String>{};
    _seedPaths(start, queue, visited);

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;

      if (current.x == end.x && current.y == end.y) {
        return path;
      }

      if (maxSteps != null && path.length - 1 >= maxSteps) continue;

      final neighbors = [
        Position(x: current.x, y: current.y + 1),
        Position(x: current.x, y: current.y - 1),
        Position(x: current.x + 1, y: current.y),
        Position(x: current.x - 1, y: current.y),
      ];

      for (final neighbor in neighbors) {
        final key = '${neighbor.x},${neighbor.y}';
        if (!_boardMap.isInsideGrid(neighbor.x, neighbor.y)) continue;
        if (visited.contains(key)) continue;

        final tileType = _boardMap.getTileType(neighbor.x, neighbor.y);
        if (tileType == TileType.wall || tileType == TileType.room) continue;
        if (occupied.contains(key)) continue;

        visited.add(key);
        queue.add([...path, neighbor]);
      }
    }

    return null;
  }

  void _seedPaths(
    Position start,
    List<List<Position>> queue,
    Set<String> visited,
  ) {
    if (start.roomId == null) {
      visited.add('${start.x},${start.y}');
      queue.add([start]);
      return;
    }

    for (final door in _boardMap.getDoorsForRoom(start.roomId!)) {
      final key = '${door.x},${door.y}';
      if (visited.add(key)) {
        queue.add([start, door]);
      }
    }
  }
}
