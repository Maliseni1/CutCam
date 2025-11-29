import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Hairstyle {
  String name;
  String description;

  Hairstyle({required this.name, required this.description});

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
      };

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
    _loadHairstyles();
  }

  // --- DATABASE LOGIC ---
  Future<void> _loadHairstyles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? stylesString = prefs.getString('saved_hairstyles');

    if (stylesString != null) {
      final List<dynamic> decodedList = jsonDecode(stylesString);
      setState(() {
        _hairstyles = decodedList.map((item) => Hairstyle.fromJson(item)).toList();
      });
    } else {
      // FIRST RUN: Simple English Sample
      setState(() {
        _hairstyles = [
          Hairstyle(
            name: "Simple Cut (Example)", 
            description: "1. Put on the #2 clip. Cut sides and back.\n2. Put on the #4 clip. Cut the top.\n3. Use #3 clip to blend them.\n4. Clean the neck area."
          )
        ];
      });
      _saveHairstyles(); 
    }
  }

  Future<void> _saveHairstyles() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = jsonEncode(_hairstyles.map((e) => e.toJson()).toList());
    await prefs.setString('saved_hairstyles', encodedList);
  }

  // --- ACTIONS ---
  void _addHairstyle(String name, String desc) {
    setState(() {
      _hairstyles.add(Hairstyle(name: name, description: desc));
    });
    _saveHairstyles();
  }

  void _editHairstyle(int index, String name, String desc) {
    setState(() {
      _hairstyles[index] = Hairstyle(name: name, description: desc);
    });
    _saveHairstyles();
  }

  void _deleteHairstyle(int index) {
    setState(() {
      _hairstyles.removeAt(index);
    });
    _saveHairstyles();
  }

  // --- DIALOGS ---
  void _showHairstyleDialog({Hairstyle? existingStyle, int? index}) {
    final isEditing = existingStyle != null;
    final nameController = TextEditingController(text: isEditing ? existingStyle.name : '');
    final descriptionController = TextEditingController(text: isEditing ? existingStyle.description : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Hairstyle' : 'Add New Hairstyle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name (e.g. Regular Cut)'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Steps',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  hintText: '1. Use clip #2...\n2. Use clip #4...',
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  if (isEditing) {
                    _editHairstyle(index!, nameController.text, descriptionController.text);
                  } else {
                    _addHairstyle(nameController.text, descriptionController.text);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Save' : 'Add', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete?'),
          content: Text('Delete "${_hairstyles[index].name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteHairstyle(index);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // DYNAMIC THEME COLORS
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Hairstyles'),
        // No hardcoded colors here; let main.dart theme handle it
      ),
      // No hardcoded background color; let main.dart theme handle it
      body: _hairstyles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.content_cut, size: 60, color: Colors.grey[500]),
                  const SizedBox(height: 16),
                  Text(
                    'No styles yet.\nTap + to add one!', 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _hairstyles.length,
              itemBuilder: (context, index) {
                final hairstyle = _hairstyles[index];
                return Card(
                  color: cardColor, // Dynamic color
                  elevation: 2, // Slight shadow for depth in light mode
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Text(
                        hairstyle.name.isNotEmpty ? hairstyle.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      hairstyle.name,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      hairstyle.description,
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: subTextColor),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () => _showHairstyleDialog(existingStyle: hairstyle, index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _showDeleteConfirmation(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHairstyleDialog(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}