import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_app/app/modules/home/controllers/home_controller.dart';
import 'package:recipe_app/app/modules/home/views/recipe_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:recipe_app/app/routes/app_pages.dart';
import 'package:recipe_app/app/modules/favorite/controllers/favorite_controller.dart'; // Import FavoriteController
import 'package:iconsax/iconsax.dart';

class PreviewQuickFast extends StatelessWidget {
  final String currentCategory; // Accept the currentCategory as a parameter

  const PreviewQuickFast({Key? key, required this.currentCategory})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();
    final FavoriteController favoriteController =
        Get.find<FavoriteController>(); // FavoriteController instance
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Categories section
        Obx(() {
          if (controller.categories.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.categories.length,
              itemBuilder: (context, index) {
                final category = controller.categories[index];
                final isActive = currentCategory ==
                    category[
                        'strCategory']; // Use the currentCategory parameter

                return GestureDetector(
                  onTap: () {
                    controller.setActiveCategory(category['strCategory']);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: isActive ? Colors.orange : Colors.white,
                      border: Border.all(
                        color: isActive ? Colors.orange : Colors.grey.shade300,
                        width: 1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                  color: Colors.orange.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3))
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        category['strCategory'] == 'All'
                            ? const FaIcon(
                                FontAwesomeIcons
                                    .utensils, // Ikon garpu dan sendok
                                size: 50.0, // Ukuran ikon
                                color: Colors.white, // Warna ikon
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    15), // Menambahkan border radius ke gambar
                                child: Image.network(
                                  category['strCategoryThumb'],
                                  height: 50,
                                  width: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.error,
                                    size: 50,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                        const SizedBox(height: 5),
                        Text(
                          category['strCategory'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),

        const SizedBox(height: 20),

        // Quick & Fast Meals section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Quick & Fast",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            OutlinedButton(
              onPressed: () => Get.toNamed(
                Routes.VIEW_ALL,
                parameters: {'category': controller.currentCategory.value},
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: primaryColor),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                "View all",
                style: TextStyle(color: primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Horizontal scroll for meals
        Obx(() {
          if (controller.filteredMeals.isEmpty) {
            return const Center(
                child: Text("No meals available for this category."));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                controller.filteredMeals.length,
                (index) {
                  final meal = controller.filteredMeals[index];

                  return GestureDetector(
                    onTap: () => Get.to(RecipeView(food: meal)),
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 15),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Meal Image
                            Container(
                              height: 130,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15)),
                                image: DecorationImage(
                                  image:
                                      NetworkImage(meal['strMealThumb'] ?? ''),
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
                                      onPressed: () {
                                        // Ensure the meal object is valid before toggling favorite
                                        if (meal is Map<String, dynamic> &&
                                            meal['idMeal'] != null) {
                                          favoriteController.toggleFavorite(
                                              meal); // Pass the entire meal object
                                        } else {
                                          print(
                                              'Error: Invalid meal or missing idMeal'); // Debug log for invalid meal
                                        }
                                      },
                                      icon: Obx(() {
                                        // Observe the favorite status using Obx to update the icon dynamically
                                        final isFavorite = favoriteController
                                            .isFavorite(meal['idMeal']);
                                        return Icon(
                                          isFavorite
                                              ? Iconsax.heart5
                                              : Iconsax
                                                  .heart, // Show filled or outlined heart icon based on favorite status
                                          color: Theme.of(context).primaryColor,
                                        );
                                      }),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.white, // Set the heart icon background color to white
                                        fixedSize: const Size(30, 30),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Meal Title
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                meal['strMeal'] ?? 'Unknown Meal',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Calories and Time (stacked vertically)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Iconsax.flash_1,
                                          size: 18, color: Colors.grey),
                                      const SizedBox(width: 5),
                                      Text(
                                        meal['calories'] != null
                                            ? "${meal['calories']} Cal"
                                            : "Unknown Cal",
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(Iconsax.clock,
                                          size: 18, color: Colors.grey),
                                      const SizedBox(width: 5),
                                      Text(
                                        meal['time'] != null
                                            ? "${meal['time']} Min"
                                            : "Unknown Time",
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
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
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }
}
