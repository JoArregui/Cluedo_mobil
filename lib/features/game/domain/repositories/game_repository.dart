import '../entities/state_game.dart';

/// Contrato formal para la gestión del estado inicial del Cluedo.
/// 
/// Define las operaciones puras del negocio para la preparación del mazo,
/// el aislamiento del sobre del crimen y la sincronización.
abstract class GameRepository {
  
  /// Inicializa una nueva partida de Cluedo consumiendo de forma fiel
  /// la configuración de cartas.
  ///
  /// Se encarga de aislar de manera secreta el triple combo del crimen
  /// (Asesino, Arma, Habitación) antes de que empiece la partida.
  Future<ClueGameState> initializeLocalGame({required int numberOfPlayers, required String selectedCharacterId});
}