import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart'; // Importante para la orientación y control de UI

import 'features/game/data/datasources/game_cms_data_source.dart';
import 'features/game/data/repositories/game_repository_impl.dart';
import 'features/game/presentation/bloc/game_bloc.dart';
import 'features/game/presentation/pages/main_menu_page.dart';

void main() async {
  // Aseguramos la inicialización de los bindings y los servicios nativos
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
    final gameCmsDataSource = GameCmsDataSourceImpl();
    final gameRepository = GameRepositoryImpl(cmsDataSource: gameCmsDataSource);

    return MultiBlocProvider(
      providers: [
        BlocProvider<GameBloc>(
          create: (context) => GameBloc(gameRepository: gameRepository),
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
        home: const MainMenuPage(),
      ),
    );
  }
}