// lib/widgets/location_search_sheet.dart (FINAL HYBRID VERSION - REPLACE YOUR ENTIRE FILE)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as places_sdk;
import 'package:lovz/utils/app_colors.dart';

class LocationSearchSheet extends StatefulWidget {
  const LocationSearchSheet({super.key});

  @override
  _LocationSearchSheetState createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  
  // Local cities ke liye
  List<Map<String, dynamic>> _allCities = [];
  List<Map<String, dynamic>> _filteredCities = [];

  // Online search ke liye
  List<places_sdk.AutocompletePrediction> _onlinePredictions = [];
  late final places_sdk.FlutterGooglePlacesSdk _places;
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLocalCities();

    // AndroidManifest.xml se key apne aap le lega
    _places = places_sdk.FlutterGooglePlacesSdk("AIzaSyAMr573TcmBPusJj4T1O0_Ui9hLDhVzdzE"); // iOS fallback key

    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadLocalCities() async {
    final String response = await rootBundle.loadString('assets/cities.json');
    final List<dynamic> data = json.decode(response);
    if (mounted) {
      setState(() {
        _allCities = List<Map<String, dynamic>>.from(data);
        _filteredCities = _allCities;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    // Pehle local list ko filter karo
    if (query.isEmpty) {
      setState(() {
        _filteredCities = _allCities;
        _onlinePredictions = []; // Online results saaf karo
      });
    } else {
      setState(() {
        _filteredCities = _allCities
            .where((city) => city['name']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }

    // Ab online search ke liye debounce lagao
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchPlacesOnline(query);
      }
    });
  }

  Future<void> _searchPlacesOnline(String input) async {
    if (mounted) setState(() => _isLoading = true);
    final result = await _places.findAutocompletePredictions(input);
    if (mounted) {
      setState(() {
        _onlinePredictions = result.predictions;
        _isLoading = false;
      });
    }
  }

  Future<void> _getPlaceDetails(String placeId, String placeDescription) async {
    final result = await _places.fetchPlace(
      placeId,
      fields: [places_sdk.PlaceField.Location],
    );

    if (result.place != null && result.place!.latLng != null) {
      final place = result.place!;
      final locationResult = {
        'name': placeDescription,
        'lat': place.latLng!.lat,
        'lng': place.latLng!.lng,
      };
      if (mounted) Navigator.of(context).pop(locationResult);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Container(
              width: 40, height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search any city...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          if (_isLoading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: LinearProgressIndicator()),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCities.length + _onlinePredictions.length,
              itemBuilder: (context, index) {
                // Pehle local cities dikhao
                if (index < _filteredCities.length) {
                  final city = _filteredCities[index];
                  return ListTile(
                    leading: const Icon(Icons.location_city, color: AppColors.primaryPink),
                    title: Text(city['name']!),
                    onTap: () {
                      Navigator.of(context).pop(city);
                    },
                  );
                } else {
                  // Phir online results dikhao
                  final predictionIndex = index - _filteredCities.length;
                  final prediction = _onlinePredictions[predictionIndex];
                  return ListTile(
                    leading: const Icon(Icons.public, color: Colors.blue),
                    title: Text(prediction.primaryText),
                    subtitle: Text(prediction.secondaryText),
                    onTap: () {
                      _getPlaceDetails(prediction.placeId, prediction.fullText);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}