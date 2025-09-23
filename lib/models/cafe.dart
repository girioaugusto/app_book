// lib/models/cafe.dart
class Cafe {
  final String name;
  final double lat;
  final double lng;
  final String? address;
  final double? rating;
  final bool? openNow;

  Cafe({
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
    this.rating,
    this.openNow,
  });

  String distanceLabel(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
