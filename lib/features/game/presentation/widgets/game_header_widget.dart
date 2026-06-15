import 'package:flutter/material.dart';
import 'dart:async';
import '../../domain/entities/character.dart';
import '../../domain/entities/state_game.dart';
import '../bloc/game_bloc.dart';

class GameHeaderWidget extends StatefulWidget {
  final PlayerCharacter jugadorActual;
  final dynamic gameState;
  final VoidCallback? onBotTimeout; // Called when bot's time runs out

  const GameHeaderWidget({
    super.key,
    required this.jugadorActual,
    required this.gameState,
    this.onBotTimeout,
  });

  @override
  State<GameHeaderWidget> createState() => _GameHeaderWidgetState();
}

class _GameHeaderWidgetState extends State<GameHeaderWidget> {
  Timer? _timer;
  int _remainingSeconds = 15; // total time for bot turn
  bool _isBotTurn = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _updateTurnStatus();
  }

  @override
  void didUpdateWidget(covariant GameHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gameState != oldWidget.gameState) {
      _updateTurnStatus();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTurnStatus() {
    final state = widget.gameState as GamePlayReady?;
    if (state == null) {
      _cancelTimer();
      return;
    }

    final bool isBotTurn = state.gameState.players[state.gameState.currentTurnIndex].isBot;
    final bool shouldPause =
        state.gameState.phase == GamePhase.suggesting; // pause while waiting for refutation

    setState(() {
      _isBotTurn = isBotTurn;
      _isPaused = shouldPause;
    });

    if (isBotTurn && !shouldPause) {
      _startTimer();
    } else {
      _cancelTimer();
    }
  }

  void _startTimer() {
    _remainingSeconds = 15; // reset each turn
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0 && !_isPaused) {
        setState(() {
          _remainingSeconds--;
        });
      } else if (_remainingSeconds <= 0) {
        _timer?.cancel();
        if (widget.onBotTimeout != null) {
          widget.onBotTimeout!();
        }
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.gameState as GamePlayReady?;
    final bool esMiTurno =
        state != null && state.gameState.currentTurnIndex == 0; // human player index 0

    // Determine current player name (turn player)
    String currentPlayerName = '';
    if (state != null) {
      final currentPlayer =
          state.gameState.players[state.gameState.currentTurnIndex];
      currentPlayerName = currentPlayer.card.nameEs.toUpperCase();
    }

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
                  currentPlayerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  state != null &&
                          state.gameState.currentCharacter.position.roomId != null
                      ? "En: ${state.gameState.currentCharacter.position.roomId!.toUpperCase()}"
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
          // Timer bar on the right
          if (_isBotTurn && !_isPaused)
            SizedBox(
              width: 80,
              child: Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: _remainingSeconds / 15,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_isBotTurn && _isPaused)
            const Icon(
              Icons.pause_circle_filled,
              color: Colors.amber,
              size: 20,
            )
          else if (esMiTurno)
            const Icon(Icons.stars, color: Colors.amber, size: 20),
        ],
      ),
    );
  }
}