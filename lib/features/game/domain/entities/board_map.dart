import 'position.dart';
import 'tile_type.dart';
import 'dart:math';

class BoardMap {
  final int columns = 24;
  final int rows = 25;

  const BoardMap();

  // ── Grid 24x25 ────────────────────────────────────────────────────────────
  //
  //  x:  0   | 1-6        | 7-8     | 9-14       | 15-16   | 17-22      | 23
  //      borde  hab col A   pasillo   hab col B    pasillo   hab col C   borde
  //
  //  y:  0   | 1-6        | 7-8     | 9-14       | 15-16   | 17-22      | 23-24
  //      borde  hab fila 1  pasillo   hab fila 2   pasillo   hab fila 3  borde
  //
  //  Habitaciones (todas 6x6):
  //    study        x:1-6,   y:1-6
  //    hall         x:9-14,  y:1-6
  //    lounge       x:17-22, y:1-6
  //    library      x:1-6,   y:9-14
  //    billiard_room x:9-14, y:9-14
  //    dining_room  x:17-22, y:9-14
  //    conservatory x:1-6,   y:17-22
  //    ballroom     x:9-14,  y:17-22
  //    kitchen      x:17-22, y:17-22

  TileType getTileType(int x, int y) {
    if (_isWall(x, y)) return TileType.wall;
    if (_isDoor(x, y)) return TileType.door;
    if (getRoomIdAt(x, y) != null) return TileType.room;
    return TileType.walkway;
  }

  String? getRoomIdAt(int x, int y) {
    // Fila 1
    if (x >= 1  && x <= 6  && y >= 1  && y <= 6)  return 'study';
    if (x >= 9  && x <= 14 && y >= 1  && y <= 6)  return 'hall';
    if (x >= 17 && x <= 22 && y >= 1  && y <= 6)  return 'lounge';
    // Fila 2
    if (x >= 1  && x <= 6  && y >= 9  && y <= 14) return 'library';
    if (x >= 9  && x <= 14 && y >= 9  && y <= 14) return 'billiard_room';
    if (x >= 17 && x <= 22 && y >= 9  && y <= 14) return 'dining_room';
    // Fila 3
    if (x >= 1  && x <= 6  && y >= 17 && y <= 22) return 'conservatory';
    if (x >= 9  && x <= 14 && y >= 17 && y <= 22) return 'ballroom';
    if (x >= 17 && x <= 22 && y >= 17 && y <= 22) return 'kitchen';
    return null;
  }

  bool _isWall(int x, int y) {
    // Sin muros interiores — los pasillos de 2 tiles garantizan navegación fluida
    return false;
  }

  bool _isDoor(int x, int y) {
    return getAllDoors().any((d) => d.x == x && d.y == y);
  }

  List<Position> getAllDoors() {
    return const [
      // study (x:1-6, y:1-6)
      Position(x: 7, y: 3),   // salida derecha  → pasillo x:7-8
      Position(x: 3, y: 7),   // salida inferior → pasillo y:7-8

      // hall (x:9-14, y:1-6)
      Position(x: 10, y: 7),  // salida inferior izquierda
      Position(x: 13, y: 7),  // salida inferior derecha

      // lounge (x:17-22, y:1-6)
      Position(x: 16, y: 3),  // salida izquierda → pasillo x:15-16
      Position(x: 19, y: 7),  // salida inferior

      // library (x:1-6, y:9-14)
      Position(x: 3, y: 8),   // salida superior → pasillo y:7-8
      Position(x: 7, y: 11),  // salida derecha  → pasillo x:7-8
      Position(x: 3, y: 15),  // salida inferior → pasillo y:15-16

      // billiard_room (x:9-14, y:9-14)
      Position(x: 11, y: 8),  // salida superior
      Position(x: 8,  y: 11), // salida izquierda
      Position(x: 15, y: 11), // salida derecha
      Position(x: 11, y: 15), // salida inferior

      // dining_room (x:17-22, y:9-14)
      Position(x: 19, y: 8),  // salida superior
      Position(x: 16, y: 11), // salida izquierda
      Position(x: 19, y: 15), // salida inferior

      // conservatory (x:1-6, y:17-22)
      Position(x: 3, y: 16),  // salida superior → pasillo y:15-16
      Position(x: 7, y: 19),  // salida derecha  → pasillo x:7-8

      // ballroom (x:9-14, y:17-22)
      Position(x: 10, y: 16), // salida superior izquierda
      Position(x: 13, y: 16), // salida superior derecha

      // kitchen (x:17-22, y:17-22)
      Position(x: 19, y: 16), // salida superior
      Position(x: 16, y: 19), // salida izquierda
    ];
  }

  List<Position> getDoorsForRoom(String roomId) {
    return getAllDoors()
        .where((d) => _isAdjacentToRoom(d, roomId))
        .toList();
  }

  /// Returns a random walkable position inside the specified room.
  /// Returns null if the roomId is invalid or no walkable positions found.
  Position? getRandomWalkablePositionInRoom(String roomId, Random random) {
    // Define room boundaries based on roomId
    int xStart, xEnd, yStart, yEnd;
    switch (roomId) {
      case 'study':
        xStart = 1;
        xEnd = 6;
        yStart = 1;
        yEnd = 6;
        break;
      case 'hall':
        xStart = 9;
        xEnd = 14;
        yStart = 1;
        yEnd = 6;
        break;
      case 'lounge':
        xStart = 17;
        xEnd = 22;
        yStart = 1;
        yEnd = 6;
        break;
      case 'library':
        xStart = 1;
        xEnd = 6;
        yStart = 9;
        yEnd = 14;
        break;
      case 'billiard_room':
        xStart = 9;
        xEnd = 14;
        yStart = 9;
        yEnd = 14;
        break;
      case 'dining_room':
        xStart = 17;
        xEnd = 22;
        yStart = 9;
        yEnd = 14;
        break;
      case 'conservatory':
        xStart = 1;
        xEnd = 6;
        yStart = 17;
        yEnd = 22;
        break;
      case 'ballroom':
        xStart = 9;
        xEnd = 14;
        yStart = 17;
        yEnd = 22;
        break;
      case 'kitchen':
        xStart = 17;
        xEnd = 22;
        yStart = 17;
        yEnd = 22;
        break;
      default:
        return null; // Invalid roomId
    }

    // Generate random positions until we find a walkable one
    final attempts = 50; // Prevent infinite loop
    for (int i = 0; i < attempts; i++) {
      final x = random.nextInt(xEnd - xStart + 1) + xStart;
      final y = random.nextInt(yEnd - yStart + 1) + yStart;
      final tileType = getTileType(x, y);
      if (tileType == TileType.room) {
        return Position(x: x, y: y, roomId: roomId);
      }
      // If we find a door position within the room bounds, skip it
      // (though doors should be at the boundaries, not inside 6x6 rooms)
    }

    // Fallback: return center of room if no walkable found after attempts
    final xCenter = (xStart + xEnd) ~/ 2;
    final yCenter = (yStart + yEnd) ~/ 2;
    return Position(x: xCenter, y: yCenter, roomId: roomId);
  }

  bool _isAdjacentToRoom(Position door, String roomId) {
    const adjacentOffsets = [
      [0, 1], [0, -1], [1, 0], [-1, 0],
    ];
    for (final offset in adjacentOffsets) {
      final nx = door.x + offset[0];
      final ny = door.y + offset[1];
      if (nx >= 0 && nx < columns && ny >= 0 && ny < rows) {
        if (getRoomIdAt(nx, ny) == roomId) return true;
      }
    }
    return false;
  }
}