import '../../domain/entities/card.dart';

class ClueCardModel {
  // Factory que produce directamente el subtipo correcto de ClueCard
  static ClueCard fromJson(Map<String, dynamic> json) {
    final id     = json['id'] as String;
    final nameEs = json['name_es'] as String;
    final nameEn = (json['name_en'] as String?) ?? nameEs;
    final type   = json['type'] as String;

    switch (type.toLowerCase()) {
      case 'character':
        return CharacterCard(
          id: id,
          nameEs: nameEs,
          nameEn: nameEn,
          hexColor: (json['hex_color'] as String?) ?? '#FFFFFF',
        );
      case 'weapon':
        return WeaponCard(id: id, nameEs: nameEs, nameEn: nameEn);
      case 'room':
        return RoomCard(
          id: id,
          nameEs: nameEs,
          nameEn: nameEn,
          secretPassageToRoomId: json['secret_passage_to_room_id'] as String?,
        );
      default:
        throw ArgumentError('Tipo de carta desconocido en el CMS: $type');
    }
  }
}