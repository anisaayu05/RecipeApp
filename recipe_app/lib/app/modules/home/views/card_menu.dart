import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_app/app/modules/home/views/recipe_view.dart';
import 'package:recipe_app/app/modules/favorite/controllers/favorite_controller.dart'; // Import FavoriteController
import 'package:iconsax/iconsax.dart';

class CardMenu extends StatelessWidget {
  final List meals; // Tambahkan parameter meals
  final FavoriteController favoriteController = Get.find<FavoriteController>(); // Init FavoriteController

  CardMenu({super.key, required this.meals});

  @override
  Widget build(BuildContext context) {
    if (meals.isEmpty) {
      return const Center(child: Text('No meals available.'));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Jumlah kolom grid
        crossAxisSpacing: 15, // Add more space between cards
        mainAxisSpacing: 15,  // Add more space between cards
        childAspectRatio: 0.75, // Mengatur proporsi card
      ),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];

        return GestureDetector(
          onTap: () => Get.to(RecipeView(food: meal)),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Larger corner radius for a more modern look
            ),
            elevation: 5, // Increase shadow for more depth
            shadowColor: Colors.grey.withOpacity(0.2), // Soft shadow color
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bagian gambar dengan proporsi yang lebih besar
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 10,
                        ),
                      ],
                      image: DecorationImage(
                        image: NetworkImage(meal['strMealThumb']),
                        fit: BoxFit.cover, // Gambar ditampilkan penuh di area
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Ikon heart untuk favorite
                        Positioned(
                          top: 1,
                          right: 1,
                          child: Obx(() {
                            final isFavorite = favoriteController.isFavorite(meal['idMeal']); // Check if meal is favorite
                            return IconButton(
                              onPressed: () {
                                favoriteController.toggleFavorite(meal); // Toggle favorite status with full meal object
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white, // Set the heart icon background color to white
                                fixedSize: const Size(30, 30),
                              ),
                              iconSize: 20,
                              icon: Icon(
                                isFavorite ? Iconsax.heart5 : Iconsax.heart, // Update icon based on favorite status
                                color: Theme.of(context).primaryColor, // Set the heart icon color to primary color
                              ),
                            );
                          }),
                        )
                      ],
                    ),
                  ),
                ),

                // Bagian informasi nama dan detail
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal['strMeal'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),

                        // Flexible layout untuk kalori dan waktu
                        Row(
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  const Icon(Iconsax.flash_1, size: 18, color: Colors.grey),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      meal['calories'] != null
                                          ? "${meal['calories']} Cal"
                                          : "Unknown Cal",
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Row(
                                children: [
                                  const Icon(Iconsax.clock, size: 18, color: Colors.grey),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      meal['time'] != null
                                          ? "${meal['time']} Min"
                                          : "Unknown Time",
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
