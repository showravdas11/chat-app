import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:record_mp3_plus/record_mp3_plus.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatRooms extends StatefulWidget {
  const ChatRooms({super.key});

  @override
  _ChatRoomsState createState() => _ChatRoomsState();
}

class _ChatRoomsState extends State<ChatRooms>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textEditingController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "N/A";
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isRecording = false;
  bool _isPlayingAudio = false;
  double _uploadProgress = 0.0;
  String? audioPath;
  String? currentlyPlayingAudio;
  late AnimationController _animationController;
  final AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: const Text(
          'Our Chat',
          style: TextStyle(color: Colors.white),
        )),
        backgroundColor: const Color(0xFF005544),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/chatbg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.darken,
            ),
          ),
        ),
        child: Column(
          children: [
            Expanded(child: _buildMessagesList()),
            if (_isRecording) _buildRecordingAnimation(),
            _buildMessageInput(),
            if (_isUploading)
              LinearProgressIndicator(
                  color: const Color(0xFF005544), value: _uploadProgress),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No messages here yet',
                  style: TextStyle(fontSize: 18, color: Colors.white70)));
        }

        final messages = snapshot.data!.docs;
        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) => _buildMessageItem(messages[index]),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot message) {
    final isCurrentUser = message['senderId'] == currentUserId;
    final isPlaying =
        _isPlayingAudio && currentlyPlayingAudio == message['audioUrl'];

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          gradient: isCurrentUser
              ? LinearGradient(colors: [
                  const Color(0xFF005544),
                  const Color.fromARGB(255, 1, 111, 89)
                ])
              : LinearGradient(colors: [
                  const Color.fromARGB(255, 231, 229, 229),
                  Colors.grey[200]!
                ]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isCurrentUser ? const Radius.circular(15) : Radius.zero,
            bottomRight:
                isCurrentUser ? Radius.zero : const Radius.circular(15),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message['senderName'] ?? 'Unknown',
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            if (message['audioUrl'] != null)
              GestureDetector(
                onTap: () {
                  _playAudio(message['audioUrl']);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? Colors.teal[200] : Colors.teal[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPlaying ? Icons.graphic_eq : Icons.play_arrow,
                        color: isCurrentUser ? Colors.white : Colors.teal,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Play Audio',
                        style: TextStyle(
                          color: isCurrentUser ? Colors.white : Colors.teal,
                        ),
                      ),
                      if (isPlaying)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ScaleTransition(
                            scale: Tween(begin: 1.0, end: 1.5)
                                .animate(_animationController),
                            child: Icon(
                              Icons.circle,
                              color: Colors.redAccent,
                              size: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else if (message['imageUrl'] != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FullScreenImage(imageUrl: message['imageUrl']),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    message['imageUrl'],
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Text(
                message['text'] ?? '',
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : Colors.black,
                ),
              ),
            const SizedBox(height: 5),
            Text(
              message['timestamp'] != null
                  ? _formatTimestamp(message['timestamp'])
                  : 'Just now',
              style: TextStyle(
                color: isCurrentUser ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.teal),
            onPressed: _pickAndSendImage,
          ),
          GestureDetector(
            onLongPress: startRecord,
            onLongPressEnd: (details) => stopRecord(),
            child:
                Icon(Icons.mic, color: _isRecording ? Colors.red : Colors.teal),
          ),
          Expanded(
            child: TextField(
              controller: _textEditingController,
              decoration: InputDecoration(
                hintText: 'Type a message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.grey[200],
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: Colors.teal,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingAnimation() {
    return Center(
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.5).animate(_animationController),
        child: Icon(Icons.mic, color: Colors.red, size: 40),
      ),
    );
  }

  Future<void> startRecord() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return;
    }
    Directory tempDir = await getTemporaryDirectory();
    String path =
        '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
    RecordMp3.instance.start(path, (type) {});
    setState(() => _isRecording = true);
    audioPath = path;
  }

  Future<void> stopRecord() async {
    if (_isRecording) {
      bool result = RecordMp3.instance.stop();
      setState(() => _isRecording = false);
      if (result) await _uploadAudio();
    }
  }

  Future<void> _uploadAudio() async {
    setState(() => _isUploading = true);
    final audioFile = File(audioPath!);
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('audio/${DateTime.now().millisecondsSinceEpoch}.mp3');
    final uploadTask = storageRef.putFile(audioFile);
    uploadTask.snapshotEvents.listen((event) {
      setState(
          () => _uploadProgress = event.bytesTransferred / event.totalBytes);
    });
    final audioUrl = await (await uploadTask).ref.getDownloadURL();
    FirebaseFirestore.instance.collection('messages').add({
      'senderId': currentUserId,
      'senderName': 'Anonymous',
      'audioUrl': audioUrl,
      'timestamp': Timestamp.now(),
    });
    setState(() => _isUploading = false);
  }

  void _sendMessage() {
    final messageText = _textEditingController.text.trim();
    if (messageText.isNotEmpty) {
      FirebaseFirestore.instance.collection('messages').add({
        'senderId': currentUserId,
        'senderName': 'Anonymous',
        'text': messageText,
        'timestamp': Timestamp.now(),
      });
      _textEditingController.clear();
    }
  }

  void _playAudio(String url) async {
    if (_isPlayingAudio && currentlyPlayingAudio == url) {
      // If the same audio is playing, pause it
      await audioPlayer.pause();
      setState(() {
        _isPlayingAudio = false;
      });
    } else if (!_isPlayingAudio && currentlyPlayingAudio == url) {
      // If the audio is paused, resume playback
      await audioPlayer.resume();
      setState(() {
        _isPlayingAudio = true;
      });
    } else {
      await audioPlayer.stop();
      setState(() {
        _isPlayingAudio = true;
        currentlyPlayingAudio = url;
      });
      await audioPlayer.play(UrlSource(url));
    }
    audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlayingAudio = false;
        currentlyPlayingAudio = null;
      });
    });
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('dd MMM, hh:mm a').format(date);
  }

  Future<void> _pickAndSendImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() => _isUploading = true);
      final imageFile = File(pickedImage.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = storageRef.putFile(imageFile);
      uploadTask.snapshotEvents.listen((event) {
        setState(
            () => _uploadProgress = event.bytesTransferred / event.totalBytes);
      });
      final imageUrl = await (await uploadTask).ref.getDownloadURL();
      FirebaseFirestore.instance.collection('messages').add({
        'senderId': currentUserId,
        'senderName': 'Anonymous',
        'imageUrl': imageUrl,
        'timestamp': Timestamp.now(),
      });
      setState(() => _isUploading = false);
    }
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
