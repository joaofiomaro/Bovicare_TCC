import 'package:geolocator/geolocator.dart';

/// Origem da posição devolvida por [LocationService].
enum LocationSource {
  /// Posição atual obtida do GPS/rede.
  gps,

  /// Última posição conhecida pelo sistema (GPS demorou ou falhou).
  lastKnown,

  /// Posição padrão do protótipo — permissão negada, serviço desligado ou
  /// plataforma sem suporte.
  fallback,
}

/// Localização do usuário com metadado de origem. A UI usa [isFallback] para
/// avisar que o mapa está centralizado numa posição padrão, e não na real.
class UserLocation {
  const UserLocation({
    required this.lat,
    required this.lng,
    required this.source,
  });

  final double lat;
  final double lng;
  final LocationSource source;

  bool get isFallback => source == LocationSource.fallback;
}

/// Wrapper sobre geolocator com fallback seguro para localização padrão.
/// Fallback: Rio Claro, SP — cidade de referência do protótipo.
///
/// Nunca lança: qualquer falha (permissão, serviço desligado, timeout,
/// plataforma sem suporte) resulta em [fallback].
class LocationService {
  static const double defaultLat = -22.4149;
  static const double defaultLng = -47.5613;

  static const UserLocation fallback = UserLocation(
    lat:    defaultLat,
    lng:    defaultLng,
    source: LocationSource.fallback,
  );

  /// Tempo máximo esperando o GPS antes de cair na última posição conhecida.
  static const Duration _gpsTimeout = Duration(seconds: 10);

  Future<UserLocation> getCurrentLocation() async {
    try {
      // Serviço de localização desligado no aparelho → nem pede permissão.
      if (!await Geolocator.isLocationServiceEnabled()) return fallback;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return fallback;
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy:  LocationAccuracy.medium,
            timeLimit: _gpsTimeout,
          ),
        ).timeout(_gpsTimeout + const Duration(seconds: 2));

        return UserLocation(
          lat:    position.latitude,
          lng:    position.longitude,
          source: LocationSource.gps,
        );
      } on Exception catch (_) {
        // GPS demorou/falhou: última posição conhecida ainda é útil para
        // ordenar os veterinários por distância.
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) return fallback;
        return UserLocation(
          lat:    last.latitude,
          lng:    last.longitude,
          source: LocationSource.lastKnown,
        );
      }
    } on Exception catch (_) {
      return fallback;
    }
  }
}
