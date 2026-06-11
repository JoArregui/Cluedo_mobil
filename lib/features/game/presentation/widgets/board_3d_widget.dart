import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../domain/entities/board_map.dart';
import '../../domain/entities/position.dart';
import '../../domain/entities/state_game.dart';
import '../../domain/entities/tile_type.dart';
import '../../domain/usecases/validate_movement.dart';
import '../bloc/game_bloc.dart';

class Board3DWidget extends StatefulWidget {
  const Board3DWidget({super.key});

  @override
  State<Board3DWidget> createState() => _Board3DWidgetState();
}

class _Board3DWidgetState extends State<Board3DWidget> {
  InAppWebViewController? _webController;
  bool _webReady = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _webController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameBloc, GameBlocState>(
      listener: (context, state) {
        if (state is GamePlayReady) {
          if (_webReady && _webController != null) {
            _syncState(state);
            if (state.animationPath != null) {
              _handleAnimationPath(state.animationPath!);
            }
          }
        }
      },
      child: InAppWebView(
        initialFile: 'assets/board3d.html',
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          mediaPlaybackRequiresUserGesture: false,
          allowFileAccessFromFileURLs: true,
          allowUniversalAccessFromFileURLs: true,
          hardwareAcceleration: true,
          transparentBackground: false,
        ),
        onWebViewCreated: (controller) {
          _webController = controller;

          // Canal JS → Flutter
          controller.addJavaScriptHandler(
            handlerName: 'FlutterChannel',
            callback: (args) {
              if (args.isEmpty) return;
              try {
                final msg =
                    jsonDecode(args[0] as String) as Map<String, dynamic>;
                if (msg['type'] == 'ready') {
                  _webReady = true;
                  final state = context.read<GameBloc>().state;
                  if (state is GamePlayReady) {
                    _syncState(state);
                  }
                } else if (msg['type'] == 'gridClick') {
                  _handleGridClick(msg);
                } else if (msg['type'] == 'rollDice') {
                  _handleRollDice();
                }
              } catch (e) {
                // ignore
              }
            },
          );
        },
        onLoadStop: (controller, url) async {
          // Capturar el bloc ANTES del await
          final bloc = context.read<GameBloc>();

          await controller.evaluateJavascript(
            source: '''
    window.FlutterChannel = {
      postMessage: function(msg) {
        window.flutter_inappwebview.callHandler('FlutterChannel', msg);
      }
    };
  ''',
          );

          if (!mounted) return;

          // Si el tablero ya envió 'ready' antes de que inyectáramos el puente,
          // forzamos la sincronización aquí
          final state = bloc.state;
          if (state is GamePlayReady) {
            _webReady = true;
            _syncState(state);
          }
        },
        onConsoleMessage: (controller, message) {
        },
      ),
    );
  }

  void _syncState(GamePlayReady state) {
    if (_webController == null) return;

    final gameState = state.gameState;

    final players = gameState.players
        .map(
          (p) => {
            'id': p.card.id,
            'hexColor': p.card.hexColor,
            'x': p.position.x,
            'y': p.position.y,
            'roomId': p.position.roomId,
            'isEliminated': p.isEliminated,
          },
        )
        .toList();

    // Calcular casillas válidas solo cuando es el turno humano en fase moving
    List<Map<String, dynamic>> validTiles = [];
    List<String> validRoomIds = [];

    if (gameState.phase == GamePhase.moving &&
        gameState.currentTurnIndex == 0 &&
        gameState.currentDiceResult != null) {
      final result = _calculateValidTiles(gameState);
      validTiles = result['tiles'] as List<Map<String, dynamic>>;
      validRoomIds = result['roomIds'] as List<String>;
    }

    final isHumanRolling = gameState.phase == GamePhase.rolling &&
        gameState.currentTurnIndex == 0;

    // Construir payload: incluir validTiles y validRoomIds solo en fase moving del humano
    final Map<String, dynamic> payload = {
      'players': players,
      'phase': gameState.phase.name,
      'showDice': isHumanRolling,
      'lastDiceRoll': gameState.lastDiceRoll,
    };
    if (gameState.phase == GamePhase.moving &&
        gameState.currentTurnIndex == 0) {
      payload['validTiles'] = validTiles;
      payload['validRoomIds'] = validRoomIds;
    }

    final json = jsonEncode(payload);
    _webController!.evaluateJavascript(
      source: 'window.updateGameState(${jsonEncode(json)});',
    );
  }

  Map<String, dynamic> _calculateValidTiles(ClueGameState gameState) {
    const boardMap = BoardMap();
    final validator = ValidateMovement(boardMap: boardMap);
    final List<Map<String, dynamic>> tiles = [];
    final List<String> roomIds = [];

    // Explorar todas las casillas del grid para pasillos y puertas
    for (int x = 0; x < boardMap.columns; x++) {
      for (int y = 0; y < boardMap.rows; y++) {
        final tileType = boardMap.getTileType(x, y);

        // Solo casillas de pasillo y puertas (movimiento normal)
        if (tileType == TileType.walkway || tileType == TileType.door) {
          final isValid = validator.call(
            gameState: gameState,
            target: Position(x: x, y: y),
          );
          if (isValid) {
            tiles.add({
              'x': x,
              'y': y,
              'type': tileType == TileType.door ? 'door' : 'walkway',
            });
          }
        }
      }
    }

    // Verificar habitaciones alcanzables
    const roomIdList = [
      'study',
      'hall',
      'lounge',
      'library',
      'billiard_room',
      'dining_room',
      'conservatory',
      'ballroom',
      'kitchen',
    ];
    for (final roomId in roomIdList) {
      final isValid = validator.call(
        gameState: gameState,
        target: Position(x: 0, y: 0, roomId: roomId),
      );
      if (isValid) roomIds.add(roomId);
    }

    return {'tiles': tiles, 'roomIds': roomIds};
  }

  void _handleRollDice() {
    final state = context.read<GameBloc>().state;
    if (state is! GamePlayReady) return;

    final gameState = state.gameState;
    if (gameState.currentTurnIndex != 0) return;
    if (gameState.phase != GamePhase.rolling) return;

    context.read<GameBloc>().add(RollDiceEvent());
  }

  void _handleGridClick(Map<String, dynamic> msg) {
    if (_webController == null || !_webReady) return;

    try {
      // FIX: flutter_inappwebview deserializa números JSON como num, no como int.
      // Usar (msg['x'] as num).toInt() para evitar el cast silencioso que fallaba.
      final x = (msg['x'] as num?)?.toInt();
      final y = (msg['y'] as num?)?.toInt();
      if (x == null || y == null) return;

      final state = context.read<GameBloc>().state;
      if (state is! GamePlayReady) return;

      final gameState = state.gameState;

      // Solo procesar si es el turno humano (índice 0) y estamos en fase de movimiento
      if (gameState.currentTurnIndex != 0) return;
      if (gameState.phase != GamePhase.moving) return;

      // FIX: detectar si el tile clickado pertenece a una habitación para pasar
      // el roomId correcto a ValidateMovement. Antes siempre se pasaba roomId: null,
      // lo que hacía que los clicks sobre habitaciones alcanzables (highlight verde)
      // siempre fallaran la validación.
      const boardMap = BoardMap();
      final tileType = boardMap.getTileType(x, y);
      final String? roomId = boardMap.getRoomIdAt(x, y);

      // Si el tile es de tipo room, mover a esa habitación con su roomId.
      // Si es pasillo o puerta, mover a la casilla exacta sin roomId.
      final Position target;
      if (tileType == TileType.room && roomId != null) {
        target = Position(x: x, y: y, roomId: roomId);
      } else {
        target = Position(x: x, y: y, roomId: null);
      }

      final validator = ValidateMovement(boardMap: boardMap);
      final isValid = validator.call(
        gameState: gameState,
        target: target,
      );

      if (isValid) {
        context.read<GameBloc>().add(
          MoveCharacterEvent(x: x, y: y, roomId: target.roomId),
        );
      }
    } catch (e) {
      // ignore grid click errors
    }
  }

  void _handleAnimationPath(Map<String, dynamic> animationPath) {
    if (_webController == null || !_webReady) return;

    try {
      final playerId = animationPath['playerId'] as String;
      final pathJson = animationPath['path'] as List;
      // FIX: cast garantiza non-null, '?.' era innecesario
      final duration = (animationPath['duration'] as num).toDouble();

      // Convert path to List<List<double>>
      final List<List<double>> path = [];
      for (final point in pathJson) {
        if (point is List && point.length >= 2) {
          path.add([
            (point[0] as num).toDouble(),
            (point[1] as num).toDouble(),
          ]);
        }
      }

      if (path.isNotEmpty) {
        final animationData = {
          'type': 'animateToken',
          'playerId': playerId,
          'path': path,
          'duration': duration,
        };

        final json = jsonEncode(animationData);
        _webController!.evaluateJavascript(
          source: 'window.handleFlutterMessage(${jsonEncode(json)});',
        );
      }
    } catch (e) {
      // ignore animation errors
    }
  }
}

class AnimationInfo {
  final String playerId;
  final List<List<double>> path;
  final double startTime;
  final double duration;
  int currentIndex;

  AnimationInfo({
    required this.playerId,
    required this.path,
    required this.startTime,
    required this.duration,
    this.currentIndex = 0,
  });
}