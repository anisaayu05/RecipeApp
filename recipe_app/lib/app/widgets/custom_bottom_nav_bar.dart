import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:recipe_app/app/modules/home/controllers/auth_controller.dart';
import 'package:recipe_app/app/modules/home/controllers/home_controller.dart';

class CustomBottomNavBar extends StatelessWidget {
  final HomeController controller = Get.put(HomeController());
  final AuthController authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Obx(() {
      return BottomNavigationBar(
        currentIndex: controller.currentIndex.value, // Set current index
        onTap: (index) {
          // Perbarui currentIndex dengan tab yang dipilih
          controller.changeTabIndex(index); 

          // Navigasi tergantung status login
          if (authController.isLoggedIn.value) {
            switch (index) {
              case 0:
                Get.toNamed('/home-login'); // Jika sudah login
                break;
              case 1:
                Get.toNamed('/favorite-login');
                break;
              case 2:
                Get.toNamed('/upload-login');
                break;
              case 3:
                Get.toNamed('/mealplan-login');
                break;
              case 4:
                Get.toNamed('/profile-login');
                break;
              default:
                Get.toNamed('/home-login'); // Default jika index tidak ditemukan
                break;
            }
          } else {
            switch (index) {
              case 0:
                Get.toNamed('/home'); // Jika belum login
                break;
              case 1:
                Get.toNamed('/favorite');
                break;
              case 2:
                Get.toNamed('/upload');
                break;
              case 3:
                Get.toNamed('/meal-plan');
                break;
              case 4:
                Get.toNamed('/profile');
                break;
              default:
                Get.toNamed('/home'); // Default jika index tidak ditemukan
                break;
            }
          }
        },
        selectedItemColor: primaryColor, // Warna icon yang aktif
        unselectedItemColor: Colors.grey, // Warna icon yang tidak aktif
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 10), // Padding di atas ikon
              child: Icon(Iconsax.home),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 10), // Padding di atas ikon
              child: Icon(Iconsax.heart),
            ),
            label: 'Favorite',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 10), // Padding di atas ikon
              child: Icon(Iconsax.add_circle),
            ),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 10), // Padding di atas ikon
              child: Icon(Iconsax.note),
            ),
            label: 'Meal Plan',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 10), // Padding di atas ikon
              child: Icon(Iconsax.profile_circle),
            ),
            label: 'Profile',
          ),
        ],
        selectedLabelStyle: const TextStyle(fontSize: 12), // Gaya label saat aktif
        unselectedLabelStyle: const TextStyle(fontSize: 12), // Gaya label saat tidak aktif
        iconSize: 28,
        showUnselectedLabels: true, // Menampilkan label untuk ikon yang tidak aktif
      );
    });
  }
}
