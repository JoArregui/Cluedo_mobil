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
      {'id': 'white',    'name_es': 'White',  'name_en': 'Dr White', 'type': 'character', 'hex_color': '#9B5DE5'},
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
      // Cartas de pista (29 cartas)
      {'id': 'clue_01',  'name_es': 'Pista 1',  'name_en': 'Clue 1', 'type': 'clue'},
      {'id': 'clue_02',  'name_es': 'Pista 2',  'name_en': 'Clue 2', 'type': 'clue'},
      {'id': 'clue_03',  'name_es': 'Pista 3',  'name_en': 'Clue 3', 'type': 'clue'},
      {'id': 'clue_04',  'name_es': 'Pista 4',  'name_en': 'Clue 4', 'type': 'clue'},
      {'id': 'clue_05',  'name_es': 'Pista 5',  'name_en': 'Clue 5', 'type': 'clue'},
      {'id': 'clue_06',  'name_es': 'Pista 6',  'name_en': 'Clue 6', 'type': 'clue'},
      {'id': 'clue_07',  'name_es': 'Pista 7',  'name_en': 'Clue 7', 'type': 'clue'},
      {'id': 'clue_08',  'name_es': 'Pista 8',  'name_en': 'Clue 8', 'type': 'clue'},
      {'id': 'clue_09',  'name_es': 'Pista 9',  'name_en': 'Clue 9', 'type': 'clue'},
      {'id': 'clue_10',  'name_es': 'Pista 10', 'name_en': 'Clue 10', 'type': 'clue'},
      {'id': 'clue_11',  'name_es': 'Pista 11', 'name_en': 'Clue 11', 'type': 'clue'},
      {'id': 'clue_12',  'name_es': 'Pista 12', 'name_en': 'Clue 12', 'type': 'clue'},
      {'id': 'clue_13',  'name_es': 'Pista 13',  'name_en': 'Clue 13', 'type': 'clue'},
      {'id': 'clue_14',  'name_es': 'Pista 14', 'name_en': 'Clue 14', 'type': 'clue'},
      {'id': 'clue_15',  'name_es': 'Pista 15',  'name_en': 'Clue 15', 'type': 'clue'},
      {'id': 'clue_16',  'name_es': 'Pista 16',  'name_en': 'Clue 16', 'type': 'clue'},
      {'id': 'clue_17',  'name_es': 'Pista 17',  'name_en': 'Clue 17', 'type': 'clue'},
      {'id': 'clue_18',  'name_es': 'Pista 18',  'name_en': 'Clue 18', 'type': 'clue'},
      {'id': 'clue_19',  'name_es': 'Pista 19',  'name_en': 'Clue 19', 'type': 'clue'},
      {'id': 'clue_20',  'name_es': 'Pista 20',  'name_en': 'Clue 20', 'type': 'clue'},
      {'id': 'clue_21',  'name_es': 'Pista 21',  'name_en': 'Clue 21', 'type': 'clue'},
      {'id': 'clue_22',  'name_es': 'Pista 22',  'name_en': 'Clue 22', 'type': 'clue'},
      {'id': 'clue_23',  'name_es': 'Pista 23',  'name_en': 'Clue 23', 'type': 'clue'},
      {'id': 'clue_24',  'name_es': 'Pista 24',  'name_en': 'Clue 24', 'type': 'clue'},
      {'id': 'clue_25',  'name_es': 'Pista 25',  'name_en': 'Clue 25', 'type': 'clue'},
      {'id': 'clue_26',  'name_es': 'Pista 26',  'name_en': 'Clue 26', 'type': 'clue'},
      {'id': 'clue_27',  'name_es': 'Pista 27',  'name_en': 'Clue 27', 'type': 'clue'},
      {'id': 'clue_28',  'name_es': 'Pista 28',  'name_en': 'Clue 28', 'type': 'clue'},
      {'id': 'clue_29',  'name_es': 'Pista 29',  'name_en': 'Clue 29', 'type': 'clue'},
    ];


    return mockLocalData.map(ClueCardModel.fromJson).toList();
  }
}