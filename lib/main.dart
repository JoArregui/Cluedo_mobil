import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import 'features/game/data/datasources/game_local_data_source.dart';
import 'features/game/data/repositories/game_repository_impl.dart';
import 'features/game/domain/entities/board_map.dart';
import 'features/game/domain/usecases/execute_bot_turn.dart';
import 'features/game/domain/usecases/validate_movement.dart';
import 'features/game/presentation/bloc/game_bloc.dart';
import 'features/game/presentation/pages/main_menu_page.dart';
import 'features/game/presentation/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloqueamos la orientación en modo vertical (retrato) para evitar rotaciones
  // inesperadas que afecten la experiencia de juego
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ClueApp());
}

class ClueApp extends StatelessWidget {
  const ClueApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definición de dependencias
    final gameLocalDataSource = GameLocalDataSourceImpl();
    final gameRepository = GameRepositoryImpl(localDataSource: gameLocalDataSource);
    final boardMap = BoardMap();
    final validateMovement = ValidateMovement(boardMap: boardMap);
    final executeBotTurn = ExecuteBotTurn(
      validateMovement: validateMovement,
      boardMap: boardMap,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<GameBloc>(
          create: (context) => GameBloc(
            gameRepository: gameRepository,
            executeBotTurn: executeBotTurn,
            boardMap: boardMap,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Cluedo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blueGrey,
          // Un fondo oscuro ayuda a ocultar parpadeos en el renderizado 3D inicial
          scaffoldBackgroundColor: const Color(0xFF0D0F14),
        ),
        // La splash screen se muestra al arrancar y navega sola hacia MainMenuPage
        home: const SplashScreen(
          nextScreen: MainMenuPage(),
        ),
      ),
    );
  }
}