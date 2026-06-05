import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import '../widgets/detective_notebook_widget.dart';
import '../../domain/entities/state_game.dart';
import '../../domain/entities/clue_deck.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/board_map.dart';
import '../../domain/entities/tile_type.dart';

class GameBoardPage extends StatelessWidget {
  final BoardMap boardMap = const BoardMap();

  const GameBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14), // Fondo de la app ultra oscuro (Onyx)
      appBar: AppBar(
        title: const Text(
          'Mansion Tudor - Cluedo Pro', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)
        ),
        backgroundColor: const Color(0xFF151821),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.amber.withValues(alpha: 0.15), height: 1),
        ),
      ),
      body: BlocConsumer<GameBloc, GameBlocState>(
        listener: (context, state) {
          if (state is GamePlayReady && state.notificationMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.privacy_tip_outlined, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.notificationMessage!, style: const TextStyle(fontWeight: FontWeight.w600))),
                  ],
                ),
                backgroundColor: const Color(0xFF1F1212),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.red[800]!, width: 1),
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is GameInitial) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1D24), Color(0xFF090A0F)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'CLUEDO',
                      style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 8),
                    ),
                    const SizedBox(height: 50),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[900],
                        foregroundColor: Colors.white,
                        elevation: 12,
                        shadowColor: Colors.red.withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.amber, width: 0.5)
                        ),
                      ),
                      onPressed: () {
                        context.read<GameBloc>().add(const StartNewGameEvent(numberOfPlayers: 1));
                      },
                      child: const Text(
                        'Iniciar Investigación',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is GameLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }

          if (state is GamePlayReady) {
            final gameState = state.gameState;
            final jugadorActual = gameState.currentCharacter;

            return SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildHeaderPanel(jugadorActual, gameState),
                      
                      // Zona de renderizado del Tablero Moderno con InteractiveViewer
                      Expanded(
                        child: Container(
                          color: const Color(0xFF090A0F),
                          padding: const EdgeInsets.all(8),
                          child: InteractiveViewer(
                            maxScale: 5.0,
                            minScale: 0.8,
                            boundaryMargin: const EdgeInsets.all(40),
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: boardMap.columns / boardMap.rows,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF12141C),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF2E2416), width: 5), // Marco de caoba del tablero
                                    boxShadow: const [
                                      BoxShadow(color: Color(0xFA000000), blurRadius: 24, offset: Offset(0, 8))
                                    ],
                                  ),
                                  child: GridView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: boardMap.columns,
                                    ),
                                    itemCount: boardMap.columns * boardMap.rows,
                                    itemBuilder: (context, index) {
                                      final x = index % boardMap.columns;
                                      final y = index ~/ boardMap.columns;
                                      return _buildInteractiveTile(context, gameState, x, y);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      _buildControlPanel(context, state),
                    ],
                  ),
                  
                  // Botón flotante estilizado para desplegar el Cuaderno de Notas
                  Positioned(
                    right: 16,
                    bottom: 240, // Estratégicamente ubicado arriba de la botonera inferior
                    child: FloatingActionButton.extended(
                      elevation: 6,
                      backgroundColor: const Color(0xFF2E3547),
                      foregroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(color: Colors.amber, width: 0.8),
                      ),
                      icon: const Icon(Icons.assignment_turned_in_rounded, size: 20),
                      label: const Text(
                        'NOTAS', 
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 13)
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => DetectiveNotebookWidget(
                            totalDeck: gameState.totalDeck,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeaderPanel(PlayerCharacter jugadorActual, ClueGameState gameState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF151821),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12, 
                    height: 12, 
                    decoration: BoxDecoration(
                      color: _parseHexColor(jugadorActual.card.hexColor), 
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: _parseHexColor(jugadorActual.card.hexColor).withValues(alpha: 0.5), blurRadius: 4)]
                    )
                  ),
                  const SizedBox(width: 10),
                  Text(
                    jugadorActual.card.nameEs,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'FASE: ${gameState.phase.name.toUpperCase()}',
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 1),
              ),
            ],
          ),
          if (gameState.currentDiceResult != null)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8A1A1A), Color(0xFF4A0F0F)]),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.casino, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${gameState.currentDiceResult}',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInteractiveTile(BuildContext context, ClueGameState gameState, int x, int y) {
    final type = boardMap.getTileType(x, y);
    final roomId = boardMap.getRoomIdAt(x, y);

    PlayerCharacter? characterOnTile;
    for (var player in gameState.players) {
      if (player.position.x == x && player.position.y == y && player.position.roomId == null) {
        characterOnTile = player;
        break;
      }
    }

    BoxDecoration tileDecoration = const BoxDecoration();
    Widget? tileContent;

    switch (type) {
      case TileType.wall:
        tileDecoration = const BoxDecoration(
          color: Color(0xFF090B0E),
        );
        break;

      case TileType.walkway:
        tileDecoration = BoxDecoration(
          color: const Color(0xFF1E222D),
          border: Border.all(color: const Color(0xFF282D3B), width: 0.4),
        );
        break;

      case TileType.door:
        tileDecoration = BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9E763B), Color(0xFF5C431D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.amber, width: 0.5),
        );
        tileContent = const Icon(Icons.sensor_door_outlined, size: 9, color: Colors.white);
        break;

      case TileType.room:
        final baseRoomColor = _getRoomUiColor(roomId!);
        tileDecoration = BoxDecoration(
          gradient: RadialGradient(
            colors: [baseRoomColor, baseRoomColor.withValues(alpha: 0.6)],
            radius: 0.85,
          ),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 0.2),
        );

        final charactersInRoom = gameState.players.where((p) => p.position.roomId == roomId).toList();
        
        if (charactersInRoom.isNotEmpty) {
          final roomIndex = charactersInRoom.indexWhere((p) => p.position.roomId == roomId);
          if (x % 4 == 1 && y % 4 == 1 && roomIndex < charactersInRoom.length) {
            final targetPlayer = charactersInRoom[roomIndex];
            tileContent = _buildPlayerToken(targetPlayer.card.hexColor);
          }
        } else if (x % 4 == 2 && y % 4 == 2) {
          final room = ClueDeck.rooms.firstWhere((r) => r.id == roomId);
          tileContent = Text(
            room.nameEs.substring(0, 2).toUpperCase(),
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.15), letterSpacing: 0.5),
          );
        }
        break;
    }

    if (characterOnTile != null && roomId == null) {
      tileContent = _buildPlayerToken(characterOnTile.card.hexColor);
    }

    final bool esCasillaValidaYFaseMovimiento = gameState.phase == GamePhase.moving && type != TileType.wall;

    return GestureDetector(
      onTap: () {
        if (esCasillaValidaYFaseMovimiento) {
          context.read<GameBloc>().add(MoveCharacterEvent(x: x, y: y, roomId: roomId));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: tileDecoration.copyWith(
          boxShadow: esCasillaValidaYFaseMovimiento 
              ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.2), blurRadius: 4, spreadRadius: 0.5)] 
              : null,
          border: esCasillaValidaYFaseMovimiento
              ? Border.all(color: Colors.amber.withValues(alpha: 0.6), width: 0.8)
              : tileDecoration.border,
        ),
        child: Container(
          color: esCasillaValidaYFaseMovimiento ? Colors.amber.withValues(alpha: 0.04) : Colors.transparent,
          child: Center(child: tileContent),
        ),
      ),
    );
  }

  Widget _buildPlayerToken(String hexString) {
    final tokenColor = _parseHexColor(hexString);
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: tokenColor,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF0D0F14), width: 1.8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 4, offset: const Offset(0, 2)),
          BoxShadow(color: tokenColor.withValues(alpha: 0.4), blurRadius: 6),
        ],
      ),
    );
  }

  Color _getRoomUiColor(String roomId) {
    switch (roomId) {
      case 'study': return const Color(0xFF2E221D);
      case 'hall': return const Color(0xFF1F2B3E);
      case 'lounge': return const Color(0xFF3A1F1F);
      case 'library': return const Color(0xFF1B3232);
      case 'billiard_room': return const Color(0xFF14301A);
      case 'conservatory': return const Color(0xFF263A21);
      case 'ballroom': return const Color(0xFF2E1B3B);
      case 'kitchen': return const Color(0xFF3B311B);
      case 'dining_room': return const Color(0xFF3B271B);
      default: return const Color(0xFF1C1E24);
    }
  }

  Widget _buildControlPanel(BuildContext context, GamePlayReady state) {
    final gameState = state.gameState;
    final jugadorActual = gameState.currentCharacter;

    final bool esFaseRefutacion = gameState.phase == GamePhase.refuting;
    final int? refuterIndex = gameState.refutingPlayerIndex;
    final PlayerCharacter? refutingPlayer = refuterIndex != null ? gameState.players[refuterIndex] : null;
    final bool leTocaRefutarAHumano = esFaseRefutacion && refutingPlayer != null && !refutingPlayer.isBot;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF151821),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Color(0xD9000000), blurRadius: 16, offset: Offset(0, -4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leTocaRefutarAHumano)
            _buildHumanRefutationInterface(context, gameState, refutingPlayer)
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (gameState.phase == GamePhase.rolling) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[900], 
                      foregroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    onPressed: () => context.read<GameBloc>().add(RollDiceEvent()),
                    icon: const Icon(Icons.casino, size: 18),
                    label: const Text('Tirar Dados', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                  if (jugadorActual.position.roomId != null &&
                      ClueDeck.rooms.firstWhere((r) => r.id == jugadorActual.position.roomId).secretPassageToRoomId != null)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A1A75), 
                        foregroundColor: Colors.white, 
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      onPressed: () => context.read<GameBloc>().add(UseSecretPassageEvent()),
                      icon: const Icon(Icons.alt_route, size: 18),
                      label: const Text('Pasadizo Secreto', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                ],
                if (gameState.phase == GamePhase.suggesting)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB56A15), 
                      foregroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    onPressed: () => _showSuggestionSelector(context),
                    icon: const Icon(Icons.gavel_rounded, size: 18),
                    label: const Text('Formular Sugerencia', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                if (gameState.phase == GamePhase.moving)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Usa los recuadros iluminados en el mapa para desplazarte.',
                      style: TextStyle(color: Colors.white60, fontStyle: FontStyle.italic, fontSize: 13, letterSpacing: 0.2),
                    ),
                  ),
                if (gameState.phase == GamePhase.refuting)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'A la espera de la coartada de: ${refutingPlayer?.card.nameEs}...',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 18),

          const Text(
            'Tus Cartas Asignadas:',
            style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 95,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: gameState.players.firstWhere((p) => !p.isBot).hand.length,
              itemBuilder: (context, index) {
                final carta = gameState.players.firstWhere((p) => !p.isBot).hand[index];
                return Container(
                  width: 95,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D222F),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2E3547), width: 1.2),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        carta.type == CardType.character
                            ? Icons.person_search_rounded
                            : carta.type == CardType.weapon
                                ? Icons.gavel_rounded
                                : Icons.gite_rounded,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        carta.nameEs,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHumanRefutationInterface(BuildContext context, ClueGameState gameState, PlayerCharacter humano) {
    final sugerencia = gameState.currentSuggestion ?? [];
    
    final matchingCards = humano.hand.where((card) {
      return sugerencia.any((sug) => sug.id == card.id);
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1611),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8A531A), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debes refutar la sospecha de ${gameState.currentCharacter.card.nameEs}',
            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            'Sospecha actual: ${sugerencia.map((e) => e.nameEs).join(" + ")}',
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 14),
          if (matchingCards.isEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'No posees ninguna de las cartas.',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                  onPressed: () {
                    context.read<GameBloc>().add(const RefuteSuggestionEvent(matchingCard: null));
                  },
                  child: const Text('No puedo refutar', style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          else ...[
            const Text(
              'Elige qué evidencia revelar en secreto:',
              style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: matchingCards.map((carta) {
                return ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6E1B1B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    context.read<GameBloc>().add(RefuteSuggestionEvent(matchingCard: carta));
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: Text(carta.nameEs, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                );
              }).toList(),
            ),
          ]
        ],
      ),
    );
  }

  void _showSuggestionSelector(BuildContext context) {
    CharacterCard selectedCharacter = ClueDeck.characters.first;
    WeaponCard selectedWeapon = ClueDeck.weapons.first;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151821),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Formular Hipótesis Oficial',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 20),
                  
                  const Text('Sospechoso implicado:', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                  DropdownButton<CharacterCard>(
                    value: selectedCharacter,
                    dropdownColor: const Color(0xFF1D222F),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    underline: Container(height: 1, color: Colors.amber.withValues(alpha: 0.3)),
                    items: ClueDeck.characters.map((CharacterCard char) {
                      return DropdownMenuItem<CharacterCard>(
                        value: char,
                        child: Text(char.nameEs),
                      );
                    }).toList(),
                    onChanged: (CharacterCard? newValue) {
                      if (newValue != null) {
                        setModalState(() => selectedCharacter = newValue);
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  const Text('Arma utilizada:', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                  DropdownButton<WeaponCard>(
                    value: selectedWeapon,
                    dropdownColor: const Color(0xFF1D222F),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    underline: Container(height: 1, color: Colors.amber.withValues(alpha: 0.3)),
                    items: ClueDeck.weapons.map((WeaponCard weapon) {
                      return DropdownMenuItem<WeaponCard>(
                        value: weapon,
                        child: Text(weapon.nameEs),
                      );
                    }).toList(),
                    onChanged: (WeaponCard? newValue) {
                      if (newValue != null) {
                        setModalState(() => selectedWeapon = newValue);
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[900],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        context.read<GameBloc>().add(
                          MakeSuggestionEvent(suspect: selectedCharacter, weapon: selectedWeapon),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Lanzar Sospecha', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _parseHexColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}