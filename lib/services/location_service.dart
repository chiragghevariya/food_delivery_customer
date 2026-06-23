import 'package:geolocator/geolocator.dart';

/// A simple lat/lng pair.
class LatLngResult {
  final double lat;
  final double lng;
  LatLngResult(this.lat, this.lng);
}

/// Reads the device's GPS location using the geolocator package.
class LocationService {
  /// Returns the current location, or throws a readable String error.
  static Future<LatLngResult> getCurrentLocation() async {
    final servicesOn = await Geolocator.isLocationServiceEnabled();
    if (!servicesOn) {
      throw 'Location services are turned off.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw 'Location permission was denied.';
    }

    final position = await Geolocator.getCurrentPosition();
    return LatLngResult(position.latitude, position.longitude);
  }
}
