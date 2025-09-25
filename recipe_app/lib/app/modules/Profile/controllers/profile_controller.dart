import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileController extends GetxController {
  final picker = ImagePicker();
  RxString profileImage = ''.obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final GetStorage storage = GetStorage(); // Inisialisasi GetStorage
  final box = GetStorage();

  // Location variables
  Rx<Position?> currentPosition = Rx<Position?>(null);  // Store current position
  RxString locationMessage = "Mencari Lintang dan Bujur...".obs;
  RxString locationAddress = "Mencari alamat...".obs;
  RxBool loading = false.obs;
  Rx<DateTime?> lastUpdatedTime = Rx<DateTime?>(null);
  Rx<int> weatherCode = 0.obs; // Kode cuaca untuk ikon
  RxString weatherInfo = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfileImage();
    getCurrentLocation();  // Fetch current location when the profile is loaded
    checkAndUploadPendingImage(); // Cek jika ada gambar yang belum diunggah
  }

  // Getter untuk menampilkan waktu pembaruan dalam format string
  String get lastUpdated {
    if (lastUpdatedTime.value == null) {
      return "Belum diperbarui";
    }
    final time = lastUpdatedTime.value!;
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} pada ${time.day.toString().padLeft(2, '0')}-${time.month.toString().padLeft(2, '0')}-${time.year}";
  }

  // Method to get current location
  Future<void> getCurrentLocation() async {
    loading.value = true;
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        throw Exception('Layanan lokasi tidak aktif');
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak secara permanen');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      currentPosition.value = position;
      locationMessage.value =
          "Lintang : ${position.latitude}, \nBujur: ${position.longitude}";
      
      // Simpan waktu pembaruan
      lastUpdatedTime.value = DateTime.now();

      // Konversi lintang dan bujur ke alamat
      List<Placemark> placemarks = await GeocodingPlatform.instance!.placemarkFromCoordinates(
        position.latitude, 
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        locationAddress.value = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      }

      // Get weather data
      await getWeather(position.latitude, position.longitude);

      // Simpan lokasi dan alamat ke Firestore
      await saveLocationToFirestore(position, locationAddress.value);

      } catch (e) {
        locationMessage.value = 'Gagal mendapatkan lokasi: $e';
      } finally {
        loading.value = false;
      }
    }

    // Method to get current weather info
    Future<void> getWeather(double latitude, double longitude) async {
      try {
        final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true',
        );
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final weather = data['current_weather'];
          final temperature = weather['temperature'];
          final windSpeed = weather['windspeed'];
          final weatherDescription = weather['weathercode'];

          // Update weather information and weather code for the icon
          weatherInfo.value =
              "Suhu: $temperature°C, Kecepatan Angin: $windSpeed km/jam";
          weatherCode.value = weatherDescription;  // Set the weather code
        } else {
          weatherInfo.value = "Gagal memuat cuaca";
        }
      } catch (e) {
        weatherInfo.value = "Error saat mendapatkan cuaca: $e";
      }
    }

    // Fungsi untuk menyimpan lokasi dan alamat ke Firestore
    Future<void> saveLocationToFirestore(Position position, String address) async {
      User? user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore.collection('users').doc(user.uid).update({
            'location': {
              'latitude': position.latitude,
              'longitude': position.longitude,
            },
            'location address': address,  // Menambahkan alamat ke Firestore
            'lastUpdated': FieldValue.serverTimestamp(), // Tambahkan waktu pembaruan ke Firestore
          });
          Get.snackbar('Lokasi Disimpan', 'Lokasi dan alamat berhasil disimpan ke Firestore!');
        } catch (e) {
          Get.snackbar('Error', 'Gagal menyimpan lokasi: $e');
        }
      }
    }

  // Method to open Google Maps with current location
  void openGoogleMaps() {
    if (currentPosition.value != null) {
      final url =
          'https://www.google.com/maps?q=${currentPosition.value!.latitude},${currentPosition.value!.longitude}';
      _launchURL(url);
    }
  }

  // Method to launch URL
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Tidak dapat membuka $url';
    }
  }

  // Fetch profile image from Firestore
  Future<void> fetchProfileImage() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        bool isConnected = await checkInternetConnection();
        if (isConnected) {
          DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
          if (doc.exists && doc['profileImage'] != null) {
            profileImage.value = doc['profileImage'];
          }
        } else {
          // Muat gambar dari path lokal
          String? localPath = box.read('localProfileImage');
          if (localPath != null && File(localPath).existsSync()) {
            profileImage.value = localPath;
          }
        }
      } catch (e) {
        Get.snackbar('Error', 'Failed to fetch profile image: $e');
      }
    }
  }

  // Show image source dialog for profile image selection
  void showImageSourceDialog() {
    Get.defaultDialog(
      title: "Select Image Source",
      content: Column(
        children: [
          TextButton(
            onPressed: () {
              pickImage(ImageSource.camera);
              Get.back();
            },
            child: Text("Camera"),
          ),
          TextButton(
            onPressed: () {
              pickImage(ImageSource.gallery);
              Get.back();
            },
            child: Text("Gallery"),
          ),
        ],
      ),
    );
  }

  // Pick profile image (camera or gallery)
  Future<void> pickProfileImage() async {
    showImageSourceDialog();
  }

  Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Pick profile image
  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        String filePath = pickedFile.path;

        // Cek koneksi internet sebelum mengunggah
        bool isConnected = await checkInternetConnection();
        if (isConnected) {
          await uploadProfileImageToStorage(filePath);
        } else {
          // Simpan path gambar lokal ke Get Storage
          box.write('localProfileImage', filePath);
          Get.snackbar('Offline Mode', 'Gambar disimpan sementara di perangkat.');
        }
      } else {
        Get.snackbar('No Image Selected', 'Please select an image.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e');
    }
  }

  // Upload profile image to Firebase Storage
  Future<void> uploadProfileImageToStorage(String filePath) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        Reference storageRef = _storage.ref().child('profileImages').child('${user.uid}.jpg');

        UploadTask uploadTask = storageRef.putFile(File(filePath));

        TaskSnapshot snapshot = await uploadTask;

        String downloadUrl = await snapshot.ref.getDownloadURL();

        await updateProfileImageUrl(downloadUrl);

        // Hapus file sementara dari lokal setelah berhasil diunggah
        storage.remove('pendingImage');
      } catch (e) {
        Get.snackbar('Error', 'Failed to upload image: $e');
      }
    }
  }

  // Update the profile image URL in Firestore
  Future<void> updateProfileImageUrl(String imageUrl) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'profileImage': imageUrl,
        });
        profileImage.value = imageUrl; // Update local value
        Get.snackbar('Success', 'Profile image updated successfully!');
      } catch (e) {
        print('Error updating profile image URL: $e');
        Get.snackbar('Error', 'Failed to update profile image: $e');
      }
    }
  }

  // Check for pending image and upload when internet is available
  void checkAndUploadPendingImage() async {
    String? pendingImage = storage.read('pendingImage');
    if (pendingImage != null && File(pendingImage).existsSync()) {
      // Cek koneksi internet
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Unggah gambar jika ada koneksi
        await uploadProfileImageToStorage(pendingImage);
      }
    }
  }

  // Confirm logout
  void confirmLogout() {
    Get.defaultDialog(
      title: "Logout Confirmation",
      content: Text("Are you sure you want to logout?"),
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
          },
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            logout();
            Get.back();
          },
          child: Text("Logout"),
        ),
      ],
    );
  }

  // Logout method
  void logout() {
    try {
      _auth.signOut();
      Get.snackbar('Success', 'You have logged out successfully.');
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('Error', 'Failed to logout: $e');
    }
  }
}
