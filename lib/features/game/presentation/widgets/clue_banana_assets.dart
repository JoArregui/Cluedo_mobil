import 'package:flutter/material.dart';
import '../../domain/entities/card.dart';

/// Factoría de Assets Gráficos Procedurales generados en caliente.
/// Cumple con la especificación de diseño para el motor de Cluedo.
class ClueBananaAssets {
  
  /// Genera un fondo decorativo con un degradado Noir y un patrón de damero
  /// victoriano para el menú principal, evitando cargar un archivo .png pesado.
  static Widget buildMenuBackground({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0F0F), // Rojo sangre muy oscuro
            Color(0xFF0F111A), // Azul noche profundo
            Color(0xFF000000), // Negro puro
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Capa de textura procedural: Líneas de cuadrícula sutiles estilo mansión
          Opacity(
            opacity: 0.03,
            child: GridPaper(
              color: Colors.amber[100]!,
              divisions: 1,
              subdivisions: 1,
              interval: 40,
            ),
          ),
          child,
        ],
      ),
    );
  }

  /// Pinta el arte representativo del sospechoso mediante siluetas vectoriales de alta fidelidad.
  /// Evita el uso de imágenes externas mapeando el color exacto desde el CMS.
  static Widget renderCharacterArt({required CharacterCard character, double size = 80}) {
    final Color characterColor = _parseHexColor(character.hexColor);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Aura de misterio de fondo
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  characterColor.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Lupa / Mira de investigación estilizada
          Icon(
            Icons.blur_circular_rounded,
            size: size,
            color: characterColor.withValues(alpha: 0.3),
          ),
          // Icono del avatar del sospechoso
          Icon(
            Icons.person_outline_rounded,
            size: size * 0.6,
            color: characterColor,
          ),
          // Marca de sospecha
          Positioned(
            right: size * 0.1,
            top: size * 0.1,
            child: const Icon(
              Icons.help_outline,
              size: 16,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  /// Genera la ilustración procedural para las cartas de Armas.
  static Widget renderWeaponArt({required WeaponCard weapon, double size = 80}) {
    IconData weaponIcon;
    
    // Mapeo lógico de iconos según el ID del CMS libre de caracteres extraños
    switch (weapon.id) {
      case 'knife':
        weaponIcon = Icons.colorize_rounded; // Símbolo aguzado estilizado
        break;
      case 'revolver':
        weaponIcon = Icons.gavel_rounded; // Alternativa a gatillo/martillo de revólver
        break;
      case 'rope':
        weaponIcon = Icons.all_inclusive_rounded; // Lazo/Cuerda estilizado
        break;
      case 'candlestick':
        weaponIcon = Icons.light_rounded; // Candelabro / Vela encendida
        break;
      default:
        weaponIcon = Icons.construction_rounded; // Para la llave inglesa o tubería de plomo
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black26,
            ),
          ),
          Icon(
            weaponIcon,
            size: size * 0.5,
            color: Colors.grey[400],
          ),
          Icon(
            Icons.dangerous_outlined,
            size: size * 0.85,
            color: Colors.red[900]!.withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }

  /// Genera la ilustración procedural para los planos de las Habitaciones.
  static Widget renderRoomArt({required RoomCard room, double size = 80}) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.architecture_rounded,
            size: size * 0.9,
            color: Colors.amber[700]!.withValues(alpha: 0.15),
          ),
          Icon(
            Icons.meeting_room_outlined,
            size: size * 0.5,
            color: Colors.amber[200],
          ),
          if (room.secretPassageToRoomId != null)
            Positioned(
              bottom: 4,
              right: 4,
              child: Tooltip(
                message: 'Tiene pasadizo secreto',
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.purple[900],
                  child: const Icon(Icons.vpn_key, size: 10, color: Colors.amber),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Utilidad interna para parsear los colores hexadecimales que vienen del ClueDeck
  static Color _parseHexColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}