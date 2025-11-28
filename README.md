# ✂️ CutCam - AI Haircut Assistant

**CutCam** is a Flutter application designed to assist with DIY haircuts using real-time, offline Artificial Intelligence. The app uses the device's camera to detect the user's head position and provides step-by-step guard recommendations for a perfect haircut.

## 🚀 Features

* **Real-Time AI Detection:** Uses TensorFlow Lite to detect heads/faces in the live camera feed with visual bounding boxes.
* **100% Offline:** All processing happens on the device. No internet connection is required, ensuring privacy and speed.
* **Performance Optimized:** Includes image throttling and resolution scaling to ensure smooth performance on mid-range Android devices (e.g., Infinix).
* **Interactive Guide:** Displays current haircut steps (e.g., "Use #2 Guard") overlaying the camera view.
* **Hairstyle Management:** Dedicated UI for users to add and manage custom hairstyle presets.
* **Custom Splash Screen:** Professional loading experience on startup.

## 🛠️ Tech Stack

* **Framework:** Flutter (Dart)
* **AI Engine:** TensorFlow Lite (`tflite_flutter`)
* **Model:** SSD MobileNet V1 (Quantized)
* **Camera:** `camera` package (Custom resolution handling)
* **Image Processing:** `image` package for raw byte conversion

## 📂 Project Structure

cutcam/ ├── android/ # Android native configuration ├── assets/ # AI Models and Icons │ ├── icon/ # App launcher icons │ ├── nanodet.tflite # The AI Model file │ └── labels.txt # Model labels ├── lib/ │ ├── main.dart # Core logic (Camera, AI, UI overlay) │ └── hairstyles_screen.dart # Hairstyle management UI └── pubspec.yaml # Dependencies


## ⚡ How to Run

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/Maliseni1/CutCam.git](https://github.com/Maliseni1/CutCam.git)
    cd cutcam
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run on device:**
    Connect your Android device and run:
    ```bash
    flutter run
    ```

## 🔮 Future Roadmap

* [ ] Local Database integration (SQLite/Hive) to save hairstyles permanently.
* [ ] Voice commands for hands-free step navigation.
* [ ] Augmented Reality (AR) overlay to visualize the cut line.

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

---
*Built with ❤️ in Flutter.*