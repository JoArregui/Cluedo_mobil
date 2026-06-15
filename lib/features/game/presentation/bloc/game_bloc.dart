import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/position.dart';
import '../../domain/entities/state_game.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/board_map.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/usecases/execute_bot_turn.dart';
import 'dart:async';

import 'bot_decision_service.dart';
import 'movement_service.dart';
import 'suggestion_service.dart';

part 'game_state.dart';
part 'game_event.dart';

class GameBloc extends Bloc<GameBlocEvent, GameBlocState> {
  final GameRepository gameRepository;
  final Random _random = Random();
  final MovementService _movementService;
  final SuggestionService _suggestionService;
  final BotDecisionService _botDecisionService;

  GameBloc({
    required this.gameRepository,
    required ExecuteBotTurn executeBotTurn,
    required BoardMap boardMap,
  })  : _movementService = MovementService(boardMap: boardMap),
        _suggestionService = SuggestionService(),
        _botDecisionService = BotDecisionService(executeBotTurn: executeBotTurn),
        super(GameInitial()) {
    on<StartNewGameEvent>(_onStartNewGame);
    on<RollDiceEvent>(_onRollDice);
    on<MoveCharacterEvent>(_onMoveCharacter);
    on<MakeSuggestionEvent>(_onMakeSuggestion);
    on<RefuteSuggestionEvent>(_onRefuteSuggestion);
    on<MakeAccusationEvent>(_onMakeAccusation);
    on<UseSecretPassageEvent>(_onUseSecretPassage);
    on<PassTurnEvent>(_onPassTurn);
    on<EndGameEvent>(_onEndGame);
  }

  @override
  void onChange(Change<GameBlocState> change) {
    super.onChange(change);
    // Delegate bot turn logic to BotDecisionService
    if (change.nextState is GamePlayReady) {
      final state = change.nextState as GamePlayReady;
      _botDecisionService.handleBotTurnIfNeeded(state, add);
    }
  }

  Future<void> _onStartNewGame(
    StartNewGameEvent event,
    Emitter<GameBlocState> emit,
  ) async {
    emit(GameLoading());
    await Future.delayed(Duration.zero);
    try {
      // Obtener estado inicial del repositorio (incluye posiciones de armas, mazo de pistas, etc.)
      final ClueGameState initialState = await gameRepository.initializeLocalGame(
        numberOfPlayers: event.numberOfPlayers,
        selectedCharacterId: event.selectedCharacterId,
      );

      // El personaje secreto ya está eliminado de la lista de caracteres en el repositorio
      final List<CharacterCard> remainingCharacters = initialState.totalDeck
          .where((c) => c.type == CardType.character && c.id != initialState.solution.character.id)
          .cast<CharacterCard>()
          .toList();

      // Aseguramos de tener exactamente cinco personajes restantes (seis total menos el secreto)
      assert(remainingCharacters.length == 5, 'Se esperaban 5 personajes restantes');

      // Crear posiciones iniciales para las seis fichas (espacios nombrados alrededor del tablero)
      final List<Position> startPositions = [
        const Position(x: 1, y: 1),   // cerca de esquina superior izquierda
        const Position(x: 1, y: 22),  // cerca de esquina inferior izquierda
        const Position(x: 22, y: 1),  // cerca de esquina superior derecha
        const Position(x: 22, y: 22), // cerca de esquina inferior derecha
        const Position(x: 11, y: 0),  // medio superior
        const Position(x: 11, y: 24), // medio inferior
      ];
      startPositions.shuffle(_random);

      // Crear jugadores basado en numberOfPlayers (1 humano + (numberOfPlayers-1) bots)
      final List<PlayerCharacter> players = <PlayerCharacter>[];
      // Encontrar el índice del personaje seleccionado en la lista restante
      final int selectedIndex = remainingCharacters.indexWhere((c) => c.id == event.selectedCharacterId);
      if (selectedIndex == -1) {
        // Si por alguna razón el personaje seleccionado no está en la lista restante (debería estar)
        // lanzamos un error o asumimos el primero
        throw Exception('Personaje seleccionado no disponible');
      }
      // Extraer el personaje seleccionado
      final CharacterCard selectedCharacter = remainingCharacters.removeAt(selectedIndex);
      // Ahora remainingCharacters tiene los personajes restantes para bots

      // Asignar posición al jugador humano (índice 0)
      players.add(
        PlayerCharacter(
          card: selectedCharacter,
          position: startPositions[0],
          hand: [], // Se llenará después
          isBot: false,
        ),
      );

      // Asignar posiciones y personajes a los bots (numberOfPlayers - 1)
      for (int i = 0; i < (event.numberOfPlayers - 1); i++) {
        final CharacterCard botChar = remainingCharacters[i];
        players.add(
          PlayerCharacter(
            card: botChar,
            position: startPositions[i + 1],
            hand: [], // Se llenará después
            isBot: true,
          ),
        );
      }

      // Barajar las cartas restantes de personajes, armas y habitaciones para repartir
      final List<ClueCard> remainingCards = [
        ...initialState.totalDeck
            .where((c) => c.type == CardType.character && c.id != initialState.solution.character.id && c.id != selectedCharacter.id),
        ...initialState.totalDeck
            .where((c) => c.type == CardType.weapon && c.id != initialState.solution.weapon.id),
        ...initialState.totalDeck
            .where((c) => c.type == CardType.room && c.id != initialState.solution.room.id),
      ];
      remainingCards.shuffle(_random);

      // Repartir las cartas restantes entre los seis jugadores
      int playerIndex = 0;
      for (final card in remainingCards) {
        final player = players[playerIndex % players.length];
        player.hand.add(card);
        playerIndex++;
      }

      // Update bot memories with their initial hands
      _botDecisionService.updateBotMemories(players);

      // El estado inicial del repositorio ya tiene weaponPositions (posiblemente con placeholders)
      // Nous allons utiliser l'état du dépôt tel quel, mais nous devons nous assurer que le currentTurnIndex soit 0
      // et que la phase soit rolling.
      final ClueGameState gameState = initialState.copyWith(
        players: players,
        currentTurnIndex: 0,
        phase: GamePhase.rolling,
      );

      emit(
        GamePlayReady(
          gameState: gameState,
          notificationMessage: "¡La mansión Tudor ha sido cerrada! Investiga las habitaciones.",
        ),
      );
    } catch (e) {
      emit(GameInitial());
    }
  }

