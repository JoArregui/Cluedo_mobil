import 'package:flutter/material.dart';
import '../../domain/entities/card.dart';

class ClueCardRender extends StatelessWidget {
  final ClueCard card;
  final bool isSelected;

  const ClueCardRender({
    super.key,
    required this.card,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    IconData cardIcon;

    // Asignación dinámica de estilos según las reglas del CMS del juego
    switch (card.type) {
      case CardType.character:
        cardColor = Colors.red[900]!;
        cardIcon = Icons.person_search;
        break;
      case CardType.weapon:
        cardColor = Colors.blueGrey[800]!;
        cardIcon = Icons.gavel_rounded;
        break;
      case CardType.room:
        cardColor = Colors.brown[700]!;
        cardIcon = Icons.gite_rounded;
        break;
    }

    return Container(
      width: 130,
      height: 190,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? Colors.amber : Colors.grey[800]!,
          width: isSelected ? 3 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Fondo decorativo abstracto (Reemplaza la necesidad de un asset físico)
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                cardIcon,
                size: 110,
                color: cardColor.withValues(alpha: 0.25),
              ),
            ),
            // Contenido de la carta
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(cardIcon, color: Colors.amber, size: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          card.type.name.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    card.nameEs.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${card.id}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 9,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}