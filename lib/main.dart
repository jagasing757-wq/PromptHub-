import 'package:flutter/material.dart';

void main() {
  runApp(const PromptHubApp());
}

class PromptHubApp extends StatelessWidget {
  const PromptHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PromptHub',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PromptHub'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'Welcome to PromptHub!',
            style: TextStyle(fontSize: 22),
          ),
        ),
      ),
    );
  }
}
