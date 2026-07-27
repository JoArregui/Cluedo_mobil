import 'dart:math';

import 'position.dart';
import 'tile_type.dart';

class BoardMap {
  final int columns = 24;
  final int rows = 25;

  const BoardMap();

  static const Map<String, _Bounds> _rooms = {
    'study': _Bounds(1, 5, 1, 4),
    'hall': _Bounds(9, 13, 1, 5),
    'lounge': _Bounds(17, 21, 1, 5),
    'library': _Bounds(1, 6, 7, 10),
    'dining_room': _Bounds(16, 22, 8, 14),
    'billiard_room': _Bounds(1, 5, 12, 16),
    'conservatory': _Bounds(1, 5, 18, 22),
    'ballroom': _Bounds(8, 14, 18, 22),
    'kitchen': _Bounds(17, 21, 18, 22),
  };

  /// Conexiones VIRTUALES de puertas (la puerta NO es una casilla física: es el
  /// hueco en la pared. El valor aquí es la CASILLA DE PASILLO (walkway) que
  /// queda justo enfrente de dicha abertura. Para entrar/salir, la ficha tiene
  /// que alcanzar esta casilla de pasillo y desde allí cruzar (+1 paso extra).
  /// Conexiones de puertas según la imagen board_texturedoors.png.
  /// Cada Position es la CASILLA DE PASILLO (walkway) que queda frente al hueco
  /// de la puerta virtual. Para entrar/salir, la ficha tiene que alcanzar esta
  /// casilla y desde allí cruzar (+1 paso extra).
  static const Map<String, List<Position>> _doorConnections = {
    'study': [
      Position(x: 6, y: 4),
    ],
    'hall': [
      Position(x: 8, y: 5),
      Position(x: 11, y: 6),
    ],
    'lounge': [
      Position(x: 16, y: 4),
      Position(x: 19, y: 6),
    ],
    'library': [
      Position(x: 7, y: 8),
      Position(x: 6, y: 11),
    ],
    'dining_room': [
      Position(x: 15, y: 11),
      Position(x: 15, y: 13),
    ],
    'billiard_room': [
      Position(x: 6, y: 13),
      Position(x: 6, y: 15),
    ],
    'conservatory': [
      Position(x: 6, y: 19),
      Position(x: 6, y: 21),
    ],
    'ballroom': [
      Position(x: 8, y: 17),
      Position(x: 14, y: 17),
      Position(x: 15, y: 15),
    ],
    'kitchen': [
      Position(x: 16, y: 20),
      Position(x: 19, y: 17),
    ],
  };

  static const Map<String, Position> characterStartPositions = {
    'scarlett': Position(x: 16, y: 0),
    'plum': Position(x: 0, y: 5),
    'mustard': Position(x: 23, y: 7),
    'white': Position(x: 23, y: 15),
    'green': Position(x: 9, y: 24),
    'peacock': Position(x: 0, y: 17),
  };

  static const List<Position> _edgeExitPositions = [
    Position(x: 16, y: 0),
    Position(x: 0, y: 5),
    Position(x: 23, y: 7),
    Position(x: 23, y: 15),
    Position(x: 9, y: 24),
    Position(x: 0, y: 17),
  ];

  static const List<_Bounds> _inaccessibleZones = [
    _Bounds(9, 14, 8, 14),
    _Bounds(7, 8, 1, 3),
    _Bounds(15, 15, 1, 4),
    _Bounds(7, 8, 21, 24),
    _Bounds(16, 16, 22, 24),
    _Bounds(22, 23, 21, 24),
  ];

  bool isInsideGrid(int x, int y) {
    return x >= 0 && x < columns && y >= 0 && y < rows;
  }

  bool isSelectableTile(int x, int y) {
    final type = getTileType(x, y);
    return type == TileType.walkway || type == TileType.room;
  }

  /// Devuelve el tipo de la casilla FÍSICA del tablero.
  /// Importante: las PUERTAS no son casillas físicas, son huecos virtuales en la
  /// pared. Por tanto getTileType NUNCA devuelve TileType.door. La casilla que
  /// queda "frente al hueco" es una walkway normal.
  TileType getTileType(int x, int y) {
    if (!isInsideGrid(x, y)) return TileType.wall;
    if (getRoomIdAt(x, y) != null) return TileType.room;
    if (_isWall(x, y)) return TileType.wall;
    if (_isOuterBorder(x, y) && !_isEdgeExit(x, y)) return TileType.wall;
    return TileType.walkway;
  }

  String? getRoomIdAt(int x, int y) {
    if (!isInsideGrid(x, y)) return null;
    for (final entry in _rooms.entries) {
      if (entry.value.contains(x, y)) return entry.key;
    }
    return null;
  }

  Position getStartPositionForCharacter(String characterId) {
    return characterStartPositions[characterId] ?? const Position(x: 0, y: 0);
  }

  List<String> get roomIds => _rooms.keys.toList(growable: false);

  /// Devuelve true si la casilla de pasillo (x, y) es "el punto de acceso" a
  /// alguna habitación (está justo enfrente del hueco de una puerta virtual).
  bool isDoorwayTile(int x, int y) {
    final tile = getTileType(x, y);
    if (tile != TileType.walkway) return false;
    for (final entry in _doorConnections.entries) {
      for (final p in entry.value) {
        if (p.x == x && p.y == y) return true;
      }
    }
    return false;
  }

