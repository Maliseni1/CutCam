// lib/hairstyles_screen.dart
import 'package:flutter/material.dart';

class Hairstyle {
  String name;
  String description;

  Hairstyle({required this.name, required this.description});
}

class HairstylesScreen extends StatefulWidget {
  const HairstylesScreen({super.key});

  @override
  State<HairstylesScreen> createState() => _HairstylesScreenState();
}

class _HairstylesScreenState extends State<HairstylesScreen> {
  final List<Hairstyle> _hairstyles = [];

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
                decoration: const InputDecoration(labelText: 'Hairstyle Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
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
                setState(() {
                  _hairstyles.add(Hairstyle(
                    name: nameController.text,
                    description: descriptionController.text,
                  ));
                });
                Navigator.pop(context);
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
          ? const Center(
              child: Text('No hairstyles added yet. Press the + button to add one.'),
            )
          : ListView.builder(
              itemCount: _hairstyles.length,
              itemBuilder: (context, index) {
                final hairstyle = _hairstyles[index];
                return ListTile(
                  title: Text(hairstyle.name),
                  subtitle: Text(hairstyle.description),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHairstyleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}