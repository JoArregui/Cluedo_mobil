import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
  Widget build(BuildContext context) {
    return BlocListener<GameBloc, GameBlocState>(
      listener: (context, state) {
        if (state is GamePlayReady && _webReady) {
          _syncState(state);
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
                final msg = jsonDecode(args[0] as String) as Map<String, dynamic>;
                if (msg['type'] == 'ready') {
                  _webReady = true;
                  final state = context.read<GameBloc>().state;
                  if (state is GamePlayReady) {
                    _syncState(state);
                  }
                }
              } catch (e) {
                debugPrint('FlutterChannel error: $e');
              }
            },
          );
        },
        onLoadStop: (controller, url) async {
          // Inyectar el puente JS para que window.FlutterChannel.postMessage
          // llame al handler de Flutter
          await controller.evaluateJavascript(source: '''
            window.FlutterChannel = {
              postMessage: function(msg) {
                window.flutter_inappwebview.callHandler('FlutterChannel', msg);
              }
            };
          ''');

          // Si el tablero ya envió 'ready' antes de que inyectáramos el puente,
          // forzamos la sincronización aquí
          final state = context.read<GameBloc>().state;
          if (state is GamePlayReady) {
            _webReady = true;
            _syncState(state);
          }
        },
        onConsoleMessage: (controller, message) {
          debugPrint('[WebView] ${message.message}');
        },
      ),
    );
  }

  void _syncState(GamePlayReady state) {
    if (_webController == null) return;

    final players = state.gameState.players.map((p) => {
      'id': p.card.id,
      'hexColor': p.card.hexColor,
      'x': p.position.x,
      'y': p.position.y,
      'roomId': p.position.roomId,
      'isEliminated': p.isEliminated,
    }).toList();

    final json = jsonEncode({'players': players});
    _webController!.evaluateJavascript(
      source: 'window.updateGameState(${jsonEncode(json)});',
    );
  }
}