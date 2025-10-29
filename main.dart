// main.dart
// PromptHub - Prompt Collection App (Flutter)
// Simple UI: shows image preview + prompt text + copy button
// Admin mode: add / delete prompts locally (stored with shared_preferences)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // for Clipboard

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class PromptItem {
  String prompt;
  String imageUrl; // can be empty
  bool favorite;

  PromptItem({required this.prompt, this.imageUrl = '', this.favorite = false});

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        'imageUrl': imageUrl,
        'favorite': favorite,
      };

  factory PromptItem.fromJson(Map<String, dynamic> json) => PromptItem(
        prompt: json['prompt'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        favorite: json['favorite'] ?? false,
      );
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;
  const MyApp({Key? key, required this.prefs}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<PromptItem> prompts = [];
  bool adminMode = false;
  String search = '';

  static const String kStorageKey = 'prompt_items_v1';

  @override
  void initState() {
    super.initState();
    _loadPrompts();
  }

  void _loadPrompts() {
    final raw = widget.prefs.getString(kStorageKey);
    if (raw != null) {
      try {
        final List decoded = json.decode(raw);
        prompts = decoded.map((e) => PromptItem.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (e) {
        prompts = [];
      }
    } else {
      // initial sample data (you can remove these)
      prompts = [
        PromptItem(
            prompt:
                'A cinematic portrait of an old sailor, dramatic lighting, ultra-detailed, 85mm, film grain',
            imageUrl:
                'https://images.pexels.com/photos/428338/pexels-photo-428338.jpeg'),
        PromptItem(
            prompt:
                'Futuristic city skyline at sunset, flying cars, neon reflections, super wide composition',
            imageUrl:
                'https://images.pexels.com/photos/373912/pexels-photo-373912.jpeg')
      ];
      _savePrompts();
    }
    setState(() {});
  }

  void _savePrompts() {
    final raw = json.encode(prompts.map((p) => p.toJson()).toList());
    widget.prefs.setString(kStorageKey, raw);
  }

  void _addPrompt(PromptItem item) {
    prompts.insert(0, item);
    _savePrompts();
    setState(() {});
  }

  void _deletePrompt(int index) {
    prompts.removeAt(index);
    _savePrompts();
    setState(() {});
  }

  void _toggleFavorite(int index) {
    prompts[index].favorite = !prompts[index].favorite;
    _savePrompts();
    setState(() {});
  }

  List<PromptItem> get _filteredPrompts {
    if (search.trim().isEmpty) return prompts;
    final q = search.toLowerCase();
    return prompts.where((p) => p.prompt.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PromptHub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PromptHub'),
          actions: [
            IconButton(
              icon: Icon(adminMode ? Icons.lock_open : Icons.lock_outline),
              onPressed: () {
                setState(() => adminMode = !adminMode);
              },
              tooltip: adminMode ? 'Exit Admin' : 'Enter Admin',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search prompts...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (v) => setState(() => search = v),
              ),
            ),
          ),
        ),
        body: _buildBody(),
        floatingActionButton: adminMode
            ? FloatingActionButton(
                tooltip: 'Add Prompt',
                child: const Icon(Icons.add),
                onPressed: () => _showAddDialog(context),
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    final list = _filteredPrompts;
    if (list.isEmpty) {
      return const Center(child: Text('No prompts found. Add some from Admin mode.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final item = list[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.imageUrl.trim().isNotEmpty)
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                SelectableText(item.prompt),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Prompt'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: item.prompt));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prompt copied')));
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(item.favorite ? Icons.favorite : Icons.favorite_border),
                      onPressed: () => _toggleFavorite(prompts.indexOf(item)),
                      tooltip: 'Favorite',
                    ),
                    const Spacer(),
                    if (adminMode)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          final globalIndex = prompts.indexOf(item);
                          _confirmDelete(context, globalIndex);
                        },
                        tooltip: 'Delete',
                      )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, int globalIndex) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete prompt?'),
        content: const Text('Are you sure you want to delete this prompt?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) _deletePrompt(globalIndex);
  }

  void _showAddDialog(BuildContext context) {
    final promptCtrl = TextEditingController();
    final imageCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add Prompt'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: promptCtrl,
                decoration: const InputDecoration(hintText: 'Enter prompt text'),
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: imageCtrl,
                decoration: const InputDecoration(hintText: 'Optional image URL'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final p = promptCtrl.text.trim();
              if (p.isEmpty) return; // don't add empty
              final item = PromptItem(prompt: p, imageUrl: imageCtrl.text.trim());
              _addPrompt(item);
              Navigator.pop(c);
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }
}

/*
README (instructions):

1) pubspec.yaml (add these deps):

name: prompthub
description: A simple PromptHub app (Android + Web)

environment:
  sdk: '>=2.17.0 <3.0.0'

dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.0.15

# Then run:
# flutter pub get

2) Run for Android:
# Connect an Android device or emulator
# flutter run -d android

3) Run for Web:
# flutter run -d chrome

4) How the app works (quick):
- Open the app. You'll see a list of prompts (sample ones included).
- Use the search bar to filter prompts.
- Tap "Copy Prompt" to copy text to clipboard.
- Tap the heart icon to favorite (stored locally).
- To add your own prompts, tap the lock icon in the app bar to toggle Admin mode, then use the + FAB to add prompt text and an optional image URL.
- Prompts persist locally using shared_preferences.

5) Next improvements you can ask me for:
- Admin with password
- Syncing prompts to Firebase (so you can update prompts from web and mobile centrally)
- CSV import/export
- Categorization and tags
- Better image handling (upload images instead of URLs)
- A small web admin panel (React) to manage prompts remotely

*/
