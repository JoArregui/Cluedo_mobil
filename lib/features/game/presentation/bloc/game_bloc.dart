import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/position.dart';
import '../../domain/entities/tile_type.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/entities/state_game.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/card.dart';

part 'game_state.dart';
part 'game_event.dart';

class GameBloc extends Bloc<GameBlocEvent, GameBlocState> {
  final GameRepository gameRepository;
  final Random _random = Random();

  GameBloc({required this.gameRepository}) : super(GameInitial()) {
    on<StartNewGameEvent>(_onStartNewGame);
    on<RollDiceEvent>(_onRollDice);
    on<MoveCharacterEvent>(_onMoveCharacter);
    on<MakeSuggestionEvent>(_onMakeSuggestion);
    on<RefuteSuggestionEvent>(_onRefuteSuggestion);
    on<MakeAccusationEvent>(_onMakeAccusation);
    on<UseSecretPassageEvent>(_onUseSecretPassage);
    on<PassTurnEvent>(_onPassTurn);
  }

  Future<void> _onStartNewGame(
    StartNewGameEvent event,
    Emitter<GameBlocState> emit,
  ) async {
    emit(GameLoading());
    await Future.delayed(Duration.zero);
    try {
      final initialGameState = await gameRepository.initializeCmsGame(
        numberOfPlayers: event.numberOfPlayers,
      );

      final List<Position> spawnPoints = [
        const Position(x: 7, y: 23, roomId: null),
        const Position(x: 0, y: 17, roomId: null),
        const Position(x: 14, y: 0, roomId: null),
        const Position(x: 23, y: 7, roomId: null),
      ];
      spawnPoints.shuffle(_random);

      final List<PlayerCharacter> allCharacters = [
        PlayerCharacter(
          card: const CharacterCard(id: 'scarlett', nameEs: 'Amapola', nameEn: 'Miss Scarlett', hexColor: '#E63946'),
          position: spawnPoints[0],
          isBot: false,
          hand: [],
        ),
        PlayerCharacter(
          card: const CharacterCard(id: 'mustard', nameEs: 'Pradillo', nameEn: 'Colonel Mustard', hexColor: '#FFB703'),
          position: spawnPoints[1],
          isBot: true,
          hand: [],
        ),
        PlayerCharacter(
          card: const CharacterCard(id: 'green', nameEs: 'Verdi', nameEn: 'Reverend Green', hexColor: '#2A9D8F'),
          position: spawnPoints[2],
          isBot: true,
          hand: [],
        ),
      ];

      final mainPlayer = allCharacters.firstWhere((p) => p.card.id == event.selectedCharacterId);
      final bots = allCharacters.where((p) => p.card.id != event.selectedCharacterId).toList();
      final List<PlayerCharacter> gamePlayers = [mainPlayer, ...bots];

      final remainingCards = initialGameState.totalDeck.where((card) {
        return card.id != initialGameState.solution.character.id &&
            card.id != initialGameState.solution.weapon.id &&
            card.id != initialGameState.solution.room.id;
      }).toList();
      remainingCards.shuffle(_random);

      int playerIndex = 0;
      while (remainingCards.isNotEmpty) {
        final card = remainingCards.removeLast();
        gamePlayers[playerIndex] = gamePlayers[playerIndex].copyWith(
          hand: [...gamePlayers[playerIndex].hand, card],
        );
        playerIndex = (playerIndex + 1) % gamePlayers.length;
      }

      emit(
        GamePlayReady(
          gameState: initialGameState.copyWith(
            players: gamePlayers,
            currentTurnIndex: 0,
            phase: GamePhase.rolling,
          ),
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

      final dice1 = _random.nextInt(6) + 1;
      final dice2 = _random.nextInt(6) + 1;
      final total = dice1 + dice2;

      emit(
        GamePlayReady(
          gameState: currentState.copyWith(
            lastDiceRoll: [dice1, dice2],
            currentDiceResult: total,
            phase: GamePhase.moving,
          ),
          notificationMessage: "Has obtenido un $total en los dados. Elige tu destino.",
        ),
      );
    }
  }

  List<Position> _calculateMovementPath(Position start, Position end, ClueGameState gameState) {
    // If moving to a room, we need to handle door entry
    if (end.roomId != null) {
      // For room entry, path goes to the door then into the room
      // Simplified: just return start and end for now
      return [start, end];
    } else {
      // Hallway movement - use BFS to find shortest path
      return _findHallwayPath(start, end, gameState);
    }
  }

  List<Position> _findHallwayPath(Position start, Position end, ClueGameState gameState) {
    // BFS to find shortest path in hallways
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

      // Explore neighbors (up, down, left, right)
      final neighbors = [
        Position(x: current.x, y: current.y + 1),
        Position(x: current.x, y: current.y - 1),
        Position(x: current.x + 1, y: current.y),
        Position(x: current.x - 1, y: current.y),
      ];

      for (final neighbor in neighbors) {
        // Check bounds
        if (neighbor.x < 0 || neighbor.x >= 24 || neighbor.y < 0 || neighbor.y >= 25) {
          continue;
        }

        // Check if not a wall
        final boardMap = gameState.boardMap;
        final tileType = boardMap.getTileType(neighbor.x, neighbor.y);
        if (tileType == TileType.wall) {
          continue;
        }

        // Check if not occupied by another player (in hallway)
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

    // If no path found (shouldn't happen in valid game), return direct path
    return [start, end];
  }

  void _onMoveCharacter(MoveCharacterEvent event, Emitter<GameBlocState> emit) {
    if (state is GamePlayReady) {
      final currentState = (state as GamePlayReady).gameState;
      if (currentState.phase != GamePhase.moving) return;

      final updatedPlayers = List<PlayerCharacter>.from(currentState.players);
      final int index = currentState.currentTurnIndex;

      // Get the player who is moving
      final movingPlayer = updatedPlayers[index];
      final startPosition = movingPlayer.position;
      final endPosition = Position(x: event.x, y: event.y, roomId: event.roomId);

      // Calculate the path for animation
      final movementPath = _calculateMovementPath(startPosition, endPosition, currentState);

      // Convert path to JSON-serializable format
      final pathJson = movementPath.map((pos) => [pos.x.toDouble(), pos.y.toDouble()]).toList();

      // Update the player's position
      updatedPlayers[index] = updatedPlayers[index].copyWith(
        position: endPosition,
      );

      final enHabitacion = event.roomId != null;
      final proximaFase = enHabitacion ? GamePhase.suggesting : GamePhase.rolling;
      int siguienteTurno = currentState.currentTurnIndex;

      if (!enHabitacion) {
        siguienteTurno = _calcularSiguienteTurnoValido(currentState.currentTurnIndex, updatedPlayers);
      }

      // Emit the state change with path data for animation
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
            'duration': 1000, // 1 second animation duration
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

      emit(
        GamePlayReady(
          gameState: currentState.copyWith(
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
      // If not in suggesting phase, ignore the pass (or could handle other cases)
    }
  }
}