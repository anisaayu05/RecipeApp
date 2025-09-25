import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepOrange.shade300, Colors.deepOrange.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Login
                Icon(
                  Icons.login,
                  size: 100,
                  color: Colors.white,
                ),
                SizedBox(height: 32),
                // Judul
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                // Input Email
                _buildTextField(
                  controller: emailController,
                  hintText: 'Email',
                  icon: Icons.email,
                ),
                SizedBox(height: 16),
                // Input Password
                _buildTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  icon: Icons.lock,
                  obscureText: true,
                ),
                SizedBox(height: 24),
                // Tombol Login
                ElevatedButton(
                  onPressed: () => controller.loginUser(
                    emailController.text,
                    passwordController.text,
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepOrange.shade900,
                  ),
                ),
                SizedBox(height: 16),
                // Divider dengan teks "or"
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'or',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white)),
                  ],
                ),
                SizedBox(height: 16),
                // Tombol Login dengan Google
                ElevatedButton(
                  onPressed: () {
                    // Integrasi login Google di sini
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0, // Menghilangkan bayangan
                    backgroundColor: Colors.white, // Warna latar belakang putih
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18), // Radius untuk tombol
                      side: BorderSide(color: Colors.grey.shade300), // Border abu-abu terang
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Sesuaikan dengan konten
                    children: [
                      Image.asset(
                        'assets/images/google.png', // Masukkan gambar logo Google di folder assets
                        height: 24, // Ukuran ikon
                        width: 24,
                      ),
                      SizedBox(width: 10), // Jarak antara logo dan teks
                      Text(
                        'Login with Google',
                        style: TextStyle(
                          color: Colors.black, // Teks berwarna hitam
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // Tombol Register
                TextButton(
                  onPressed: () => Get.toNamed(Routes.REGISTER),
                  child: Text(
                    'Don\'t have an account? Register',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Fungsi untuk membuat TextField dengan style seragam
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
        prefixIcon: Icon(icon, color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
      ),
      style: TextStyle(color: Colors.white),
      obscureText: obscureText,
      keyboardType: hintText == 'Email' ? TextInputType.emailAddress : TextInputType.text,
    );
  }
}
