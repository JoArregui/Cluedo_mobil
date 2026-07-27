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

  // Orden clásico del Cluedo original (sentido horario): Scarlett siempre empieza
  static const List<String> _characterClockwiseOrder = [
    'scarlett',   // Miss Scarlett (1ª)
    'mustard',    // Colonel Mustard (2ª)
    'white',      // Mrs. / Dr. White (3ª)
    'green',      // Reverend Green (4º)
    'peacock',    // Mrs. Peacock (5ª)
    'plum',       // Professor Plum (6º)
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

    // 5. Preparar posiciones iniciales FIJAS según las reglas del Cluedo.
    // Cada personaje tiene su START fijo en el borde del tablero (NO se mezclan).
    final boardMap = BoardMap();

    // 6. Crear los SEIS personajes fichas SIEMPRE (6 en total), aunque haya menos jugadores.
    // Los primeros numberOfPlayers son los participantes; el resto se marcan como isBot=true.
    // Se respeta el orden: Scarlett, Mustard, White, Green, Peacock, Plum.
    final List<CharacterCard> allSuspects = fullDeck
        .where((c) => c.type == CardType.character)
        .cast<CharacterCard>()
        .toList();
    final List<PlayerCharacter> players = <PlayerCharacter>[];
    int assignedHumans = 0;
    for (final characterId in _characterClockwiseOrder) {
      final CharacterCard characterCard =
          allSuspects.firstWhere((c) => c.id == characterId);
      final Position startPosition =
          BoardMap.characterStartPositions[characterId] ??
              const Position(x: 0, y: 0);
      final bool esHumano = characterId == selectedCharacterId;
      // Siempre se crean los 6 (fichas visibles). isBot = false solo para el humano seleccionado.
      players.add(
        PlayerCharacter(
          card: characterCard,
          position: startPosition,
          hand: [], // Se llenará después (solo jugadores, es decir, no todos los 6)
          isBot: !esHumano,
          isEliminated: false,
        ),
      );
      if (esHumano) assignedHumans++;
    }
    // Asegurar que numberOfPlayers <= 6 y que los bots/complementarios están en el array
    // (players ya contiene 6 fichas, todas son "jugadores" para refutar; si numberOfPlayers
    // es menor que 6, los sobrantes simplemente actúan como bots más).
    if (assignedHumans == 0 && players.isNotEmpty) {
      // Fallback por si acaso: primer no-eliminado como humano (no debería ocurrir)
      players[0] = players[0].copyWith(isBot: false);
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