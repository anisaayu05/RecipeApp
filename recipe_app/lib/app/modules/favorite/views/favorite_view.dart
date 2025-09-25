import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_app/app/modules/favorite/controllers/favorite_controller.dart';
import 'package:recipe_app/app/modules/home/views/recipe_view.dart';
import 'package:iconsax/iconsax.dart';
import 'package:recipe_app/app/widgets/custom_bottom_nav_bar.dart';

class FavoriteView extends GetView<FavoriteController> {
  const FavoriteView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Disable the back button
        centerTitle: true, // Center the title text
        title: Text(
          'Favorite Recipes',
          style: TextStyle(color: primaryColor), // Change the text color to primaryColor
        ),
        backgroundColor: Colors.white, // White background for AppBar
        elevation: 0, // Remove AppBar shadow
      ),
      body: Obx(() {
        if (controller.favoriteMeals.isEmpty) {
          return const Center(
            child: Text(
              'No favorite meals yet.',
              style: TextStyle(fontSize: 18),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: controller.favoriteMeals.length,
          itemBuilder: (context, index) {
            final meal = controller.favoriteMeals[index];
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
                    // Meal Image with favorite icon
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
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white, // Set the heart icon background color to white
                                  fixedSize: const Size(30, 30),
                                ),
                                icon: Icon(
                                  Iconsax.heart5, // Display the filled heart icon
                                  color: Theme.of(context).primaryColor,
                                ),
                                onPressed: () => controller.toggleFavorite(meal), // Toggle favorite status
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
      bottomNavigationBar: CustomBottomNavBar(), // Custom Bottom Navigation
    );
  }
}
