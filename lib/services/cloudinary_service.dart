import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = "drse29esy";
  static const String uploadPreset = "profile_pictures";

  static Future<String> uploadImage({
    Uint8List? webImage,
    String? filePath,
  }) async {
    final url =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = uploadPreset;

    if (kIsWeb && webImage != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          webImage,
          filename: 'avatar.jpg',
        ),
      );
    } else if (!kIsWeb && filePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );
    } else {
      throw Exception("Invalid image data");
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      return data['secure_url'];
    } else {
      throw Exception("Cloudinary upload failed: $responseBody");
    }
  }
}
