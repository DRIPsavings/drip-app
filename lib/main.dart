import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

void main() => runApp(const DripApp());

class DripApp extends StatelessWidget {
  const DripApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DRIP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF00D4FF),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: MaterialStateProperty.all(const Color(0xFF00D4FF)),
          thickness: MaterialStateProperty.all(10),
          radius: const Radius.circular(10),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ====================== SPLASH SCREEN ======================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AudioPlayer _greetingPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () async {
      final prefs = await SharedPreferences.getInstance();
      final bool isFirstLaunch = prefs.getBool('first_launch') ?? true;
      final String? savedVoice = prefs.getString('greeting_voice');

      if (isFirstLaunch) {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GreetingSelectionScreen()));
        }
      } else if (savedVoice != null) {
        // Start greeting 1 second after splash opens
        await Future.delayed(const Duration(seconds: 1));
        try {
          await _greetingPlayer.play(AssetSource('greetings/$savedVoice'));
        } catch (e) {
          debugPrint('Greeting playback error: $e');
        }
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      } else {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      }
    });
  }

  @override
  void dispose() {
    // Do NOT dispose the player here — we want greeting to continue on HomeScreen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1F3A), Color(0xFF1E3A5F)],
          ),
        ),
        child: Center(
          child: Image.asset('assets/splash.png', fit: BoxFit.contain, width: MediaQuery.of(context).size.width * 0.85),
        ),
      ),
    );
  }
}

// ====================== GREETING SELECTION SCREEN ======================
class GreetingSelectionScreen extends StatefulWidget {
  const GreetingSelectionScreen({super.key});
  @override State<GreetingSelectionScreen> createState() => _GreetingSelectionScreenState();
}

class _GreetingSelectionScreenState extends State<GreetingSelectionScreen> {
  final AudioPlayer _player = AudioPlayer();
  String? selectedVoice;

  final List<Map<String, String>> voices = [
    {"name": "Female Voice 1", "file": "female1.mp3"},
    {"name": "Female Voice 2", "file": "female2.mp3"},
    {"name": "Female Voice 3", "file": "female3.mp3"},
    {"name": "Female Voice 4", "file": "female4.mp3"},
    {"name": "Female Voice 5", "file": "female5.mp3"},
    {"name": "Male Voice 1", "file": "male1.mp3"},
    {"name": "Male Voice 2", "file": "male2.mp3"},
    {"name": "Male Voice 3", "file": "male3.mp3"},
    {"name": "Male Voice 4", "file": "male4.mp3"},
    {"name": "Male Voice 5", "file": "male5.mp3"},
  ];

  Future<void> playPreview(String file) async {
    await _player.stop();
    await _player.play(AssetSource('greetings/$file'));
  }

  Future<void> selectVoice(String file) async {
    setState(() => selectedVoice = file);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('greeting_voice', file);
    await prefs.setBool('first_launch', false);

    await _player.stop();
    await Future.delayed(const Duration(milliseconds: 300));
    await _player.play(AssetSource('greetings/$file'));

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(title: const Text("Select Your Personal Greeting Voice")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Choose how DRIP greets you every time",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: voices.length,
                itemBuilder: (context, index) {
                  final voice = voices[index];
                  return Card(
                    color: const Color(0xFF1A1A1A),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(voice["name"]!),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_circle, color: Color(0xFF00D4FF), size: 32),
                            onPressed: () => playPreview(voice["file"]!),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => selectVoice(voice["file"]!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00D4FF),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text("Select", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

// ====================== HOME SCREEN ======================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playSound(String file) async {
    await _player.stop(); // Stop any previous sound (including greeting if wanted)
    await _player.play(AssetSource(file));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DRIP", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00D4FF))),
        centerTitle: true,
      ),
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _imageButton('assets/smoothie_button.png', () => _goToCategory("Groovy Smoothie", Colors.green), 88)),
                  const SizedBox(width: 12),
                  Expanded(child: _imageButton('assets/coffee_button.png', () => _goToCategory("Iced Coffee's My Jam!", Colors.brown), 88)),
                ],
              ),
              const SizedBox(height: 16),
              _imageButton('assets/party_button.png', () => _goToCategory("Get The Party Started", Colors.purple), 88),
              const SizedBox(height: 25),
              _imageButton('assets/instant_alerts.png', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InstantSavingsScreen())), 120),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  _imageButton('assets/selfie_share.jpg', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SelfieFilterScreen())), 120),
                  const Positioned(
                    top: 20,
                    child: Text("Share this moment with a selfie!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _imageButton('assets/family_mode_button.png', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyModeScreen())), 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageButton(String asset, VoidCallback onTap, double height) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(asset, fit: BoxFit.contain, height: height, width: double.infinity),
      ),
    );
  }

  void _goToCategory(String title, Color color) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryScreen(title: title, color: color)));
  }
}

// ====================== PLACEHOLDER SCREENS ======================
class CategoryScreen extends StatelessWidget {
  final String title;
  final Color color;
  const CategoryScreen({super.key, required this.title, required this.color});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title), backgroundColor: color), body: const Center(child: Text("Category Screen")));
}

class InstantSavingsScreen extends StatelessWidget {
  const InstantSavingsScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Instant Alerts")), body: const Center(child: Text("Instant Alerts Page")));
}

class SelfieFilterScreen extends StatelessWidget {
  const SelfieFilterScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Selfie Share")), body: const Center(child: Text("Selfie Screen")));
}

class FamilyModeScreen extends StatelessWidget {
  const FamilyModeScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Family Mode")), body: const Center(child: Text("Family Mode Screen")));
}