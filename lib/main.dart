import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  final themeService = ThemeService();
  await themeService.loadTheme(); // Load saved preference before app starts

  runApp(MyApp(themeService: themeService));
}

class MyApp extends StatelessWidget {
  final ThemeService themeService;
  const MyApp({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          // Define Light Theme
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: Colors.orange,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white, 
              foregroundColor: Colors.black,
              elevation: 0
            ),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange, brightness: Brightness.light),
          ),
          // Define Dark Theme
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.orange,
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black, 
              foregroundColor: Colors.white
            ),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange, brightness: Brightness.dark),
          ),
          themeMode: themeService.themeMode, // This switches the modes
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Splash is always black for style
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icon/app_icon.png',
                  width: 150,
                  height: 150,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.content_cut, size: 100, color: Colors.orange);
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'CutCam',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 10),
                const Text('Easy Haircuts at Home.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                const CircularProgressIndicator(color: Colors.orange),
              ],
            ),
          ),
          const Positioned(
            bottom: 40, left: 0, right: 0,
            child: Center(
              child: Text(
                'Powered by Chiza Labs',
                style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}