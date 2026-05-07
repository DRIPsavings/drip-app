import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

void main() {
  runApp(const DripApp());
}

class DripApp extends StatelessWidget {
  const DripApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DRIP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF00A8E8),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      ),
      home: const HomeScreen(),
    );
  }
}

// ==================== HOME SCREEN ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playSound(String fileName) async {
    try {
      await _audioPlayer.play(AssetSource('assets/$fileName'));
    } catch (e) {
      debugPrint("Audio error: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/drip_logo.png', height: 55), // Updated
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBigButton(
              'party_button.png', 'party.mp3', const CategoryScreen("party")),
          const SizedBox(height: 12),
          _buildBigButton('coffee_button.png', 'coffee.mp3',
              const CategoryScreen("coffee")),
          const SizedBox(height: 12),
          _buildBigButton('smoothie_button.png', 'smoothie.mp3',
              const CategoryScreen("smoothie")),
          const SizedBox(height: 25),
          _buildBigButton('instant_alerts.png', 'alerts.mp3',
              const InstantAlertsUpgradeScreen()),
          const SizedBox(height: 30),
          _buildBigButton(
              'family_mode_button.png', null, const FamilyModeScreen()),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const InstantSavingsScreen())),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 18)),
            child: const Text("💰 Instant Savings",
                style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 40),
          _buildSelfieButton(),
        ],
      ),
    );
  }

  Widget _buildBigButton(String imageName, String? soundFile, Widget screen) {
    return GestureDetector(
      onTap: () {
        if (soundFile != null) playSound(soundFile);
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset('assets/$imageName',
            width: double.infinity, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildSelfieButton() {
    return GestureDetector(
      onTap: () {
        playSound('selfie.mp3');
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SelfieFilterScreen()));
      },
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Image.asset('assets/selfie_share.jpg',  // Still .jpg
                width: 220, height: 220, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          const Text("Drop the Drip",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const Text("Share this moment",
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 17,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}