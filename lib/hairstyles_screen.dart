import 'dart:convert'; // Needed to convert data to text
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // The database package

// 1. Update the Data Class to support saving/loading
class Hairstyle {
  String name;
  String description;

  Hairstyle({required this.name, required this.description});

  // Convert a Hairstyle object into a Map (for saving)
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
      };

  // Create a Hairstyle object from a Map (for loading)
  factory Hairstyle.fromJson(Map<String, dynamic> json) {
    return Hairstyle(
      name: json['name'],
      description: json['description'],
    );
  }
}

class HairstylesScreen extends StatefulWidget {
  const HairstylesScreen({super.key});

  @override
  State<HairstylesScreen> createState() => _HairstylesScreenState();
}

class _HairstylesScreenState extends State<HairstylesScreen> {
  List<Hairstyle> _hairstyles = [];

  @override
  void initState() {
    super.initState();
    _loadHairstyles(); // Load data when the screen starts
  }

  // --- DATABASE LOGIC ---

  // Load saved styles from phone storage
  Future<void> _loadHairstyles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? stylesString = prefs.getString('saved_hairstyles');

    if (stylesString != null) {
      // Decode the text back into a list of Hairstyle objects
      final List<dynamic> decodedList = jsonDecode(stylesString);
      setState(() {
        _hairstyles = decodedList.map((item) => Hairstyle.fromJson(item)).toList();
      });
    }
  }

  // Save current list to phone storage
  Future<void> _saveHairstyles() async {
    final prefs = await SharedPreferences.getInstance();
    // Convert the list of objects into a text string
    final String encodedList = jsonEncode(_hairstyles.map((e) => e.toJson()).toList());
    await prefs.setString('saved_hairstyles', encodedList);
  }

  // --- UI LOGIC ---

  void _addHairstyle(String name, String desc) {
    setState(() {
      _hairstyles.add(Hairstyle(name: name, description: desc));
    });
    _saveHairstyles(); // Save immediately after adding
  }

  void _deleteHairstyle(int index) {
    setState(() {
      _hairstyles.removeAt(index);
    });
    _saveHairstyles(); // Save immediately after deleting
  }

  void _showAddHairstyleDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Hairstyle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Hairstyle Name (e.g. Fade)'),
                textCapitalization: TextCapitalization.sentences,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Steps/Notes'),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _addHairstyle(nameController.text, descriptionController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Hairstyles'),
      ),
      body: _hairstyles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.content_cut, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hairstyles saved yet.\nTap + to add your first one!', 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _hairstyles.length,
              itemBuilder: (context, index) {
                final hairstyle = _hairstyles[index];
                return Dismissible(
                  key: Key(hairstyle.name + index.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _deleteHairstyle(index);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${hairstyle.name} deleted')),
                    );
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Text(hairstyle.name.isNotEmpty ? hairstyle.name[0].toUpperCase() : '?'),
                    ),
                    title: Text(hairstyle.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(hairstyle.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      // Future feature: Load this style into the camera view
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHairstyleDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}