class AssetManager {
  static String getCharacter(String id) => 'assets/images/characters/Imagen_Cluedo_$id.jpg';
  
  static String getRoom(String id) {
    // Lista de archivos que son .png en tu estructura
    final pngRooms = ['Billiard_Room', 'Conservatory', 'Kitchen'];
    final extension = pngRooms.contains(id) ? 'png' : 'jpg';
    return 'assets/images/rooms/Imagen_Cluedo_$id.$extension';
  }

  static String getWeapon(String id) {
    // Normalización: tus archivos tienen guiones bajos
    return 'assets/images/weapons/Imagen_Cluedo_$id.jpg';
  }
}