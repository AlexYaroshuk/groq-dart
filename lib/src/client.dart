import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';
import 'error.dart';
import 'model.dart';

final class ApiClient {
  final String _apiKey;
  final Uri _uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

  ApiClient({required String apiKey}) : _apiKey = apiKey;

  // Send request to Groq API
    Future<GroqResponse> makeRequest({
    required GroqRequest groqRequest,
  }) async {
    final response = await http.post(
      _uri,
      headers: {
        ApiHeaderKeys.authorization: ApiHeaderValues.bearer(_apiKey),
        ApiHeaderKeys.contentType: ApiHeaderValues.applicationJson,
      },
      body: jsonEncode(groqRequest),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Assuming the response is now a stream wrapped in "data" objects
      final Map<String, dynamic> decodedResponse = jsonDecode(response.body);
      if (decodedResponse.containsKey('data')) {
        // If the response contains 'data', parse it
        return GroqResponse.fromJson(decodedResponse['data']);
      } else {
        // If there's no 'data' key, the format is unexpected
        throw FormatException('Expected response to contain "data" key.');
      }
    } else {
      throw parseErrorFor(
        response.statusCode,
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
  }
}