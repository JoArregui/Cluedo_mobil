enum CardType { character, weapon, room, clue }

abstract class ClueCard {
  final String id;
  final String nameEs;
  final String nameEn;
  final CardType type;

  const ClueCard({
    required this.id,
    required this.nameEs,
    required this.nameEn,
    required this.type,
  });
}

class CharacterCard extends ClueCard {
  final String hexColor;

  const CharacterCard({
    required super.id,
    required super.nameEs,
    required super.nameEn,
    required this.hexColor,
  }) : super(type: CardType.character);
}

class WeaponCard extends ClueCard {
  const WeaponCard({
    required super.id,
    required super.nameEs,
    required super.nameEn,
  }) : super(type: CardType.weapon);
}

class RoomCard extends ClueCard {
  final String? secretPassageToRoomId;

  const RoomCard({
    required super.id,
    required super.nameEs,
    required super.nameEn,
    this.secretPassageToRoomId,
  }) : super(type: CardType.room);
}

class ClueCardClass extends ClueCard {
  final String description; 

  const ClueCardClass({
    required super.id,
    required super.nameEs,
    required super.nameEn,
    required this.description,
  }) : super(type: CardType.clue);
}

