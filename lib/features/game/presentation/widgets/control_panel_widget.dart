import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import '../pages/main_menu_page.dart';
import '../../domain/entities/state_game.dart';
import '../../domain/entities/card.dart';
import 'card_selection_dialog.dart';

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
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.lightbulb_outline,
                  label: "Sugerir",
                  enabled: isMyTurn && phase == GamePhase.suggesting,
                  onPressed: () => _handleSuggestion(context),
                ),
                _ActionButton(
                  icon: Icons.gavel,
                  label: "Acusar",
                  enabled: isMyTurn && phase == GamePhase.suggesting,
                  onPressed: () => _handleAccusation(context),
                ),
                _ActionButton(
                  icon: Icons.skip_next,
                  label: "Pasar",
                  enabled: isMyTurn && phase == GamePhase.suggesting,
                  onPressed: () =>
                      context.read<GameBloc>().add(const PassTurnEvent()),
                ),
              ],
            ),
          ),
          _ActionButton(
            icon: Icons.logout,
            label: "Terminar",
            enabled: true,
            onPressed: () => _handleEndGame(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEndGame(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1C1F26),
        title: const Text(
          'Terminar partida',
          style: TextStyle(color: Colors.amber),
        ),
        content: const Text(
          '¿Seguro de que quieres terminar esta partida?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    context.read<GameBloc>().add(const EndGameEvent());
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainMenuPage()));
  }

  Future<void> _handleSuggestion(BuildContext context) async {
    final currentRoomId = state.gameState.currentCharacter.position.roomId;
    if (currentRoomId == null) return;

    final suspect = await _pickCard<CharacterCard>(context, 'Elige sospechoso');
    if (suspect == null || !context.mounted) return;
    final weapon = await _pickCard<WeaponCard>(context, 'Elige arma');
    if (weapon == null || !context.mounted) return;

    context.read<GameBloc>().add(
      MakeSuggestionEvent(suspect: suspect, weapon: weapon),
    );
  }

  Future<void> _handleAccusation(BuildContext context) async {
    final currentRoomId = state.gameState.currentCharacter.position.roomId;
    if (currentRoomId == null) return;

    final suspect = await _pickCard<CharacterCard>(
      context,
      'Acusar: Sospechoso',
    );
    if (suspect == null || !context.mounted) return;
    final weapon = await _pickCard<WeaponCard>(context, 'Acusar: Arma');
    if (weapon == null || !context.mounted) return;
    final room = await _pickCard<RoomCard>(context, 'Acusar: Habitación');
    if (room == null || !context.mounted) return;

    context.read<GameBloc>().add(
      MakeAccusationEvent(suspect: suspect, weapon: weapon, room: room),
    );
  }

  Future<T?> _pickCard<T extends ClueCard>(
    BuildContext context,
    String title,
  ) async {
    final myHand = state.gameState.players
        .firstWhere(
          (player) => !player.isBot,
          orElse: () => state.gameState.players.first,
        )
        .hand;

    final selected = await showCardSelectionDialog(
      context: context,
      myHand: myHand,
      allOptions: state.gameState.totalDeck.whereType<T>().toList(),
      title: title,
    );

    return selected is T ? selected : null;
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: enabled ? Colors.white : Colors.grey),
          onPressed: enabled ? onPressed : null,
        ),
        Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