  void _onRollDice(RollDiceEvent event, Emitter<GameBlocState> emit) {
    if (state is GamePlayReady) {
      final currentState = (state as GamePlayReady).gameState;
      if (currentState.phase != GamePhase.rolling) return;

      final random = Random();
      final dice1 = random.nextInt(6) + 1;
      final dice2 = random.nextInt(6) + 1;
      final int movementTotal = dice1 + dice2;

      emit(
        GamePlayReady(
          gameState: currentState.copyWith(
            lastDiceRoll: [dice1, dice2],
            currentDiceResult: movementTotal,
            phase: GamePhase.moving,
          ),
          notificationMessage: "Has obtenido un $movementTotal en los dados. Elige tu destino.",
        ),
      );
    }
  }

  void _onMoveCharacter(MoveCharacterEvent event, Emitter<GameBlocState> emit) {
    if (state is GamePlayReady) {
      final currentState = (state as GamePlayReady).gameState;
      if (currentState.phase != GamePhase.moving) return;

      final updatedPlayers = List<PlayerCharacter>.from(currentState.players);
      final int index = currentState.currentTurnIndex;

      final movingPlayer = updatedPlayers[index];
      final startPosition = movingPlayer.position;
      final endPosition = Position(x: event.x, y: event.y, roomId: event.roomId);

      final movementPath = _movementService.calculateMovementPath(startPosition, endPosition, currentState);

      final pathJson = movementPath.map((pos) => [pos.x.toDouble(), pos.y.toDouble()]).toList();

      // Actualizar la posición del jugador
      updatedPlayers[index] = updatedPlayers[index].copyWith(
        position: endPosition,
      );

      final enHabitacion = event.roomId != null;
      final proximaFase = enHabitacion ? GamePhase.suggesting : GamePhase.rolling;
      int siguienteTurno = currentState.currentTurnIndex;

      if (!enHabitacion) {
        siguienteTurno = _calcularSiguienteTurnoValido(currentState.currentTurnIndex, updatedPlayers);
      }

      emit(
        GamePlayReady(
          gameState: currentState.copyWith(
            players: updatedPlayers,
            phase: proximaFase,
            currentTurnIndex: siguienteTurno,
            currentDiceResult: enHabitacion ? currentState.currentDiceResult : null,
          ),
          notificationMessage: enHabitacion
              ? "Has entrado a la sala. Puedes formular una hipótesis o pasar."
              : "Movimiento finalizado. Turno del siguiente detective.",
          animationPath: {
            'playerId': movingPlayer.card.id,
            'path': pathJson,
            'duration': 2000,
          },
        ),
      );
    }
  }

