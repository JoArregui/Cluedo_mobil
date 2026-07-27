import 'package:cluedo_mobil/features/game/domain/entities/board_map.dart';
import 'package:cluedo_mobil/features/game/domain/entities/tile_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const boardMap = BoardMap();

  group('BoardMap', () {
    test('keeps every coordinate inside the 24x25 grid', () {
      expect(boardMap.isInsideGrid(0, 0), isTrue);
      expect(boardMap.isInsideGrid(23, 24), isTrue);
      expect(boardMap.isInsideGrid(-1, 0), isFalse);
      expect(boardMap.isInsideGrid(24, 0), isFalse);
      expect(boardMap.isInsideGrid(0, 25), isFalse);
      expect(boardMap.getTileType(24, 0), TileType.wall);
    });

    test('maps rooms to the board texture layout', () {
      expect(boardMap.getRoomIdAt(3, 2), 'study');
      expect(boardMap.getRoomIdAt(11, 3), 'hall');
      expect(boardMap.getRoomIdAt(19, 3), 'lounge');
      expect(boardMap.getRoomIdAt(3, 8), 'library');
      expect(boardMap.getRoomIdAt(18, 11), 'dining_room');
      expect(boardMap.getRoomIdAt(3, 14), 'billiard_room');
      expect(boardMap.getRoomIdAt(3, 20), 'conservatory');
      expect(boardMap.getRoomIdAt(11, 20), 'ballroom');
      expect(boardMap.getRoomIdAt(19, 20), 'kitchen');
    });

    test('marks central furniture and clue area as non-selectable walls', () {
      expect(boardMap.getTileType(11, 10), TileType.wall);
      expect(boardMap.getTileType(14, 14), TileType.wall);
      expect(boardMap.isSelectableTile(11, 10), isFalse);
    });

    test('treats outer border tiles as non-selectable unless they are explicit exits', () {
      expect(boardMap.getTileType(0, 0), TileType.wall);
      expect(boardMap.getTileType(23, 0), TileType.wall);
      expect(boardMap.getTileType(0, 5), TileType.walkway);
      expect(boardMap.isSelectableTile(0, 0), isFalse);
      expect(boardMap.isSelectableTile(0, 5), isTrue);
    });

    test('exposes doors adjacent to their rooms', () {
      // Las puertas NO son casillas físicas (no son TileType.door).
      // Son huecos virtuales en la pared; las siguientes coordenadas son
      // casillas NORMALES de PASILLO (walkway) situadas justo enfrente del hueco.
      // Se distinguen porque boardMap.isDoorwayTile las marca como "acceso".
      const doorwayTiles = [
        (6, 4),
        (11, 6),
        (19, 6),
        (7, 8),
        (19, 17),
      ];
      for (final (x, y) in doorwayTiles) {
        expect(boardMap.getTileType(x, y), TileType.walkway,
            reason: '($x,$y) debe ser pasillo normal (frente a hueco puerta)');
        expect(boardMap.isDoorwayTile(x, y), isTrue,
            reason: '($x,$y) debe marcarse como doorway (punto de acceso)');
      }

      expect(boardMap.getDoorsForRoom('study'), isNotEmpty);
      expect(boardMap.getDoorsForRoom('kitchen'), isNotEmpty);
      expect(boardMap.getDoorsForRoom('unknown'), isEmpty);

      // La conexión study ↔ (6,4) es exactamente el punto de acceso
      final studyDoors = boardMap.getDoorsForRoom('study');
      expect(
        studyDoors.any((p) => p.x == 6 && p.y == 4),
        isTrue,
        reason: 'Study debe tener doorway en casilla pasillo (6,4)',
      );
    });

    test('uses the six texture start cells for character tokens', () {
      final starts = BoardMap.characterStartPositions.values
          .map((p) => '${p.x},${p.y}')
          .toSet();

      expect(starts.length, 6);
      for (final position in BoardMap.characterStartPositions.values) {
        expect(boardMap.isInsideGrid(position.x, position.y), isTrue);
        expect(boardMap.getTileType(position.x, position.y), TileType.walkway);
      }
    });

    test('exposes the derived texture layout for the board UI and movement logic', () {
      final layout = boardMap.getBoardLayout();

      expect(layout['columns'], 24);
      expect(layout['rows'], 25);
      expect(layout['rooms'], isA<List>());
      expect((layout['rooms'] as List).length, 9);
      expect(layout['doors'], isA<List>());
      expect((layout['doors'] as List).length, greaterThan(0));
      expect(layout['inaccessibleZones'], isA<List>());
      expect((layout['inaccessibleZones'] as List).length, greaterThan(0));
      expect(layout['characterStartPositions'], isA<Map>());
      expect((layout['characterStartPositions'] as Map).containsKey('scarlett'), isTrue);
    });

    test('TODAS las doorways son WALKWAY reales (no wall / no room / no inaccesible) y adyacentes a la pared de su habitación', () {
      // Iterar todas las habitaciones, revisar cada doorway asociada:
      final roomIds = boardMap.roomIds;
      final failures = <String>[];

      for (final roomId in roomIds) {
        final doors = boardMap.getDoorsForRoom(roomId);
        if (doors.isEmpty) {
          failures.add('Habitación $roomId sin puertas!');
          continue;
        }
        for (final d in doors) {
          final type = boardMap.getTileType(d.x, d.y);
          if (type != TileType.walkway) {
            failures.add(
              '$roomId → doorway (${d.x},${d.y}) NO es walkway! es $type',
            );
          }
          if (!boardMap.isDoorwayTile(d.x, d.y)) {
            failures.add(
              '$roomId → doorway (${d.x},${d.y}) isDoorwayTile=false',
            );
          }
          // Debe ser vecino ortogonal (adyacente) de la habitación objetivo
          final neighbors = [
            [d.x + 1, d.y],
            [d.x - 1, d.y],
            [d.x, d.y + 1],
            [d.x, d.y - 1],
          ];
          final touches = neighbors.any((pair) => boardMap.getRoomIdAt(pair[0], pair[1]) == roomId);
          if (!touches) {
            failures.add(
              '$roomId → doorway (${d.x},${d.y}) NO es adyacente ortogonal a la pared de la habitación',
            );
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('; '));
    });
  });
}
