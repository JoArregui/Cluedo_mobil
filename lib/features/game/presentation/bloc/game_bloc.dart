import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/position.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/entities/state_game.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/card.dart';

part 'game_state.dart';
part 'game_event.dart';

class GameBloc extends Bloc<GameBlocEvent, GameBlocState> {
  final GameRepository gameRepository;

  GameBloc({required this.gameRepository}) : super(GameInitial()) {
    on<StartNewGameEvent>(_onStartNewGame);
    on<RollDiceEvent>(_onRollDice);
    on<MoveCharacterEvent>(_onMoveCharacter);
    on<MakeSuggestionEvent>(_onMakeSuggestion);
    on<RefuteSuggestionEvent>(_onRefuteSuggestion);
    on<MakeAccusationEvent>(_onMakeAccusation);
  }

  Future<void> _onStartNewGame(
    StartNewGameEvent event,
    Emitter<GameBlocState> emit,
  ) async {
    emit(GameLoading());
    // Permite que la pantalla dibuje el estado "GameLoading" antes de procesar el algoritmo
    await Future.delayed(Duration.zero);
    try {
      print("1");
      final initialGameState = await gameRepository.initializeCmsGame(
        numberOfPlayers: event.numberOfPlayers,
      );

      final List<PlayerCharacter> gamePlayers = [
        const PlayerCharacter(
          card: CharacterCard(
            id: 'scarlett',
            nameEs: 'Amapola',
            nameEn: 'Miss Scarlett',
            hexColor: '#E63946',
          ),
          position: Position(x: 7, y: 24),
          isBot: false,
          hand: [],
        ),
        const PlayerCharacter(
          card: CharacterCard(
            id: 'mustard',
            nameEs: 'Pradillo',
            nameEn: 'Colonel Mustard',
            hexColor: '#FFB703',
          ),
          position: Position(x: 0, y: 17),
          isBot: true,
          hand: [],
        ),
        const PlayerCharacter(
          card: CharacterCard(
            id: 'green',
            nameEs: 'Verdi',
            nameEn: 'Reverend Green',
            hexColor: '#2A9D8F',
          ),
          position: Position(x: 14, y: 0),
          isBot: true,
          hand: [],
        ),
      ];
      print("2");
      final remainingCards = initialGameState.totalDeck.where((card) {
        return card.id != initialGameState.solution.character.id &&
            card.id != initialGameState.solution.weapon.id &&
            card.id != initialGameState.solution.room.id;
      }).toList();

      int playerIndex = 0;
      print("3");
      while (remainingCards.isNotEmpty) {
        final card = remainingCards.removeLast();
        gamePlayers[playerIndex] = gamePlayers[playerIndex].copyWith(
          hand: [...gamePlayers[playerIndex].hand, card],
        );
        playerIndex = (playerIndex + 1) % gamePlayers.length;
      }
      print("4");
      emit(
        GamePlayReady(
          gameState: initialGameState.copyWith(
            players: gamePlayers,
            currentTurnIndex: 0,
            phase: GamePhase.rolling,
          ),
          notificationMessage:
              "¡La mansión Tudor ha sido cerrada! Investiga las habitaciones.",
        ),
      );
      print("5");
    } catch (e) {
      emit(GameInitial());
    }
  }

