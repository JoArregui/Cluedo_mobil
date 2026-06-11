import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RoomRevealWidget extends StatelessWidget {
  final String roomId;
  final String roomName;
  final VoidCallback onDismiss;

  const RoomRevealWidget({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black87,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de fondo de la habitación
            Image.asset(
              'assets/images/rooms/$roomId.jpg',
              fit: BoxFit.cover,
            )
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(begin: const Offset(1.05, 1.05), end: const Offset(1.0, 1.0), duration: 800.ms),

            // Gradiente inferior
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.5, 1.0],
                ),
              ),
            ),

            // Nombre de la habitación
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Text(
                roomName.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3),
            ),

            // Instrucción
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: const Text(
                'Toca para continuar',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 2),
              ).animate(delay: 1200.ms).fadeIn(),
            ),
          ],
        ),
      ),
    );
  }
}