import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../home/views/home_view.dart';
import '../views/no_connection_view.dart';

class ConnectionController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = false.obs; // Status koneksi sebagai reaktif
  final RxBool wasPreviouslyOffline = false.obs; // Menyimpan apakah sebelumnya offline
  bool isFirstCheck = true; // Menandai apakah ini adalah pemeriksaan koneksi pertama kali
  String? lastRoute; // Rute terakhir sebelum kehilangan koneksi

  @override
  void onInit() {
    super.onInit();
    _connectivity.onConnectivityChanged.listen((connectivityResults) {
      _updateConnectionStatus(connectivityResults.first);
    });

    // Periksa koneksi saat inisialisasi
    _checkConnection();
  }

  // Fungsi untuk memeriksa koneksi secara manual
  Future<void> _checkConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResult.first);
  }

  // Fungsi untuk mengupdate status koneksi
  void _updateConnectionStatus(ConnectivityResult connectivityResult) {
  if (connectivityResult == ConnectivityResult.none) {
    if (isConnected.value) {
      // Koneksi baru saja putus, menggunakan AwesomeSnackbarContent
      _showAwesomeSnackbar(
        title: 'Offline',
        message: 'No internet connection. Please check your connection.',
        contentType: ContentType.failure, // Menggunakan failure untuk status offline
      );
    }
    isConnected.value = false;
    wasPreviouslyOffline.value = true; // Menandai bahwa sebelumnya offline

    // Simpan rute terakhir sebelum ke NoConnectionView
    if (Get.currentRoute != '/NoConnectionView') {
      lastRoute = Get.currentRoute;
    }
    Get.to(() => const NoConnectionView());
  } else {
    if (!isFirstCheck && !isConnected.value && wasPreviouslyOffline.value) {
      // Koneksi baru saja kembali online, bukan pada pemeriksaan pertama
      _showAwesomeSnackbar(
        title: 'Online',
        message: 'You\'re back online!',
        contentType: ContentType.success, // Menggunakan success untuk status online
      );
      wasPreviouslyOffline.value = false; // Reset flag setelah online
    }
    isConnected.value = true;

    // Hindari memicu snackbar pada pemeriksaan pertama
    isFirstCheck = false;

    // Kembali ke rute terakhir jika ada, atau ke HomeView jika tidak
    if (Get.currentRoute == '/NoConnectionView') {
      if (lastRoute != null) {
        // Kembali ke rute terakhir jika ada
        Get.back(); // Akan kembali ke rute terakhir di tumpukan navigasi
      } else {
        // Jika tidak ada rute terakhir, arahkan ke HomeView
        Get.offAll(() => const HomeView());
      }
    }
  }
}

  // Fungsi untuk menampilkan snackbar dengan AwesomeSnackbarContent
  void _showAwesomeSnackbar({
  required String title,
  required String message,
  required ContentType contentType,
  }) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating, // Menampilkan snackbar sebagai floating
        margin: const EdgeInsets.only(top: 100.0), // Posisi dari atas layar, sesuaikan jaraknya
        content: AwesomeSnackbarContent(
          title: title,
          message: message,
          contentType: contentType,
          titleTextStyle: TextStyle(
            fontSize: 18, // Ukuran font untuk title
            fontWeight: FontWeight.bold,
          ),
          messageTextStyle: TextStyle(
            fontSize: 13.5, // Ukuran font untuk message
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Fungsi Retry untuk tombol
  Future<void> retryConnection() async {
    await _checkConnection();
    if (isConnected.value) {
      // Kembali ke rute terakhir jika ada
      if (lastRoute != null) {
        Get.offNamed(lastRoute!);
      } else {
        Get.offAll(() => const HomeView());
      }
    } else {
      _showAwesomeSnackbar(
        title: 'Error',
        message: 'No internet connection. Please try again.',
        contentType: ContentType.failure, // Menggunakan failure untuk error
      );
    }
  }

  // Fungsi untuk melanjutkan offline
  void continueOffline() {
    Get.back(); // Kembali ke layar sebelumnya
    _showAwesomeSnackbar(
      title: 'Offline Mode',
      message: 'You are now in offline mode. Some features may not be available.',
      contentType: ContentType.warning, // Notifikasi mode offline
    );
  }
}