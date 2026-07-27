import 'package:cluedo_mobil/features/game/domain/entities/position.dart';
import '../../domain/entities/state_game.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/character.dart';
import 'game_bloc.dart';

/// Servicio responsable de manejar la lógica de sugerencias, refutaciones y acusaciones
/// según las reglas originales del Cluedo.
class SuggestionService {
  /// Procesa una sugerencia hecha por el jugador actual.
  /// - El personaje y el arma se mueven automáticamente a la habitación de la sugerencia.
  /// - La habitación de la sugerencia es SIEMPRE la habitación donde se encuentra el jugador actual.
  /// - La refutación comienza por el jugador siguiente en el orden de turnos.
  GamePlayReady makeSuggestion({
    required ClueGameState state,
    required CharacterCard suspect,
    required WeaponCard weapon,
  }) {
    final currentRoomId = state.currentCharacter.position.roomId;
    if (currentRoomId == null) {
      return GamePlayReady(gameState: state, notificationMessage: '');
    }

    final Position? roomCenter = state.boardMap.getRoomCenterPosition(currentRoomId);

    final roomCard = state.boardMap.roomIds.contains(currentRoomId)
        ? RoomCard(id: currentRoomId, nameEs: _roomNameEs(currentRoomId), nameEn: _roomNameEn(currentRoomId))
        : state.solution.room;
    final List<ClueCard> sugerencia = [suspect, weapon, roomCard];

    // Regla Cluedo: refutación empieza por el jugador SIGUIENTE en la mesa (sentido horario),
    // incluyéndose a sí mismo solo como último caso (cuando todos los demás han pasado).
    int primerRefutador = (state.currentTurnIndex + 1) % state.players.length;

    // Mueve la ficha del personaje sospechoso a la habitación actual (regla obligatoria).
    final List<PlayerCharacter> updatedPlayers = List<PlayerCharacter>.from(state.players);
    final int suspectIndex = updatedPlayers.indexWhere((p) => p.card.id == suspect.id);
    if (suspectIndex != -1 && roomCenter != null) {
      updatedPlayers[suspectIndex] = updatedPlayers[suspectIndex].copyWith(
        position: roomCenter,
      );
    }

    // Mueve la ficha del arma a la habitación actual (regla obligatoria).
    final Map<String, Position> updatedWeaponPositions =
        Map<String, Position>.from(state.weaponPositions);
    if (roomCenter != null) {
      updatedWeaponPositions[weapon.id] = roomCenter;
    }

    final newState = state.copyWith(
      players: updatedPlayers,
      weaponPositions: updatedWeaponPositions,
      phase: GamePhase.refuting,
      currentSuggestion: sugerencia,
      refutingPlayerIndex: primerRefutador,
      currentDiceResult: null,
    );

    return GamePlayReady(
      gameState: newState,
      notificationMessage:
          "${state.currentCharacter.card.nameEs} sospecha de ${suspect.nameEs} con el ${weapon.nameEs} en ${roomCard.nameEs}.",
    );
  }

