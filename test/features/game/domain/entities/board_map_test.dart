import 'package:cluedo_mobil/features/game/domain/entities/board_map.dart';
import 'package:cluedo_mobil/features/game/domain/entities/position.dart';
import 'package:cluedo_mobil/features/game/domain/entities/tile_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BoardMap boardMap;

  setUp(() {
    boardMap = const BoardMap();
  });

  group('BoardMap - getTileType', () {
    test('debería devolver TileType.wall para posiciones de pared central', () {
      // Pared central (10,10 a 14,14 según _isWall)
      expect(boardMap.getTileType(10, 10), equals(TileType.wall));
      expect(boardMap.getTileType(12, 12), equals(TileType.wall));
      expect(boardMap.getTileType(14, 14), equals(TileType.wall));
    });

    test('debería devolver TileType.door para posiciones de puerta conocidas', () {
      // Algunas puertas conocidas de getAllDoors()
      expect(boardMap.getTileType(6, 4), equals(TileType.door));
      expect(boardMap.getTileType(6, 11), equals(TileType.door));
      expect(boardMap.getTileType(3, 14), equals(TileType.door));
      expect(boardMap.getTileType(16, 12), equals(TileType.door));
      expect(boardMap.getTileType(19, 15), equals(TileType.door));
    });

    test('debería devolver TileType.room para posiciones dentro de habitaciones conocidas', () {
      // Study: x 0-5, y 0-5
      expect(boardMap.getTileType(2, 2), equals(TileType.room));
      expect(boardMap.getTileType(0, 0), equals(TileType.room));
      expect(boardMap.getTileType(5, 5), equals(TileType.room));

      // Hall: x 9-14, y 0-6
      expect(boardMap.getTileType(10, 3), equals(TileType.room));
      expect(boardMap.getTileType(9, 0), equals(TileType.room));
      expect(boardMap.getTileType(14, 6), equals(TileType.room));

      // Lounge: x 18-23, y 0-5
      expect(boardMap.getTileType(20, 2), equals(TileType.room));
      expect(boardMap.getTileType(18, 0), equals(TileType.room));
      expect(boardMap.getTileType(23, 5), equals(TileType.room));

      // Library: x 0-5, y 9-13
      expect(boardMap.getTileType(2, 10), equals(TileType.room));
      expect(boardMap.getTileType(0, 9), equals(TileType.room));
      expect(boardMap.getTileType(5, 13), equals(TileType.room));

      // Billiard Room: x 0-5, y 16-20
      expect(boardMap.getTileType(2, 18), equals(TileType.room));
      expect(boardMap.getTileType(0, 16), equals(TileType.room));
      expect(boardMap.getTileType(5, 20), equals(TileType.room));

      // Conservatory: x 0-5, y 22-24
      expect(boardMap.getTileType(2, 23), equals(TileType.room));
      expect(boardMap.getTileType(0, 22), equals(TileType.room));
      expect(boardMap.getTileType(5, 24), equals(TileType.room));

      // Ballroom: x 8-15, y 19-24
      expect(boardMap.getTileType(10, 22), equals(TileType.room));
      expect(boardMap.getTileType(8, 19), equals(TileType.room));
      expect(boardMap.getTileType(15, 24), equals(TileType.room));

      // Kitchen: x 18-23, y 19-24
      expect(boardMap.getTileType(20, 23), equals(TileType.room));
      expect(boardMap.getTileType(18, 19), equals(TileType.room));
      expect(boardMap.getTileType(23, 24), equals(TileType.room));

      // Dining Room: x 17-23, y 9-14
      expect(boardMap.getTileType(18, 10), equals(TileType.room));
      expect(boardMap.getTileType(17, 9), equals(TileType.room));
      expect(boardMap.getTileType(23, 14), equals(TileType.room));
    });

    test('debería devolver TileType.walkway para posiciones válidas de pasillo', () {
      // Posiciones que no son pared, puerta ni habitación
      expect(boardMap.getTileType(6, 1), equals(TileType.walkway)); // Pasillo Norte
      expect(boardMap.getTileType(1, 6), equals(TileType.walkway)); // Pasillo Oeste
      expect(boardMap.getTileType(12, 8), equals(TileType.walkway)); // Area central
    });

    test('debería devolver TileType.walkway para posiciones fuera de los límites', () {
      // Fuera del tablero (0-23 x, 0-24 y) - se tratan como walkway, no wall
      expect(boardMap.getTileType(-1, 0), equals(TileType.walkway));
      expect(boardMap.getTileType(24, 0), equals(TileType.walkway));
      expect(boardMap.getTileType(0, -1), equals(TileType.walkway));
      expect(boardMap.getTileType(0, 25), equals(TileType.walkway));
      expect(boardMap.getTileType(30, 30), equals(TileType.walkway));
    });
  });

  group('BoardMap - getRoomIdAt', () {
    test('debería devolver el ID de habitación correcto para coordenadas conocidas', () {
      // Study
      expect(boardMap.getRoomIdAt(2, 2), equals('study'));
      expect(boardMap.getRoomIdAt(0, 0), equals('study'));
      expect(boardMap.getRoomIdAt(5, 5), equals('study'));

      // Hall
      expect(boardMap.getRoomIdAt(10, 3), equals('hall'));
      expect(boardMap.getRoomIdAt(9, 0), equals('hall'));
      expect(boardMap.getRoomIdAt(14, 6), equals('hall'));

      // Lounge
      expect(boardMap.getRoomIdAt(20, 2), equals('lounge'));
      expect(boardMap.getRoomIdAt(18, 0), equals('lounge'));
      expect(boardMap.getRoomIdAt(23, 5), equals('lounge'));

      // Library
      expect(boardMap.getRoomIdAt(2, 10), equals('library'));
      expect(boardMap.getRoomIdAt(0, 9), equals('library'));
      expect(boardMap.getRoomIdAt(5, 13), equals('library'));

      // Billiard Room
      expect(boardMap.getRoomIdAt(2, 18), equals('billiard_room'));
      expect(boardMap.getRoomIdAt(0, 16), equals('billiard_room'));
      expect(boardMap.getRoomIdAt(5, 20), equals('billiard_room'));

      // Conservatory
      expect(boardMap.getRoomIdAt(2, 23), equals('conservatory'));
      expect(boardMap.getRoomIdAt(0, 22), equals('conservatory'));
      expect(boardMap.getRoomIdAt(5, 24), equals('conservatory'));

      // Ballroom
      expect(boardMap.getRoomIdAt(10, 22), equals('ballroom'));
      expect(boardMap.getRoomIdAt(8, 19), equals('ballroom'));
      expect(boardMap.getRoomIdAt(15, 24), equals('ballroom'));

      // Kitchen
      expect(boardMap.getRoomIdAt(20, 23), equals('kitchen'));
      expect(boardMap.getRoomIdAt(18, 19), equals('kitchen'));
      expect(boardMap.getRoomIdAt(23, 24), equals('kitchen'));

      // Dining Room
      expect(boardMap.getRoomIdAt(18, 10), equals('dining_room'));
      expect(boardMap.getRoomIdAt(17, 9), equals('dining_room'));
      expect(boardMap.getRoomIdAt(23, 14), equals('dining_room'));
    });

    test('debería devolver null para coordenadas que no pertenecen a ninguna habitación', () {
      // Pasillos
      expect(boardMap.getRoomIdAt(6, 1), isNull);
      expect(boardMap.getRoomIdAt(1, 6), isNull);
      expect(boardMap.getRoomIdAt(12, 8), isNull);

      // Paredes (que no son puertas)
      expect(boardMap.getRoomIdAt(12, 12), isNull);

      // Fuera de límites
      expect(boardMap.getRoomIdAt(-1, 0), isNull);
      expect(boardMap.getRoomIdAt(24, 0), isNull);
    });
  });

  group('BoardMap - getAllDoors', () {
    test('debería devolver la lista completa de puertas', () {
      final doors = boardMap.getAllDoors();

      // Verificar que tenga la cantidad esperada (contadas manualmente)
      expect(doors.length, equals(17));

      // Verificar posiciones específicas por índice (el orden es fijo)
      expect(doors[0].x, equals(6));
      expect(doors[0].y, equals(4));
      expect(doors[1].x, equals(6));
      expect(doors[1].y, equals(11));
      expect(doors[2].x, equals(3));
      expect(doors[2].y, equals(14));
      expect(doors[3].x, equals(2));
      expect(doors[3].y, equals(15));
      expect(doors[4].x, equals(6));
      expect(doors[4].y, equals(18));
      expect(doors[5].x, equals(4));
      expect(doors[5].y, equals(21));
      expect(doors[6].x, equals(8));
      expect(doors[6].y, equals(4));
      expect(doors[7].x, equals(11));
      expect(doors[7].y, equals(7));
      expect(doors[8].x, equals(12));
      expect(doors[8].y, equals(7));
      expect(doors[9].x, equals(7));
      expect(doors[9].y, equals(21));
      expect(doors[10].x, equals(16));
      expect(doors[10].y, equals(21));
      expect(doors[11].x, equals(9));
      expect(doors[11].y, equals(18));
      expect(doors[12].x, equals(14));
      expect(doors[12].y, equals(18));
      expect(doors[13].x, equals(16));
      expect(doors[13].y, equals(12));
      expect(doors[14].x, equals(19));
      expect(doors[14].y, equals(15));
      expect(doors[15].x, equals(17));
      expect(doors[15].y, equals(4));
      expect(doors[16].x, equals(19));
      expect(doors[16].y, equals(18));

      // Verificar que todas las posiciones sean válidas
      for (final door in doors) {
        expect(door.x, greaterThanOrEqualTo(0));
        expect(door.x, lessThan(24));
        expect(door.y, greaterThanOrEqualTo(0));
        expect(door.y, lessThan(25));
      }
    });
  });

  group('BoardMap - getDoorsForRoom', () {
    test('debería devolver las puertas correctas para cada habitación', () {
      // Probamos unas cuantas habitaciones como muestra

      // Study debería tener puertas que llevan a él
      final studyDoors = boardMap.getDoorsForRoom('study');
      expect(studyDoors, isNotEmpty);
      // Verificar que cada puerta en studyDoors sea adyacente a study o tenga roomId study
      for (final door in studyDoors) {
        final roomId = boardMap.getRoomIdAt(door.x, door.y);
        final isAdjacent = [
          [0, 1], [0, -1], [1, 0], [-1, 0]
        ].any((offset) {
          final nx = door.x + offset[0];
          final ny = door.y + offset[1];
          if (nx >= 0 && nx < 24 && ny >= 0 && ny < 25) {
            return boardMap.getRoomIdAt(nx, ny) == 'study';
          }
          return false;
        });
        expect(roomId == 'study' || isAdjacent, isTrue,
            reason: 'Puerta $door debería estar adyacente o ser de study');
      }

      // Hall
      final hallDoors = boardMap.getDoorsForRoom('hall');
      expect(hallDoors, isNotEmpty);
      for (final door in hallDoors) {
        final roomId = boardMap.getRoomIdAt(door.x, door.y);
        final isAdjacent = [
          [0, 1], [0, -1], [1, 0], [-1, 0]
        ].any((offset) {
          final nx = door.x + offset[0];
          final ny = door.y + offset[1];
          if (nx >= 0 && nx < 24 && ny >= 0 && ny < 25) {
            return boardMap.getRoomIdAt(nx, ny) == 'hall';
          }
          return false;
        });
        expect(roomId == 'hall' || isAdjacent, isTrue,
            reason: 'Puerta $door debería estar adyacente o ser de hall');
      }
    });

    test('debería devolver lista vacía para habitación inexistente', () {
      final doors = boardMap.getDoorsForRoom('nonexistent');
      expect(doors, isEmpty);
    });
  });
}