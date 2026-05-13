import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:share_plus/share_plus.dart';
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
      home: const HomeScreen(),
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
    await _player.play(AssetSource(file));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DRIP", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00D4FF))),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset('assets/drip_logo.png', height: 120),
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

            _imageButton('assets/instant_alerts.png', () {
              playSound('alerts.mp3');
              Navigator.push(context, MaterialPageRoute(builder: (_) => const InstantSavingsScreen()));
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

  // Smaller buttons as requested
  Widget _imageButton(String asset, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(asset, fit: BoxFit.cover, height: 80, width: double.infinity),
        ),
      ),
    );
  }
}

// ====================== CATEGORY SCREEN (Coffee / Party / Smoothie) ======================
class CategoryScreen extends StatefulWidget {
  final String title;
  final Color color;
  const CategoryScreen({super.key, required this.title, required this.color});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _searchController = TextEditingController();
  String selectedRadius = "5 miles";
  LatLng? userLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: widget.color),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Search deals or speak address...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.mic, color: Color(0xFF00D4FF)),
                  onPressed: () async {
                    bool available = await _speech.initialize();
                    if (available) {
                      _speech.listen(onResult: (result) {
                        _searchController.text = result.recognizedWords;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // Mile Radius - 1, 5, 10 only
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ["1 mile", "5 miles", "10 miles"].map((radius) {
                return ChoiceChip(
                  label: Text(radius),
                  selected: selectedRadius == radius,
                  onSelected: (_) => setState(() => selectedRadius = radius),
                  selectedColor: widget.color,
                );
              }).toList(),
            ),
          ),

          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) => const ListTile(
                title: Text("Live Special Near You"),
                subtitle: Text("0.8 mi • Open now"),
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: userLocation ?? const LatLng(29.7604, -95.3698),
                zoom: 14,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== INSTANT SAVINGS (Unlocked for Testing) ======================
class InstantSavingsScreen extends StatefulWidget {
  const InstantSavingsScreen({super.key});
  @override
  State<InstantSavingsScreen> createState() => _InstantSavingsScreenState();
}

class _InstantSavingsScreenState extends State<InstantSavingsScreen> {
  final List<Map<String, String>> activeAlerts = [];

  void addAlert(String term) {
    setState(() {
      activeAlerts.add({"term": term, "radius": "5 miles"});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Instant Savings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Your Active Alerts", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: activeAlerts.length,
                itemBuilder: (context, index) {
                  final alert = activeAlerts[index];
                  return ListTile(
                    title: Text(alert["term"]!),
                    subtitle: Text("${alert["radius"]} radius"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => activeAlerts.removeAt(index)),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () => addAlert("Coffee Specials"),
              child: const Text("Add Test Alert (Coffee)"),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== SELFIE "DROP THE DRIP" ======================
class SelfieFilterScreen extends StatelessWidget {
  const SelfieFilterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Drop the DRIP")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/selfie_share.jpg', fit: BoxFit.cover),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Share.share("Saved again by my DRIP app! 🎉");
              },
              child: const Text("Share Selfie"),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== FAMILY MODE ======================
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
            const SizedBox(height: 15),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text("Share My Alerts"),
              onPressed: () {},
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
            ),
          ],
        ),
      ),
    );
  }
}