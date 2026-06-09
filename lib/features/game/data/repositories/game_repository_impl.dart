import 'dart:math';
import '../../domain/entities/character.dart';
import '../../domain/entities/position.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/state_game.dart';
import '../../domain/entities/board_map.dart';
import '../datasources/game_cms_data_source.dart';

class GameRepositoryImpl implements GameRepository {
  final GameCmsDataSource cmsDataSource;
  final Random _random = Random();

  GameRepositoryImpl({required this.cmsDataSource});

  @override
  Future<ClueGameState> initializeCmsGame({required int numberOfPlayers}) async {
    // 1. Obtener cartas desde el CMS
    final List<ClueCard> fullDeck = await cmsDataSource.getCmsDeck();

    // 2. Separar el mazo por categorías con casting explícito
    final characters = fullDeck.where((c) => c.type == CardType.character).cast<CharacterCard>().toList();
    final weapons = fullDeck.where((c) => c.type == CardType.weapon).cast<WeaponCard>().toList();
    final rooms = fullDeck.where((c) => c.type == CardType.room).cast<RoomCard>().toList();

    // 3. Extraer una carta aleatoria de cada tipo para el sobre (Solución)
    final CharacterCard secretCharacter = characters.removeAt(_random.nextInt(characters.length));
    final WeaponCard secretWeapon = weapons.removeAt(_random.nextInt(weapons.length));
    final RoomCard secretRoom = rooms.removeAt(_random.nextInt(rooms.length));
    
    // 4. Mezclar el resto de las cartas sobrantes para repartirlas
    final List<ClueCard> remainingCards = [...characters, ...weapons, ...rooms];
    remainingCards.shuffle(_random);

    // 5. Inicializamos el mapa del tablero
    const boardMap = BoardMap(); 

    // 6. Crea el jugador inicial con los parámetros obligatorios requeridos
    final List<PlayerCharacter> initialPlayers = [
      PlayerCharacter(
        card: secretCharacter, // Usamos la carta extraída como ejemplo
        position: const Position(x: 1, y: 1),
        hand: [], // Requerido por PlayerCharacter
        isBot: false, // Requerido por PlayerCharacter
      ),
    ];

    // 7. Devolver el estado inicial
    return ClueGameState(
      players: initialPlayers, 
      currentTurnIndex: 0,
      solution: CaseSolution(
        character: secretCharacter, 
        weapon: secretWeapon, 
        room: secretRoom
      ),
      phase: GamePhase.rolling,
      totalDeck: fullDeck,
      boardMap: boardMap,
    );
  }
}