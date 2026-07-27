import 'package:flutter/material.dart';
import 'game_board_page.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  final List<Map<String, String>> characters = const [
    {'id': 'scarlett', 'name': 'Scarlett'},
    {'id': 'mustard', 'name': 'Mustard'},
    {'id': 'green', 'name': 'Green'},
    {'id': 'plum', 'name': 'Plum'},
    {'id': 'white', 'name': 'White'},
    {'id': 'peacock', 'name': 'Peacock'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "CLUEDO",
              style: TextStyle(
                color: Colors.amber,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Elige a tu detective:",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            // Lista de botones para seleccionar personaje
            ...characters.map((char) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: 250,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    // Navegamos pasando el ID del personaje seleccionado
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => GameBoardPage(
                          selectedCharacterId: char['id']!,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    char['name']!,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}