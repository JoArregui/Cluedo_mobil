import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import '../../domain/entities/state_game.dart';
import '../../domain/entities/card.dart';

class ControlPanelWidget extends StatelessWidget {
  final GamePlayReady state;

  const ControlPanelWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isMyTurn = state.gameState.currentTurnIndex == 0;
    final phase = state.gameState.phase;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1F26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.directions_walk,
            label: "Mover",
            enabled: isMyTurn && phase == GamePhase.moving,
            onPressed: () => context.read<GameBloc>().add(const MoveCharacterEvent(x: 0, y: 0)),
          ),

          _DiceControl(state: state, enabled: isMyTurn && phase == GamePhase.rolling),

          _ActionButton(
            icon: Icons.lightbulb_outline,
            label: "Sugerir",
            enabled: isMyTurn && phase == GamePhase.suggesting,
            onPressed: () => _handleSuggestion(context),
          ),

          _ActionButton(
            icon: Icons.gavel,
            label: "Acusar",
            enabled: isMyTurn && (phase == GamePhase.rolling || phase == GamePhase.moving || phase == GamePhase.suggesting),
            onPressed: () => _handleAccusation(context),
          ),
        ],
      ),
    );
  }

  // (Dentro de control_panel_widget.dart, reemplaza _handleSuggestion)
  Future<void> _handleSuggestion(BuildContext context) async {
    final currentRoomId = state.gameState.currentCharacter.position.roomId;
    if (currentRoomId == null) return;

    final suspect = await _pickCard<CharacterCard>(context, "Elige sospechoso");
    if (suspect == null) return;
    final weapon = await _pickCard<WeaponCard>(context, "Elige arma");
    if (weapon == null) return;

    // Aquí disparas el evento. La "Aventura Gráfica" se activará por
    // la escucha del BLoC en el GameBoardPage mediante un Overlay.
    context.read<GameBloc>().add(MakeSuggestionEvent(suspect: suspect, weapon: weapon));
  }

  Future<void> _handleAccusation(BuildContext context) async {
    final suspect = await _pickCard<CharacterCard>(context, "Acusar: Sospechoso");
    if (suspect == null) return;
    final weapon = await _pickCard<WeaponCard>(context, "Acusar: Arma");
    if (weapon == null) return;
    final room = await _pickCard<RoomCard>(context, "Acusar: Habitación");
    if (room == null) return;

    context.read<GameBloc>().add(MakeAccusationEvent(suspect: suspect, weapon: weapon, room: room));
  }

  Future<T?> _pickCard<T extends ClueCard>(BuildContext context, String title) async {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1F26),
        title: Text(title, style: const TextStyle(color: Colors.amber)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            children: state.gameState.totalDeck.whereType<T>().map((card) => ListTile(
              title: Text(card.nameEs, style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, card),
            )).toList(),
          ),
        ),
      ),
    );
  }
}

class _DiceControl extends StatelessWidget {
  final GamePlayReady state;
  final bool enabled;
  const _DiceControl({required this.state, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final diceResult = state.gameState.currentDiceResult;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: enabled ? () => context.read<GameBloc>().add(RollDiceEvent()) : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: enabled ? Colors.amber.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: enabled ? Colors.amber : Colors.grey),
            ),
            child: Icon(Icons.casino, color: enabled ? Colors.amber : Colors.grey, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(diceResult != null ? "Dado: $diceResult" : "Lanzar",
          style: TextStyle(color: enabled ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionButton({required this.icon, required this.label, required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: enabled ? Colors.white : Colors.grey),
          onPressed: enabled ? onPressed : null,
        ),
        Text(label, style: TextStyle(color: enabled ? Colors.white : Colors.grey, fontSize: 12)),
      ],
    );
  }
}