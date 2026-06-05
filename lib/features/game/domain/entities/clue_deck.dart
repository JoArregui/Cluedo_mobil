import 'card.dart';
import 'position.dart';

class ClueDeck {
  static const List<CharacterCard> characters = [
    CharacterCard(id: 'scarlet', nameEs: 'Srta. Amapola', nameEn: 'Miss Scarlet', hexColor: '#FF0000'),
    CharacterCard(id: 'mustard', nameEs: 'Coronel Rubio', nameEn: 'Colonel Mustard', hexColor: '#FFD700'),
    CharacterCard(id: 'white', nameEs: 'Sra. Blanco', nameEn: 'Mrs. White', hexColor: '#FFFFFF'),
    CharacterCard(id: 'green', nameEs: 'Reverendo Verde', nameEn: 'Reverend Green', hexColor: '#008000'),
    CharacterCard(id: 'peacock', nameEs: 'Sra. Celeste', nameEn: 'Mrs. Peacock', hexColor: '#0000FF'),
    CharacterCard(id: 'plum', nameEs: 'Profesor Mora', nameEn: 'Professor Plum', hexColor: '#800080'),
  ];

  static const List<WeaponCard> weapons = [
    WeaponCard(id: 'candlestick', nameEs: 'Candelabro', nameEn: 'Candlestick'),
    WeaponCard(id: 'knife', nameEs: 'Cuchillo', nameEn: 'Knife'),
    WeaponCard(id: 'lead_pipe', nameEs: 'Tubería de plomo', nameEn: 'Lead Pipe'),
    WeaponCard(id: 'revolver', nameEs: 'Revólver', nameEn: 'Revolver'),
    WeaponCard(id: 'rope', nameEs: 'Cuerda', nameEn: 'Rope'),
    WeaponCard(id: 'wrench', nameEs: 'Llave inglesa', nameEn: 'Wrench'),
  ];

  static const List<RoomCard> rooms = [
    RoomCard(id: 'kitchen', nameEs: 'Cocina', nameEn: 'Kitchen', secretPassageToRoomId: 'study'),
    RoomCard(id: 'ballroom', nameEs: 'Salón de baile', nameEn: 'Ballroom'),
    RoomCard(id: 'conservatory', nameEs: 'Conservatorio', nameEn: 'Conservatory', secretPassageToRoomId: 'lounge'),
    RoomCard(id: 'dining_room', nameEs: 'Comedor', nameEn: 'Dining Room'),
    RoomCard(id: 'billiard_room', nameEs: 'Sala de billar', nameEn: 'Billiard Room'),
    RoomCard(id: 'library', nameEs: 'Biblioteca', nameEn: 'Library'),
    RoomCard(id: 'lounge', nameEs: 'Salón', nameEn: 'Lounge', secretPassageToRoomId: 'conservatory'),
    RoomCard(id: 'hall', nameEs: 'Vestíbulo', nameEn: 'Hall'),
    RoomCard(id: 'study', nameEs: 'Estudio', nameEn: 'Study', secretPassageToRoomId: 'kitchen'),
  ];

  static Position getInitialPosition(String characterId) {
    switch (characterId) {
      case 'scarlet': return const Position(x: 16, y: 0); // Cerca del Vestíbulo
      case 'mustard': return const Position(x: 23, y: 14); // Cerca del Comedor
      case 'white': return const Position(x: 9, y: 24); // Cerca de la Cocina
      case 'green': return const Position(x: 14, y: 24); // Cerca del Conservatorio
      case 'peacock': return const Position(x: 0, y: 18); // Cerca del Conservatorio
      case 'plum': return const Position(x: 0, y: 5); // Cerca del Estudio
      default: return const Position(x: 0, y: 0);
    }
  }
}