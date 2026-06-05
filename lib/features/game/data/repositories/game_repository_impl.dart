import 'dart:math';
import '../../domain/repositories/game_repository.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/state_game.dart';
import '../datasources/game_cms_data_source.dart';

class GameRepositoryImpl implements GameRepository {
  final GameCmsDataSource cmsDataSource;
  final Random _random = Random();

  GameRepositoryImpl({required this.cmsDataSource});

  @override
  Future<ClueGameState> initializeCmsGame({required int numberOfPlayers}) async {
    // 1. Obtener cartas desde el CMS de forma fiel
    final List<ClueCard> fullDeck = await cmsDataSource.getCmsDeck();

    // 2. Separar el mazo por categorías para construir el crimen secreto
    final characters = fullDeck.where((c) => c.type == CardType.character).toList();
    final weapons = fullDeck.where((c) => c.type == CardType.weapon).toList();
    final rooms = fullDeck.where((c) => c.type == CardType.room).toList();

    // 3. Extraer una carta aleatoria de cada tipo para el sobre del sobre cerrado (Solución)
    final ClueCard secretCharacter = characters.removeAt(_random.nextInt(characters.length));
    final ClueCard secretWeapon = weapons.removeAt(_random.nextInt(weapons.length));
    final ClueCard secretRoom = rooms.removeAt(_random.nextInt(rooms.length));
    
    final List<ClueCard> solutionEnvelope = [secretCharacter, secretWeapon, secretRoom];

    // 4. Mezclar el resto de las cartas sobrantes para repartirlas
    final List<ClueCard> remainingCards = [...characters, ...weapons, ...rooms];
    remainingCards.shuffle(_random);

    // 5. Devolver el estado inicial con el sobre configurado
    // Nota: El reparto específico a las manos de los PlayerCharacter se gestionará en el BLoC
    return ClueGameState.initial(
      totalDeck: fullDeck,
      envelope: solutionEnvelope,
    );
  }
}