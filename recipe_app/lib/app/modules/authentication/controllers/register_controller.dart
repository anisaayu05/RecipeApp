import 'package:cloud_firestore/cloud_firestore.dart'; // Tambahkan ini untuk Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

class RegisterController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Tambahkan ini untuk Firestore

  Future<void> registerUser(String name, String email, String password) async {
    try {
      // Buat user baru dengan email dan password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Dapatkan user ID dari user yang baru terdaftar
      String userId = userCredential.user!.uid;

      // Simpan data user ke Firestore
      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        // Anda bisa menambahkan field lain yang diperlukan
      });

      // Navigasi ke halaman HOME setelah sukses register
      Get.offAllNamed(Routes.HOME);
    } catch (e) {
      // Tampilkan pesan error jika ada masalah
      Get.snackbar('Error', e.toString());
    }
  }
}
