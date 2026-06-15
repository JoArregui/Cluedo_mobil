// lib/features/game/presentation/controllers/adventure_controller.dart
import 'package:flutter/material.dart';
import '../../domain/entities/card.dart';

class AdventureController extends ChangeNotifier {
  String? _currentTitle;
  String? _currentMessage;
  String? _currentImagePath;
  bool _isOverlayVisible = false;

  bool get isOverlayVisible => _isOverlayVisible;
  String? get currentTitle => _currentTitle;
  String? get currentMessage => _currentMessage;
  String? get currentImagePath => _currentImagePath;

  void triggerRoomEvent(RoomCard room) {
    _currentTitle = room.nameEs;
    _currentMessage = "Has entrado en la ${room.nameEs}. ¿Qué secretos encontrarás aquí?";
    // Usamos la lógica de rutas definida anteriormente
    _currentImagePath = 'assets/images/rooms/Imagen_Cluedo_${room.id}.jpg';
    _isOverlayVisible = true;
    notifyListeners();
  }

  void closeOverlay() {
    _isOverlayVisible = false;
    notifyListeners();
  }
}