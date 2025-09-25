import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/upload_controller.dart';

class MyRecipeView extends StatelessWidget {
  final String mealId;
  final RxBool isEditingName = false.obs;
  final TextEditingController mealNameController = TextEditingController();
  final RxInt servings = 1.obs;

  MyRecipeView({Key? key, required this.mealId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UploadController uploadController = Get.find<UploadController>();

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('meals')
            .doc(mealId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No data available.'));
          }

          final meal = snapshot.data!.data() as Map<String, dynamic>;
          final ingredients = meal['ingredients'] as List<dynamic>? ?? [];
          final instructions =
              (meal['strInstructions'] as String?)?.split('\n') ?? [];
          final imageUrl = meal['strMealThumb'] ?? null;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image_not_supported,
                                    color: Colors.red);
                              },
                            )
                          : Image.asset(
                              'assets/placeholder.png',
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      top: 40, // Meningkatkan jarak dari tepi atas
                      right: 20,
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.7),
                        child: IconButton(
                          icon:
                              const Icon(Icons.camera_alt, color: Colors.black),
                          onPressed: () async {
                            final oldImageUrl = meal['strMealThumb'];
                            await uploadController.updateImage(
                                mealId, oldImageUrl);
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40, // Meningkatkan jarak dari tepi atas
                      left: 20,
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.7),
                        child: IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Get.back(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Obx(() {
                    if (isEditingName.value) {
                      mealNameController.text = meal['strMeal'] ?? 'No Name';
                      return TextField(
                        controller: mealNameController,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Edit Meal Name',
                        ),
                        onSubmitted: (newName) async {
                          await FirebaseFirestore.instance
                              .collection('meals')
                              .doc(mealId)
                              .update({'strMeal': newName});
                          isEditingName.value = false;
                        },
                      );
                    } else {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            meal['strMeal'] ?? 'No Name',
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey),
                            onPressed: () {
                              isEditingName.value = true;
                            },
                          ),
                        ],
                      );
                    }
                  }),
                ),
                const SizedBox(height: 8),
                // Calories and Time Info in minimal style
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flash_on,
                              size: 20, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text(
                            meal['strCalories'] != null &&
                                    meal['strCalories']!.isNotEmpty
                                ? "${meal['strCalories']} Calories"
                                : "Calories info not available",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 20, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text(
                            meal['strTime'] != null &&
                                    meal['strTime']!.isNotEmpty
                                ? "${meal['strTime']} Min"
                                : "Time info not available",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
                    'Ingredients',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: ingredients.map<Widget>((ingredient) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              // Ingredient image
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  image: DecorationImage(
                                    image: NetworkImage(ingredient['image']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Ingredient name
                              Expanded(
                                child: Text(
                                  ingredient['ingredient'] ?? 'Unknown',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              // Ingredient measure
                              Text(
                                '${ingredient['measure']} x${servings.value}',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
                    'Instructions',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: instructions.map((instruction) {
                      final index = instructions.indexOf(instruction) + 1;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Step number in a rounded background
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$index',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Step instruction text
                            Expanded(
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    instruction,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
