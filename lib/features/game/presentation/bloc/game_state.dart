part of 'game_bloc.dart';


abstract class GameBlocState extends Equatable {
  const GameBlocState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameBlocState {
  const GameInitial();
}

class GameLoading extends GameBlocState {
  const GameLoading();
}

class GamePlayReady extends GameBlocState {
  final ClueGameState gameState;
  final String? notificationMessage;
  final Map<String, dynamic>? animationPath; // For token movement animation

  const GamePlayReady({
    required this.gameState,
    this.notificationMessage,
    this.animationPath,
  });

  GamePlayReady copyWith({
    ClueGameState? gameState,
    String? notificationMessage,
    Map<String, dynamic>? animationPath,
  }) {
    return GamePlayReady(
      gameState: gameState ?? this.gameState,
      notificationMessage: notificationMessage ?? this.notificationMessage,
      animationPath: animationPath ?? this.animationPath,
    );
  }

  @override
  List<Object?> get props => [gameState, notificationMessage, animationPath];
}

class GameVictory extends GameBlocState {
  final ClueGameState? finalState;
  final String winnerName;

  const GameVictory({
    required this.finalState,
    required this.winnerName,
  });

  @override
  List<Object?> get props => [finalState, winnerName];
}