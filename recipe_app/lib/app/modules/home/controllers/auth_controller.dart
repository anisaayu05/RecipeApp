import 'package:get/get.dart';

class AuthController extends GetxController {
  var isLoggedIn = false.obs;  // Status login

  void loginWithGoogle() {
    isLoggedIn.value = true;  // Ubah status login menjadi true
  }

  void logout() {
    isLoggedIn.value = false;  // Ubah status login menjadi false (logout)
  }
}
