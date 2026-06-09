import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import 'detective_notebook_widget.dart';
import '../../domain/entities/card.dart'; // Asegúrate de importar el tipo base

class NotebookFloatingButton extends StatelessWidget {
  const NotebookFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameBlocState>(
      builder: (context, state) {
        // Filtramos y convertimos a List<ClueCard> explícitamente
        final List<ClueCard> totalDeck = (state is GamePlayReady) 
            ? state.gameState.totalDeck.cast<ClueCard>() 
            : [];
        
        return FloatingActionButton(
          backgroundColor: Colors.amber,
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => DetectiveNotebookWidget(totalDeck: totalDeck),
            );
          },
          child: const Icon(Icons.menu_book, color: Colors.black),
        );
      },
    );
  }
}