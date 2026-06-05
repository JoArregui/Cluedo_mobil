import 'position.dart';
import 'tile_type.dart';

class BoardMap {
  final int columns = 24;
  final int rows = 25;

  const BoardMap();

  /// Obtiene el tipo de casilla en unas coordenadas dadas
  TileType getTileType(int x, int y) {
    if (_isWall(x, y)) return TileType.wall;
    if (_isDoor(x, y)) return TileType.door;
    if (getRoomIdAt(x, y) != null) return TileType.room;
    return TileType.walkway;
  }

  /// Centralización exhaustiva de los ID de habitaciones del Cluedo clásico
  String? getRoomIdAt(int x, int y) {
    // Habitaciones de la zona superior
    if (x >= 0 && x <= 5 && y >= 0 && y <= 5) return 'study';
    if (x >= 9 && x <= 14 && y >= 0 && y <= 6) return 'hall';
    if (x >= 18 && x <= 23 && y >= 0 && y <= 5) return 'lounge';

    // Habitaciones de la zona media
    if (x >= 0 && x <= 5 && y >= 9 && y <= 13) return 'library';
    if (x >= 0 && x <= 5 && y >= 16 && y <= 20) return 'billiard_room';
    if (x >= 17 && x <= 23 && y >= 9 && y <= 14) return 'dining_room';

    // Habitaciones de la zona inferior
    if (x >= 0 && x <= 5 && y >= 22 && y <= 24) return 'conservatory';
    if (x >= 8 && x <= 15 && y >= 19 && y <= 24) return 'ballroom';
    if (x >= 18 && x <= 23 && y >= 19 && y <= 24) return 'kitchen';

    return null;
  }

  bool _isWall(int x, int y) {
    // Clásico sótano/escaleras central (inaccesible)
    if (x >= 10 && x <= 14 && y >= 10 && y <= 14) return true;
    return false;
  }

  bool _isDoor(int x, int y) {
    final doors = getAllDoors();
    return doors.any((d) => d.x == x && d.y == y);
  }

  /// Coordenadas de las puertas alineadas milimétricamente con el borde exterior de cada habitación
  List<Position> getAllDoors() {
    return const [
      // Estudio (Frontera: x:0-5, y:0-5) -> Puerta en su muro sur externo
      Position(x: 6, y: 4, roomId: null),
      
      // Biblioteca (Frontera: x:0-5, y:9-13) -> Puerta este y puerta sur
      Position(x: 6, y: 11, roomId: null),
      Position(x: 3, y: 14, roomId: null),
      
      // Sala de billar (Frontera: x:0-5, y:16-20) -> Puerta norte y puerta este
      Position(x: 2, y: 15, roomId: null),
      Position(x: 6, y: 18, roomId: null),
      
      // Conservatorio (Frontera: x:0-5, y:22-24) -> Puerta norte
      Position(x: 4, y: 21, roomId: null),
      
      // Vestíbulo / Hall (Frontera: x:9-14, y:0-6) -> Puerta oeste y puertas sur
      Position(x: 8, y: 4, roomId: null),
      Position(x: 11, y: 7, roomId: null),
      Position(x: 12, y: 7, roomId: null),
      
      // Sala de baile / Ballroom (Frontera: x:8-15, y:19-24) -> Puertas laterales y norte
      Position(x: 7, y: 21, roomId: null),
      Position(x: 16, y: 21, roomId: null),
      Position(x: 9, y: 18, roomId: null),
      Position(x: 14, y: 18, roomId: null),
      
      // Comedor / Dining Room (Frontera: x:17-23, y:9-14) -> Puerta oeste y puerta sur
      Position(x: 16, y: 12, roomId: null),
      Position(x: 19, y: 15, roomId: null),
      
      // Salón / Lounge (Frontera: x:18-23, y:0-5) -> Puerta oeste en su muro externo
      Position(x: 17, y: 4, roomId: null),
      
      // Cocina (Frontera: x:18-23, y:19-24) -> Puerta norte en su muro externo
      Position(x: 19, y: 18, roomId: null),
    ];
  }

  /// Retorna las puertas específicas de una habitación
  List<Position> getDoorsForRoom(String roomId) {
    return getAllDoors().where((d) => getRoomIdAt(d.x, d.y) == roomId || _isAdjacentToRoom(d, roomId)).toList();
  }

  bool _isAdjacentToRoom(Position door, String roomId) {
    final adjacentCoords = [
      [0, 1], [0, -1], [1, 0], [-1, 0]
    ];
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