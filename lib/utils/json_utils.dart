/// Small helpers to safely read JSON values from the API.
/// (The API sends money as strings like "12.50", so we parse carefully.)

double? toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

double toDouble(dynamic value, [double fallback = 0]) =>
    toDoubleOrNull(value) ?? fallback;

bool toBool(dynamic value) =>
    value == true || value == 1 || value == '1' || value == 'true';

int toInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

DateTime? toDate(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());
