import 'package:flutter/material.dart';

class SavedMessagesScreen extends StatefulWidget {
  const SavedMessagesScreen({super.key});

  @override
  State<SavedMessagesScreen> createState() => _SavedMessagesScreenState();
}

class _SavedMessagesScreenState extends State<SavedMessagesScreen> {
  final List<String> _savedNotes = [];
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addNote() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _savedNotes.insert(0, text);
        _textController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Messages & Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _savedNotes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'Your Saved Messages Vault',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Save messages, links, and personal notes here for quick access.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _savedNotes.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.bookmark, color: Colors.blueAccent),
                          title: Text(_savedNotes[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _savedNotes.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Colors.grey.withAlpha(50))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Save a note or message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _addNote(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: _addNote,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
