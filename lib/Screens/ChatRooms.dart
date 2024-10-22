import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class ChatRooms extends StatefulWidget {
  const ChatRooms({super.key});

  @override
  _ChatRoomsState createState() => _ChatRoomsState();
}

class _ChatRoomsState extends State<ChatRooms> {
  final TextEditingController _textEditingController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "N/A";
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat App'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages here yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message['senderId'] == currentUserId;

                    return Align(
                      alignment: isCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isCurrentUser ? Colors.teal : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(15),
                            topRight: const Radius.circular(15),
                            bottomLeft: isCurrentUser
                                ? const Radius.circular(15)
                                : Radius.zero,
                            bottomRight: isCurrentUser
                                ? Radius.zero
                                : const Radius.circular(15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isCurrentUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['senderName'] ?? 'Unknown',
                              style: TextStyle(
                                color: isCurrentUser
                                    ? Colors.white70
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            message['imageUrl'] != null
                                ? GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FullScreenImage(
                                              imageUrl: message['imageUrl']),
                                        ),
                                      );
                                    },
                                    child: Image.network(
                                      message['imageUrl'],
                                      height: 150,
                                      width: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Text(
                                    message['text'] ?? '',
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                            const SizedBox(height: 5),
                            Text(
                              message['timestamp'] != null
                                  ? _formatTimestamp(message['timestamp'])
                                  : 'Just now',
                              style: TextStyle(
                                color: isCurrentUser
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
          if (_isUploading)
            LinearProgressIndicator(
              value: _uploadProgress,
            ),
        ],
      ),
    );
  }

  // --------msg box ----------------

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.teal),
            onPressed: () {
              _pickAndSendImage();
            },
          ),
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.teal),
            onPressed: () {},
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
              onPressed: () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }

  // Image picker code
  Future<void> _pickAndSendImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      String? imageUrl = await _uploadImage(imageFile);

      if (imageUrl != null) {
        _sendMessage(imageUrl: imageUrl);
      }

      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      String fileName = 'images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      UploadTask uploadTask =
          FirebaseStorage.instance.ref().child(fileName).putFile(imageFile);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _sendMessage({String? imageUrl}) async {
    final text = _textEditingController.text.trim();

    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (userDoc.exists) {
      final String? userName = userDoc['name'];

      if (text.isNotEmpty || imageUrl != null) {
        try {
          await FirebaseFirestore.instance.collection('messages').add({
            'text': text.isEmpty ? null : text,
            'senderId': currentUserId,
            'senderName': userName,
            'imageUrl': imageUrl,
            'timestamp': FieldValue.serverTimestamp(),
          });
          _textEditingController.clear();
        } catch (e) {
          print('Error sending message: $e');
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error'),
                content:
                    const Text('Failed to send message. Please try again.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      }
    } else {
      print('User document does not exist');
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final String formattedTime = DateFormat('hh:mm a').format(dateTime);
    return formattedTime;
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
      backgroundColor: Colors.black,
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
