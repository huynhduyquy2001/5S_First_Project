class Coordinate {
  final int? id;
  final double latitude;
  final double longitude;
  final String timestamp;

  Coordinate({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  // Chuyển từ Map sang Coordinate
  factory Coordinate.fromMap(Map<String, dynamic> map) {
    return Coordinate(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      timestamp: map['timestamp'],
    );
  }

  // Chuyển từ Coordinate sang Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
  }
}