  /// Procesa una refutación.
  /// Regla Cluedo: TODOS los jugadores (incluidos eliminados) deben intentar refutar en orden.
  /// Si un jugador tiene al menos una carta de la sugerencia, DEBE mostrarla (solo una, a elegir).
  /// Si no tiene ninguna, pasa al siguiente.
  /// Si se llega de nuevo al jugador que hizo la sugerencia sin que nadie refute, la sugerencia no se ha podido refutar.
  (GamePlayReady, ClueCard?) refuteSuggestion({
    required ClueGameState state,
    required ClueCard? matchingCard,
    required int Function(int, List<PlayerCharacter>) calculateNextValidTurn,
  }) {
    if (state.phase != GamePhase.refuting) {
      return (GamePlayReady(gameState: state, notificationMessage: ''), null);
    }

    final refutadorActualIdx = state.refutingPlayerIndex!;

    // Caso 1: se ha especificado una carta concreta para mostrar (jugador humano).
    if (matchingCard != null) {
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
                "${state.players[refutadorActualIdx].card.nameEs} mostró una prueba. Hipótesis refutada.",
          ),
          matchingCard
        );
      }
      // Si dice que tiene la carta pero no la tiene, tratar como "no refuta".
    }

    // Caso 2: detección automática (bots o humano sin especificar).
    final playerHand = state.players[refutadorActualIdx].hand;
    final suggestedCards = state.currentSuggestion!;
    final matchingCards = playerHand.where((carta) =>
        suggestedCards.any((sugerida) => sugerida.id == carta.id)).toList();

    if (matchingCards.isNotEmpty) {
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
              "${state.players[refutadorActualIdx].card.nameEs} mostró una prueba. Hipótesis refutada.",
        ),
        cardToShow
      );
    }

    // Caso 3: este jugador NO tiene ninguna carta coincidente → pasa al siguiente.
    // Regla Cluedo: incluso los eliminados participan (siguen teniendo mano y deben responder).
    final siguienteRefutador = (refutadorActualIdx + 1) % state.players.length;

    if (siguienteRefutador == state.currentTurnIndex) {
      // Hemos dado toda la vuelta sin que nadie refute.
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
              "Nadie ha podido refutar la sospecha. ¡Las pistas parecen sólidas!",
        ),
        null
      );
    }

    final newState = state.copyWith(refutingPlayerIndex: siguienteRefutador);
    final refutadorName = state.players[refutadorActualIdx].card.nameEs;
    final eliminadoTag = state.players[refutadorActualIdx].isEliminated
        ? " (eliminado)"
        : "";
    return (
      GamePlayReady(
        gameState: newState,
        notificationMessage:
            "$refutadorName$eliminadoTag no tiene pruebas. Preguntando al siguiente...",
      ),
      null
    );
  }

  /// Procesa una acusación hecha por el jugador actual.
  /// Regla Cluedo: si falla la acusación, el jugador queda ELIMINADO del juego:
  /// - No tira más dados, no se mueve, no hace sugerencias ni acusaciones.
  /// - PERO sí sigue participando en refutaciones (debe mostrar cartas si se le pide).
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
    }

    // Acusación fallida: eliminar al jugador (sigue refutando).
    final updatedPlayers = List<PlayerCharacter>.from(state.players);
    final int indexAcusador = state.currentTurnIndex;
    updatedPlayers[indexAcusador] = updatedPlayers[indexAcusador].copyWith(
      isEliminated: true,
    );

    // Determinar si quedan jugadores activos (no eliminados).
    final quedanJugadoresActivos = updatedPlayers.any((p) => !p.isEliminated);

    if (!quedanJugadoresActivos) {
      return GamePlayReady(
        gameState: state.copyWith(
          players: updatedPlayers,
          phase: GamePhase.gameOver,
        ),
        notificationMessage: "Todos los investigadores han fallado. El asesino escapó.",
      );
    }

    // Pasar el turno al siguiente jugador NO eliminado.
    final siguienteTurno = _nextNonEliminated(indexAcusador, updatedPlayers);
    return GamePlayReady(
      gameState: state.copyWith(
        players: updatedPlayers,
        currentTurnIndex: siguienteTurno,
        phase: GamePhase.rolling,
        currentDiceResult: null,
      ),
      notificationMessage:
          "¡La acusación de ${state.currentCharacter.card.nameEs} era errónea! Ha quedado eliminado, pero sigue refutando.",
    );
  }

  /// Devuelve el siguiente índice de jugador NO eliminado, empezando por turnoActual+1.
  int _nextNonEliminated(int turnoActual, List<PlayerCharacter> lista) {
    int n = lista.length;
    for (int i = 1; i <= n; i++) {
      int idx = (turnoActual + i) % n;
      if (!lista[idx].isEliminated) return idx;
    }
    return turnoActual;
  }

  String _roomNameEs(String roomId) {
    return {
      'study': 'Estudio',
      'hall': 'Vestíbulo',
      'lounge': 'Salón',
      'library': 'Biblioteca',
      'dining_room': 'Comedor',
      'billiard_room': 'Sala de billar',
      'conservatory': 'Invernadero',
      'ballroom': 'Salón de baile',
      'kitchen': 'Cocina',
    }[roomId] ?? roomId;
  }

  String _roomNameEn(String roomId) {
    return {
      'study': 'Study',
      'hall': 'Hall',
      'lounge': 'Lounge',
      'library': 'Library',
      'dining_room': 'Dining Room',
      'billiard_room': 'Billiard Room',
      'conservatory': 'Conservatory',
      'ballroom': 'Ballroom',
      'kitchen': 'Kitchen',
    }[roomId] ?? roomId;
  }
}
