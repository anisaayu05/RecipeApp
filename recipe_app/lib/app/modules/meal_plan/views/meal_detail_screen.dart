import 'package:flutter/material.dart';

class MealDetailScreen extends StatelessWidget {
  final String mealId;
  final String mealName;
  final String mealThumb;
  final String? instructions;
  final String category;
  final String area;
  final List<String> ingredients;
  final List<String> measures;
  final String youtubeUrl;

  MealDetailScreen({
    required this.mealId,
    required this.mealName,
    required this.mealThumb,
    this.instructions,
    required this.category,
    required this.area,
    required this.ingredients,
    required this.measures,
    required this.youtubeUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(mealName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(mealThumb), // Menampilkan gambar makanan
              const SizedBox(height: 10),
              Text(
                'Category: $category',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                'Area: $area',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ingredients:',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildIngredientsList(), // Menampilkan bahan dan ukurannya
              const SizedBox(height: 20),
              const Text(
                'Instructions:',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildInstructionsList(), // Menampilkan instruksi
              const SizedBox(height: 20),
              _buildYoutubeLink(), // Menampilkan link ke video YouTube
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${ingredients[index]} - ${measures[index]}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstructionsList() {
    final List<String> steps = instructions?.split('. ') ?? ['No instructions available.'];
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${index + 1}.', // Menambahkan penomoran
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  steps[index],
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYoutubeLink() {
    return GestureDetector(
      onTap: () {
        // Handle tap to open YouTube link
        // Bisa gunakan url_launcher package untuk membuka video YouTube
      },
      child: Text(
        'Watch on YouTube',
        style: const TextStyle(
          fontSize: 18,
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
