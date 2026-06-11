import 'package:flutter/material.dart';
import '../../domain/entities/character.dart';

class GameHeaderWidget extends StatelessWidget {
  final PlayerCharacter jugadorActual;
  final dynamic gameState;

  const GameHeaderWidget({
    super.key,
    required this.jugadorActual,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    // Verificar si es el turno del jugador actual.
    final bool esMiTurno = gameState.currentTurnIndex == 0; 

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        border: const Border(
          bottom: BorderSide(color: Colors.amber, width: 2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: esMiTurno 
                ? Colors.amber.withValues(alpha: 0.2) 
                : Colors.grey.withValues(alpha: 0.2),
            child: Icon(
              esMiTurno ? Icons.psychology : Icons.hourglass_empty,
              color: esMiTurno ? Colors.amber : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jugadorActual.card.nameEs.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  jugadorActual.position.roomId != null
                      ? "En: ${jugadorActual.position.roomId!.toUpperCase()}"
                      : "Explorando los pasillos",
                  style: TextStyle(
                    color: Colors.amber[200],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          if (esMiTurno)
            const Icon(Icons.stars, color: Colors.amber, size: 20),
        ],
      ),
    );
  }
}