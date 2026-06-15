import '../../domain/entities/card.dart';
import '../models/card_model.dart';

abstract class GameLocalDataSource {
  Future<List<ClueCard>> getLocalDeck(); 
}

class GameLocalDataSourceImpl implements GameLocalDataSource {
  const GameLocalDataSourceImpl();

  @override
  Future<List<ClueCard>> getLocalDeck() async {
    await Future.delayed(const Duration(milliseconds: 400));

    final List<Map<String, dynamic>> mockLocalData = [
      // Sospechosos — hex_color requerido por CharacterCard
      {'id': 'scarlett',  'name_es': 'Scarlett',  'name_en': 'Miss Scarlett', 'type': 'character', 'hex_color': '#E63946'},
      {'id': 'mustard',   'name_es': 'Mustard',  'name_en': 'Colonel Mustard', 'type': 'character', 'hex_color': '#FFB703'},
      {'id': 'orchid',    'name_es': 'Orchid',  'name_en': 'Dr Orchid', 'type': 'character', 'hex_color': '#9B5DE5'},
      {'id': 'green',     'name_es': 'Green',     'name_en': 'Reverend Green', 'type': 'character', 'hex_color': '#2A9D8F'},
      {'id': 'peacock',   'name_es': 'Peacock',   'name_en': 'Mrs Peacock', 'type': 'character', 'hex_color': '#457B9D'},
      {'id': 'plum',      'name_es': 'Plum',      'name_en': 'Prof. Plum', 'type': 'character', 'hex_color': '#6A0572'},

      // Armas
      {'id': 'knife',      'name_es': 'Puñal',             'name_en': 'Dagger', 'type': 'weapon'},
      {'id': 'revolver',   'name_es': 'Revólver',          'name_en': 'Revolver', 'type': 'weapon'},
      {'id': 'rope',       'name_es': 'Cuerda',            'name_en': 'Rope', 'type': 'weapon'},
      {'id': 'candlestick','name_es': 'Candelabro',        'name_en': 'Candlestick', 'type': 'weapon'},
      {'id': 'lead_pipe',  'name_es': 'Tubería de Plomo',  'name_en': 'Lead Pipe', 'type': 'weapon'},
      {'id': 'wrench',     'name_es': 'Llave Inglesa',     'name_en': 'Wrench', 'type': 'weapon'},

      // Habitaciones
      {'id': 'study',        'name_es': 'Estudio',         'name_en': 'Study',         'type': 'room',
       'secret_passage_to_room_id': 'kitchen'},   // Pasadizo secreto clásico
      {'id': 'hall',         'name_es': 'Vestíbulo',       'name_en': 'Hall',          'type': 'room'},
      {'id': 'lounge',       'name_es': 'Salón',           'name_en': 'Lounge',        'type': 'room',
       'secret_passage_to_room_id': 'conservatory'}, // Pasadizo secreto
      {'id': 'library',      'name_es': 'Biblioteca',      'name_en': 'Library',       'type': 'room'},
      {'id': 'billiard_room','name_es': 'Sala de Billar',  'name_en': 'Billiard Room', 'type': 'room'},
      {'id': 'dining_room',  'name_es': 'Comedor',         'name_en': 'Dining Room',   'type': 'room'},
      {'id': 'conservatory', 'name_es': 'Invernadero',     'name_en': 'Conservatory',  'type': 'room',
       'secret_passage_to_room_id': 'lounge'},
      {'id': 'ballroom',     'name_es': 'Sala de Baile',   'name_en': 'Ballroom',      'type': 'room'},
      {'id': 'kitchen',      'name_es': 'Cocina',          'name_en': 'Kitchen',       'type': 'room',
       'secret_passage_to_room_id': 'study'},
    ];


    return mockLocalData.map(ClueCardModel.fromJson).toList();
  }
}