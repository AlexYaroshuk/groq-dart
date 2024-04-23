import 'api.dart';
import 'client.dart';
import 'model.dart';

/// A back-and-forth chat with a generative model.
///
/// Records messages sent and received in [_messages]. The history will always
/// record the content until the user clean the chat message.
class GroqChat {
  late ApiClient _apiClient;
  late Configuration _configuration;
  List<GroqMessage> _messages = [];
  GroqMessage? _instructions;

  GroqChat({
    required ApiClient apiClient,
    required GroqModel model,
  }) {
    _apiClient = apiClient;
    _configuration = Configuration(model: model);
  }

  // Set instruction to the model
  void setCustomInstructionsWith(String value) {
    _instructions = GroqMessage(role: RoleMessage.system, content: value);
  }

  // Remove instruction form the model
  void removeCustomInstructions() {
    _instructions = null;
  }

  // Set instruction to the model
// Example of adjusting a consumer of _sendRequest to handle a stream
Future<void> sendMessage(String content) async {
  final message = GroqMessage(role: RoleMessage.user, content: content);
  _messages.add(message);

  // Listen to the stream of responses
  _sendRequest().listen((response) {
    // Process each response
    // For example, adding the response message to _messages
    // This is a simplified example; actual implementation may vary
    if (response.choices.first.message != null) {}
   /*  _messages.add(response.choices.first.message); */
  }, onError: (error) {
    // Handle errors, if any
    print("Error sending message: $error");
  });

  // Since we're now dealing with streams, there might not be a direct "return" value here
  // Adjust according to your application's needs
}
  // Clear the messages from the chat
  void clearChat() {
    _messages = [];
  }

  // Send a request to Groq API and handle streamed responses
// Send a request to Groq API and handle streamed responses
Stream<GroqMessage> sendStreamedMessage(String content) async* {
  print("sendStreamedMessage called with content: $content");
  final message = GroqMessage(role: RoleMessage.user, content: content);
  _messages.add(message);
    await for (final response in _apiClient.makeRequest(groqRequest: _generateRequest())) {
    for (var choice in response.choices) {
      if (choice.message != null) {
        if (choice.message!.content.isNotEmpty) {
          print("Yielding message: ${choice.message!.content}");
          yield choice.message!;
        } else {
          print("Received valid but empty content, skipping...");
        }
      } else {
        print("Choice message is null, skipping...");
      }
    }
  }
}

 // Adjusted to return a Stream<GroqResponse>
Stream<GroqResponse> _sendRequest() {
  final request = _generateRequest();
  return _apiClient.makeRequest(groqRequest: request);
}
  // Create a request with all details (instructions, messages, configurations)
  GroqRequest _generateRequest() {
    final message = _messages;

    if (_instructions != null) {
      _messages.insert(0, _instructions!);
    }

    return GroqRequest(
      messages: message,
      model: _configuration.modelName,
      temperature: _configuration.temperature,
      maxTokens: _configuration.maxTokens,
      topP: _configuration.topP,
      stream: _configuration.stream,
      stop: _configuration.stop,
    );
  }
}
