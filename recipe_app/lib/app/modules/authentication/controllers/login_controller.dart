import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> loginUser(String email, String password) async {
    // === 1. Validasi input tidak boleh kosong ===
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Error', 'Email dan password tidak boleh kosong.');
      return;
    }

    // === 2. Validasi format email (harus @gmail.com) ===
    final emailRegex = RegExp(r'^[\w\.-]+@gmail\.com$');
    if (!emailRegex.hasMatch(email)) {
      Get.snackbar('Error',
          'Gunakan email dengan format yang valid, misalnya: nama@gmail.com');
      return;
    }

    // === 3. Validasi panjang minimal password ===
    if (password.length < 8) {
      Get.snackbar('Error', 'Password minimal 8 karakter.');
      return;
    }

    try {
      // === 4. Login ke Firebase ===
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // === 5. Jika berhasil, arahkan ke halaman HOME ===
      Get.offAllNamed(Routes.HOME);
      Get.snackbar('Berhasil', 'Login berhasil, selamat datang!');
    } on FirebaseAuthException catch (e) {
      // === 6. Tangani error dari Firebase ===
      if (e.code == 'user-not-found') {
        Get.snackbar('Error', 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.');
      } else if (e.code == 'wrong-password') {
        Get.snackbar('Error', 'Password salah. Coba lagi.');
      } else if (e.code == 'invalid-email') {
        Get.snackbar('Error', 'Format email tidak valid.');
      } else {
        Get.snackbar('Error', e.message ?? 'Terjadi kesalahan saat login.');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
}