  void _onUseSecretPassage(UseSecretPassageEvent event, Emitter<GameBlocState> emit) {
    if (state is GamePlayReady) {
      final currentState = (state as GamePlayReady).gameState;
      if (currentState.phase != GamePhase.rolling) return;

      final player = currentState.currentCharacter;
      final roomId = player.position.roomId;
      if (roomId == null) return;

      final secretPassages = {
        'study': 'kitchen',
        'kitchen': 'study',
        'lounge': 'conservatory',
        'conservatory': 'lounge',
      };

      final destination = secretPassages[roomId];
      if (destination == null) return;

      final updatedPlayers = List<PlayerCharacter>.from(currentState.players);
      final int index = currentState.currentTurnIndex;

      updatedPlayers[index] = updatedPlayers[index].copyWith(
        position: Position(
          x: player.position.x,
          y: player.position.y,
          roomId: destination,
        ),
      );

      emit(
        GamePlayReady(
          gameState: currentState.copyWith(
            players: updatedPlayers,
            phase: GamePhase.suggesting,
            currentTurnIndex: currentState.currentTurnIndex,
            currentDiceResult: null,
          ),
          notificationMessage: "Has utilizado el pasaje secreto para moverte a la $destination.",
        ),
      );
    }
  }

  void _onMakeSuggestion(MakeSuggestionEvent event, Emitter<GameBlocState> emit) {
    if (state is GamePlayReady) {
      final currentState = (state as GamePlayReady).gameState;
      if (currentState.phase != GamePhase.suggesting) return;

      final newState = _suggestionService.makeSuggestion(
        state: currentState,
        suspect: event.suspect,
        weapon: event.weapon,
      );
      emit(newState);
    }
  }

  void _onRefuteSuggestion(RefuteSuggestionEvent event, Emitter<GameBlocState> emit) {
    if (state is GamePlayReady) {
      final currentState = (state as GamePlayReady).gameState;
      if (currentState.phase != GamePhase.refuting) return;

      final result = _suggestionService.refuteSuggestion(
        state: currentState,
        matchingCard: event.matchingCard,
        calculateNextValidTurn: _calcularSiguienteTurnoValido,
      );
      final newState = result.$1;
      final shownCard = result.$2;
      emit(newState);
      if (shownCard != null) {
        _botDecisionService.learnCardShown(shownCard);
      }
    }
  }

  void _onMakeAccusation(MakeAccusationEvent event, Emitter<GameBlocState> emit) {
    if (state is GamePlayReady) {
      final currentState = (state as GamePlayReady).gameState;
      final result = _suggestionService.makeAccusation(
        state: currentState,
        suspect: event.suspect,
        weapon: event.weapon,
        room: event.room,
      );
      if (result is GameVictory) {
        emit(result);
      } else if (result is GamePlayReady) {
        emit(result);
      }
    }
  }

  int _calcularSiguienteTurnoValido(int turnoActual, List<PlayerCharacter> listaJugadores) {
    int siguiente = (turnoActual + 1) % listaJugadores.length;
    for (int i = 0; i < listaJugadores.length; i++) {
      if (!listaJugadores[siguiente].isEliminated) {
        return siguiente;
      }
      siguiente = (siguiente + 1) % listaJugadores.length;
    }
    return turnoActual;
  }

  void _onPassTurn(PassTurnEvent event, Emitter<GameBlocState> emit) {
    if (state is GamePlayReady) {
      final currentState = (state as GamePlayReady).gameState;

      // Only allow passing when in suggesting phase (after entering a room)
      if (currentState.phase == GamePhase.suggesting) {
        final siguienteTurno = _calcularSiguienteTurnoValido(currentState.currentTurnIndex, currentState.players);

        emit(
          GamePlayReady(
            gameState: currentState.copyWith(
              phase: GamePhase.rolling,
              currentTurnIndex: siguienteTurno,
              currentDiceResult: null,
            ),
            notificationMessage: "Has pasado tu turno. Turno del siguiente detective.",
          ),
        );
      }
    }
  }

  void _onEndGame(EndGameEvent event, Emitter<GameBlocState> emit) {
    _botDecisionService.updateBotMemories([]); // clear memories
    emit(const GameInitial());
  }
}