import '../../domain/entities/card.dart';
import '../models/card_model.dart';

abstract class GameCmsDataSource {
  Future<List<ClueCard>> getCmsDeck(); // ClueCard en lugar de ClueCardModel
}

class GameCmsDataSourceImpl implements GameCmsDataSource {
  const GameCmsDataSourceImpl();

  @override
  Future<List<ClueCard>> getCmsDeck() async {
    await Future.delayed(const Duration(milliseconds: 400));

    final List<Map<String, dynamic>> mockCmsData = [
      // Sospechosos — hex_color requerido por CharacterCard
      {'id': 'scarlett',  'name_es': 'Amapola',  'type': 'character', 'hex_color': '#E63946'},
      {'id': 'mustard',   'name_es': 'Pradillo',  'type': 'character', 'hex_color': '#FFB703'},
      {'id': 'orchid',    'name_es': 'Orquídea',  'type': 'character', 'hex_color': '#9B5DE5'},
      {'id': 'green',     'name_es': 'Verdi',     'type': 'character', 'hex_color': '#2A9D8F'},
      {'id': 'peacock',   'name_es': 'Celeste',   'type': 'character', 'hex_color': '#457B9D'},
      {'id': 'plum',      'name_es': 'Mora',      'type': 'character', 'hex_color': '#6A0572'},

      // Armas
      {'id': 'knife',      'name_es': 'Puñal',             'type': 'weapon'},
      {'id': 'revolver',   'name_es': 'Revólver',          'type': 'weapon'},
      {'id': 'rope',       'name_es': 'Cuerda',            'type': 'weapon'},
      {'id': 'candlestick','name_es': 'Candelabro',        'type': 'weapon'},
      {'id': 'lead_pipe',  'name_es': 'Tubería de Plomo',  'type': 'weapon'},
      {'id': 'wrench',     'name_es': 'Llave Inglesa',     'type': 'weapon'},

      // Habitaciones
      {'id': 'study',        'name_es': 'Estudio',         'type': 'room'},
      {'id': 'hall',         'name_es': 'Vestíbulo',       'type': 'room'},
      {'id': 'lounge',       'name_es': 'Salón',           'type': 'room'},
      {'id': 'library',      'name_es': 'Biblioteca',      'type': 'room'},
      {'id': 'billiard_room','name_es': 'Sala de Billar',  'type': 'room'},
      {'id': 'dining_room',  'name_es': 'Comedor',         'type': 'room'},
      {'id': 'conservatory', 'name_es': 'Invernadero',     'type': 'room',
       'secret_passage_to_room_id': 'study'},   // Pasadizo secreto clásico
      {'id': 'ballroom',     'name_es': 'Sala de Baile',   'type': 'room'},
      {'id': 'kitchen',      'name_es': 'Cocina',          'type': 'room',
       'secret_passage_to_room_id': 'study'},
    ];

    return mockCmsData.map(ClueCardModel.fromJson).toList();
  }
}