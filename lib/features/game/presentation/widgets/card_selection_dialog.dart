import 'package:flutter/material.dart';
import '../../domain/entities/card.dart';

Future<void> showCardSelectionDialog({
  required BuildContext context,
  required List<ClueCard> myHand,
  required List<ClueCard> allOptions,
  required Function(ClueCard selected) onSelected,
  required String title,
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1C1F26),
      title: Text(title, style: const TextStyle(color: Colors.amber)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: allOptions.length,
          itemBuilder: (context, index) {
            final card = allOptions[index];
            final isInHand = myHand.any((c) => c.id == card.id);
            
            return ListTile(
              title: Text(card.nameEs, style: const TextStyle(color: Colors.white)),
              subtitle: Text(isInHand ? "En tu mano" : "Pista", 
                           style: TextStyle(color: isInHand ? Colors.green : Colors.grey)),
              onTap: () {
                onSelected(card);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    ),
  );
}