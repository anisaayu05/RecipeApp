import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/profile_controller.dart';

class WeatherIcon extends StatelessWidget {
  final int weatherCode;

  WeatherIcon({required this.weatherCode});

  @override
  Widget build(BuildContext context) {
    // Mapping kode cuaca ke ikon
    IconData weatherIcon;
    String description = '';

    switch (weatherCode) {
      case 0:
        weatherIcon = Icons.wb_sunny; // Clear sky
        description = "Langit Cerah";
        break;
      case 1:
        weatherIcon = Icons.cloud; // Mainly clear
        description = "Cerah sebagian";
        break;
      case 2:
        weatherIcon = Icons.cloud_queue; // Partly cloudy
        description = "Berawan sebagian";
        break;
      case 3:
        weatherIcon = Icons.cloud_outlined; // Overcast
        description = "Berawan";
        break;
      case 45:
        weatherIcon = Icons.filter_drama; // Fog
        description = "Kabut";
        break;
      case 51:
        weatherIcon = Icons.beach_access; // Light rain
        description = "Hujan ringan";
        break;
      case 61:
        weatherIcon = Icons.grain; // Moderate rain
        description = "Hujan sedang";
        break;
      case 71:
        weatherIcon = Icons.thunderstorm; // Heavy rain
        description = "Hujan deras";
        break;
      default:
        weatherIcon = Icons.help_outline; // Unknown weather
        description = "Cuaca Tidak Diketahui";
        break;
    }

    return Column(
      children: [
        Icon(weatherIcon, size: 80, color: Colors.orange),
        SizedBox(height: 8.0),
        Text(description, style: TextStyle(fontSize: 16)),
      ],
    );
  }
}

class LocationView extends GetView<ProfileController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Lokasi Terkini",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepOrange,
      ),
      body: Stack(
        children: [
          // Peta utama
          Obx(() {
            return FlutterMap(
              options: MapOptions(
                center: LatLng(
                  controller.currentPosition.value?.latitude ?? 0,
                  controller.currentPosition.value?.longitude ?? 0,
                ),
                zoom: 16.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    if (controller.currentPosition.value != null)
                      Marker(
                        width: 40.0,
                        height: 40.0,
                        point: LatLng(
                          controller.currentPosition.value!.latitude,
                          controller.currentPosition.value!.longitude,
                        ),
                        builder: (ctx) => const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                  ],
                ),
              ],
            );
          }),

          // Bottom sheet untuk informasi lokasi
          DraggableScrollableSheet(
            initialChildSize: 0.25,
            minChildSize: 0.2,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Garis kecil di atas bottom sheet untuk indikasi draggable
                      Center(
                        child: Container(
                          width: 40.0,
                          height: 5.0,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Informasi lintang dan bujur dengan ikon titik koordinat
                      Obx(() {
                        final latitude = controller.currentPosition.value?.latitude ?? '-';
                        final longitude = controller.currentPosition.value?.longitude ?? '-';

                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.my_location, color: Colors.deepOrange, size: 30),  // Ikon titik koordinat
                                const SizedBox(width: 8.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Lintang: $latitude",
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      "Bujur: $longitude",
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              "Pembaruan terakhir: ${controller.lastUpdated}",
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      }),

                      const SizedBox(height: 24.0),

                      // Pemisah garis tipis
                      Divider(color: Colors.grey, thickness: 1.0, height: 24.0),

                      // Informasi tambahan hanya muncul saat ditarik
                      Obx(() {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (controller.locationAddress.value.isNotEmpty)
                              Column(
                                children: [
                                  const Text(
                                    "Alamat:",
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.deepOrange, size: 30),  // Ikon lokasi
                                      const SizedBox(width: 8.0),
                                      Expanded(
                                        child: Text(
                                          controller.locationAddress.value,
                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16.0),
                                ],
                              ),

                              // Pemisah garis tipis
                              Divider(color: Colors.grey, thickness: 1.0, height: 24.0),
                              const SizedBox(height: 50.0),

                              // Menampilkan cuaca
                              if (controller.weatherInfo.value.isNotEmpty)
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Cuaca Saat Ini:",
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Center(  // Membungkus Text di dalam widget Center
                                      child: Text(
                                        controller.weatherInfo.value,
                                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    WeatherIcon(weatherCode: controller.weatherCode.value), // Menampilkan ikon cuaca
                                    const SizedBox(height: 50.0),
                                  ],
                                ),
                            ElevatedButton.icon(
                              onPressed: controller.loading.value
                                  ? null
                                  : () async {
                                      controller.loading.value = true;
                                      await controller.getCurrentLocation();
                                      controller.loading.value = false;
                                    },
                              icon: controller.loading.value
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.0,
                                    )
                                  : const Icon(Icons.location_searching),
                              label: Text(controller.loading.value ? "Memuat..." : "Dapatkan Lokasi"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (controller.currentPosition.value != null) {
                                  final latitude = controller.currentPosition.value!.latitude;
                                  final longitude = controller.currentPosition.value!.longitude;
                                  final googleMapsUrl =
                                      "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";
                                  launchUrl(Uri.parse(googleMapsUrl));
                                } else {
                                  Get.snackbar("Peringatan", "Lokasi belum tersedia.",
                                      snackPosition: SnackPosition.BOTTOM);
                                }
                              },
                              icon: const Icon(Icons.map),
                              label: const Text("Buka di Google Maps"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 255, 140, 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
