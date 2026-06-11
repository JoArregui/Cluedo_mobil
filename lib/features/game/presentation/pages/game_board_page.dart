import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/state_game.dart';
import '../bloc/game_bloc.dart';
import '../widgets/board_3d_widget.dart';
import '../widgets/control_panel_widget.dart';
import '../widgets/game_header_widget.dart';
import '../widgets/notebook_floating_button.dart';
import '../widgets/start_game_view.dart';
import '../widgets/room_narrative_overlay.dart';

class GameBoardPage extends StatefulWidget {
  final String selectedCharacterId;

  const GameBoardPage({super.key, required this.selectedCharacterId});

  @override
  State<GameBoardPage> createState() => _GameBoardPageState();
}

class _GameBoardPageState extends State<GameBoardPage> {
  @override
  void initState() {
    super.initState();
    context.read<GameBloc>().add(
      StartNewGameEvent(
        numberOfPlayers: 3,
        selectedCharacterId: widget.selectedCharacterId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: BlocBuilder<GameBloc, GameBlocState>(
        builder: (context, state) {
          if (state is GameInitial) return const StartGameView();

          if (state is GameLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          if (state is GamePlayReady) {
            final gameState = state.gameState;
            // Captura local para permitir la promoción de tipo del campo público
            final roomNarrative = gameState.currentRoomForNarrative;

            return SafeArea(
              child: Column(
                children: [
                  GameHeaderWidget(
                    jugadorActual: gameState.currentCharacter,
                    gameState: gameState,
                  ),
                  _buildHandView(gameState.currentCharacter.hand),
                  Expanded(
                    child: Stack(
                      children: [
                        // Capa base 3D
                        Positioned.fill(child: const Board3DWidget()),

                        // Botón flotante del cuaderno
                        const Positioned(
                          right: 16,
                          bottom: 16,
                          child: NotebookFloatingButton(),
                        ),

                        // Capa de Aventura Gráfica (Overlay dinámico)
                        if (gameState.phase == GamePhase.narrative &&
                            roomNarrative != null)
                          RoomNarrativeOverlay(
                            room: roomNarrative,
                            onClose: () {
                              context.read<GameBloc>().add(
                                CloseNarrativeEvent(),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  ControlPanelWidget(state: state),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHandView(List<dynamic> hand) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: hand.length,
          itemBuilder: (context, index) {
            final card = hand[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  card.nameEs,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: Colors.black),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
