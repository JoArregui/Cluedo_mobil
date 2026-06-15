import 'package:cluedo_mobil/features/game/domain/entities/position.dart';
import '../../domain/entities/state_game.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/character.dart';
import 'game_bloc.dart';

/// Service responsible for suggestion, refutation, and accusation logic.
class SuggestionService {
  /// Processes a suggestion made by the current player.
  /// Returns the new [GamePlayReady] state after the suggestion is made.
  GamePlayReady makeSuggestion({
    required ClueGameState state,
    required CharacterCard suspect,
    required WeaponCard weapon,
  }) {
    final currentRoomId = state.currentCharacter.position.roomId;
    if (currentRoomId == null) {
      // Should not happen if called correctly, but return state unchanged.
      return GamePlayReady(gameState: state, notificationMessage: '');
    }

    final roomCard = state.solution.room;
    final List<ClueCard> sugerencia = [suspect, weapon, roomCard];
    final primerRefutador = (state.currentTurnIndex + 1) % state.players.length;

    // Move the ficha del personaje sospechado a la habitación actual
    final List<PlayerCharacter> updatedPlayers = List<PlayerCharacter>.from(state.players);
    final int suspectIndex = updatedPlayers.indexWhere((p) => p.card.id == suspect.id);
    if (suspectIndex != -1) {
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
    final Map<String, Position> updatedWeaponPositions =
        Map<String, Position>.from(state.weaponPositions);
    if (updatedWeaponPositions.containsKey(weapon.id)) {
      final Position oldPos = updatedWeaponPositions[weapon.id]!;
      updatedWeaponPositions[weapon.id] = Position(
        x: oldPos.x,
        y: oldPos.y,
        roomId: currentRoomId,
      );
    } else {
      updatedWeaponPositions[weapon.id] = const Position(x: 0, y: 0, roomId: null);
    }

    final newState = state.copyWith(
      players: updatedPlayers,
      weaponPositions: updatedWeaponPositions,
      phase: GamePhase.refuting,
      currentSuggestion: sugerencia,
      refutingPlayerIndex: primerRefutador,
    );

    return GamePlayReady(
      gameState: newState,
      notificationMessage:
          "${state.currentCharacter.card.nameEs} sospecha de ${suspect.nameEs} con el ${weapon.nameEs}.",
    );
  }

  /// Processes a refutation attempt by the current refuting player.
  /// Returns a tuple of (newState, shownCard). shownCard is the card that was shown
  /// (if any) so the caller can learn it.
  (GamePlayReady, ClueCard?) refuteSuggestion({
    required ClueGameState state,
    required ClueCard? matchingCard,
    required int Function(int, List<PlayerCharacter>) calculateNextValidTurn,
  }) {
    if (state.phase != GamePhase.refuting) {
      return (GamePlayReady(gameState: state, notificationMessage: ''), null);
    }

    final refutadorActualIdx = state.refutingPlayerIndex!;

    if (matchingCard != null) {
      final siguienteTurno = calculateNextValidTurn(state.currentTurnIndex, state.players);
      final newState = state.copyWith(
        phase: GamePhase.rolling,
        currentTurnIndex: siguienteTurno,
        currentSuggestion: null,
        refutingPlayerIndex: null,
        currentDiceResult: null,
      );
      return (
        GamePlayReady(
          gameState: newState,
          notificationMessage:
              "${state.players[refutadorActualIdx].card.nameEs} mostró una prueba regulatoria. Hipótesis refutada.",
        ),
        matchingCard
      );
    }

    final siguienteRefutador = (refutadorActualIdx + 1) % state.players.length;

    if (siguienteRefutador == state.currentTurnIndex) {
      final siguienteTurno = calculateNextValidTurn(state.currentTurnIndex, state.players);
      final newState = state.copyWith(
        phase: GamePhase.rolling,
        currentTurnIndex: siguienteTurno,
        currentSuggestion: null,
        refutingPlayerIndex: null,
        currentDiceResult: null,
      );
      return (
        GamePlayReady(
          gameState: newState,
          notificationMessage: "Nadie ha podido refutar la sospecha. ¡Las pistas parecen sólidas!",
        ),
        null
      );
    } else {
      final newState = state.copyWith(refutingPlayerIndex: siguienteRefutador);
      return (
        GamePlayReady(
          gameState: newState,
          notificationMessage:
              "${state.players[refutadorActualIdx].card.nameEs} no tiene pruebas. Preguntando al siguiente...",
        ),
        null
      );
    }
  }

  /// Processes an accusation made by the current player.
  /// Returns either a [GameVictory] or a [GamePlayReady] state.
  Object makeAccusation({
    required ClueGameState state,
    required CharacterCard suspect,
    required WeaponCard weapon,
    required RoomCard room,
  }) {
    final solucion = state.solution;
    final bool exitoPersona = solucion.character.id == suspect.id;
    final bool exitoArma = solucion.weapon.id == weapon.id;
    final bool exitoHabitacion = solucion.room.id == room.id;

    if (exitoPersona && exitoArma && exitoHabitacion) {
      return GameVictory(
        finalState: state.copyWith(phase: GamePhase.gameOver),
        winnerName: state.currentCharacter.card.nameEs,
      );
    } else {
      final updatedPlayers = List<PlayerCharacter>.from(state.players);
      final int indexAcusador = state.currentTurnIndex;

      updatedPlayers[indexAcusador] = updatedPlayers[indexAcusador].copyWith(
        isEliminated: true,
      );

      final bool todosEliminados = updatedPlayers.every((p) => p.isEliminated);

      if (todosEliminados) {
        return GamePlayReady(
          gameState: state.copyWith(
            players: updatedPlayers,
            phase: GamePhase.gameOver,
          ),
          notificationMessage: "Todos los investigadores han fallado. El asesino escapó.",
        );
      } else {
        final siguienteTurno =
            _calcularSiguienteTurnoValido(state.currentTurnIndex, updatedPlayers);
        return GamePlayReady(
          gameState: state.copyWith(
            players: updatedPlayers,
            currentTurnIndex: siguienteTurno,
            phase: GamePhase.rolling,
            currentDiceResult: null,
          ),
          notificationMessage:
              "La acusación de ${state.currentCharacter.card.nameEs} era errónea. Ha quedado fuera.",
        );
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
}