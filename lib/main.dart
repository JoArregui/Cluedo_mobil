import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Imports de la Capa de Datos y Dominio para la inyección de dependencias
import 'features/game/data/datasources/game_cms_data_source.dart';
import 'features/game/data/repositories/game_repository_impl.dart';
import 'features/game/presentation/bloc/game_bloc.dart';
import 'features/game/presentation/pages/game_board_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClueApp());
}

class ClueApp extends StatelessWidget {
  const ClueApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Inicializamos de forma limpia las dependencias de la infraestructura
    final gameCmsDataSource = GameCmsDataSourceImpl(); // O la clase concreta de tu DataSource
    final gameRepository = GameRepositoryImpl(cmsDataSource: gameCmsDataSource);

    return MultiBlocProvider(
      providers: [
        BlocProvider<GameBloc>(
          // 2. Inyectamos el repositorio requerido al inicializar el BLoC
          create: (context) => GameBloc(gameRepository: gameRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Cluedo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blueGrey, // Material 3 prefiere colorSchemeSeed antes que primarySwatch
          scaffoldBackgroundColor: Colors.grey[100],
        ),
        home: const GameBoardPage(),
      ),
    );
  }
}