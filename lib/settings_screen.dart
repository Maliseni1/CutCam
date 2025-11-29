import 'package:flutter/material.dart';
import 'theme_service.dart';
import 'update_service.dart'; // Import the new service

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Function to handle the update check UI
  Future<void> _handleUpdateCheck(BuildContext context) async {
    // 1. Show Loading Indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    // 2. Perform Check
    final result = await UpdateService.checkVersion();

    // 3. Close Loading Indicator
    if (context.mounted) Navigator.pop(context);

    // 4. Show Result Dialog
    if (context.mounted) {
      if (result == null) {
        _showDialog(context, "Error", "Could not check for updates.\nCheck your internet connection.");
      } else if (result['updateAvailable']) {
        _showUpdateDialog(context, result['latestVersion'], result['url']);
      } else {
        _showDialog(context, "Up to Date", "You are using the latest version (${result['currentVersion']}).");
      }
    }
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: Colors.orange)),
          )
        ],
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, String version, String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Update Available!"),
        content: Text("Version $version is available on GitHub."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Later", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(ctx);
              UpdateService.launchUpdateUrl(url);
            },
            child: const Text("Download", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: themeService,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Appearance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                value: ThemeMode.system,
                groupValue: themeService.themeMode,
                activeColor: Colors.orange,
                onChanged: (val) => themeService.updateTheme(val!),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light Mode'),
                value: ThemeMode.light,
                groupValue: themeService.themeMode,
                activeColor: Colors.orange,
                onChanged: (val) => themeService.updateTheme(val!),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark Mode'),
                value: ThemeMode.dark,
                groupValue: themeService.themeMode,
                activeColor: Colors.orange,
                onChanged: (val) => themeService.updateTheme(val!),
              ),
              const Divider(),
              
              // NEW: Updates Section
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'About & Updates',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.update),
                title: const Text('Check for Updates'),
                subtitle: const Text('Check GitHub for new versions'),
                onTap: () => _handleUpdateCheck(context),
              ),
              
              const Spacer(),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'CutCam v1.0.0\n© 2025 Chiza Labs',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}