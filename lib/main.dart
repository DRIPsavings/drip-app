import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: MaterialStateProperty.all(const Color(0xFF00D4FF)),
          thickness: MaterialStateProperty.all(10.0), // thicker blue scrollbar
          radius: const Radius.circular(10),
          minThumbLength: 60,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ====================== SPLASH SCREEN ======================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0A1F3A), Color(0xFF1E3A5F)]),
        ),
        child: Center(child: Image.asset('assets/splash.png', fit: BoxFit.contain, width: MediaQuery.of(context).size.width * 0.85)),
      ),
    );
  }
}

// ====================== HOME SCREEN (layout unchanged) ======================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playSound(String file) async {
    try { await _player.play(AssetSource(file)); } catch (e) { debugPrint("Audio error: $e"); }
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DRIP", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00D4FF), letterSpacing: 2)), centerTitle: true),
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _imageButton('assets/smoothie_button.png', () { playSound('smoothie.mp3'); Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen(title: "Groovy Smoothie", color: Colors.green))); }, height: 68)),
                  const SizedBox(width: 12),
                  Expanded(child: _imageButton('assets/coffee_button.png', () { playSound('coffee.mp3'); Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen(title: "Coffee's My CRACK!", color: Colors.brown))); }, height: 68)),
                ],
              ),
              const SizedBox(height: 16),
              _imageButton('assets/party_button.png', () { playSound('party.mp3'); Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen(title: "Get The Party Started", color: Colors.purple))); }, height: 68),
              const SizedBox(height: 30),
              _imageButton('assets/instant_alerts.png', () { playSound('alerts.mp3'); Navigator.push(context, MaterialPageRoute(builder: (_) => const InstantSavingsScreen())); }),
              _imageButton('assets/selfie_share.jpg', () { playSound('selfie.mp3'); Navigator.push(context, MaterialPageRoute(builder: (_) => const SelfieFilterScreen())); }),
              _imageButton('assets/family_mode_button.png', () { Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyModeScreen())); }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageButton(String asset, VoidCallback onTap, {double height = 88}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset(asset, fit: BoxFit.contain, height: height, width: double.infinity)),
      ),
    );
  }
}

