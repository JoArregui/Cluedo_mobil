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

  // Character IDs in clockwise order starting from Miss Scarlett
  static const List<String> _characterClockwiseOrder = [
    'scarlett',   // Miss Scarlett
    'green',      // Reverend Green
    'peacock',    // Mrs Peacock
    'plum',       // Prof Plum
    'orchid',     // Dr Orchid
    'mustard',    // Colonel Mustard
  ];

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
      print('_onStartNewGame: calling initializeLocalGame with players=${event.numberOfPlayers}, selected=${event.selectedCharacterId}');
      // Obtener estado inicial del repositorio (incluye posiciones de armas, mazo de pistas, etc.)
      final ClueGameState initialState = await gameRepository.initializeLocalGame(
        numberOfPlayers: event.numberOfPlayers,
        selectedCharacterId: event.selectedCharacterId,
      );
      print('_onStartNewGame: initialState obtained, players=${initialState.players.length}');

      // Obtener todos los caracteres de sospecha (6 en total)
      final List<CharacterCard> allSuspects = initialState.totalDeck
          .where((c) => c.type == CardType.character)
          .cast<CharacterCard>()
          .toList();

      // Verificar que tenemos exactamente 6 sospechosos
      assert(allSuspects.length == 6, 'Se esperaban 6 personajes de sospecha');

      // Identificar el personaje secreto (del sobre)
      final CharacterCard secretCharacter = initialState.solution.character;

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

      // Crear los seis personajes de sospecha (siempre se muestran todas las fichas en el tablero)
      final List<PlayerCharacter> suspects = <PlayerCharacter>[];

      // Asignar posición al jugador humano
      final CharacterCard humanCharacter = CharacterCard(
        id: event.selectedCharacterId,
        nameEs: allSuspects.firstWhere((c) => c.id == event.selectedCharacterId).nameEs,
        nameEn: allSuspects.firstWhere((c) => c.id == event.selectedCharacterId).nameEn,
        hexColor: allSuspects.firstWhere((c) => c.id == event.selectedCharacterId).hexColor,
      );

      suspects.add(
        PlayerCharacter(
          card: humanCharacter,
          position: startPositions[0],
          hand: [], // Se llenará después
          isBot: false,
          isEliminated: false, // Jugador humano activo
        ),
      );

      // Preparar lista de sospechosos disponibles para bots (excluyendo secreto y humano)
      final List<CharacterCard> availableForBots = allSuspects
          .where((c) => c.id != secretCharacter.id && c.id != event.selectedCharacterId)
          .toList();

      // Asignar posiciones y personajes a los bots (número de bots = event.numberOfPlayers - 1)
      for (int i = 0; i < (event.numberOfPlayers - 1); i++) {
        final CharacterCard botCharacter = availableForBots[i];
        suspects.add(
          PlayerCharacter(
            card: botCharacter,
            position: startPositions[i + 1],
            hand: [], // Se llenará después
            isBot: true,
            isEliminated: false, // Bot activo
          ),
        );
      }

      // Los sospechosos restantes (secreto y no asignados) van al tablero pero eliminados (no turnos)
      final Set<String> assignedCharacterIds = {
        event.selectedCharacterId,
        ...availableForBots.take(event.numberOfPlayers - 1).map((c) => c.id)
      };

      for (final CharacterCard suspect in allSuspects) {
        if (!assignedCharacterIds.contains(suspect.id)) {
          suspects.add(
            PlayerCharacter(
              card: suspect,
              position: startPositions[suspects.length], // Posiciones restantes
              hand: [],
              isBot: false, // No importa para sospechosos eliminados
              isEliminated: true, // No tiene turno
            ),
          );
        }
      }

      // Ahora tenemos exactamente 6 sospechosos en la lista 'suspects'
      assert(suspects.length == 6, 'Se esperaban 6 personajes de sospecha en total');

      // Barajar las cartas restantes de personajes, armas y habitaciones para repartir
      // Solo repartimos a los jugadores activos (no eliminados)
      final List<PlayerCharacter> activePlayers = suspects.where((p) => !p.isEliminated).toList();
      final List<CharacterCard> remainingCharacters = [
        ...activePlayers.map((p) => p.card), // Estos ya tienen sus cartas de personaje asignadas como fichas
      ];

      // Añadir armas y habitaciones excluyendo la solución
      final List<ClueCard> remainingWeapons = initialState.totalDeck
          .where((c) => c.type == CardType.weapon && c.id != initialState.solution.weapon.id)
          .toList();
      final List<ClueCard> remainingRooms = initialState.totalDeck
          .where((c) => c.type == CardType.room && c.id != initialState.solution.room.id)
          .toList();

      final List<ClueCard> remainingCards = [
        ...remainingCharacters,
        ...remainingWeapons,
        ...remainingRooms,
      ];
      remainingCards.shuffle(_random);

      // Repartir las cartas restantes entre los jugadores activos
      int playerIndex = 0;
      for (final card in remainingCards) {
        final player = activePlayers[playerIndex % activePlayers.length];
        player.hand.add(card);
        playerIndex++;
      }

      // Update bot memories with their initial hands
      _botDecisionService.updateBotMemories(activePlayers);

      // Determine the first player in clockwise order (only among active players)
      int firstPlayerIndex = 0;
      if (suspects.isNotEmpty) {
        // Find the active player with the smallest clockwise order index
        int smallestOrderIndex = _characterClockwiseOrder.length;
        for (int i = 0; i < suspects.length; i++) {
          // Only consider non-eliminated suspects for turn order
          if (!suspects[i].isEliminated) {
            String characterId = suspects[i].card.id;
            int orderIndex = _characterClockwiseOrder.indexOf(characterId);
            if (orderIndex != -1 && orderIndex < smallestOrderIndex) {
              smallestOrderIndex = orderIndex;
              firstPlayerIndex = i;
            }
          }
        }
        // If no standard characters found (should not happen), default to first active player
        if (smallestOrderIndex == _characterClockwiseOrder.length) {
          // Find first non-eliminated player
          for (int i = 0; i < suspects.length; i++) {
            if (!suspects[i].isEliminated) {
              firstPlayerIndex = i;
              break;
            }
          }
        }
      }

      // El estado inicial del repositorio ya tiene weaponPositions (posiblemente con placeholders)
      // Nous allons utiliser l'état du dépôt tel quel, mais nous devons nous assurer que le currentTurnIndex soit correct
      // et que la phase sea rolling.
      final ClueGameState gameState = initialState.copyWith(
        players: suspects,
        currentTurnIndex: firstPlayerIndex,
        phase: GamePhase.rolling,
      );

      emit(
        GamePlayReady(
          gameState: gameState,
          notificationMessage: "¡La mansión Tudor ha sido cerrada! Investiga las habitaciones.",
        ),
      );
      print('_onStartNewGame: Emitted GamePlayReady');
    } catch (e, stackTrace) {
      // Log the error for debugging
      print('Error in _onStartNewGame: $e');
      print('StackTrace: $stackTrace');
      emit(GameInitial());
    }
  }

  void _onRollDice(RollDiceEvent event, Emitter<GameBlocState> emit) {
    if (state is GamePlayReady) {
      final currentState = (state as GamePlayReady).gameState;
      if (currentState.phase != GamePhase.rolling) return;

      final random = Random();

      // Roll special dice: each die shows 1-5 or a magnifying glass (lupa)
      // Lupa counts as 1 for movement and allows drawing a clue card
      final int die1 = random.nextInt(6); // 0-5, where 5 represents lupa
      final int die2 = random.nextInt(6); // 0-5, where 5 represents lupa

      final bool isDie1Lupa = die1 == 5;
      final bool isDie2Lupa = die2 == 5;

      final int die1Value = isDie1Lupa ? 1 : die1 + 1; // 0-4 -> 1-5, 5 (lupa) -> 1
      final int die2Value = isDie2Lupa ? 1 : die2 + 1; // 0-4 -> 1-5, 5 (lupa) -> 1

      final int movementTotal = die1Value + die2Value;
      final int lupaCount = (isDie1Lupa ? 1 : 0) + (isDie2Lupa ? 1 : 0);

      // Handle clue cards drawn from lupa rolls
      List<ClueCard> updatedClueDeck = List.from(currentState.clueDeck);
      String clueNotification = "";

      for (int i = 0; i < lupaCount; i++) {
        if (updatedClueDeck.isNotEmpty) {
          // Draw the top card from the clue deck
          final ClueCard drawnCard = updatedClueDeck.removeAt(0);
          // In a real implementation, the card would be read and its effect applied
          // For now, we'll just note that a clue card was drawn
          clueNotification = "Has sacado una carta de pista: ${drawnCard.nameEn}. ";
          // Place the used clue card at the bottom of the deck
          updatedClueDeck.add(drawnCard);
        } else {
          clueNotification = "No hay más cartas de pista en el mazo. ";
          break;
        }
      }

      final String baseMessage = "Has obtenido un $movementTotal en los dados. ";
      final String lupaMessage = lupaCount > 0
          ? "$lupaCount icono${lupaCount == 1 ? '' : 's'} de lupa. $clueNotification"
          : "";
      final String notificationMessage = baseMessage + lupaMessage.trim();

      emit(
        GamePlayReady(
          gameState: currentState.copyWith(
            lastDiceRoll: [die1Value, die2Value],
            currentDiceResult: movementTotal,
            phase: GamePhase.moving,
            clueDeck: updatedClueDeck,
          ),
          notificationMessage: notificationMessage,
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

      // Determinar el número máximo de pasos permitido
      // Si estamos moviéndonos por dados, el máximo es el resultado del dado
      // Si es otro tipo de movimiento (como pasadizo secreto manejado en otro evento), usar null
      final int? maxSteps = currentState.currentDiceResult != null ? currentState.currentDiceResult : null;

      final movementPath = _movementService.calculateMovementPath(startPosition, endPosition, currentState, maxSteps: maxSteps);

      final pathJson = movementPath.map((pos) => [pos.x.toDouble(), pos.y.toDouble()]).toList();

      // Determinar la posición final válida (la última posición en el camino calculado)
      final validEndPosition = movementPath.isNotEmpty ? movementPath.last : startPosition;

      // Verificar si el movimiento realmente cambió la posición (evitar movimientos nulos que puedan causar bucles)
      final bool positionChanged = !(validEndPosition.x == startPosition.x &&
          validEndPosition.y == startPosition.y &&
          validEndPosition.roomId == startPosition.roomId);

      // Actualizar la posición del jugador a la posición válida calculada
      updatedPlayers[index] = updatedPlayers[index].copyWith(
        position: validEndPosition,
      );

      final enHabitacion = validEndPosition.roomId != null;
      final proximaFase = enHabitacion ? GamePhase.suggesting : GamePhase.rolling;
      int siguienteTurno = currentState.currentTurnIndex;

      // Solo avanzar al siguiente turno si no estamos entrando a una habitación
      // O si entramos a una habitación pero el movimiento fue válido (aunque no cambiamos de posición físicamente)
      if (!enHabitacion) {
        siguienteTurno = _calcularSiguienteTurnoValido(currentState.currentTurnIndex, updatedPlayers);
      }
      // Si estamos en una habitación pero no cambiamos de posición (por ejemplo, intentamos mover pero no pudimos),
      // todavía deberíamos permitir sugerir o pasar el turno según las reglas
      else if (!positionChanged) {
        // Intentamos entrar a una habitación pero no pudimos llegar a ninguna puerta válida
        // Tratamos esto como si no hubiéramos entrado a una habitación
        siguienteTurno = _calcularSiguienteTurnoValido(currentState.currentTurnIndex, updatedPlayers);
      }

      emit(
        GamePlayReady(
          gameState: currentState.copyWith(
            players: updatedPlayers,
            phase: proximaFase,
            currentTurnIndex: siguienteTurno,
            currentDiceResult: enHabitacion && positionChanged ? currentState.currentDiceResult : null,
          ),
          notificationMessage: enHabitacion && positionChanged
              ? "Has entrado a la sala. Puedes formular una hipótesis o pasar."
              : !positionChanged && enHabitacion
                  ? "No puedes llegar a esa habitación con ese lanzamiento. Turno perdido."
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
      // Check if player is in a room (required to make an accusation)
      if (currentState.currentCharacter.position.roomId == null) {
        emit(GamePlayReady(
          gameState: currentState,
          notificationMessage: "Debes estar en una habitación para hacer una acusación.",
        ));
        return;
      }

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
    // If no players or only one player, return current turn
    if (listaJugadores.length <= 1) {
      return turnoActual;
    }

    // Get the current player's character ID
    final String currentCharacterId = listaJugadores[turnoActual].card.id;

    // Find the position of the current character in the clockwise order
    int currentOrderIndex = _characterClockwiseOrder.indexOf(currentCharacterId);
    if (currentOrderIndex == -1) {
      // Character not found in our order list (should not happen with standard characters)
      // Fall back to original logic
      int siguiente = (turnoActual + 1) % listaJugadores.length;
      for (int i = 0; i < listaJugadores.length; i++) {
        if (!listaJugadores[siguiente].isEliminated) {
          return siguiente;
        }
        siguiente = (siguiente + 1) % listaJugadores.length;
      }
      return turnoActual;
    }

    // Search clockwise for the next non-eliminated player
    for (int i = 1; i <= _characterClockwiseOrder.length; i++) {
      int nextOrderIndex = (currentOrderIndex + i) % _characterClockwiseOrder.length;
      String nextCharacterId = _characterClockwiseOrder[nextOrderIndex];

      // Find this character in the player list
      for (int j = 0; j < listaJugadores.length; j++) {
        if (!listaJugadores[j].isEliminated &&
            listaJugadores[j].card.id == nextCharacterId) {
          return j;
        }
      }
    }

    // If all players are eliminated (should not happen in normal game), return current turn
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