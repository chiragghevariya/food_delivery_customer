import 'package:geocoding/geocoding.dart';
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

  /// Resolves latitude and longitude coordinates into a human-readable street address.
  /// Returns a formatted address string (street, locality, postal code, country) or falls back to coordinate string.
  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        final List<String> addressParts = [];

        // Build a readable address string sequentially
        if (pm.street != null && pm.street!.isNotEmpty) {
          addressParts.add(pm.street!);
        } else if (pm.name != null && pm.name!.isNotEmpty) {
          addressParts.add(pm.name!);
        }

        if (pm.subLocality != null && pm.subLocality!.isNotEmpty) {
          addressParts.add(pm.subLocality!);
        }

        if (pm.locality != null && pm.locality!.isNotEmpty) {
          addressParts.add(pm.locality!);
        }

        if (pm.postalCode != null && pm.postalCode!.isNotEmpty) {
          addressParts.add(pm.postalCode!);
        }

        if (pm.country != null && pm.country!.isNotEmpty) {
          addressParts.add(pm.country!);
        }

        if (addressParts.isNotEmpty) {
          return addressParts.join(', ');
        }
      }
    } catch (_) {
      // Best-effort fallback: if geocoding fails, return formatted raw coordinates
    }
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }
}
