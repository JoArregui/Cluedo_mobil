import 'package:flutter/material.dart';

class StartGameView extends StatelessWidget {
  const StartGameView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.amber),
          SizedBox(height: 16),
          Text("Iniciando la investigación...", style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}