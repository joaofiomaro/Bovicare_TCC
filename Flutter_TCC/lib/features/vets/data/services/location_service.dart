import 'package:geolocator/geolocator.dart';

/// Wrapper sobre geolocator com fallback seguro para localização padrão.
/// Fallback: Rio Claro, SP — cidade de referência do protótipo.
class LocationService {
  static const double _defaultLat = -22.4149;
  static const double _defaultLng = -47.5613;

  Future<(double lat, double lng)> getCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (_defaultLat, _defaultLng);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () => Position(
          latitude:               _defaultLat,
          longitude:              _defaultLng,
          timestamp:              DateTime.now(),
          accuracy:               0,
          altitude:               0,
          altitudeAccuracy:       0,
          heading:                0,
          headingAccuracy:        0,
          speed:                  0,
          speedAccuracy:          0,
        ),
      );

      return (position.latitude, position.longitude);
    } on Exception catch (_) {
      return (_defaultLat, _defaultLng);
    }
  }
}
