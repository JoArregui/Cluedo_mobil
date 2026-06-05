class Position {
  final int x;
  final int y;
  final String? roomId; // Si es nulo, está en un pasillo.

  const Position({
    required this.x,
    required this.y,
    this.roomId,
  });

  Position copyWith({int? x, int? y, String? roomId}) {
    return Position(
      x: x ?? this.x,
      y: y ?? this.y,
      roomId: roomId ?? this.roomId,
    );
  }
}