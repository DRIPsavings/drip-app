import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'widgets/drip_tip_popup.dart';
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
        primaryColor: const Color(0xFF00D4FF),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      ),
      home: const SplashScreen(),   // Your timed intro
    );
  }
}

// ==================== TIMED SPLASH SCREEN ====================
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
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/drip_logo.png', height: 180),
            const SizedBox(height: 24),
            const Text("Real Drink Deals Near You", style: TextStyle(fontSize: 22, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

// ====================== HOME SCREEN ======================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playSound(String file) async {
    try {
      await _player.play(AssetSource('assets/$file'));
    } catch (e) {
      debugPrint("Audio error: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/drip_logo.png', height: 45),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb),
            onPressed: () => showDialog(context: context, builder: (_) => const DripTipPopup()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset('assets/drip_logo.png', height: 140),
            const SizedBox(height: 30),

            _imageButton('assets/party_button.png', () {
              playSound('party.mp3');
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen(title: "Get The Party Started", color: Colors.purple)));
            }),
            _imageButton('assets/coffee_button.png', () {
              playSound('coffee.mp3');
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen(title: "Coffee's My CRACK!", color: Colors.brown)));
            }),
            _imageButton('assets/smoothie_button.png', () {
              playSound('smoothie.mp3');
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen(title: "Groovy Smoothie", color: Colors.green)));
            }),

            const SizedBox(height: 20),
            _imageButton('assets/instant_alerts.png', () {
              playSound('alerts.mp3');
              Navigator.push(context, MaterialPageRoute(builder: (_) => const InstantAlertsUpgradeScreen()));
            }),

            _imageButton('assets/selfie_share.jpg', () {
              playSound('selfie.mp3');
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SelfieFilterScreen()));
            }),

            _imageButton('assets/family_mode_button.png', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyModeScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _imageButton(String asset, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(asset, fit: BoxFit.cover, height: 140, width: double.infinity),
        ),
      ),
    );
  }
}

// ====================== CATEGORY SCREEN ======================
class CategoryScreen extends StatelessWidget {
  final String title;
  final Color color;
  const CategoryScreen({super.key, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: color),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(target: LatLng(29.7604, -95.3698), zoom: 14),
        markers: {
          const Marker(
            markerId: MarkerId('1'),
            position: LatLng(29.7604, -95.3698),
            infoWindow: InfoWindow(title: 'Special Deal', snippet: 'Live right now near you'),
          ),
        },
      ),
    );
  }
}

// ====================== INSTANT ALERTS UPGRADE ======================
class InstantAlertsUpgradeScreen extends StatelessWidget {
  const InstantAlertsUpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Premium Instant Alerts")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Premium Instant Alerts", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const Text("Only \$12/year • Cancel anytime", style: TextStyle(fontSize: 24, color: Colors.greenAccent)),
            const SizedBox(height: 30),
            const Text("What you get:", style: TextStyle(fontSize: 20)),
            _benefit("Real-time alerts for coffee, smoothies & happy hour"),
            _benefit("Personalized alerts on anything you want"),
            _benefit("One-tap DoorDash & Uber Eats ordering"),
            _benefit("Family/Group sharing mode"),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18)),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const InstantSavingsScreen())),
              child: const Text("Upgrade Now — \$12/year", style: TextStyle(fontSize: 20, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefit(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [const Icon(Icons.check_circle, color: Colors.greenAccent), const SizedBox(width: 12), Text(text, style: const TextStyle(fontSize: 17))]),
  );
}

// ====================== OTHER SCREENS ======================
class InstantSavingsScreen extends StatelessWidget {
  const InstantSavingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("My Instant Savings")),
        body: const Center(child: Text("Full Premium Instant Savings Screen\n(Alerts, Addresses, Maps, Delivery)")),
      );
}

class SelfieFilterScreen extends StatefulWidget {
  const SelfieFilterScreen({super.key});
  @override
  State<SelfieFilterScreen> createState() => _SelfieFilterScreenState();
}

class _SelfieFilterScreenState extends State<SelfieFilterScreen> {
  final List<String> vibes = ["ROCKSTAR", "VIP", "CHILLIN", "PARTY TIME", "BOSS MODE"];
  String currentVibe = "PARTY TIME";

  void changeVibe() {
    setState(() => currentVibe = vibes[Random().nextInt(vibes.length)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Drop the DRIP")),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset('assets/selfie_share.jpg', fit: BoxFit.cover),
          Text(currentVibe, style: const TextStyle(fontSize: 55, color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10)])),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: changeVibe, child: const Icon(Icons.refresh)),
    );
  }
}

class FamilyModeScreen extends StatelessWidget {
  const FamilyModeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("👨‍👩‍👧‍👦 Family / Group Mode")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Share deals with friends & family", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.group_add),
              label: const Text("Create New Group"),
              onPressed: () {},
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text("Add Members"),
              onPressed: () {},
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
            ),
          ],
        ),
      ),
    );
  }
}