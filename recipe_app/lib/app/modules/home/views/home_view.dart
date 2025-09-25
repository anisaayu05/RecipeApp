import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_app/app/modules/home/controllers/home_controller.dart';
import 'package:recipe_app/app/modules/home/controllers/search_recipe_app_controller.dart'; // Import SearchRecipeAppController
import 'package:recipe_app/app/modules/home/views/card_menu.dart'; // Menggunakan CardMenu
import 'package:recipe_app/app/modules/home/views/home_appbar.dart';
import 'package:recipe_app/app/modules/home/views/home_search_bar.dart';
import 'package:recipe_app/app/modules/home/views/preview_quick_fast.dart'; // Combine CategoryView and QuickAndFastList
import 'package:recipe_app/app/widgets/custom_bottom_nav_bar.dart';

import '../controllers/location_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final searchController = Get.put(SearchRecipeAppController());
    final PageController _pageController = PageController();
    // Declare currentPage as Rx to make it reactive
    Rx<int> currentPage = 0.obs;

    // Define dark yellow color
    Color darkYellow = Color.fromARGB(255, 255, 0, 0); // Dark Yellow Hex color

    // Mengambil instance dari LocationController
    final locationController = Get.put(LocationController());

    // Fungsi untuk menampilkan dialog dengan informasi alamat lengkap
    void _showAddressDialog(BuildContext context, String locationAddress) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Alamat Lengkap"),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  // Menampilkan alamat lengkap di dalam dialog
                  Text(locationAddress.isEmpty ? "Alamat tidak tersedia" : locationAddress),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  "Tutup",
                  style: TextStyle(color: Colors.white), // Menetapkan warna teks menjadi putih
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Menutup dialog
                },
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const HomeAppbar(),
                const SizedBox(height: 20),
                const HomeSearchBar(),
                const SizedBox(height: 2),

                // Menampilkan lokasi
                Obx(() {
                  return locationController.loading.value
                      ? Center(child: CircularProgressIndicator())
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: GestureDetector(
                            onTap: () {
                              _showAddressDialog(context, locationController.locationAddress.value);
                            },
                            child: Row(
                              children: [
                                Icon(Icons.location_on, color: primaryColor),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    locationController.locationAddress.value.isEmpty
                                        ? "Lokasi tidak tersedia"
                                        : locationController.locationAddress.value,
                                    style: TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                }),

                // Search logic
                Obx(() {
                  if (searchController.isSearching && searchController.filteredMeals.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Search Results",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        CardMenu(meals: searchController.filteredMeals), // Display search results in CardMenu
                      ],
                    );
                  } else if (searchController.isSearching && searchController.filteredMeals.isEmpty) {
                    return const Text(
                      "No results found.",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    );
                  } else {
                    // Default view when there's no search
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Slider (PageView)
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              height: 170,
                              child: PageView(
                                controller: _pageController,
                                onPageChanged: (int page) {
                                  currentPage.value = page; // Update currentPage when page changes
                                },
                                children: [
                                  // First image
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      image: const DecorationImage(
                                        fit: BoxFit.cover,
                                        image: AssetImage("assets/images/recipefood.jpg"),
                                      ),
                                    ),
                                  ),
                                  // Second image
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      image: const DecorationImage(
                                        fit: BoxFit.cover,
                                        image: AssetImage("assets/images/recipefood1.jpg"),
                                      ),
                                    ),
                                  ),
                                  // Third image
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      image: const DecorationImage(
                                        fit: BoxFit.cover,
                                        image: AssetImage("assets/images/recipefood2.jpg"),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Dots Indicators inside the image
                            Positioned(
                              bottom: 10,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (int i = 0; i < 3; i++)
                                    Obx(() => AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          margin: const EdgeInsets.symmetric(horizontal: 5),
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: currentPage.value == i
                                                ? darkYellow // Dark Yellow color for active dot
                                                : Colors.white.withOpacity(0.7),
                                          ),
                                        )),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Categories and Quick & Fast Section combined in PreviewQuickFast
                        Obx(() => PreviewQuickFast(currentCategory: controller.currentCategory.value)),
                      ],
                    );
                  }
                }),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(), // Custom Bottom Navigation
    );
  }
}
