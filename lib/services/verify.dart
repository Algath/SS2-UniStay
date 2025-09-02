import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Face verification service using face-api server
Future<String> verifyFaces(XFile image1, XFile image2) async {
  // 1. Read bytes and encode to Base64
  final bytes1 = await image1.readAsBytes();
  final bytes2 = await image2.readAsBytes();
  final b64_1 = 'data:image/jpeg;base64,${base64Encode(bytes1)}';
  final b64_2 = 'data:image/jpeg;base64,${base64Encode(bytes2)}';

  // 2. Prepare request
  // TODO: Change the URI address to the online one (currently local docker)
  final uri = Uri.parse("http://127.0.0.1:8080/verify");
  final resp = await http.post(
    uri,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"img1": b64_1, "img2": b64_2}),
  );

  // 3. Parse response
  if (resp.statusCode == 200) {
    final json = jsonDecode(resp.body);
    return "Verified: ${json['verified']}\n"
           "Distance: ${json['distance']}\n"
           "Model: ${json['model']}";
  } else {
    return "Error ${resp.statusCode}: ${resp.body}";
  }
}
