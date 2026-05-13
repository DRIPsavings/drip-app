import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;

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
          thickness: MaterialStateProperty.all(6.0),
          radius: const Radius.circular(10),
          minThumbLength: 60,
        ),
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
    try {
      await _player.play(AssetSource(file));
    } catch (e) {
      debugPrint("Audio play error: $e");
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
        title: const Text(
          "DRIP",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00D4FF), letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 10),

              _imageButton('assets/party_button.png', () {
                playSound('party.mp3');
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen(title: "Get The Party Started", color: Colors.purple)));
              }, height: 52),

              _imageButton('assets/coffee_button.png', () {
                playSound('coffee.mp3');
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen(title: "Coffee's My CRACK!", color: Colors.brown)));
              }, height: 52),

              _imageButton('assets/smoothie_button.png', () {
                playSound('smoothie.mp3');
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen(title: "Groovy Smoothie", color: Colors.green)));
              }, height: 52),

              const SizedBox(height: 30),

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
      ),
    );
  }

  Widget _imageButton(String asset, VoidCallback onTap, {double height = 88}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(asset, fit: BoxFit.contain, height: height, width: double.infinity),
        ),
      ),
    );
  }
}

// ====================== CATEGORY SCREEN (Map scroll disabled + Blue Scrollbar) ======================
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
  bool isLoadingLocation = true;

  late List<Map<String, dynamic>> _allDeals;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
        isLoadingLocation = false;
      });

      _generateDealsNearUser();
    } catch (e) {
      debugPrint("Location error: $e");
      setState(() => isLoadingLocation = false);
    }
  }

  void _generateDealsNearUser() {
    if (userLocation == null) return;

    final String categoryType = widget.title.toLowerCase().contains("coffee") ? "coffee" :
                                widget.title.toLowerCase().contains("smoothie") ? "smoothie" : "party";

    final List<Map<String, dynamic>> templates = [
      {'name': 'Starbucks BOGO Latte', 'description': 'Buy one get one free lattes', 'price': '\$5.99'},
      {'name': 'Local Coffee House Special', 'description': '25% off any espresso drink', 'price': '\$4.49'},
      {'name': 'Dunkin Donuts Deal', 'description': 'Free donut with any coffee', 'price': '\$3.99'},
      {'name': 'Neon Bar Happy Hour', 'description': '\$5 cocktails 4-7pm', 'price': '\$5.00'},
      {'name': 'Club 54 Shot Special', 'description': '2-for-1 shots all night', 'price': '\$8.00'},
      {'name': 'Downtown Pub Pitcher', 'description': '\$12 pitchers until midnight', 'price': '\$12.00'},
      {'name': 'Smoothie King Protein', 'description': 'Buy one get one 50% off', 'price': '\$6.99'},
      {'name': 'Tropical Smoothie Cafe', 'description': 'Any smoothie + snack for \$7', 'price': '\$7.00'},
      {'name': 'Jamba Juice Boost', 'description': 'Free booster shot with any smoothie', 'price': '\$5.49'},
    ];

    _allDeals = [];
    final random = math.Random();

    for (int i = 0; i < templates.length; i++) {
      final double latOffset = (random.nextDouble() * 0.08) - 0.04;
      final double lngOffset = (random.nextDouble() * 0.08) - 0.04;

      final LatLng dealPos = LatLng(
        userLocation!.latitude + latOffset,
        userLocation!.longitude + lngOffset,
      );

      _allDeals.add({
        'id': i.toString(),
        'name': templates[i]['name'],
        'type': categoryType,
        'description': templates[i]['description'],
        'price': templates[i]['price'],
        'position': dealPos,
      });
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredDeals() {
    if (userLocation == null || _allDeals.isEmpty) return [];

    final String query = _searchController.text.trim().toLowerCase();
    final double radiusMiles = double.tryParse(selectedRadius.split(' ')[0]) ?? 5.0;

    List<Map<String, dynamic>> candidates = _allDeals.where((deal) {
      if (query.isEmpty) return true;
      return deal['name'].toLowerCase().contains(query) ||
             deal['description'].toLowerCase().contains(query);
    }).toList();

    List<Map<String, dynamic>> filtered = candidates.map((deal) {
      final double distance = _calculateDistance(userLocation!, deal['position'] as LatLng);
      return {...deal, 'distance': distance};
    }).where((deal) => (deal['distance'] as double) <= radiusMiles).toList();

    filtered.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    return filtered;
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const double earthRadiusMiles = 3958.8;
    final double lat1 = p1.latitude * math.pi / 180;
    final double lon1 = p1.longitude * math.pi / 180;
    final double lat2 = p2.latitude * math.pi / 180;
    final double lon2 = p2.longitude * math.pi / 180;

    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMiles * c;
  }

  Set<Marker> _getMapMarkers() {
    final filtered = _getFilteredDeals();
    final Set<Marker> markers = {};

    if (userLocation != null) {
      markers.add(Marker(markerId: const MarkerId('user'), position: userLocation!, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)));
    }

    for (var deal in filtered) {
      final double dist = deal['distance'] as double;
      markers.add(Marker(
        markerId: MarkerId(deal['id']),
        position: deal['position'] as LatLng,
        infoWindow: InfoWindow(title: deal['name'], snippet: "${deal['description']} • ${dist.toStringAsFixed(1)} mi"),
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

  @override
  Widget build(BuildContext context) {
    final filteredDeals = _getFilteredDeals();

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
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(hintText: "Search deals or speak address...", border: OutlineInputBorder()),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.mic, color: Color(0xFF00D4FF)), onPressed: _startListening),
                ],
              ),
            ),

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

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                "Showing ${widget.title} deals (${filteredDeals.length} found)",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00D4FF)),
              ),
            ),

            Expanded(
              flex: 2,
              child: Scrollbar(
                thumbVisibility: true,
                child: filteredDeals.isEmpty
                    ? const Center(child: Text("No matching deals in this radius.\nTry a larger radius or different search term.", textAlign: TextAlign.center))
                    : ListView.builder(
                        itemCount: filteredDeals.length,
                        itemBuilder: (context, index) {
                          final deal = filteredDeals[index];
                          final double dist = deal['distance'] as double;
                          return ListTile(
                            leading: Icon(widget.title.toLowerCase().contains("coffee") ? Icons.coffee : widget.title.toLowerCase().contains("smoothie") ? Icons.local_drink : Icons.local_bar, color: const Color(0xFF00D4FF)),
                            title: Text(deal['name']),
                            subtitle: Text("${deal['description']} • ${dist.toStringAsFixed(1)} mi"),
                            trailing: Text(deal['price'], style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          );
                        },
                      ),
              ),
            ),

            Expanded(
              flex: 3,
              child: isLoadingLocation
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(target: userLocation ?? const LatLng(29.7604, -95.3698), zoom: 15),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      scrollGesturesEnabled: false,        // ← Disabled accidental dragging
                      zoomGesturesEnabled: true,           // ← Zoom still works
                      markers: _getMapMarkers(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== INSTANT SAVINGS, SELFIE & FAMILY MODE (with Scrollbar) ======================
class InstantSavingsScreen extends StatefulWidget {
  const InstantSavingsScreen({super.key});
  @override
  State<InstantSavingsScreen> createState() => _InstantSavingsScreenState();
}

class _InstantSavingsScreenState extends State<InstantSavingsScreen> {
  final List<Map<String, String>> activeAlerts = [];

  void addAlert(String term) {
    setState(() => activeAlerts.add({"term": term, "radius": "5 miles"}));
  }

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
                    : ListView.builder(
                        itemCount: activeAlerts.length,
                        itemBuilder: (context, index) {
                          final alert = activeAlerts[index];
                          return ListTile(
                            title: Text(alert["term"]!),
                            subtitle: Text("${alert["radius"]} radius"),
                            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => activeAlerts.removeAt(index))),
                          );
                        },
                      ),
              ),
              ElevatedButton(onPressed: () => addAlert("Coffee Specials"), child: const Text("Add Test Alert (Coffee)")),
            ],
          ),
        ),
      ),
    );
  }
}

class SelfieFilterScreen extends StatelessWidget {
  const SelfieFilterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Drop the DRIP")),
      body: Scrollbar(
        thumbVisibility: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/selfie_share.jpg', fit: BoxFit.contain),
              const SizedBox(height: 40),
              ElevatedButton(onPressed: () => Share.share("Saved again by my DRIP app! 🎉 #DRIPApp"), child: const Text("Share Selfie")),
            ],
          ),
        ),
      ),
    );
  }
}

class FamilyModeScreen extends StatelessWidget {
  const FamilyModeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("👨‍👩‍👧‍👦 Family / Group Mode")),
      body: Scrollbar(
        thumbVisibility: true,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text("Share deals with friends & family", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              ElevatedButton.icon(icon: const Icon(Icons.group_add), label: const Text("Create New Group"), onPressed: () {}, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60))),
              const SizedBox(height: 15),
              ElevatedButton.icon(icon: const Icon(Icons.person_add), label: const Text("Add Members"), onPressed: () {}, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60))),
              const SizedBox(height: 15),
              ElevatedButton.icon(icon: const Icon(Icons.share), label: const Text("Share My Alerts"), onPressed: () {}, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60))),
            ],
          ),
        ),
      ),
    );
  }
}