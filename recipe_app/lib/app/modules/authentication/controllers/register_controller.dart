import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

class RegisterController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerUser(String name, String email, String password) async {
    // === 1. Validasi nama pengguna ===
    if (name.isEmpty || name.length < 4) {
      Get.snackbar('Error', 'Nama minimal 4 karakter.');
      return;
    }

    // === 2. Validasi format email ===
  final emailRegex = RegExp(r'^[\w\.-]+@gmail\.com$');
    if (!emailRegex.hasMatch(email)) {
      Get.snackbar('Error',
          'Format email tidak valid. Hanya email dengan domain @gmail.com yang diperbolehkan.');
      return;
    }


    // === 3. Validasi password ===
    final passwordRegex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[A-Za-z\d]{8,}$');
    if (!passwordRegex.hasMatch(password)) {
      Get.snackbar('Error',
          'Password minimal 8 karakter dan harus mengandung huruf besar, huruf kecil, serta angka.');
      return;
    }

    try {
      // === 4. Buat user baru di Firebase Authentication ===
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // === 5. Simpan data user ke Firestore ===
      String userId = userCredential.user!.uid;
      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // === 6. Navigasi ke halaman HOME setelah berhasil ===
      Get.offAllNamed(Routes.HOME);
      Get.snackbar('Berhasil', 'Akun berhasil dibuat.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        Get.snackbar('Error', 'Email sudah terdaftar.');
      } else if (e.code == 'invalid-email') {
        Get.snackbar('Error', 'Email tidak valid.');
      } else if (e.code == 'weak-password') {
        Get.snackbar('Error', 'Password terlalu lemah.');
      } else {
        Get.snackbar('Error', e.message ?? 'Terjadi kesalahan.');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
}
