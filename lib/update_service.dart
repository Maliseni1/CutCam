import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  // Your GitHub Repo Details
  static const String owner = "Maliseni1";
  static const String repo = "CutCam";

  // Returns true if an update is available, false otherwise
  // Returns null if there was an error checking
  static Future<Map<String, dynamic>?> checkVersion() async {
    try {
      // 1. Get Current Installed Version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // 2. Get Latest Version from GitHub API
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String latestTag = data['tag_name']; // e.g., "v1.0.1"
        String downloadUrl = data['html_url']; // Link to the release page

        // 3. Compare Versions
        // Remove 'v' prefix if it exists (e.g., v1.0.0 -> 1.0.0)
        String cleanLatest = latestTag.replaceAll('v', '');
        
        if (_isNewer(cleanLatest, currentVersion)) {
          return {
            'updateAvailable': true,
            'latestVersion': cleanLatest,
            'url': downloadUrl,
            'currentVersion': currentVersion
          };
        } else {
          return {
            'updateAvailable': false,
            'latestVersion': cleanLatest,
            'currentVersion': currentVersion
          };
        }
      } else {
        // If no releases found yet (404), just assume up to date
        return null;
      }
    } catch (e) {
      print("Error checking updates: $e");
      return null;
    }
  }

  static Future<void> launchUpdateUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  // Simple version comparison logic
  static bool _isNewer(String latest, String current) {
    List<int> l = latest.split('.').map((e) => int.parse(e)).toList();
    List<int> c = current.split('.').map((e) => int.parse(e)).toList();

    for (int i = 0; i < 3; i++) {
      int latestPart = i < l.length ? l[i] : 0;
      int currentPart = i < c.length ? c[i] : 0;
      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }
    return false;
  }
}