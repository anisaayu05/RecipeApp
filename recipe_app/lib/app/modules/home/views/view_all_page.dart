import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_app/app/modules/home/controllers/home_controller.dart';
import 'package:recipe_app/app/modules/favorite/controllers/favorite_controller.dart'; // Import FavoriteController
import 'package:recipe_app/app/modules/home/views/recipe_view.dart';
import 'package:iconsax/iconsax.dart';

class ViewAllPage extends StatelessWidget {
  final String categoryName; // Parameter untuk kategori yang aktif

  const ViewAllPage({Key? key, required this.categoryName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();
    final FavoriteController favoriteController = Get.find<FavoriteController>(); // Get instance of FavoriteController
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          categoryName, // Menampilkan nama kategori di AppBar
          style: TextStyle(color: primaryColor), // Mengatur warna teks sesuai primaryColor
        ),
        backgroundColor: Colors.white, // Latar belakang AppBar putih
        iconTheme: IconThemeData(color: primaryColor), // Warna ikon sesuai dengan primaryColor
        elevation: 0, // Opsional, menghilangkan shadow AppBar jika diinginkan
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Obx(() {
          if (controller.filteredMeals.isEmpty) {
            return const Center(child: Text("No meals available for this category."));
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Jumlah kolom dalam grid
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75, // Mengatur rasio grid
            ),
            itemCount: controller.filteredMeals.length,
            itemBuilder: (context, index) {
              final meal = controller.filteredMeals[index];

              return GestureDetector(
                onTap: () => Get.to(RecipeView(food: meal)),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meal Image
                      Flexible(
                        flex: 3,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            image: DecorationImage(
                              image: NetworkImage(meal['strMealThumb'] ?? ''),
                              fit: BoxFit.cover,
                              onError: (error, stackTrace) => const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 50,
                              ),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 1,
                                right: 1,
                                child: IconButton(
                                  style: IconButton.styleFrom( // Mengatur style dari IconButton
                                    backgroundColor: Colors.white, // Set the heart icon background color to white
                                    fixedSize: const Size(30, 30),
                                  ),
                                  onPressed: () {
                                    // Ensure the meal object is valid before toggling favorite
                                    if (meal is Map<String, dynamic> && meal['idMeal'] != null) {
                                      favoriteController.toggleFavorite(meal); // Pass the entire meal object
                                    } else {
                                      print('Error: Invalid meal or missing idMeal');
                                    }
                                  },
                                  icon: Obx(() {
                                    // Observe the favorite status using Obx to update the icon dynamically
                                    final isFavorite = favoriteController.isFavorite(meal['idMeal']);
                                    return Icon(
                                      isFavorite ? Iconsax.heart5 : Iconsax.heart, // Show filled or outlined heart icon
                                      color: Theme.of(context).primaryColor,
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Meal Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          meal['strMeal'] ?? 'Unknown Meal',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Calories and Time (stacked vertically)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Iconsax.flash_1, size: 18, color: Colors.grey),
                                const SizedBox(width: 5),
                                Text(
                                  meal['calories'] != null ? "${meal['calories']} Cal" : "Unknown Cal",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Iconsax.clock, size: 18, color: Colors.grey),
                                const SizedBox(width: 5),
                                Text(
                                  meal['time'] != null ? "${meal['time']} Min" : "Unknown Time",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
