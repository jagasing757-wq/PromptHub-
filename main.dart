// main.dart
// PromptHub - Online (uses Firebase Firestore for prompts)
//
// NOTE: To run this app you must configure Firebase and add the
// google-services.json (Android) or GoogleService-Info.plist (iOS).
//
// This app lists prompts from Firestore collection "prompts".
// Each document fields: prompt (string), imageUrl (string), createdAt (timestamp)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PromptHubApp());
}

class PromptHubApp extends StatelessWidget {
  const PromptHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PromptHub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PromptListPage(),
    );
  }
}

class PromptListPage extends StatefulWidget {
  const PromptListPage({super.key});

  @override
  State<PromptListPage> createState() => _PromptListPageState();
}

class _PromptListPageState extends State<PromptListPage> {
  bool adminMode = false;
  String search = '';

  CollectionReference promptsRef = FirebaseFirestore.instance.collection('prompts');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PromptHub'),
        actions: [
          IconButton(
            icon: Icon(adminMode ? Icons.lock_open : Icons.lock_outline),
            onPressed: () => setState(() => adminMode = !adminMode),
            tooltip: adminMode ? 'Exit Admin' : 'Enter Admin',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search prompts...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => search = v),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: promptsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading prompts'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.where((d) => (d['prompt'] as String).toLowerCase().contains(search.toLowerCase())).toList();
          if (docs.isEmpty) return const Center(child: Text('No prompts found.'));
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index];
              final prompt = d['prompt'] as String? ?? '';
              final imageUrl = d['imageUrl'] as String? ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl.isNotEmpty)
                        SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s)=>Container(color: Colors.grey[200],child: const Center(child: Icon(Icons.broken_image)))),
                          ),
                        ),
                      const SizedBox(height: 8),
                      SelectableText(prompt),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy Prompt'),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: prompt));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prompt copied')));
                            },
                          ),
                          const Spacer(),
                          if (adminMode)
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await promptsRef.doc(d.id).delete();
                              },
                            )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: adminMode ? FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ) : null,
    );
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
              TextField(controller: promptCtrl, decoration: const InputDecoration(hintText: 'Enter prompt'), maxLines: 4),
              const SizedBox(height: 8),
              TextField(controller: imageCtrl, decoration: const InputDecoration(hintText: 'Optional image URL')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            final p = promptCtrl.text.trim();
            if (p.isEmpty) return;
            await promptsRef.add({
              'prompt': p,
              'imageUrl': imageCtrl.text.trim(),
              'createdAt': FieldValue.serverTimestamp(),
            });
            Navigator.pop(c);
          }, child: const Text('Add'))
        ],
      ),
    );
  }
}
