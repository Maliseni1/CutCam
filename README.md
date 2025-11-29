# ✂️ CutCam - AI Haircut Assistant

**CutCam** is a smart, offline Flutter application that helps users perform DIY haircuts using real-time AI object detection. It features voice guidance, a persistent database for custom styles, and an auto-update system.

## 🚀 Features

* **🧠 Offline AI:** Uses TensorFlow Lite (SSD MobileNet) to detect heads/faces in real-time without internet.
* **🗣️ Voice Guidance:** Text-to-Speech (TTS) reads instructions aloud for hands-free usage.
* **💾 Local Database:** Saves your custom hairstyles and steps permanently using SharedPreferences.
* **🌗 Dynamic Themes:** Full support for Light Mode, Dark Mode, and System Default.
* **🔄 Auto-Updater:** Checks this GitHub repository for new releases and lets users download updates directly within the app.
* **📏 AR Guides:** Visual overlay to help align the camera and ensure a symmetrical cut.

## 🛠️ Tech Stack

* **Framework:** Flutter (Dart)
* **AI/ML:** `tflite_flutter`, `image` (processing)
* **Camera:** `camera` package with aspect ratio calibration
* **Storage:** `shared_preferences` (JSON serialization)
* **Networking:** `http`, `package_info_plus`, `url_launcher` (for updates)

## 📂 Project Structure

```text
cutcam/
├── assets/             # AI Models and Icons
│   ├── nanodet.tflite  # SSD MobileNet Model
│   └── icon/           # App launcher icons
├── lib/
│   ├── main.dart          # Entry point & Splash Screen
│   ├── home_screen.dart   # Dashboard & Navigation
│   ├── camera_screen.dart # Real-time AI & Camera Logic
│   ├── hairstyles_screen.dart # Database CRUD UI
│   ├── settings_screen.dart   # Theme & Update UI
│   ├── theme_service.dart     # Theme State Management
│   └── update_service.dart    # GitHub API Update Logic
└── pubspec.yaml        # Dependencies