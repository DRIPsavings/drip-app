import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'widgets/drip_tip_popup.dart';

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
      home: const SplashScreen(),
    );
  }
}

// ==================== SPLASH SCREEN ====================
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
        title: Image.asset('assets/drip_logo.png', height: 55),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb),
            onPressed: () => showDialog(context: context, builder: (_) => const DripTipPopup()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBigButton('party_button.png', 'party.mp3', const CategoryScreen("Party")),
          const SizedBox(height: 12),
          _buildBigButton('coffee_button.png', 'coffee.mp3', const CategoryScreen("Coffee")),
          const SizedBox(height: 12),
          _buildBigButton('smoothie_button.png', 'smoothie.mp3', const CategoryScreen("Smoothies")),
          const SizedBox(height: 30),

          _buildBigButton('instant_alerts.png', 'alerts.mp3', const InstantAlertsUpgradeScreen()),
          const SizedBox(height: 30),

          _buildBigButton('family_mode_button.png', null, const FamilyModeScreen()),
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
        child: Image.asset('assets/$imageName', width: double.infinity, height: 130, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildSelfieButton() {
    return GestureDetector(
      onTap: () {
        playSound('selfie.mp3');
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SelfieFilterScreen()));
      },
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Image.asset('assets/selfie_share.jpg', width: 220, height: 220, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          const Text("Drop the Drip", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const Text("Share this moment", style: TextStyle(color: Colors.grey, fontSize: 17, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

// ==================== CATEGORY SCREEN (Fixed) ====================
class CategoryScreen extends StatelessWidget {
  final String category;
  const CategoryScreen(this.category, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$category Specials Near You")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Text(
              "Live $category Deals Near You",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(target: LatLng(29.7604, -95.3698), zoom: 13),
              markers: {
                const Marker(
                  markerId: MarkerId('1'),
                  position: LatLng(29.7604, -95.3698),
                  infoWindow: InfoWindow(title: 'Happy Hour', snippet: '\$2 Wells 4-7pm'),
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== INSTANT ALERTS UPGRADE ====================
class InstantAlertsUpgradeScreen extends StatelessWidget {
  const InstantAlertsUpgradeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Instant Alerts")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Premium Instant Alerts", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Only \$12 / year • Cancel anytime", style: TextStyle(fontSize: 24, color: Colors.greenAccent)),
            const SizedBox(height: 30),
            const Text("What you'll get:", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 15),
            _benefitRow("Real-time push alerts for coffee, smoothies & happy hour"),
            _benefitRow("Personalized savings on anything you want"),
            _benefitRow("One-tap DoorDash & Uber Eats ordering"),
            _benefitRow("Family/Group sharing mode"),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20)),
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const InstantSavingsScreen()));
              },
              child: const Text("Upgrade Now — \$12/year", style: TextStyle(fontSize: 20, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [const Icon(Icons.check_circle, color: Colors.greenAccent), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(fontSize: 17)))]),
    );
  }
}

// Placeholder screens
class InstantSavingsScreen extends StatelessWidget {
  const InstantSavingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("My Instant Savings")),
        body: const Center(child: Text("Full Instant Savings Dashboard\n(Coming Soon)")),
      );
}

class FamilyModeScreen extends StatelessWidget {
  const FamilyModeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Family Mode")),
        body: const Center(child: Text("Share deals with family & friends")),
      );
}

class SelfieFilterScreen extends StatelessWidget {
  const SelfieFilterScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Drop the Drip")),
        body: const Center(child: Text("Selfie Filter & Share Screen\n(Coming Soon)")),
      );
}