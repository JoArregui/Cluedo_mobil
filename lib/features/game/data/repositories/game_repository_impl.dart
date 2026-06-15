import 'dart:math';
import '../../domain/entities/character.dart';
import '../../domain/entities/position.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/state_game.dart';
import '../../domain/entities/board_map.dart';
import '../datasources/game_local_data_source.dart';

class GameRepositoryImpl implements GameRepository {
  final GameLocalDataSource localDataSource;
  final Random _random = Random();

  // Character IDs in clockwise order starting from Miss Scarlett
  static const List<String> _characterClockwiseOrder = [
    'scarlett',   // Miss Scarlett
    'green',      // Reverend Green
    'peacock',    // Mrs Peacock
    'plum',       // Prof Plum
    'orchid',     // Dr Orchid
    'mustard',    // Colonel Mustard
  ];

  GameRepositoryImpl({required this.localDataSource});

  @override
  Future<ClueGameState> initializeLocalGame({required int numberOfPlayers, required String selectedCharacterId}) async {
    // 1. Obtener cartas
    final List<ClueCard> fullDeck = await localDataSource.getLocalDeck();

    // 2. Separar el mazo por categorías
    final List<CharacterCard> characters = fullDeck
        .where((c) => c.type == CardType.character)
        .cast<CharacterCard>()
        .toList();
    final List<WeaponCard> weapons = fullDeck
        .where((c) => c.type == CardType.weapon)
        .cast<WeaponCard>()
        .toList();
    final List<RoomCard> rooms = fullDeck
        .where((c) => c.type == CardType.room)
        .cast<RoomCard>()
        .toList();
    final List<ClueCard> clueCards = fullDeck
        .where((c) => c.type == CardType.clue)
        .cast<ClueCard>()
        .toList();
    // Ensure the selected character is not chosen as secret
    characters.removeWhere((c) => c.id == selectedCharacterId);

    // 3. Seleccionar una carta aleatoria de cada tipo para el sobre (solución)
    final CharacterCard secretCharacter =
        characters.removeAt(_random.nextInt(characters.length));
    final WeaponCard secretWeapon =
        weapons.removeAt(_random.nextInt(weapons.length));
    final RoomCard secretRoom =
        rooms.removeAt(_random.nextInt(rooms.length));

    // 4. Barajar las cartas restantes de personajes, armas y habitación para repartir
    final List<ClueCard> remainingCharacterWeaponRoom = [
      ...characters,
      ...weapons,
      ...rooms,
    ];
    remainingCharacterWeaponRoom.shuffle(_random);

    // 5. Barajar el mazo de cartas de pista
    final List<ClueCard> shuffledClueCards = List.of(clueCards)..shuffle(_random);

    // 5. Preparar posiciones iniciales para los tokens (espacios nombrados alrededor del tablero)
    // Definimos seis posiciones iniciales (esquinas y puntos medios de los lados)
    final List<Position> startPositions = [
      const Position(x: 1, y: 1),   // cerca de esquina superior izquierda
      const Position(x: 1, y: 22),  // cerca de esquina inferior izquierda
      const Position(x: 22, y: 1),  // cerca de esquina superior derecha
      const Position(x: 22, y: 22), // cerca de esquina inferior derecha
      const Position(x: 11, y: 0),  // medio superior
      const Position(x: 11, y: 24), // medio inferior
    ];
    startPositions.shuffle(_random);

    // 6. Crear jugadores basado en numberOfPlayers
    final List<PlayerCharacter> players = <PlayerCharacter>[];
    for (int i = 0; i < numberOfPlayers; i++) {
      // Asignar un personaje aleatorio del mazo de personajes restantes
      final CharacterCard characterCard =
          characters.isNotEmpty
              ? characters.removeAt(_random.nextInt(characters.length))
              : // Si no quedan personajes, usar uno de la solución (no debería ocurrir con <=6 jugadores)
                  secretCharacter;
      players.add(
        PlayerCharacter(
          card: characterCard,
          position: startPositions[i % startPositions.length],
          hand: [], // Se llenará después
          isBot: i != 0, // Primer jugador es humano, el resto bots
        ),
      );
    }

    // 8. Repartir las cartas restantes de personajes, armas y habitaciones entre los jugadores
    int playerIndex = 0;
    for (final card in remainingCharacterWeaponRoom) {
      final player = players[playerIndex % players.length];
      player.hand.add(card);
      playerIndex++;
    }

    // 9. Colocar las armas en habitaciones aleatorias y distintas
    final List<String> availableRoomIds =
        rooms.map((r) => r.id).toList()..shuffle(_random);
    final Map<String, Position> weaponPositions = <String, Position>{};
    final boardMap = BoardMap();
    for (int i = 0; i < weapons.length; i++) {
      final String roomId = availableRoomIds[i % availableRoomIds.length];
      // Colocar el arma en una posición caminable aleatoria dentro de la habitación
      final weaponPosition = boardMap.getRandomWalkablePositionInRoom(roomId, _random);
      weaponPositions[weapons[i].id] = weaponPosition ?? Position(x: 0, y: 0, roomId: roomId);
    }

    // Determine the first player in clockwise order
    int firstPlayerIndex = 0;
    if (players.isNotEmpty) {
      // Find the player with the smallest clockwise order index
      int smallestOrderIndex = _characterClockwiseOrder.length;
      for (int i = 0; i < players.length; i++) {
        String characterId = players[i].card.id;
        int orderIndex = _characterClockwiseOrder.indexOf(characterId);
        if (orderIndex != -1 && orderIndex < smallestOrderIndex) {
          smallestOrderIndex = orderIndex;
          firstPlayerIndex = i;
        }
      }
      // If no standard characters found, default to player 0
      if (smallestOrderIndex == _characterClockwiseOrder.length) {
        firstPlayerIndex = 0;
      }
    }

    // 10. Devolver el estado inicial
    return ClueGameState(
      players: players,
      currentTurnIndex: firstPlayerIndex,
      solution: CaseSolution(
        character: secretCharacter,
        weapon: secretWeapon,
        room: secretRoom,
      ),
      phase: GamePhase.rolling,
      totalDeck: fullDeck,
      clueDeck: shuffledClueCards,
      boardMap: boardMap,
      weaponPositions: weaponPositions,
      lastDiceRoll: const [0, 0],
      currentDiceResult: null,
      refutingPlayerIndex: null,
      currentSuggestion: null,
      currentRoomForNarrative: null,
    );
  }
}