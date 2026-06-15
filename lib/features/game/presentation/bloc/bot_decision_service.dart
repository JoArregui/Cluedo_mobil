import 'package:cluedo_mobil/features/game/domain/entities/position.dart';
import '../../domain/entities/state_game.dart';
import '../../domain/entities/bot_memory.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/character.dart';
import '../../domain/usecases/execute_bot_turn.dart';
import 'game_bloc.dart';


/// Service responsible for handling bot decision logic.
class BotDecisionService {
  final ExecuteBotTurn _executeBotTurn;
  final Map<String, BotMemory> _botMemories = {};
  bool _isBotDecisionScheduled = false;
  Map<String, dynamic>? _pendingBotSuggestion;
  bool _isBotTurnInProgress = false;

  BotDecisionService({required ExecuteBotTurn executeBotTurn})
      : _executeBotTurn = executeBotTurn;

  /// Call this from the bloc's onChange when a bot turn might be needed.
  /// Returns true if a bot turn was initiated (or scheduled).
  bool handleBotTurnIfNeeded(GamePlayReady state, void Function(GameBlocEvent) addEvent) {
    if (_isBotTurnInProgress) return false;

    final gameState = state.gameState;
    // Bot's turn when not human (index 0) and phase is rolling -> roll dice
    if (gameState.currentTurnIndex != 0 && gameState.phase == GamePhase.rolling) {
      _isBotTurnInProgress = true;
      // Delay to simulate thinking time
      Future.delayed(const Duration(milliseconds: 500), () {
        addEvent(RollDiceEvent());
        _isBotTurnInProgress = false;
      });
      return true;
    }
    // Bot's turn after dice rolled (phase moving) -> decide move and suggestion (with delay)
    if (gameState.currentTurnIndex != 0 && gameState.phase == GamePhase.moving) {
      final botMem = _botMemories[gameState.currentCharacter.card.id];
      if (botMem != null && !_isBotDecisionScheduled) {
        _isBotDecisionScheduled = true;
        Future.delayed(const Duration(seconds: 15), () {
          // Re-check that we are still in a bot turn and moving phase
          final currentState = state; // capture from outer scope
          if (currentState.gameState.currentTurnIndex != 0 &&
              currentState.gameState.phase == GamePhase.moving) {
            final mem = _botMemories[currentState.gameState.currentCharacter.card.id];
            if (mem != null) {
              try {
                final result = _executeBotTurn.call(
                  gameState: currentState.gameState,
                  botMemory: mem,
                );
                final newPos = result['newPosition'] as Position;
                final suggestion = result['suggestion'] as Map<String, dynamic>?;
                // Always move (even if same position) to advance turn
                addEvent(MoveCharacterEvent(
                  x: newPos.x,
                  y: newPos.y,
                  roomId: newPos.roomId,
                ));
                if (suggestion != null && newPos.roomId != null) {
                  _pendingBotSuggestion = {
                    'suspect': suggestion['suspect'] as CharacterCard,
                    'weapon': suggestion['weapon'] as WeaponCard,
                    'room': suggestion['room'] as RoomCard,
                  };
                } else {
                  _pendingBotSuggestion = null;
                }
              } catch (e) {
                // If bot decision fails, clear pending suggestion and treat as no move
                _pendingBotSuggestion = null;
                // Still move to avoid getting stuck
                addEvent(MoveCharacterEvent(
                  x: currentState.gameState.currentCharacter.position.x,
                  y: currentState.gameState.currentCharacter.position.y,
                  roomId: currentState.gameState.currentCharacter.position.roomId,
                ));
              }
            }
          }
          _isBotDecisionScheduled = false;
        });
        return true;
      }
    }
    // If we have a pending bot suggestion and now we are in suggesting phase, execute it
    if (_pendingBotSuggestion != null && state.gameState.phase == GamePhase.suggesting) {
      final sug = _pendingBotSuggestion!;
      addEvent(MakeSuggestionEvent(
        suspect: sug['suspect'] as CharacterCard,
        weapon: sug['weapon'] as WeaponCard,
      ));
      _pendingBotSuggestion = null;
      return true;
    }
    return false;
  }

  void updateBotMemories(List<PlayerCharacter> players) {
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

  void learnCardShown(ClueCard card) {
    for (final mem in _botMemories.values) {
      mem.markAsChecked(card.id);
    }
  }

  // Getters for bloc to access pending suggestion and flags if needed
  Map<String, dynamic>? get pendingBotSuggestion => _pendingBotSuggestion;
  bool get isBotDecisionScheduled => _isBotDecisionScheduled;
  bool get isBotTurnInProgress => _isBotTurnInProgress;
}