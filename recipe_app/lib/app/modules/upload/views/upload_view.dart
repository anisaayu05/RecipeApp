import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/upload_controller.dart';
import 'my_recipe_view.dart';

class UploadView extends StatelessWidget {
  const UploadView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uploadController = Get.find<UploadController>();
    final primaryColor = Theme.of(context).primaryColor;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Recipes'),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Create Recipe'),
              Tab(text: 'My Recipes'),
            ],
            labelColor: Colors.black,
            indicatorColor: Colors.black,
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _buildCreateRecipeTab(uploadController, primaryColor),
              _buildMyRecipesTab(uploadController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateRecipeTab(
      UploadController uploadController, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            return _buildImagePicker(uploadController);
          }),
          const SizedBox(height: 24),
          _buildTextField(
            controller: uploadController.mealNameController,
            label: 'Meal Name',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: uploadController.caloriesController,
            label: 'Calories',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: uploadController.timeController,
            label: 'Preparation Time (mins)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildDropdownField(
                      label: 'Category',
                      value: uploadController.selectedCategory.value,
                      items: uploadController.categories,
                      onChanged: (value) =>
                          uploadController.selectedCategory.value = value ?? '',
                    )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(() => _buildDropdownField(
                      label: 'Area',
                      value: uploadController.selectedArea.value,
                      items: uploadController.areas,
                      onChanged: (value) =>
                          uploadController.selectedArea.value = value ?? '',
                    )),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Ingredients'),
          const SizedBox(height: 8),
          Obx(() => _buildIngredientList(uploadController)),
          const SizedBox(height: 16),
          _buildAddIngredientFields(uploadController),
          const SizedBox(height: 24),
          _buildSectionTitle('Instructions'),
          const SizedBox(height: 8),
          Obx(() => _buildInstructionList(uploadController)),
          const SizedBox(height: 16),
          _buildAddInstructionField(uploadController),
          const SizedBox(height: 24),
          _buildTextField(
            controller: uploadController.tagsController,
            label: 'Tags (Optional)',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: uploadController.youtubeLinkController,
            label: 'YouTube Link (Optional)',
          ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                final mealId = uploadController.mealNameController
                    .text; // Buat ID unik atau gunakan nama meal
                // Unggah gambar dan simpan data meal
                await uploadController.uploadImageToFirebase(mealId);
                uploadController.saveMeal();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Save Recipe',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildImagePicker(UploadController controller) {
    return GestureDetector(
      onTap: () async {
        // Hanya menyimpan path lokal, tidak mengunggah ke Firebase
        await controller.pickImage();
      },
      child: DottedBorder(
        color: Colors.grey.shade400,
        strokeWidth: 1,
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        dashPattern: const [6, 4],
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade100,
          ),
          child: controller.imageUrl.value != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(controller
                        .imageUrl.value!), // Menampilkan gambar dari file lokal
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined,
                        size: 48, color: Colors.grey.shade600),
                    const SizedBox(height: 8),
                    Text('Tap to add a photo',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMyRecipesTab(UploadController uploadController) {
    return Obx(() {
      final savedMeals = uploadController.savedMeals;
      if (savedMeals.isEmpty) {
        return const Center(child: Text('No recipes saved.'));
      }
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: savedMeals.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final meal = savedMeals[index];
            return GestureDetector(
              onTap: () {
                Get.to(() => MyRecipeView(mealId: meal['idMeal']));
              },
              child: _buildRecipeCard(
                  meal, uploadController), // Tambahkan uploadController
            );
          },
        ),
      );
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(Get.context!).primaryColor),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(Get.context!).primaryColor),
        ),
      ),
      value: value.isEmpty ? null : value,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildIngredientList(UploadController controller) {
    return Column(
      children: controller.ingredients.map((ingredient) {
        int index = controller.ingredients.indexOf(ingredient);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Image.network(
            Uri.encodeFull(
                ingredient['image']), // Ensure URL encoding for Firebase URLs
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.image_not_supported, color: Colors.red);
            },
            fit: BoxFit.cover,
          ),
          title: Text(
            '- ${ingredient['ingredient']} (${ingredient['measure']})',
            style: TextStyle(color: Colors.grey.shade800),
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
            onPressed: () => controller.removeIngredient(index),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddIngredientFields(UploadController controller) {
    final primaryColor = Theme.of(Get.context!).primaryColor;
    return Column(
      children: [
        _buildAutoCompleteField(
          controller: controller.currentIngredientNameController,
          label: 'Ingredient',
          suggestions: controller.ingredientList,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.currentMeasureController,
          label: 'Measure',
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: controller.addIngredient,
          icon: const Icon(Icons.add),
          label: const Text('Add Ingredient'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionList(UploadController controller) {
    return Column(
      children: controller.instructions.map((instruction) {
        int index = controller.instructions.indexOf(instruction);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            '${index + 1}. $instruction',
            style: TextStyle(color: Colors.grey.shade800),
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
            onPressed: () => controller.removeInstruction(index),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddInstructionField(UploadController controller) {
    final primaryColor = Theme.of(Get.context!).primaryColor;
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: controller.currentInstructionController,
            label: 'Instruction',
          ),
        ),
        IconButton(
          icon: Icon(Icons.add_circle, color: primaryColor),
          onPressed: controller.addInstruction,
        ),
      ],
    );
  }

  Widget _buildAutoCompleteField({
    required TextEditingController controller,
    required String label,
    required List<String> suggestions,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        } else {
          return suggestions.where((suggestion) => suggestion
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase()));
        }
      },
      onSelected: (String selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey.shade700),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: Theme.of(Get.context!).primaryColor),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecipeCard(
      Map<String, dynamic> meal, UploadController controller) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  image: DecorationImage(
                    image: meal['strMealThumb'] != null &&
                            meal['strMealThumb'] is String
                        ? NetworkImage(meal['strMealThumb'])
                        : AssetImage('assets/placeholder.png') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await controller.deleteMeal(
                        meal['idMeal'], meal['strMealThumb']);
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal['strMeal'] ?? 'No Name',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'Calories: ${meal['strCalories'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'Time: ${meal['strTime'] ?? 'N/A'} mins',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
