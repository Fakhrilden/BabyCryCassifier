import 'package:flutter/material.dart';
import 'package:voice/models/message_model.dart';
import 'package:voice/screens/home/widgets/chat_msg.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<ChatMessage> messages = [
    ChatMessage(id: 1, text: 'THIS IS THE FIRST MESSAGE.', isSentByMe: false),
    ChatMessage(id: 2, text: 'THIS IS THE Second MESSAGE.', isSentByMe: true),
    ChatMessage(id: 3, text: 'THIS IS THE third', isSentByMe: false),
    ChatMessage(id: 4, text: 'THIS IS THE Fourth', isSentByMe: true),
  ];
  final TextEditingController _controller = TextEditingController();
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microphone permission not granted')),
      );
      return;
    }

    await _recorder!.openRecorder();
  }

  Future<void> _startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder!.startRecorder(toFile: filePath);
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    final String? filePath = await _recorder!.stopRecorder();
    final int msgId = messages.length + 1;

    setState(() {
      _isRecording = false;
      messages.add(ChatMessage(
        id: msgId,
        text: 'Audio Message',
        isSentByMe: true,
        audioPath: filePath,
      ));
    });
  }

  void _sendAudioMessage(String filePath) async {
    final int msgId = messages.length + 1;
    setState(() {
      messages.add(ChatMessage(
          id: msgId,
          text: 'Audio Message',
          isSentByMe: true,
          audioPath: filePath));
    });
  }

  void _sendMessage() {
    final text = _controller.text;
    if (text.isNotEmpty) {
      final int msgId = messages.length + 1;
      setState(() {
        messages.add(ChatMessage(id: msgId, text: text, isSentByMe: true));
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Baby Assistant')),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                reverse: false,
                itemCount: messages.length,
                itemBuilder: (context, index) =>
                    MessageWidget(inputMsg: messages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Ask me anything...',
                  suffixIcon: IconButton(
                    icon: _isRecording ? Icon(Icons.mic_off) : Icon(Icons.mic),
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                  ),
                ),
                onSubmitted: (value) => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _recorder = null;
    super.dispose();
  }
}
