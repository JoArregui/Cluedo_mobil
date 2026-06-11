import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/position.dart';
import '../../domain/entities/tile_type.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/entities/state_game.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/bot_memory.dart';
import '../../domain/entities/board_map.dart';
import '../../domain/usecases/execute_bot_turn.dart';
import '../../domain/usecases/validate_movement.dart';
import 'dart:async';

part 'game_state.dart';
part 'game_event.dart';

class GameBloc extends Bloc<GameBlocEvent, GameBlocState> {
  final GameRepository gameRepository;
  final Random _random = Random();
  final ExecuteBotTurn _executeBotTurn;
  final Map<String, BotMemory> _botMemories = {};
  Map<String, dynamic>? _pendingBotSuggestion;
  bool _isBotTurnInProgress = false;

  GameBloc({required this.gameRepository})
      : _executeBotTurn = ExecuteBotTurn(
          validateMovement: ValidateMovement(),
          boardMap: const BoardMap(),
        ),
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
    if (_isBotTurnInProgress) return;
    if (change.nextState is GamePlayReady) {
      final state = (change.nextState as GamePlayReady).gameState;
      // Bot's turn when not human (index 0) and phase is rolling -> roll dice
      if (state.currentTurnIndex != 0 && state.phase == GamePhase.rolling) {
        _isBotTurnInProgress = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          add(RollDiceEvent());
          _isBotTurnInProgress = false;
        });
      }
      // Bot's turn after dice rolled (phase moving) -> decide move and suggestion
      if (state.currentTurnIndex != 0 && state.phase == GamePhase.moving) {
        final botMem = _botMemories[state.currentCharacter.card.id];
        if (botMem != null) {
          final result = _executeBotTurn.call(
            gameState: state,
            botMemory: botMem,
          );
          final newPos = result['newPosition'] as Position;
          final suggestion = result['suggestion'] as Map<String, dynamic>?;
          if (newPos != state.currentCharacter.position) {
            add(MoveCharacterEvent(
              x: newPos.x,
              y: newPos.y,
              roomId: newPos.roomId,
            ));
          }
          if (suggestion != null && newPos.roomId != null) {
            _pendingBotSuggestion = {
              'suspect': suggestion['suspect'] as CharacterCard,
              'weapon': suggestion['weapon'] as WeaponCard,
              'room': suggestion['room'] as RoomCard,
            };
          } else {
            _pendingBotSuggestion = null;
          }
        }
      }
      // If we have a pending bot suggestion and now we are in suggesting phase, execute it
      if (_pendingBotSuggestion != null && state.phase == GamePhase.suggesting) {
        final sug = _pendingBotSuggestion!;
        add(MakeSuggestionEvent(
          suspect: sug['suspect'] as CharacterCard,
          weapon: sug['weapon'] as WeaponCard,
        ));
        _pendingBotSuggestion = null;
      }
    }
  }

  void _updateBotMemories(List<PlayerCharacter> players) {
    for (final player in players) {
      if (player.isBot) {
        final mem = BotMemory(botPlayerId: player.card.id);
        mem.initializeWithHand(player.hand);
        _botMemories[player.card.id] = mem;
      } else {
        // Human player: we can keep an empty memory or not store
        _botMemories[player.card.id] = BotMemory(botPlayerId: player.card.id);
      }
    }
  }

  void _learnCardShown(ClueCard card) {
    for (final mem in _botMemories.values) {
      mem.markAsChecked(card.id);
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
      _updateBotMemories(players);

      // El estado inicial del repositorio ya tiene weaponPositions y clueDeck (posiblemente con placeholders)
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

      // El icono de lupa cuenta como 1 para movimiento y permite robar una carta de pista
      final int move1 = dice1 == 1 ? 1 : dice1;
      final int move2 = dice2 == 1 ? 1 : dice2;
      final int movementTotal = move1 + move2;

      final List<ClueCardClass> drawnClues = <ClueCardClass>[];
      final List<ClueCardClass> updatedClueDeck = List.from(currentState.clueDeck);

      // Robar cartas de pista por cada lupa
      if (dice1 == 1 && updatedClueDeck.isNotEmpty) {
        final ClueCardClass clue = updatedClueDeck.removeAt(0);
        drawnClues.add(clue);
        // Poner la carta usada al final del mazo
        updatedClueDeck.add(clue);
      }
      if (dice2 == 1 && updatedClueDeck.isNotEmpty) {
        final ClueCardClass clue = updatedClueDeck.removeAt(0);
        drawnClues.add(clue);
        updatedClueDeck.add(clue);
      }

      String clueMessage = '';
      if (drawnClues.isNotEmpty) {
        clueMessage = ' Has robado ${drawnClues.length} carta(s) de pista.';
      }

      emit(
        GamePlayReady(
          gameState: currentState.copyWith(
            lastDiceRoll: [dice1, dice2],
            currentDiceResult: movementTotal,
            clueDeck: updatedClueDeck,
            phase: GamePhase.moving,
          ),
          notificationMessage: "Has obtenido un $movementTotal en los dados. Elige tu destino.$clueMessage",
        ),
      );
    }
  }

  List<Position> _calculateMovementPath(Position start, Position end, ClueGameState gameState) {
    if (end.roomId != null) {
      return [start, end];
    } else {
      return _findHallwayPath(start, end, gameState);
    }
  }

  List<Position> _findHallwayPath(Position start, Position end, ClueGameState gameState) {
  
    final queue = <List<Position>>[];
    final visited = <String>{};

    queue.add([start]);
    visited.add('${start.x},${start.y}');

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;

      if (current.x == end.x && current.y == end.y) {
        return path;
      }

      final neighbors = [
        Position(x: current.x, y: current.y + 1),
        Position(x: current.x, y: current.y - 1),
        Position(x: current.x + 1, y: current.y),
        Position(x: current.x - 1, y: current.y),
      ];

      for (final neighbor in neighbors) {
     
        if (neighbor.x < 0 || neighbor.x >= 24 || neighbor.y < 0 || neighbor.y >= 25) {
          continue;
        }

      
        final boardMap = gameState.boardMap;
        final tileType = boardMap.getTileType(neighbor.x, neighbor.y);
        if (tileType == TileType.wall) {
          continue;
        }

        // Checar si la casilla está ocupada por otro jugador (solo en pasillos, no en habitaciones)
        final isOccupied = gameState.players.any((p) =>
          !p.isEliminated &&
          p.position.roomId == null &&
          p.position.x == neighbor.x &&
          p.position.y == neighbor.y);
        if (isOccupied) {
          continue;
        }

        final key = '${neighbor.x},${neighbor.y}';
        if (!visited.contains(key)) {
          visited.add(key);
          final newPath = [...path, neighbor];
          queue.add(newPath);
        }
      }
    }


    return [start, end];
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


      final movementPath = _calculateMovementPath(startPosition, endPosition, currentState);

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

      final currentRoomId = currentState.currentCharacter.position.roomId;
      if (currentRoomId == null) return;

      final roomCard = currentState.solution.room;
      final List<ClueCard> sugerencia = [event.suspect, event.weapon, roomCard];
      final primerRefutador = (currentState.currentTurnIndex + 1) % currentState.players.length;

      // Mover la ficha del personaje sospechado a la habitación actual
      final List<PlayerCharacter> updatedPlayers = List<PlayerCharacter>.from(currentState.players);
      final int suspectIndex = updatedPlayers.indexWhere((p) => p.card.id == event.suspect.id);
      if (suspectIndex != -1) {
        // Actualizamos la posición del sospechoso para que esté en la habitación
        // Mantener las coordenadas x,y pero establecer el roomId
        final Position oldPos = updatedPlayers[suspectIndex].position;
        updatedPlayers[suspectIndex] = updatedPlayers[suspectIndex].copyWith(
          position: Position(
            x: oldPos.x,
            y: oldPos.y,
            roomId: currentRoomId,
          ),
        );
      }

      // Mover la ficha del arma a la habitación actual
      final Map<String, Position> updatedWeaponPositions = Map<String, Position>.from(currentState.weaponPositions);
      if (updatedWeaponPositions.containsKey(event.weapon.id)) {
        // Colocar el arma en una posición dentro de la habitación (usamos coordenadas arbitrarias)
        final Position oldPos = updatedWeaponPositions[event.weapon.id]!;
        updatedWeaponPositions[event.weapon.id] = Position(
          x: oldPos.x,
          y: oldPos.y,
          roomId: currentRoomId,
        );
      } else {
        // Si no encontramos el arma, la colocamos en la habitación con posición predeterminada
        updatedWeaponPositions[event.weapon.id] = const Position(x: 0, y: 0, roomId: null);
      }

      emit(
        GamePlayReady(
          gameState: currentState.copyWith(
            players: updatedPlayers,
            weaponPositions: updatedWeaponPositions,
            phase: GamePhase.refuting,
            currentSuggestion: sugerencia,
            refutingPlayerIndex: primerRefutador,
          ),
          notificationMessage: "${currentState.currentCharacter.card.nameEs} sospecha de ${event.suspect.nameEs} con el ${event.weapon.nameEs}.",
        ),
      );
    }
  }

  void _onRefuteSuggestion(RefuteSuggestionEvent event, Emitter<GameBlocState> emit) {
    if (state is GamePlayReady) {
      final currentState = (state as GamePlayReady).gameState;
      if (currentState.phase != GamePhase.refuting) return;

      final refutadorActualIdx = currentState.refutingPlayerIndex!;

      if (event.matchingCard != null) {
        final siguienteTurno = _calcularSiguienteTurnoValido(currentState.currentTurnIndex, currentState.players);
        emit(
          GamePlayReady(
            gameState: currentState.copyWith(
              phase: GamePhase.rolling,
              currentTurnIndex: siguienteTurno,
              currentSuggestion: null,
              refutingPlayerIndex: null,
              currentDiceResult: null,
            ),
            notificationMessage: "${currentState.players[refutadorActualIdx].card.nameEs} mostró una prueba regulatoria. Hipótesis refutada.",
          ),
        );
        _learnCardShown(event.matchingCard!);
        return;
      }

      final siguienteRefutador = (refutadorActualIdx + 1) % currentState.players.length;

      if (siguienteRefutador == currentState.currentTurnIndex) {
        final siguienteTurno = _calcularSiguienteTurnoValido(currentState.currentTurnIndex, currentState.players);
        emit(
          GamePlayReady(
            gameState: currentState.copyWith(
              phase: GamePhase.rolling,
              currentTurnIndex: siguienteTurno,
              currentSuggestion: null,
              refutingPlayerIndex: null,
              currentDiceResult: null,
            ),
            notificationMessage: "Nadie ha podido refutar la sospecha. ¡Las pistas parecen sólidas!",
          ),
        );
      } else {
        emit(
          GamePlayReady(
            gameState: currentState.copyWith(refutingPlayerIndex: siguienteRefutador),
            notificationMessage: "${currentState.players[refutadorActualIdx].card.nameEs} no tiene pruebas. Preguntando al siguiente...",
          ),
        );
      }
    }
  }

  void _onMakeAccusation(MakeAccusationEvent event, Emitter<GameBlocState> emit) {
    if (state is GamePlayReady) {
      final currentState = (state as GamePlayReady).gameState;
      final solucion = currentState.solution;

      final bool exitoPersona = solucion.character.id == event.suspect.id;
      final bool exitoArma = solucion.weapon.id == event.weapon.id;
      final bool exitoHabitacion = solucion.room.id == event.room.id;

      if (exitoPersona && exitoArma && exitoHabitacion) {
        emit(
          GameVictory(
            finalState: currentState.copyWith(phase: GamePhase.gameOver),
            winnerName: currentState.currentCharacter.card.nameEs,
          ),
        );
      } else {
        final updatedPlayers = List<PlayerCharacter>.from(currentState.players);
        final int indexAcusador = currentState.currentTurnIndex;

        updatedPlayers[indexAcusador] = updatedPlayers[indexAcusador].copyWith(
          isEliminated: true,
        );

        final bool todosEliminados = updatedPlayers.every((p) => p.isEliminated);

        if (todosEliminados) {
          emit(
            GamePlayReady(
              gameState: currentState.copyWith(
                players: updatedPlayers,
                phase: GamePhase.gameOver,
              ),
              notificationMessage: "Todos los investigadores han fallado. El asesino escapó.",
            ),
          );
        } else {
          final siguienteTurno = _calcularSiguienteTurnoValido(currentState.currentTurnIndex, updatedPlayers);
          emit(
            GamePlayReady(
              gameState: currentState.copyWith(
                players: updatedPlayers,
                currentTurnIndex: siguienteTurno,
                phase: GamePhase.rolling,
                currentDiceResult: null,
              ),
              notificationMessage: "La acusación de ${currentState.currentCharacter.card.nameEs} era errónea. Ha quedado fuera.",
            ),
          );
        }
      }
    }
  }

  int _calcularSiguienteTurnoValido(
    int turnoActual,
    List<PlayerCharacter> listaJugadores,
  ) {
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
    _botMemories.clear();
    _pendingBotSuggestion = null;
    _isBotTurnInProgress = false;
    emit(const GameInitial());
  }
}