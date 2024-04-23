import 'package:flutter/material.dart';
import 'package:groq/groq.dart';

void main() {
  runApp(const GroqExample());
}

class GroqExample extends StatelessWidget {
  const GroqExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
        ),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = <ChatMessage>[];
  final ScrollController _scrollController = ScrollController();

  /// flutter run --dart-define=groqApiKey='Your Api Key'
  final _groq = Groq(apiKey: const String.fromEnvironment('groqApiKey'));

  @override
  void initState() {
    super.initState();
    _groq.startChat();
  }

  void _handleSubmitted(String text) async {
    _textController.clear();
    ChatMessage message = ChatMessage(
      text: text,
      isUserMessage: true,
    );
    setState(() {
      _messages.add(message);
    });

    _scrollToBottomWithDelay(
      const Duration(milliseconds: 200),
    );

    _sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GroqChat'),
        actions: [_buildClearChatButton()],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Flexible(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (_, int index) => _messages[index],
              ),
            ),
            const Divider(height: 1.0),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
              ),
              child: _buildTextComposer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearChatButton() {
    return IconButton(
      onPressed: () {
        _groq.clearChat();
      },
      icon: const Icon(Icons.delete),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Send a message',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ],
        ),
      ),
    );
  }

  _scrollToBottomWithDelay(Duration delay) async {
    await Future.delayed(delay);
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _sendMessage(String text) {
    print('input is $text');
    _textController.clear();

    ChatMessage? lastResponseMessage;

    // Start listening to the stream of messages
    _groq.sendStreamedMessage(text).listen(
      (message) {
        print(
            "New message received: ${message.content}"); // Debug: Ensure we're getting here
        if (message.content.isNotEmpty) {
          if (lastResponseMessage == null) {
            // First message received, create a new ChatMessage and keep a reference to it
            lastResponseMessage = ChatMessage(
              text: message.content,
              isUserMessage: false,
            );
            setState(() {
              _messages.add(lastResponseMessage!);
            });
          } else {
            // Create a new instance with updated text
            final updatedMessage = ChatMessage(
              text: lastResponseMessage!.text + message.content,
              isUserMessage: false,
            );
            setState(() {
              // Replace the last message with the updated one
              _messages.removeLast();
              _messages.add(updatedMessage);
              lastResponseMessage = updatedMessage; // Update the reference
            });
          }
        }
      },
      onError: (error) {
        print("Error receiving message: $error"); // Debug: Print any errors
        ErrorMessage errorMessage = ErrorMessage(
          text: error.toString(),
        );

        setState(() {
          _messages.add(errorMessage);
        });
      },
      // Optionally handle stream completion
      onDone: () {
        print("Stream completed"); // Debug: Confirm the stream completion
        // Handle completion of the stream if necessary
        lastResponseMessage = null; // Reset for the next message
      },
    );
  }
}

class ChatMessage extends StatelessWidget {
  String text;
  final bool isUserMessage;

  ChatMessage({super.key, required this.text, this.isUserMessage = false});

  // Add a method to update text
  void updateText(String newText) {
    text = newText;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CrossAxisAlignment crossAxisAlignment =
        isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: isUserMessage
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.tertiaryContainer,
            borderRadius: isUserMessage
                ? const BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                    bottomLeft: Radius.circular(8.0),
                    bottomRight: Radius.circular(0.0),
                  )
                : const BorderRadius.only(
                    topLeft: Radius.circular(0.0),
                    topRight: Radius.circular(8.0),
                    bottomLeft: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0),
                  ),
          ),
          child: Text(
            text,
            style: theme.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class ErrorMessage extends ChatMessage {
  ErrorMessage({super.key, required super.text});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(0.0),
              topRight: Radius.circular(8.0),
              bottomLeft: Radius.circular(8.0),
              bottomRight: Radius.circular(8.0),
            ),
          ),
          child: Text(
            text,
            style: theme.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}
