import 'dart:convert';
import 'dart:typed_data';

class ImageUtils {
  /// Converts a List<int> to base64 string
  static String encodeImage(List<int> imageBytes) {
    try {
      return base64Encode(imageBytes);
    } catch (e) {
      print('Error encoding image: $e');
      rethrow;
    }
  }

  /// Converts a base64 string to Uint8List
  static Uint8List? decodeImage(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      print('Error decoding image: $e');
      return null;
    }
  }

  /// Converts List<dynamic> to Uint8List
  static Uint8List? convertDynamicListToUint8List(List<dynamic>? list) {
    if (list == null) return null;
    try {
      return Uint8List.fromList(list.map((e) => e as int).toList());
    } catch (e) {
      print('Error converting dynamic list to Uint8List: $e');
      return null;
    }
  }

  /// Validates if a string is valid base64
  static bool isValidBase64(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }
}