  void _onRollDice(RollDiceEvent event, Emitter<GameBlocState> emit) {
    if (state is GamePlayReady) {
      final currentState = (state as GamePlayReady).gameState;
      if (currentState.phase != GamePhase.rolling) return;

      final dice1 = (DateTime.now().microsecondsSinceEpoch % 6) + 1;
      final dice2 = (DateTime.now().millisecondsSinceEpoch % 6) + 1;
      final total = dice1 + dice2;

      emit(
        GamePlayReady(
          gameState: currentState.copyWith(
            lastDiceRoll: [dice1, dice2],
            currentDiceResult: total,
            phase: GamePhase.moving,
          ),
          notificationMessage:
              "Has obtenido un $total en los dados. Elige tu destino.",
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

      updatedPlayers[index] = updatedPlayers[index].copyWith(
        position: Position(x: event.x, y: event.y, roomId: event.roomId),
      );

      final enHabitacion = event.roomId != null;
      final proximaFase = enHabitacion
          ? GamePhase.suggesting
          : GamePhase.rolling;
      int siguienteTurno = currentState.currentTurnIndex;

      if (!enHabitacion) {
        siguienteTurno = _calcularSiguienteTurnoValido(
          currentState.currentTurnIndex,
          updatedPlayers,
        );
      }

      emit(
        GamePlayReady(
          gameState: currentState.copyWith(
            players: updatedPlayers,
            phase: proximaFase,
            currentTurnIndex: siguienteTurno,
            currentDiceResult: enHabitacion
                ? currentState.currentDiceResult
                : null,
          ),
          notificationMessage: enHabitacion
              ? "Has entrado a la sala. Puedes formular una hipótesis o pasar."
              : "Movimiento finalizado. Turno del siguiente detective.",
        ),
      );
    }
  }

  void _onMakeSuggestion(
    MakeSuggestionEvent event,
    Emitter<GameBlocState> emit,
  ) {
    if (state is GamePlayReady) {
      final currentState = (state as GamePlayReady).gameState;
      if (currentState.phase != GamePhase.suggesting) return;

      final currentRoomId = currentState.currentCharacter.position.roomId;
      if (currentRoomId == null) return;

      final roomCard = currentState.totalDeck.firstWhere(
        (c) => c.id == currentRoomId,
      );
      final List<ClueCard> sugerencia = [event.suspect, event.weapon, roomCard];
      final primerRefutador =
          (currentState.currentTurnIndex + 1) % currentState.players.length;

      emit(
        GamePlayReady(
          gameState: currentState.copyWith(
            phase: GamePhase.refuting,
            currentSuggestion: sugerencia,
            refutingPlayerIndex: primerRefutador,
          ),
          notificationMessage:
              "${currentState.currentCharacter.card.nameEs} sospecha de ${event.suspect.nameEs} con el ${event.weapon.nameEs}.",
        ),
      );
    }
  }

  void _onRefuteSuggestion(
    RefuteSuggestionEvent event,
    Emitter<GameBlocState> emit,
  ) {
    if (state is GamePlayReady) {
      final currentState = (state as GamePlayReady).gameState;
      if (currentState.phase != GamePhase.refuting) return;

      final refutadorActualIdx = currentState.refutingPlayerIndex!;

      if (event.matchingCard != null) {
        final siguienteTurno = _calcularSiguienteTurnoValido(
          currentState.currentTurnIndex,
          currentState.players,
        );

        emit(
          GamePlayReady(
            gameState: currentState.copyWith(
              phase: GamePhase.rolling,
              currentTurnIndex: siguienteTurno,
              currentSuggestion: null,
              refutingPlayerIndex: null,
              currentDiceResult: null,
            ),
            notificationMessage:
                "${currentState.players[refutadorActualIdx].card.nameEs} mostró una prueba regulatoria. Hipótesis refutada.",
          ),
        );
        return;
      }

      final siguienteRefutador =
          (refutadorActualIdx + 1) % currentState.players.length;

      if (siguienteRefutador == currentState.currentTurnIndex) {
        final siguienteTurno = _calcularSiguienteTurnoValido(
          currentState.currentTurnIndex,
          currentState.players,
        );
        emit(
          GamePlayReady(
            gameState: currentState.copyWith(
              phase: GamePhase.rolling,
              currentTurnIndex: siguienteTurno,
              currentSuggestion: null,
              refutingPlayerIndex: null,
              currentDiceResult: null,
            ),
            notificationMessage:
                "Nadie ha podido refutar la sospecha. ¡Las pistas parecen sólidas!",
          ),
        );
      } else {
        emit(
          GamePlayReady(
            gameState: currentState.copyWith(
              refutingPlayerIndex: siguienteRefutador,
            ),
            notificationMessage:
                "${currentState.players[refutadorActualIdx].card.nameEs} no tiene pruebas. Preguntando al siguiente...",
          ),
        );
      }
    }
  }

  void _onMakeAccusation(
    MakeAccusationEvent event,
    Emitter<GameBlocState> emit,
  ) {
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

        final bool todosEliminados = updatedPlayers.every(
          (p) => p.isEliminated,
        );

        if (todosEliminados) {
          emit(
            GamePlayReady(
              gameState: currentState.copyWith(
                players: updatedPlayers,
                phase: GamePhase.gameOver,
              ),
              notificationMessage:
                  "Todos los investigadores han fallado. El asesino escapó. Solución: ${solucion.character.nameEs} con el ${solucion.weapon.nameEs} en el ${solucion.room.nameEs}.",
            ),
          );
        } else {
          final siguienteTurno = _calcularSiguienteTurnoValido(
            currentState.currentTurnIndex,
            updatedPlayers,
          );

          emit(
            GamePlayReady(
              gameState: currentState.copyWith(
                players: updatedPlayers,
                currentTurnIndex: siguienteTurno,
                phase: GamePhase.rolling,
                currentDiceResult: null,
              ),
              notificationMessage:
                  "La acusación de ${currentState.currentCharacter.card.nameEs} era errónea. Ha quedado fuera de la investigación.",
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
}
