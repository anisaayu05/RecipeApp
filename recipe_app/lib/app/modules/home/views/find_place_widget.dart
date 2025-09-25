import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class FindPlace extends StatefulWidget {
  final String foodName;

  const FindPlace({Key? key, required this.foodName}) : super(key: key);

  @override
  _FindPlaceState createState() => _FindPlaceState();
}

class _FindPlaceState extends State<FindPlace> {
  final String googleApiKey = 'AIzaSyAc35k51p5-VFS4SJpVWteJs7wt-ELl-us'; // Ganti dengan API Key Anda
  bool isLoading = false;
  bool isNearbySearch = false; // Mode pencarian
  List<Map<String, dynamic>> restaurants = [];
  String currentAddress = 'Lokasi tidak diketahui';
  Position? currentPosition;

  // Fungsi untuk meminta izin lokasi

bool isCheckingPermission = true;
bool hasLocationPermission = false;

Future<void> checkPermission() async {
  setState(() {
    isCheckingPermission = true;
  });

  if (await Permission.location.isDenied || await Permission.location.isPermanentlyDenied) {
    final status = await Permission.location.request();
    
    if (status.isGranted) {
      setState(() {
        hasLocationPermission = true;
      });
      await getCurrentLocation();
    } else if (status.isPermanentlyDenied) {
      setState(() {
        hasLocationPermission = false;
        currentAddress = 'Izin lokasi ditolak secara permanen. Buka pengaturan untuk mengaktifkan.';
      });
      await openAppSettings();
    }
  } else {
    setState(() {
      hasLocationPermission = true;
    });
    await getCurrentLocation();
  }

  setState(() {
    isCheckingPermission = false;
  });
}

  // Fungsi untuk mendapatkan lokasi pengguna
  Future<void> getCurrentLocation() async {
    try {
      currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (currentPosition != null) {
        final placemarks = await placemarkFromCoordinates(
            currentPosition!.latitude, currentPosition!.longitude);

        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          setState(() {
            currentAddress =
                "${place.street}, ${place.locality}, ${place.subAdministrativeArea}";
          });
        }
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // Fungsi untuk menghitung jarak antara pengguna dan restoran
  double calculateDistance(double lat, double lng) {
    if (currentPosition == null) return 0.0;

    return Geolocator.distanceBetween(
          currentPosition!.latitude,
          currentPosition!.longitude,
          lat,
          lng,
        ) /
        1000; // Konversi ke kilometer
  }

  // Fungsi untuk mengambil data restoran
  Future<void> fetchRestaurants() async {
    setState(() {
      isLoading = true;
      restaurants.clear();
    });

    try {
      String url;
      if (isNearbySearch && currentPosition != null) {
        final lat = currentPosition!.latitude;
        final lng = currentPosition!.longitude;
        url =
            'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&type=restaurant&keyword=${widget.foodName}&key=$googleApiKey';
      } else {
        url =
            'https://maps.googleapis.com/maps/api/place/textsearch/json?query=${widget.foodName}+restaurant&key=$googleApiKey';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        setState(() {
          restaurants = results.map((result) {
            final name = result['name']?.toString() ?? 'Unknown';
            final address = isNearbySearch
                ? result['vicinity']?.toString() ?? 'Alamat tidak tersedia'
                : result['formatted_address']?.toString() ?? 'Alamat tidak tersedia';
            final lat = result['geometry']['location']['lat'] as double?;
            final lng = result['geometry']['location']['lng'] as double?;

            final distance = (lat != null && lng != null)
                ? calculateDistance(lat, lng)
                : null;

            return {
              'name': name,
              'address': address,
              'lat': lat, // Tambahkan koordinat
              'lng': lng, // Tambahkan koordinat
              'distance': distance, // Tambahkan jarak ke data
            };
          }).toList();
        });
      } else {
        throw Exception('Failed to fetch restaurants');
      }
    } catch (e) {
      print('Error fetching restaurants: $e');
      setState(() {
        restaurants = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fungsi untuk membuka Google Maps
  void openGoogleMaps(double latitude, double longitude) async {
  final googleMapsUrl =
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';

  if (await canLaunch(googleMapsUrl)) {
    await launch(googleMapsUrl);
  } else {
    throw 'Tidak dapat membuka Google Maps';
  }
}


  @override
  void initState() {
    super.initState();
    checkPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Hasil dari '${widget.foodName}'",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isNearbySearch ? Icons.location_off : Icons.location_on,
              color: Colors.black87,
            ),
            onPressed: () {
              setState(() {
                isNearbySearch = !isNearbySearch;
              });
              fetchRestaurants();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Location Card
            Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.1),
        spreadRadius: 1,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.location_on, color: Colors.red),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Lokasi Anda Saat Ini",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              if (isCheckingPermission)
                const Text(
                  "Mendapatkan lokasi...",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                  ),
                )
              else
                Text(
                  currentAddress,
                  style: TextStyle(
                    color: currentAddress.contains('Izin lokasi ditolak') 
                      ? Colors.red[600] 
                      : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
        if (!hasLocationPermission && !currentAddress.contains('Izin lokasi ditolak'))
          ElevatedButton(
            onPressed: checkPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Aktifkan Lokasi"),
          )
        else if (currentAddress.contains('Izin lokasi ditolak'))
          ElevatedButton(
            onPressed: openAppSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Buka Pengaturan"),
          ),
      ],
    ),
  ),
),
            const SizedBox(height: 16),
            if (isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              )
            else if (restaurants.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index];
                    final double? lat = restaurant['lat'] as double?;
                    final double? lng = restaurant['lng'] as double?;

                    return GestureDetector(
                      onTap: () {
                        if (lat != null && lng != null) {
                          openGoogleMaps(lat, lng);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Lokasi tidak tersedia")),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      restaurant['name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      restaurant['address'] ?? 'Alamat tidak tersedia',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (restaurant['distance'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          "Jarak: ${restaurant['distance']?.toStringAsFixed(2)} km",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey[400],
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text(
                    "Tidak ada restoran ditemukan.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}