// ====================== CATEGORY SCREEN - REAL GOOGLE PLACES DATA ======================
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
  bool isLoading = true;
  List<Map<String, dynamic>> _places = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _getCurrentLocationAndPlaces();
  }

  Future<void> _getCurrentLocationAndPlaces() async {
    setState(() => isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Location services disabled");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) throw Exception("Location permission denied forever");

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      userLocation = LatLng(position.latitude, position.longitude);

      await _fetchRealPlaces(userLocation!);
    } catch (e) {
      debugPrint("Location/Places error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchRealPlaces(LatLng location) async {
    const String apiKey = "AIzaSyAkxohJYbUCHykcKlfU9EYOOs7ErvOtLdQ"; // your key

    String keyword = "";
    List<String> includedTypes = [];

    final lowerTitle = widget.title.toLowerCase();
    if (lowerTitle.contains("coffee")) {
      includedTypes = ["cafe"];
      keyword = "coffee";
    } else if (lowerTitle.contains("smoothie")) {
      keyword = "smoothie";
    } else {
      includedTypes = ["bar", "night_club", "pub"];
      keyword = "happy hour";
    }

    final url = Uri.parse("https://places.googleapis.com/v1/places:searchNearby");

    final body = jsonEncode({
      "locationRestriction": {
        "circle": {
          "center": {"latitude": location.latitude, "longitude": location.longitude},
          "radius": (double.tryParse(selectedRadius.split(" ")[0]) ?? 5) * 1609.34 // miles to meters
        }
      },
      "includedTypes": includedTypes.isNotEmpty ? includedTypes : null,
      "maxResultCount": 20,
      "languageCode": "en",
    });

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask": "places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.id",
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['places'] ?? [];

      _places = results.map((p) {
        final loc = p['location'] ?? {};
        return {
          'id': p['id'] ?? '',
          'name': p['displayName']?['text'] ?? 'Unknown Place',
          'address': p['formattedAddress'] ?? 'No address available',
          'rating': p['rating']?.toString() ?? 'N/A',
          'position': LatLng(loc['latitude'] ?? 0.0, loc['longitude'] ?? 0.0),
        };
      }).toList();
    } else {
      debugPrint("Places API error: ${response.body}");
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredPlaces() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _places;

    return _places.where((p) {
      return p['name'].toLowerCase().contains(query) || p['address'].toLowerCase().contains(query);
    }).toList();
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const double earthRadiusMiles = 3958.8;
    final dLat = (p2.latitude - p1.latitude) * (3.1416 / 180);
    final dLon = (p2.longitude - p1.longitude) * (3.1416 / 180);
    final a = (dLat / 2).sin * (dLat / 2).sin + (p1.latitude * (3.1416 / 180)).cos * (p2.latitude * (3.1416 / 180)).cos * (dLon / 2).sin * (dLon / 2).sin;
    final c = 2 * (a.sqrt).atan2(a.sqrt, (1 - a).sqrt);
    return earthRadiusMiles * c;
  }

  Set<Marker> _getMapMarkers() {
    final filtered = _getFilteredPlaces();
    final Set<Marker> markers = {};

    if (userLocation != null) {
      markers.add(Marker(markerId: const MarkerId('user'), position: userLocation!, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)));
    }

    for (var place in filtered) {
      final dist = _calculateDistance(userLocation ?? const LatLng(0, 0), place['position'] as LatLng);
      markers.add(Marker(
        markerId: MarkerId(place['id']),
        position: place['position'] as LatLng,
        infoWindow: InfoWindow(title: place['name'], snippet: "${place['address']} • ${dist.toStringAsFixed(1)} mi"),
      ));
    }
    return markers;
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      _speech.listen(onResult: (result) => setState(() => _searchController.text = result.recognizedWords));
    }
  }

  void _showPlaceDetails(Map<String, dynamic> place) async {
    final dist = userLocation != null ? _calculateDistance(userLocation!, place['position'] as LatLng) : 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(place['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📍 ${place['address']}"),
            const SizedBox(height: 8),
            Text("📏 ${dist.toStringAsFixed(1)} miles away"),
            if (place['rating'] != 'N/A') Text("⭐ ${place['rating']}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ElevatedButton.icon(
            icon: const Icon(Icons.map),
            label: const Text("Open in Google Maps"),
            onPressed: () {
              final lat = (place['position'] as LatLng).latitude;
              final lng = (place['position'] as LatLng).longitude;
              launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng"));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlaces = _getFilteredPlaces();

    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: widget.color),
      body: Scrollbar(
        thumbVisibility: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: TextField(controller: _searchController, decoration: const InputDecoration(hintText: "Search deals or speak address...", border: OutlineInputBorder()))),
                  IconButton(icon: const Icon(Icons.mic, color: Color(0xFF00D4FF)), onPressed: _startListening),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ["1 mile", "5 miles", "10 miles"].map((radius) {
                  return ChoiceChip(label: Text(radius), selected: selectedRadius == radius, onSelected: (_) => setState(() => selectedRadius = radius), selectedColor: widget.color);
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text("Showing ${widget.title} near you (${filteredPlaces.length} found)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00D4FF))),
            ),
            Expanded(
              flex: 2,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredPlaces.isEmpty
                      ? const Center(child: Text("No matching places found.\nTry a larger radius or different search term.", textAlign: TextAlign.center))
                      : ListView.builder(
                          itemCount: filteredPlaces.length,
                          itemBuilder: (context, index) {
                            final place = filteredPlaces[index];
                            final dist = userLocation != null ? _calculateDistance(userLocation!, place['position'] as LatLng) : 0.0;
                            return ListTile(
                              leading: const Icon(Icons.local_offer, color: Color(0xFF00D4FF)),
                              title: Text(place['name']),
                              subtitle: Text("${place['address']} • ${dist.toStringAsFixed(1)} mi"),
                              onTap: () => _showPlaceDetails(place),
                            );
                          },
                        ),
            ),
            Expanded(
              flex: 3,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(target: userLocation ?? const LatLng(29.7604, -95.3698), zoom: 15),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: true,
                      markers: _getMapMarkers(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== REMAINING SCREENS (unchanged) ======================
class InstantSavingsScreen extends StatefulWidget { const InstantSavingsScreen({super.key}); @override State<InstantSavingsScreen> createState() => _InstantSavingsScreenState(); }
class _InstantSavingsScreenState extends State<InstantSavingsScreen> {
  final List<Map<String, String>> activeAlerts = [];
  void addAlert(String term) => setState(() => activeAlerts.add({"term": term, "radius": "5 miles"}));
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Instant Savings")),
      body: Scrollbar(
        thumbVisibility: true,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("Your Active Alerts", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Expanded(
                child: activeAlerts.isEmpty
                    ? const Center(child: Text("No active alerts yet.\nTap the button below to test.", textAlign: TextAlign.center))
                    : ListView.builder(itemCount: activeAlerts.length, itemBuilder: (context, index) {
                        final alert = activeAlerts[index];
                        return ListTile(title: Text(alert["term"]!), subtitle: Text("${alert["radius"]} radius"), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => activeAlerts.removeAt(index))));
                      }),
              ),
              ElevatedButton(onPressed: () => addAlert("Coffee Specials"), child: const Text("Add Test Alert (Coffee)")),
            ],
          ),
        ),
      ),
    );
  }
}

class SelfieFilterScreen extends StatelessWidget { const SelfieFilterScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Drop the DRIP")), body: Scrollbar(thumbVisibility: true, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Image.asset('assets/selfie_share.jpg', fit: BoxFit.contain), const SizedBox(height: 40), ElevatedButton(onPressed: () => Share.share("Saved again by my DRIP app! 🎉 #DRIPApp"), child: const Text("Share Selfie"))])))); }

class FamilyModeScreen extends StatelessWidget { const FamilyModeScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("👨‍👩‍👧‍👦 Family / Group Mode")), body: Scrollbar(thumbVisibility: true, child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [const Text("Share deals with friends & family", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 30), ElevatedButton.icon(icon: const Icon(Icons.group_add), label: const Text("Create New Group"), onPressed: () {}, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60))), const SizedBox(height: 15), ElevatedButton.icon(icon: const Icon(Icons.person_add), label: const Text("Add Members"), onPressed: () {}, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60))), const SizedBox(height: 15), ElevatedButton.icon(icon: const Icon(Icons.share), label: const Text("Share My Alerts"), onPressed: () {}, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)))])))); }