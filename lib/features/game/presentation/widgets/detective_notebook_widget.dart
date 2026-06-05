import 'package:flutter/material.dart';
import '../../domain/entities/card.dart';

class DetectiveNotebookWidget extends StatefulWidget {
  final List<ClueCard> totalDeck;

  const DetectiveNotebookWidget({
    super.key,
    required this.totalDeck,
  });

  @override
  State<DetectiveNotebookWidget> createState() => _DetectiveNotebookWidgetState();
}

class _DetectiveNotebookWidgetState extends State<DetectiveNotebookWidget> {
  // Mapa para almacenar las notas del jugador. 
  // Clave: ID de la carta, Valor: Estado de la nota (null = sin marcar, true = confirmado, false = descartado)
  final Map<String, bool?> _notes = {};

  @override
  Widget build(BuildContext context) {
    // Clasificamos las cartas del mazo del CMS por categorías para las pestañas
    final characters = widget.totalDeck.where((c) => c.type == CardType.character).toList();
    final weapons = widget.totalDeck.where((c) => c.type == CardType.weapon).toList();
    final rooms = widget.totalDeck.where((c) => c.type == CardType.room).toList();

    return DefaultTabController(
      length: 3,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Línea superior decorativa de arrastre tipo BottomSheet
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.assignment, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Text(
                    'Cuaderno de Notas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                  ),
                ],
              ),
            ),
            // Pestañas del cuaderno
            const TabBar(
              labelColor: Colors.blueGrey,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blueGrey,
              tabs: [
                Tab(icon: Icon(Icons.people), text: 'Sospechosos'),
                Tab(icon: Icon(Icons.gavel), text: 'Armas'),
                Tab(icon: Icon(Icons.home), text: 'Habitaciones'),
              ],
            ),
            // Contenido de las listas por categoría
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: TabBarView(
                children: [
                  _buildCategoryList(characters),
                  _buildCategoryList(weapons),
                  _buildCategoryList(rooms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<ClueCard> cards) {
    if (cards.isEmpty) {
      return const Center(
        child: Text('No hay registros disponibles en el CMS.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cards.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final card = cards[index];
        final state = _notes[card.id];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            card.nameEs,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              // Efecto visual de tachado si el jugador marcó la pista como descartada
              decoration: state == false ? TextDecoration.lineThrough : null,
              color: state == false ? Colors.grey : Colors.black87,
            ),
          ),
          subtitle: Text(
            card.nameEn,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              decoration: state == false ? TextDecoration.lineThrough : null,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón de Descartar (X)
              IconButton(
                icon: Icon(
                  state == false ? Icons.cancel : Icons.cancel_outlined,
                  color: state == false ? Colors.red : Colors.grey[400],
                ),
                onPressed: () {
                  setState(() {
                    _notes[card.id] = (state == false) ? null : false;
                  });
                },
              ),
              // Botón de Confirmar / Culpable (Check)
              IconButton(
                icon: Icon(
                  state == true ? Icons.check_circle : Icons.check_circle_outline,
                  color: state == true ? Colors.green : Colors.grey[400],
                ),
                onPressed: () {
                  setState(() {
                    _notes[card.id] = (state == true) ? null : true;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}