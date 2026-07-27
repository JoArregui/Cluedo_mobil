import 'package:cluedo_mobil/features/game/domain/entities/board_map.dart';
import 'package:cluedo_mobil/features/game/domain/entities/card.dart';
import 'package:cluedo_mobil/features/game/domain/entities/character.dart';
import 'package:cluedo_mobil/features/game/domain/entities/position.dart';
import 'package:cluedo_mobil/features/game/domain/entities/state_game.dart';
import 'package:cluedo_mobil/features/game/domain/entities/tile_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const boardMap = BoardMap();

  PlayerCharacter player(String id, Position position) {
    return PlayerCharacter(
      isBot: id != 'scarlett',
      position: position,
      hand: const [],
      card: CharacterCard(id: id, nameEs: id, nameEn: id, hexColor: '#FF0000'),
    );
  }

  ClueGameState gameState({
    required Position currentPosition,
    required int? dice,
    List<PlayerCharacter> others = const [],
  }) {
    return ClueGameState(
      players: [player('scarlett', currentPosition), ...others],
      currentTurnIndex: 0,
      solution: const CaseSolution(
        character: CharacterCard(
          id: 'mustard',
          nameEs: 'Mustard',
          nameEn: 'Mustard',
          hexColor: '#FFD700',
        ),
        weapon: WeaponCard(
          id: 'revolver',
          nameEs: 'Revolver',
          nameEn: 'Revolver',
        ),
        room: RoomCard(id: 'hall', nameEs: 'Hall', nameEn: 'Hall'),
      ),
      phase: GamePhase.moving,
      currentDiceResult: dice,
      totalDeck: const [],
      clueDeck: const [],
      boardMap: boardMap,
      weaponPositions: const {},
    );
  }

  test('DIAGNÓSTICO WHITE: visualizar el grid alrededor de (23,15)', () {
    final start = BoardMap.characterStartPositions['white']!;
    print('WHITE START: (${start.x}, ${start.y})');
    print('Tile type en START: ${boardMap.getTileType(start.x, start.y)}');
    print('Tile type vecinos:');
    for (final dy in [-1, 0, 1]) {
      for (final dx in [-1, 0, 1]) {
        final nx = start.x + dx;
        final ny = start.y + dy;
        if (boardMap.isInsideGrid(nx, ny)) {
          final t = boardMap.getTileType(nx, ny);
          final r = boardMap.getRoomIdAt(nx, ny);
          print('  ($nx,$ny): tile=$t roomId=$r');
        }
      }
    }
  });

  test('DIAGNÓSTICO: ruta completa WHITE→(22,15)→(21,15)→...→(19,17)', () {
    final expectedPath = [
      const Position(x: 23, y: 15),
      const Position(x: 22, y: 15),
      const Position(x: 21, y: 15),
      const Position(x: 20, y: 15),
      const Position(x: 19, y: 15),
      const Position(x: 19, y: 16),
      const Position(x: 19, y: 17),
    ];
    for (int i = 0; i < expectedPath.length; i++) {
      final p = expectedPath[i];
      final t = boardMap.getTileType(p.x, p.y);
      final r = boardMap.getRoomIdAt(p.x, p.y);
      print('  paso $i: (${p.x},${p.y}) -> tile=$t room=$r');
      if (t != TileType.walkway) {
        print('    ¡BLOQUEADO! Casilla ${i + 1} del path no es walkway');
      }
    }
  });

  test('DIAGNÓSTICO: BFS manual desde (23,15) para ver qué casillas son alcanzables con dado=6', () {
    final start = Position(x: 23, y: 15);
    final maxSteps = 6;
    final visited = <String>{};
    final queue = <List<Position>>[[start]];

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;
      final key = '${current.x},${current.y}';
      if (visited.contains(key)) continue;
      visited.add(key);

      if (path.length - 1 >= maxSteps) continue;

      for (final dir in [
        [0, 1],
        [0, -1],
        [1, 0],
        [-1, 0]
      ]) {
        final nx = current.x + dir[0];
        final ny = current.y + dir[1];
        if (!boardMap.isInsideGrid(nx, ny)) continue;
        final t = boardMap.getTileType(nx, ny);
        if (t == TileType.wall || t == TileType.room) continue;
        final nKey = '$nx,$ny';
        if (visited.contains(nKey)) continue;
        queue.add([...path, Position(x: nx, y: ny)]);
      }
    }

    print('WHITE en (23,15) con dado=$maxSteps alcanza ${visited.length} casillas:');
    final sorted = visited.toList()..sort();
    for (final key in sorted) {
      print('  $key');
    }
  });

  test('DIAGNÓSTICO: BFS manual desde GREEN (9,24) para ver qué casillas son alcanzables con dado=6', () {
    final start = Position(x: 9, y: 24);
    final maxSteps = 6;
    final visited = <String>{};
    final queue = <List<Position>>[[start]];

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;
      final key = '${current.x},${current.y}';
      if (visited.contains(key)) continue;
      visited.add(key);

      if (path.length - 1 >= maxSteps) continue;

      for (final dir in [
        [0, 1],
        [0, -1],
        [1, 0],
        [-1, 0]
      ]) {
        final nx = current.x + dir[0];
        final ny = current.y + dir[1];
        if (!boardMap.isInsideGrid(nx, ny)) continue;
        final t = boardMap.getTileType(nx, ny);
        if (t == TileType.wall || t == TileType.room) continue;
        final nKey = '$nx,$ny';
        if (visited.contains(nKey)) continue;
        queue.add([...path, Position(x: nx, y: ny)]);
      }
    }

    print('GREEN en (9,24) con dado=$maxSteps alcanza ${visited.length} casillas:');
    final sorted = visited.toList()..sort();
    for (final key in sorted) {
      print('  $key');
    }
  });
}