import 'package:dio/dio.dart';

/// Turn any error (especially a Dio error from the API) into a friendly message.
String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      // Laravel validation errors look like:
      // { "message": "...", "errors": { "email": ["The email ..."] } }
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
      }
      if (data['message'] is String) return data['message'] as String;
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Could not reach the server. Check your connection and the API URL.';
    }
  }
  return 'Something went wrong. Please try again.';
}
