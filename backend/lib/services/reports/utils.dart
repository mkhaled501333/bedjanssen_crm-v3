import 'package:mysql1/mysql1.dart';

/// Convert call type integer to string
String convertCallTypeToString(int callType) {
  switch (callType) {
    case 0:
      return 'incoming';
    case 1:
      return 'outgoing';
    default:
      return 'unknown';
  }
}

/// Convert Blob to string safely
dynamic convertFromBlob(dynamic value) {
  if (value is Blob) {
    return value.toString();
  }
  return value;
} 