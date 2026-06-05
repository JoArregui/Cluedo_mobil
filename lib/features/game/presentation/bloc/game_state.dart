part of 'game_bloc.dart';

abstract class GameBlocState extends Equatable {
  const GameBlocState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameBlocState {}

class GameLoading extends GameBlocState {}

class GamePlayReady extends GameBlocState {
  final ClueGameState gameState;
  final String? notificationMessage;

  const GamePlayReady({
    required this.gameState,
    this.notificationMessage,
  });

  GamePlayReady copyWith({
    ClueGameState? gameState,
    String? notificationMessage,
  }) {
    return GamePlayReady(
      gameState: gameState ?? this.gameState,
      notificationMessage: notificationMessage ?? this.notificationMessage,
    );
  }

  @override
  List<Object?> get props => [gameState, notificationMessage];
}

class GameVictory extends GameBlocState {
  final ClueGameState finalState;
  final String winnerName;

  const GameVictory({required this.finalState, required this.winnerName});

  @override
  List<Object?> get props => [finalState, winnerName];
}