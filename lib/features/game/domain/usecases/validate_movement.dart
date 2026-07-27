import '../entities/board_map.dart';
import '../entities/position.dart';
import '../entities/state_game.dart';
import '../entities/tile_type.dart';

class ValidateMovement {
  final BoardMap boardMap;

  const ValidateMovement({this.boardMap = const BoardMap()});

  bool call({required ClueGameState gameState, required Position target}) {
    final start = gameState.currentCharacter.position;
    final maxSteps = gameState.currentDiceResult;

    if (maxSteps == null) return false;
    if (!boardMap.isInsideGrid(start.x, start.y)) return false;
    if (!boardMap.isInsideGrid(target.x, target.y)) return false;
    if (target.roomId == null && !boardMap.isSelectableTile(target.x, target.y)) {
      return false;
    }

    if (start.x == target.x &&
        start.y == target.y &&
        start.roomId == target.roomId) {
      return false;
    }

    if (target.roomId != null) {
      return _canEnterRoom(start, target, maxSteps, gameState);
    }

    return _distanceToTile(start, target, maxSteps, gameState) != null;
  }

  bool _canEnterRoom(
    Position start,
    Position target,
    int maxSteps,
    ClueGameState gameState,
  ) {
    if (boardMap.getRoomIdAt(target.x, target.y) != target.roomId) {
      return false;
    }

    final doors = boardMap.getDoorsForRoom(target.roomId!);
    if (doors.isEmpty) return false;

    for (final door in doors) {
      if (start.roomId == null && start.x == door.x && start.y == door.y) {
        return maxSteps >= 1;
      }

      final stepsToDoor = _distanceToTile(start, door, maxSteps, gameState);
      if (stepsToDoor != null && stepsToDoor + 1 <= maxSteps) {
        return true;
      }
    }

    return false;
  }

  int? _distanceToTile(
    Position start,
    Position target,
    int maxSteps,
    ClueGameState gameState,
  ) {
    final targetType = boardMap.getTileType(target.x, target.y);
    if (targetType == TileType.wall ||
        (targetType == TileType.room && target.roomId == null)) {
      return null;
    }

    final occupiedTiles = gameState.players
        .where((p) => p != gameState.currentCharacter)
        .where((p) => p.position.roomId == null)
        .map((p) => '${p.position.x},${p.position.y}')
        .toSet();

    if (occupiedTiles.contains('${target.x},${target.y}')) return null;

    const directions = [
      [0, 1],
      [0, -1],
      [1, 0],
      [-1, 0],
    ];
    final visited = <String>{};
    final queue = <_Node>[];

    _seedQueueFromStart(start, visited, queue);

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current.x == target.x && current.y == target.y) {
        return current.steps <= maxSteps ? current.steps : null;
      }
      if (current.steps >= maxSteps) continue;

      for (final direction in directions) {
        final nx = current.x + direction[0];
        final ny = current.y + direction[1];
        final key = '$nx,$ny';

        if (!boardMap.isInsideGrid(nx, ny) || visited.contains(key)) {
          continue;
        }

        final type = boardMap.getTileType(nx, ny);
        if (type == TileType.wall || type == TileType.room) continue;
        if (occupiedTiles.contains(key)) continue;

        visited.add(key);
        queue.add(_Node(nx, ny, current.steps + 1));
      }
    }

    return null;
  }

  void _seedQueueFromStart(
    Position start,
    Set<String> visited,
    List<_Node> queue,
  ) {
    if (start.roomId == null) {
      visited.add('${start.x},${start.y}');
      queue.add(_Node(start.x, start.y, 0));
      return;
    }

    for (final door in boardMap.getDoorsForRoom(start.roomId!)) {
      final key = '${door.x},${door.y}';
      if (visited.add(key)) {
        queue.add(_Node(door.x, door.y, 1));
      }
    }
  }
}

class _Node {
  final int x;
  final int y;
  final int steps;

  const _Node(this.x, this.y, this.steps);
}
