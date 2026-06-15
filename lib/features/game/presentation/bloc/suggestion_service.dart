import 'package:cluedo_mobil/features/game/domain/entities/position.dart';
import '../../domain/entities/state_game.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/character.dart';
import 'game_bloc.dart';

/// Servicio responsable de manejar la lógica de sugerencias, refutaciones y acusaciones.
class SuggestionService {
  /// Procesa una sugerencia hecha por el jugador actual. Mueve las fichas de personaje y arma a la habitación actual
  ///  y establece el estado para la fase de refutación.
  GamePlayReady makeSuggestion({
    required ClueGameState state,
    required CharacterCard suspect,
    required WeaponCard weapon,
  }) {
    final currentRoomId = state.currentCharacter.position.roomId;
    if (currentRoomId == null) {
      return GamePlayReady(gameState: state, notificationMessage: '');
    }

    final roomCard = state.solution.room;
    final List<ClueCard> sugerencia = [suspect, weapon, roomCard];
    final primerRefutador = (state.currentTurnIndex + 1) % state.players.length;

    // Mueve la ficha del personaje sospechoso a la habitación actual
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

  /// Procesa una refutación a la sugerencia actual. El jugador que refuta debe mostrar una carta de su mano que coincida con la sugerencia.
  (GamePlayReady, ClueCard?) refuteSuggestion({
    required ClueGameState state,
    required ClueCard? matchingCard,
    required int Function(int, List<PlayerCharacter>) calculateNextValidTurn,
  }) {
    if (state.phase != GamePhase.refuting) {
      return (GamePlayReady(gameState: state, notificationMessage: ''), null);
    }

    final refutadorActualIdx = state.refutingPlayerIndex!;

    // Si se proporciona una tarjeta específica para mostrar 
    if (matchingCard != null) {
      // Verificar que el jugador actual tenga esta carta
      final tieneCarta = state.players[refutadorActualIdx].hand
          .any((c) => c.id == matchingCard.id);

      if (tieneCarta) {
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
      } else {
        // El jugador dice que tiene la carta pero no la tiene - esto no debería pasar
        // Tratar como si no tuviera cartas para mostrar
        final siguienteRefutador = (refutadorActualIdx + 1) % state.players.length;
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

    // Lógica normal: el jugador debe mostrar una carta de su mano que coincida con la sugerencia
    final playerHand = state.players[refutadorActualIdx].hand;
    final suggestedCards = state.currentSuggestion!;

    // Encontrar todas las cartas en la mano del jugador que coinciden con la sugerencia
    final matchingCards = playerHand.where((carta) =>
        suggestedCards.any((sugerida) => sugerida.id == carta.id)).toList();

    if (matchingCards.isNotEmpty) {
      // El jugador tiene una o más cartas que coinciden - puede elegir cuál mostrar
      // Por ahora, elegimos la primera (en una implementación real, esto vendría de la UI)
      final cardToShow = matchingCards.first;

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
        cardToShow
      );
    } else {
      // El jugador no tiene ninguna carta que coincida
      final siguienteRefutador = (refutadorActualIdx + 1) % state.players.length;

      if (siguienteRefutador == state.currentTurnIndex) {
        // Todos los jugadores han sido consultados y nadie pudo refutar
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
        // Pasar al siguiente jugador
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
  }

  /// Procesa una acusación hecha por el jugador actual. Verifica si la acusación es correcta y devuelve el estado resultante.
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
      // Acusación fallida: el jugador es eliminado del juego activo
      // Pero sigue participando en las refutaciones (debe mostrar cartas cuando se le pide)
      final updatedPlayers = List<PlayerCharacter>.from(state.players);
      final int indexAcusador = state.currentTurnIndex;

      // Marcamos al jugador como que ha hecho una acusación fallida
      // En una implementación completa, tendríamos un estado especial para esto
      // Por ahora, lo eliminamos pero el service de refutación todavía le permitirá mostrar cartas
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