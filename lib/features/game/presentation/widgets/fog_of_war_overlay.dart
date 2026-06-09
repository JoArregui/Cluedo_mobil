/* import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class FogOfWarOverlay extends StatefulWidget {
  final Widget child;
  final Offset playerPosition;

  const FogOfWarOverlay({
    super.key, 
    required this.child, 
    required this.playerPosition
  });

  @override
  State<FogOfWarOverlay> createState() => _FogOfWarOverlayState();
}

class _FogOfWarOverlayState extends State<FogOfWarOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ui.FragmentProgram? _program;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _loadShader();
  }

  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset('assets/shaders/fog_of_war.frag');
    if (mounted) {
      setState(() {
        _program = program;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_program == null) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: ShaderPainter(
            program: _program!,
            playerPos: widget.playerPosition,
            time: _controller.value * 10,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class ShaderPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final Offset playerPos;
  final double time;

  ShaderPainter({
    required this.program, 
    required this.playerPos,
    required this.time
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader()
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, playerPos.dx)
      ..setFloat(3, playerPos.dy)
      ..setFloat(4, time);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant ShaderPainter oldDelegate) => true;
} */