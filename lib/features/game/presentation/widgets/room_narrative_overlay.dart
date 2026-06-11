import 'package:flutter/material.dart';
import '../../domain/entities/card.dart';

class RoomNarrativeOverlay extends StatelessWidget {
  final RoomCard room;
  final VoidCallback onClose; // Añadimos una callback para cerrar la vista

  const RoomNarrativeOverlay({
    super.key, 
    required this.room,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose, 
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/rooms/${room.id}.png'), 
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Text(
              room.nameEs, 
              style: const TextStyle(
                fontSize: 32, 
                fontWeight: FontWeight.bold, 
                color: Colors.white,
                shadows: [Shadow(blurRadius: 10, color: Colors.black)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}