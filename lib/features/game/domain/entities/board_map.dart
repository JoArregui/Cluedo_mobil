import 'position.dart';
import 'tile_type.dart';

class BoardMap {
  final int columns = 24;
  final int rows = 25;

  const BoardMap();

  TileType getTileType(int x, int y) {
    if (_isWall(x, y)) return TileType.wall;
    if (_isDoor(x, y)) return TileType.door;
    if (getRoomIdAt(x, y) != null) return TileType.room;
    return TileType.walkway;
  }

  String? getRoomIdAt(int x, int y) {
    if (x >= 0 && x <= 5 && y >= 0 && y <= 5) return 'study';
    if (x >= 9 && x <= 14 && y >= 0 && y <= 6) return 'hall';
    if (x >= 18 && x <= 23 && y >= 0 && y <= 5) return 'lounge';
    if (x >= 0 && x <= 5 && y >= 9 && y <= 13) return 'library';
    if (x >= 0 && x <= 5 && y >= 16 && y <= 20) return 'billiard_room';
    if (x >= 17 && x <= 23 && y >= 9 && y <= 14) return 'dining_room';
    if (x >= 0 && x <= 5 && y >= 22 && y <= 24) return 'conservatory';
    if (x >= 8 && x <= 15 && y >= 19 && y <= 24) return 'ballroom';
    if (x >= 18 && x <= 23 && y >= 19 && y <= 24) return 'kitchen';
    return null;
  }

  bool _isWall(int x, int y) {
    if (x >= 10 && x <= 14 && y >= 10 && y <= 14) return true;
    return false;
  }

  bool _isDoor(int x, int y) {
    return getAllDoors().any((d) => d.x == x && d.y == y);
  }

  List<Position> getAllDoors() {
    return const [
      Position(x: 6, y: 4), Position(x: 6, y: 11), Position(x: 3, y: 14),
      Position(x: 2, y: 15), Position(x: 6, y: 18), Position(x: 4, y: 21),
      Position(x: 8, y: 4), Position(x: 11, y: 7), Position(x: 12, y: 7),
      Position(x: 7, y: 21), Position(x: 16, y: 21), Position(x: 9, y: 18),
      Position(x: 14, y: 18), Position(x: 16, y: 12), Position(x: 19, y: 15),
      Position(x: 17, y: 4), Position(x: 19, y: 18),
    ];
  }

  List<Position> getDoorsForRoom(String roomId) {
    return getAllDoors().where((d) => getRoomIdAt(d.x, d.y) == roomId || _isAdjacentToRoom(d, roomId)).toList();
  }

  bool _isAdjacentToRoom(Position door, String roomId) {
    final adjacentCoords = [[0, 1], [0, -1], [1, 0], [-1, 0]];
    for (var offset in adjacentCoords) {
      final nx = door.x + offset[0];
      final ny = door.y + offset[1];
      if (nx >= 0 && nx < 24 && ny >= 0 && ny < 25) {
        if (getRoomIdAt(nx, ny) == roomId) return true;
      }
    }
    return false;
  }
}