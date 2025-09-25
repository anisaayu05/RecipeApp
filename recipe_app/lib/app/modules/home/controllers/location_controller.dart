import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class LocationController extends GetxController {
  RxBool loading = true.obs;  // Use RxBool instead of Rx<bool>
  RxString locationAddress = "".obs;

  @override
  void onInit() {
    super.onInit();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationAddress.value = 'Lokasi tidak tersedia (Layanan lokasi dinonaktifkan)';
        loading.value = false;
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          locationAddress.value = 'Lokasi tidak tersedia (Izin ditolak)';
          loading.value = false;
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];

      locationAddress.value = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      loading.value = false;
    } catch (e) {
      locationAddress.value = 'Lokasi tidak tersedia (Terjadi kesalahan)';
      loading.value = false;
    }
  }
}