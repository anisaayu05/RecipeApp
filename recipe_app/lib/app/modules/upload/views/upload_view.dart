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
    Get.put(UploadController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFF7043), Color(0xFFFF8A65)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Recipes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: [
                    Tab(text: 'Create Recipe'),
                    Tab(text: 'My Recipes'),
                  ],
                ),
                const Expanded(
                  child: TabBarView(
                    children: [
                      _CreateRecipeTab(),
                      _MyRecipesMainTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= CREATE RECIPE =================
class _CreateRecipeTab extends StatelessWidget {
  const _CreateRecipeTab();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<UploadController>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => _buildImagePicker(c)),
          const SizedBox(height: 20),

          // Meal Name
          _roundedField(
            controller: c.mealNameController,
            hint: 'Meal Name',
            icon: Icons.fastfood,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 8),
            child: Text(
              'Recipe name must be at least 3 characters long.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),

          // Calories
          _roundedField(
            controller: c.caloriesController,
            hint: 'Calories',
            icon: Icons.local_fire_department,
            type: TextInputType.number,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 8),
            child: Text(
              'Only numeric values are allowed for calories.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),

          // Preparation Time
          _roundedField(
            controller: c.timeController,
            hint: 'Preparation Time (mins)',
            icon: Icons.timer,
            type: TextInputType.number,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 8),
            child: Text(
              'Time must be entered in minutes (numbers only).',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),

          // Category & Area
          Row(
            children: [
              Expanded(
                child: Obx(() => _roundedDropdown(
                      label: 'Category',
                      value: c.selectedCategory.value,
                      items: c.categories,
                      onChanged: (v) => c.selectedCategory.value = v ?? '',
                    )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(() => _roundedDropdown(
                      label: 'Area',
                      value: c.selectedArea.value,
                      items: c.areas,
                      onChanged: (v) => c.selectedArea.value = v ?? '',
                    )),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 8),
            child: Text(
              'Please select both category and area.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),

          // Gluten-free
          Obx(() => GestureDetector(
                onTap: () => c.isGlutenFree.value = !c.isGlutenFree.value,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: c.isGlutenFree.value ? Colors.white : Colors.white70,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c.isGlutenFree.value ? Colors.white : Colors.white70,
                            width: 2,
                          ),
                          color: c.isGlutenFree.value ? Colors.white : Colors.transparent,
                        ),
                        child: c.isGlutenFree.value
                            ? const Icon(Icons.check, color: Color(0xFFFF7043), size: 18)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Is Gluten-Free?",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              )),
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 8),
            child: Text(
              '✅ Check this if your recipe contains no gluten.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),

          // Ingredients & Instructions section tetap sama
          _sectionTitle('Ingredients'),
          Obx(() => _ingredientList(c)),
          const SizedBox(height: 12),
          _addIngredientFields(c),
          const SizedBox(height: 20),

          _sectionTitle('Instructions'),
          Obx(() => _instructionList(c)),
          const SizedBox(height: 12),
          _addInstructionField(c),

          const SizedBox(height: 20),
          _roundedField(controller: c.tagsController, hint: 'Tags (Optional)', icon: Icons.tag),
          const SizedBox(height: 16),
          _roundedField(controller: c.youtubeLinkController, hint: 'YouTube Link (Optional)', icon: Icons.link),
          const SizedBox(height: 32),

          // Save Recipe button tetap sama
          Center(
            child: Obx(() => ElevatedButton(
                  onPressed: c.isLoading.value ? null : () async {
                    if (c.localImagePath.value == null || c.localImagePath.value!.isEmpty) {
                      Get.snackbar('Error', 'Please upload an image before saving.');
                      return;
                    }

                    c.isLoading.value = true;
                    try {
                      await c.saveMeal();
                    } finally {
                      c.isLoading.value = false;
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF7043),
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: c.isLoading.value
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7043)),
                          ),
                        )
                      : const Text(
                          'Save Recipe',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                )),
          )
        ],
      ),
    );
  }
}


// ================= MY RECIPES WITH FILTER =================
class _MyRecipesMainTab extends StatelessWidget {
  const _MyRecipesMainTab();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: const [
          TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Gluten-Free'),
              Tab(text: 'Non Gluten-Free'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _MyRecipesList(filter: 'all'),
                _MyRecipesList(filter: 'gf'),
                _MyRecipesList(filter: 'non'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyRecipesList extends StatelessWidget {
  final String filter;
  const _MyRecipesList({required this.filter});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<UploadController>();
    return Obx(() {
      List<Map<String, dynamic>> data = c.savedMeals;
      if (filter == 'gf') {
        data = data.where((m) => m['strIsGlutenFree'] == true).toList();
      } else if (filter == 'non') {
        data = data.where((m) => m['strIsGlutenFree'] != true).toList();
      }

      if (data.isEmpty) {
        return const Center(
          child: Text('No recipes.', style: TextStyle(color: Colors.white)),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: data.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.62, // dikurangi sedikit supaya muat
          ),
          itemBuilder: (context, i) {
            final meal = data[i];
            return GestureDetector(
              onTap: () => Get.to(() => MyRecipeView(mealId: meal['idMeal'])),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // penting supaya tidak overflow
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        meal['strMealThumb'] ?? '',
                        height: 140, // dikurangi agar muat
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (a, b, c) => Container(
                          height: 140,
                          color: Colors.white24,
                          child: const Icon(Icons.image_not_supported, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      meal['strMeal'] ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Calories: ${meal['strCalories'] ?? 'N/A'}',
                      style: const TextStyle(color: Colors.black87, fontSize: 12),
                    ),
                    Text(
                      'Time: ${meal['strTime'] ?? 'N/A'} mins',
                      style: const TextStyle(color: Colors.black87, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Label Gluten-Free kalau ada
                        if (meal['strIsGlutenFree'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.shade400,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Gluten-Free',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const Spacer(), // pastikan icon di ujung kanan
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 253, 0, 0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.white),
                            onPressed: () => _confirmDelete(context, c, meal['idMeal']),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  void _confirmDelete(BuildContext context, UploadController c, String mealId) {
  Get.defaultDialog(
    title: 'Delete Recipe',
    titleStyle: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 18,
      color: Color(0xFFFF7043),
    ),
    middleText: 'Are you sure you want to delete this recipe?',
    middleTextStyle: const TextStyle(fontSize: 16),
    radius: 20,
    // tombol "No" hijau
    cancel: ElevatedButton(
      onPressed: () => Get.back(), // tetap sama
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('No'),
    ),
    // tombol "Yes" merah
    confirm: ElevatedButton(
      onPressed: () async {
        // Tutup dialog dulu
        Get.back(); 

        // Baru jalankan proses delete
        final isConnected = await c.checkInternetConnection();
        if (isConnected) {
          await c.deleteMeal(mealId, null);
        } else {
          await c.deleteMealLocallyAndUI(mealId);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Yes'),
    ),
  );
}
}

// ================= Helper Widgets =================
Widget _buildImagePicker(UploadController c) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GestureDetector(
        onTap: () async => await c.pickImage(),
        child: DottedBorder(
          color: Colors.white,
          strokeWidth: 1.8,
          borderType: BorderType.RRect,
          radius: const Radius.circular(20),
          dashPattern: const [6, 4],
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(.1),
            ),
            child: (c.localImagePath.value != null && c.localImagePath.value!.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(File(c.localImagePath.value!), fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.camera_alt_outlined, size: 48, color: Colors.white70),
                      SizedBox(height: 8),
                      Text('Tap to add a photo', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
          ),
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Upload image in PNG or JPG format only (max 5MB)',
        style: TextStyle(color: Colors.white70, fontSize: 13),
      ),
    ],
  );
}


Widget _roundedField({
  required TextEditingController controller,
  required String hint,
  IconData? icon,
  TextInputType type = TextInputType.text,
}) {
  return TextField(
    controller: controller,
    keyboardType: type,
    style: const TextStyle(color: Colors.black87),
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFFFF7043)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

Widget _roundedDropdown({
  required String label,
  required String value,
  required List<String> items,
  required ValueChanged<String?> onChanged,
}) {
  return DropdownButtonFormField<String>(
    dropdownColor: Colors.white,
    value: value.isEmpty ? null : value,
    decoration: InputDecoration(
      hintText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
    ),
    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFF7043)),
    items: items
        .map((e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(color: Colors.black87)),
            ))
        .toList(),
    onChanged: onChanged,
  );
}

Widget _sectionTitle(String t) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(t, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
    );

Widget _ingredientList(UploadController c) => Column(
      children: c.ingredients.asMap().entries.map((e) {
        final ing = e.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  Uri.encodeFull(ing['image']),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.redAccent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${e.key + 1}. ${ing['ingredient']} (${ing['measure']})',
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => c.removeIngredient(e.key),
              ),
            ],
          ),
        );
      }).toList(),
    );

Widget _addIngredientFields(UploadController c) => Column(
      children: [
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
            return c.ingredientList.where((s) =>
                s.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (String selection) {
            c.currentIngredientNameController.text = selection;
          },
          fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textController,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Ingredient',
                prefixIcon: const Icon(Icons.kitchen, color: Color(0xFFFF7043)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _roundedField(controller: c.currentMeasureController, hint: 'Measure', icon: Icons.scale),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: c.addIngredient,
          icon: const Icon(Icons.add),
          label: const Text('Add Ingredient'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFFF7043),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      ],
    );

Widget _instructionList(UploadController c) => Column(
      children: c.instructions.asMap().entries.map((e) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${e.key + 1}. ${e.value}',
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => c.removeInstruction(e.key),
              ),
            ],
          ),
        );
      }).toList(),
    );

Widget _addInstructionField(UploadController c) => Row(
      children: [
        Expanded(child: _roundedField(controller: c.currentInstructionController, hint: 'Instruction', icon: Icons.edit)),
        IconButton(icon: const Icon(Icons.add_circle, color: Colors.white), onPressed: c.addInstruction),
      ],
    );
