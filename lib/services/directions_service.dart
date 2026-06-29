import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/api_config.dart';

class DirectionsService {
  final Dio _dio = Dio();

  /// Fetches road route coordinates (polylines) between origin and destination.
  Future<List<LatLng>> getRoute(LatLng origin, LatLng destination) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'key': ApiConfig.googleMapsApiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;
          if (routes.isNotEmpty) {
            final overviewPolyline = routes[0]['overview_polyline'] as Map;
            final points = overviewPolyline['points'] as String;
            return _decodePolyline(points);
          }
        } else {
          print('Directions API error status: ${data['status']}');
        }
      }
    } catch (e) {
      print('Failed to fetch directions: $e');
    }
    // Fallback: straight line between origin and destination
    return [origin, destination];
  }

  /// Decodes Google's Encoded Polyline Algorithm format.
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
