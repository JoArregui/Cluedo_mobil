part of 'game_bloc.dart';

abstract class GameBlocEvent extends Equatable {
  const GameBlocEvent();

  @override
  List<Object?> get props => [];
}

class StartNewGameEvent extends GameBlocEvent {
  final int numberOfPlayers;
  final String selectedCharacterId; // ID del personaje elegido por el usuario

  const StartNewGameEvent({
    required this.numberOfPlayers, 
    required this.selectedCharacterId,
  });

  @override
  List<Object?> get props => [numberOfPlayers, selectedCharacterId];
}

class RollDiceEvent extends GameBlocEvent {}

class MoveCharacterEvent extends GameBlocEvent {
  final int x;
  final int y;
  final String? roomId;

  const MoveCharacterEvent({required this.x, required this.y, this.roomId});

  @override
  List<Object?> get props => [x, y, roomId];
}

class UseSecretPassageEvent extends GameBlocEvent {}

class CloseNarrativeEvent extends GameBlocEvent {}

class MakeSuggestionEvent extends GameBlocEvent {
  final CharacterCard suspect;
  final WeaponCard weapon;

  const MakeSuggestionEvent({required this.suspect, required this.weapon});

  @override
  List<Object?> get props => [suspect, weapon];
}

class RefuteSuggestionEvent extends GameBlocEvent {
  final ClueCard? matchingCard;

  const RefuteSuggestionEvent({this.matchingCard});

  @override
  List<Object?> get props => [matchingCard];
}

class MakeAccusationEvent extends GameBlocEvent {
  final CharacterCard suspect;
  final WeaponCard weapon;
  final RoomCard room;

  const MakeAccusationEvent({
    required this.suspect,
    required this.weapon,
    required this.room,
  });

  @override
  List<Object?> get props => [suspect, weapon, room];
}

class PassTurnEvent extends GameBlocEvent {
  const PassTurnEvent();

  @override
  List<Object?> get props => [];
}