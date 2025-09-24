import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationServices {
  /// Verifica e pede permissão de localização
  static Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  /// Retorna a posição atual do usuário (GPS/Wi-Fi).
  static Future<Position> currentPosition({
    Duration highAccuracyTimeout = const Duration(seconds: 6),
    Duration lowAccuracyTimeout = const Duration(seconds: 5),
  }) async {
    final ok = await ensurePermission();
    if (!ok) {
      throw Exception('Localização desativada ou sem permissão.');
    }

    // 1) Posição de alta precisão
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: highAccuracyTimeout,
      );
    } on TimeoutException {
      // se não conseguir, tenta baixa precisão
    } catch (_) {}

    // 2) Fallback: baixa precisão (rede)
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: lowAccuracyTimeout,
      );
    } on TimeoutException {
    } catch (_) {}

    // 3) Último recurso: última posição conhecida
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) return last;

    throw Exception('Sem posição válida. No emulador, use Extended Controls → Location → Set Location.');
  }

  /// Calcula distância entre dois pontos em metros
  static double distanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}