  /// Dado un punto de pasillo que es doorway (frente a hueco), devuelve qué
  /// habitaciones tienen acceso desde ahí. Normalmente una, pero podría haber
  /// shared access.
  List<String> roomIdsReachableFromDoorwayTile(int x, int y) {
    final ids = <String>[];
    for (final entry in _doorConnections.entries) {
      for (final p in entry.value) {
        if (p.x == x && p.y == y) {
          ids.add(entry.key);
          break;
        }
      }
    }
    return ids;
  }

  Map<String, dynamic> getBoardLayout() {
    final rooms = _rooms.entries
        .map(
          (entry) => {
            'id': entry.key,
            'x0': entry.value.x0,
            'x1': entry.value.x1,
            'y0': entry.value.y0,
            'y1': entry.value.y1,
          },
        )
        .toList(growable: false);

    final walls = <Map<String, int>>[];
    for (final zone in _inaccessibleZones) {
      for (var x = zone.x0; x <= zone.x1; x++) {
        for (var y = zone.y0; y <= zone.y1; y++) {
          walls.add({'x': x, 'y': y});
        }
      }
    }

    final walkways = <Map<String, int>>[];
    for (var x = 0; x < columns; x++) {
      for (var y = 0; y < rows; y++) {
        if (getTileType(x, y) == TileType.walkway) {
          walkways.add({'x': x, 'y': y});
        }
      }
    }

    // "doors" en el layout: enviamos los puntos de pasillo frente a cada
    // hueco virtual, para que el renderer pueda marcar/highlight los puntos
    // de acceso. El campo 'isDoorway' permite distinguirlos en el HTML 3D.
    final doorways = <Map<String, dynamic>>[];
    for (final entry in _doorConnections.entries) {
      for (final p in entry.value) {
        doorways.add({
          'x': p.x,
          'y': p.y,
          'roomId': entry.key,
          'isDoorway': true,
        });
      }
    }

    final characterStartPositionsByLayout = <String, Map<String, int>>{};
    for (final entry in characterStartPositions.entries) {
      characterStartPositionsByLayout[entry.key] = {
        'x': entry.value.x,
        'y': entry.value.y,
      };
    }

    return {
      'columns': columns,
      'rows': rows,
      'rooms': rooms,
      'doors': doorways,
      'walls': walls,
      'walkways': walkways,
      'inaccessibleZones': _inaccessibleZones
          .map(
            (zone) => {
              'x0': zone.x0,
              'x1': zone.x1,
              'y0': zone.y0,
              'y1': zone.y1,
            },
          )
          .toList(growable: false),
      'characterStartPositions': characterStartPositionsByLayout,
    };
  }

  Position? getRoomCenterPosition(String roomId) {
    final bounds = _rooms[roomId];
    if (bounds == null) return null;

    final midpointX = (bounds.x0 + bounds.x1) / 2;
    final midpointY = (bounds.y0 + bounds.y1) / 2;
    double bestDistance = double.infinity;
    int bestX = (bounds.x0 + bounds.x1) ~/ 2;
    int bestY = (bounds.y0 + bounds.y1) ~/ 2;

    for (var x = bounds.x0; x <= bounds.x1; x++) {
      for (var y = bounds.y0; y <= bounds.y1; y++) {
        if (getTileType(x, y) != TileType.room) continue;

        final distance = (x - midpointX) * (x - midpointX) +
            (y - midpointY) * (y - midpointY);
        if (distance < bestDistance) {
          bestDistance = distance;
          bestX = x;
          bestY = y;
        }
      }
    }

    return Position(x: bestX, y: bestY, roomId: roomId);
  }

  bool _isWall(int x, int y) {
    return _inaccessibleZones.any((zone) => zone.contains(x, y));
  }

  bool _isOuterBorder(int x, int y) {
    return x == 0 || x == columns - 1 || y == 0 || y == rows - 1;
  }

  bool _isEdgeExit(int x, int y) {
    return _edgeExitPositions.any((position) =>
        position.x == x && position.y == y);
  }

  /// Devuelve TODOS los puntos de PASILLO que son "puerta virtual" (frente al
  /// hueco) para entrar/salir de habitaciones.
  List<Position> getAllDoorways() {
    final result = <Position>[];
    for (final entry in _doorConnections.entries) {
      result.addAll(entry.value);
    }
    return List<Position>.unmodifiable(result);
  }

  /// Devuelve los puntos de PASILLO (walkway) desde los que se puede entrar a
  /// una habitación concreta. Son las casillas justo enfrente de sus huecos.
  List<Position> getDoorsForRoom(String roomId) {
    return List<Position>.unmodifiable(
      _doorConnections[roomId] ?? const <Position>[],
    );
  }

  Position? getRandomWalkablePositionInRoom(String roomId, Random random) {
    final bounds = _rooms[roomId];
    if (bounds == null) return null;

    for (var i = 0; i < 50; i++) {
      final x = random.nextInt(bounds.x1 - bounds.x0 + 1) + bounds.x0;
      final y = random.nextInt(bounds.y1 - bounds.y0 + 1) + bounds.y0;
      if (getTileType(x, y) == TileType.room) {
        return Position(x: x, y: y, roomId: roomId);
      }
    }

    return Position(
      x: (bounds.x0 + bounds.x1) ~/ 2,
      y: (bounds.y0 + bounds.y1) ~/ 2,
      roomId: roomId,
    );
  }
}

class _Bounds {
  final int x0;
  final int x1;
  final int y0;
  final int y1;

  const _Bounds(this.x0, this.x1, this.y0, this.y1);

  bool contains(int x, int y) {
    return x >= x0 && x <= x1 && y >= y0 && y <= y1;
  }
}
