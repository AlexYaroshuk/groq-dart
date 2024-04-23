import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';
import 'error.dart';
import 'model.dart';

final class ApiClient {
  final String _apiKey;
  final Uri _uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

  ApiClient({required String apiKey}) : _apiKey = apiKey;


  // Send request to Groq API with streaming support
  Stream<GroqResponse> makeRequest({
    required GroqRequest groqRequest,
  }) async* {
    final request = http.Request("POST", _uri)
      ..headers.addAll({
        ApiHeaderKeys.authorization: ApiHeaderValues.bearer(_apiKey),
        ApiHeaderKeys.contentType: ApiHeaderValues.applicationJson,
      })
      ..body = jsonEncode(groqRequest);

    final streamedResponse = await http.Client().send(request);

   if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
  await for (final chunk in streamedResponse.stream.transform(utf8.decoder).transform(LineSplitter())) {
    print("Received chunk: $chunk"); // Debug log
    if (chunk.startsWith('data: ')) {
      final content = chunk.substring(6).trim();
      print("Processing content: $content"); // Debug log
      if (content.isNotEmpty && content != "[DONE]") {
        try {
          final data = jsonDecode(content) as Map<String, dynamic>;
          print("Decoded data: $data"); // Debug log
          yield GroqResponse.fromJson(data);
        } on FormatException catch (e) {
          print("Skipping invalid JSON chunk: $content - Error: $e");
        }
      }
    }
  }
} else {
    // Log error status code and response body for debugging
    final errorMessage = await streamedResponse.stream.bytesToString();
    print("Error response: $errorMessage");
    // Throw a generic exception with the error message
    throw Exception(errorMessage);
}
  }
}
