import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../domain/entities/position.dart';
import '../../domain/entities/state_game.dart';
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
            // Handle animation path if present
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
          // ignore console messages for cleaner output
        },
      ),
    );
  }

  void _syncState(GamePlayReady state) {
    if (_webController == null) return;

    // FIX: removed spurious 'return' inside map literal
    final players = state.gameState.players
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

    final json = jsonEncode({'players': players});
    _webController!.evaluateJavascript(
      source: 'window.updateGameState(${jsonEncode(json)});',
    );
  }

  void _handleGridClick(Map<String, dynamic> msg) {
    if (_webController == null || !_webReady) return;

    try {
      final x = msg['x'] as int?;
      final y = msg['y'] as int?;
      if (x != null && y != null) {
        final state = context.read<GameBloc>().state;
        if (state is GamePlayReady) {
          final gameState = state.gameState;
          final currentPlayerIndex = gameState.currentTurnIndex;

          // Check if it's the current player's turn
          final currentPlayer = gameState.players[currentPlayerIndex];
          final currentPlayerId = currentPlayer.card.id;

          if (currentPlayerId == gameState.currentCharacter.card.id &&
              gameState.phase == GamePhase.moving) {
            // Validate the move
            final validator = ValidateMovement();
            final isValid = validator.call(
              gameState: gameState,
              target: Position(x: x, y: y, roomId: null),
            );

            if (isValid) {
              // Emit the move character event
              context.read<GameBloc>().add(
                MoveCharacterEvent(x: x, y: y, roomId: null),
              );
            }
          }
        }
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

// Animation info class to track active animations
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
