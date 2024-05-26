import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(
    id: '0',
    firstName: 'User',
  );

  ChatUser geminiUser = ChatUser(
    id: '1',
    firstName: 'Gemini',
    profileImage:
        'https://pbs.twimg.com/profile_images/1737157574514950144/P2XFF9x4_400x400.jpg',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Minimal Gemini Chat',
          style: TextStyle(
            color: Theme.of(context).colorScheme.background,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.onBackground,
      ),
      backgroundColor:
          Theme.of(context).colorScheme.background.withOpacity(0.9),
      body: DashChat(
        inputOptions: InputOptions(
          trailing: [
            IconButton(
              onPressed: sendMediaMessage,
              icon: Icon(
                Icons.image,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            IconButton(
              onPressed: sendPhotoMediaMessage,
              icon: Icon(
                Icons.camera,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            )
          ],
        ),
        currentUser: currentUser,
        onSend: sendMessage,
        messages: messages,
      ),
    );
  }

  void sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });

    try {
      String question = chatMessage.text;

      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [
          File(chatMessage.medias!.first.url).readAsBytesSync(),
        ];
      }

      gemini.streamGenerateContent(question, images: images).listen(
        (event) {
          ChatMessage? chatMessage = messages.firstOrNull;

          if (chatMessage != null && chatMessage.user == geminiUser) {
            ChatMessage? lastMessage = messages.removeAt(0);

            String response = event.content?.parts?.fold(
                  "",
                  (previousValue, currentValue) =>
                      '$previousValue ${currentValue.text}',
                ) ??
                "";

            lastMessage.text += response;

            setState(() {
              messages = [lastMessage, ...messages];
            });
          } else {
            String response = event.content?.parts?.fold(
                  "",
                  (previousValue, currentValue) =>
                      '$previousValue ${currentValue.text}',
                ) ??
                "";

            ChatMessage chatMessage = ChatMessage(
              user: geminiUser,
              createdAt: DateTime.now(),
              text: response,
            );

            setState(() {
              messages = [chatMessage, ...messages];
            });
          }
        },
      );
    } catch (err) {
      log(err.toString());
    }
  }

  void sendMediaMessage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? file = await imagePicker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: 'Describe this image',
        medias: [
          ChatMedia(
            url: file.path,
            fileName: "",
            type: MediaType.image,
          )
        ],
      );

      sendMessage(chatMessage);
    }
  }

  void sendPhotoMediaMessage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? file = await imagePicker.pickImage(source: ImageSource.camera);

    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: 'Describe this image',
        medias: [
          ChatMedia(
            url: file.path,
            fileName: "fileName",
            type: MediaType.image,
          ),
        ],
      );

      sendMessage(chatMessage);
    }
  }
}
