import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../controllers/upload_controller.dart';

class MyRecipeView extends StatefulWidget {
  final String mealId;

  const MyRecipeView({Key? key, required this.mealId}) : super(key: key);

  @override
  State<MyRecipeView> createState() => _MyRecipeViewState();
}

class _MyRecipeViewState extends State<MyRecipeView> {
  final UploadController uploadController = Get.find<UploadController>();

  final RxBool isEditing = false.obs;

  final RxBool isSaving = false.obs;

  final TextEditingController mealNameController = TextEditingController();

  File? pickedImage;

  List<Map<String, dynamic>> ingredients = [];
  List<String> instructions = [];

  final List<TextEditingController> ingredientNameControllers = [];
  final List<TextEditingController> ingredientMeasureControllers = [];
  final List<TextEditingController> instructionControllers = [];

  bool _initializedFromRemote = false;
  Map<String, dynamic> _cachedMeal = {};

  @override
  void initState() {
    super.initState();
    _loadMeal();
  }

  Future<void> _loadMeal() async {
    final box = GetStorage();
    final meal = await _fetchMealData(box);
    setState(() {
      _initFromMeal(meal);
    });
  }

  @override
  void dispose() {
    mealNameController.dispose();
    for (final c in ingredientNameControllers) {
      c.dispose();
    }
    for (final c in ingredientMeasureControllers) {
      c.dispose();
    }
    for (final c in instructionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  BoxDecoration pillDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          offset: const Offset(0, 2),
          blurRadius: 4,
        ),
      ],
    );
  }

  void _initFromMeal(Map<String, dynamic> meal) {
    if (_initializedFromRemote) return;
    _cachedMeal = Map<String, dynamic>.from(meal);

     // --- INGREDIENTS ---
  ingredients = [];
  for (final c in ingredientNameControllers) c.dispose();
  for (final c in ingredientMeasureControllers) c.dispose();
  ingredientNameControllers.clear();
  ingredientMeasureControllers.clear();

  final rawIng = meal['ingredients'];
  if (rawIng is List) {
    for (final e in rawIng) {
      final ing = {
        'ingredient': (e['ingredient'] ?? '').toString(),
        'measure': (e['measure'] ?? '').toString(),
      };
      ingredients.add(ing);
      ingredientNameControllers.add(TextEditingController(text: ing['ingredient']));
      ingredientMeasureControllers.add(TextEditingController(text: ing['measure']));
    }
  }

  if (ingredients.isEmpty) {
    ingredients.add({'ingredient': '', 'measure': ''});
    ingredientNameControllers.add(TextEditingController());
    ingredientMeasureControllers.add(TextEditingController());
  }

  // --- INSTRUCTIONS ---
  instructions = [];
  for (final c in instructionControllers) c.dispose();
  instructionControllers.clear();

  if (meal['instructions'] is List) {
    instructions = List<String>.from(meal['instructions']);
  } else {
    final rawInstr = (meal['strInstructions'] as String?) ?? (meal['instructions'] as String? ?? '');
    instructions = rawInstr
        .split(RegExp(r"\r?\n"))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  if (instructions.isEmpty) instructions = [''];
  for (final ins in instructions) {
    instructionControllers.add(TextEditingController(text: ins));
  }

  mealNameController.text = meal['strMeal'] ?? '';

  _initializedFromRemote = true;
}

  void _enterEditMode() {
    if (ingredientNameControllers.length != ingredients.length) {
      for (final c in ingredientNameControllers) c.dispose();
      for (final c in ingredientMeasureControllers) c.dispose();
      ingredientNameControllers.clear();
      ingredientMeasureControllers.clear();
      for (final ing in ingredients) {
        ingredientNameControllers.add(TextEditingController(text: ing['ingredient']));
        ingredientMeasureControllers.add(TextEditingController(text: ing['measure']));
      }
    }
    if (instructionControllers.length != instructions.length) {
      for (final c in instructionControllers) c.dispose();
      instructionControllers.clear();
      for (final ins in instructions) {
        instructionControllers.add(TextEditingController(text: ins));
      }
    }

    isEditing.value = true;
  }

  // cancel editing: restore controllers to cached meal values
  void _cancelEdit() {
    _applyControllersToModel(); // optional: backup current state
    ingredientNameControllers.clear();
    ingredientMeasureControllers.clear();
    instructionControllers.clear();

    // restore dari cache
    if (_cachedMeal.isNotEmpty) {
      final rawIng = _cachedMeal['ingredients'] ?? [];
      for (final e in rawIng) {
        ingredientNameControllers.add(TextEditingController(text: e['ingredient'] ?? ''));
        ingredientMeasureControllers.add(TextEditingController(text: e['measure'] ?? ''));
      }

      final rawInstr = _cachedMeal['instructions'] ?? (_cachedMeal['strInstructions'] as String?)?.split('\n') ?? [''];
      for (final ins in rawInstr) {
        instructionControllers.add(TextEditingController(text: ins));
      }

      mealNameController.text = _cachedMeal['strMeal'] ?? '';
    }

    isEditing.value = false;
    setState(() {});
  }

  // apply controllers back to arrays (before saving)
  void _applyControllersToModel() {
    ingredients = [];
    for (var i = 0; i < ingredientNameControllers.length; i++) {
      final name = ingredientNameControllers[i].text.trim();
      final measure = (i < ingredientMeasureControllers.length) ? ingredientMeasureControllers[i].text.trim() : '';
      if (name.isEmpty && measure.isEmpty) continue; // skip empty
      ingredients.add({'ingredient': name, 'measure': measure});
    }

    instructions = instructionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    // keep at least one empty instruction to show placeholder if completely empty
    if (instructions.isEmpty) instructions = [''];
  }

  Future<void> _saveRecipe() async {
  isSaving.value = true;
  try {
    _applyControllersToModel();

    if (pickedImage != null) {
      await uploadController.updateImage(
        widget.mealId,
        pickedImage!,
        oldImageUrl: _cachedMeal['strMealThumb'] as String?,
      );
    }

    await uploadController.updateMealName(widget.mealId, mealNameController.text.trim());
    await uploadController.updateIngredients(widget.mealId, ingredients);
    await uploadController.updateInstructions(widget.mealId, instructions);

    final fresh = await _fetchMealData(GetStorage());
    setState(() => _cachedMeal = fresh);

    isEditing.value = false;

    for (final c in ingredientNameControllers) c.dispose();
    for (final c in ingredientMeasureControllers) c.dispose();
    for (final c in instructionControllers) c.dispose();
    ingredientNameControllers.clear();
    ingredientMeasureControllers.clear();
    instructionControllers.clear();

    Get.snackbar('Success', 'Recipe updated successfully', backgroundColor: Colors.white, colorText: Colors.black);
  } catch (e) {
    Get.snackbar('Error', 'Failed to update recipe: $e', backgroundColor: Colors.white, colorText: Colors.black);
  } finally {
    isSaving.value = false;
  }
}


  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFE8A6D),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFE8A6D),
        elevation: 0,
        centerTitle: true,
        title: const Text('Recipes', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: _cachedMeal.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo area
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                            child: Container(
                              color: const Color(0xFFFE8A6D),
                              child: pickedImage != null
                                  ? Image.file(pickedImage!, width: double.infinity, height: 260, fit: BoxFit.cover)
                                  : (_cachedMeal['strMealThumb'] != null
                                      ? Image.network(
                                          _cachedMeal['strMealThumb'],
                                          width: double.infinity,
                                          height: 260,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => _emptyPhotoBox(screenW),
                                        )
                                      : _emptyPhotoBox(screenW)),
                            ),
                          ),
                          Obx(() => isEditing.value
                              ? Positioned.fill(
                                  child: Material(
                                    color: Colors.black26,
                                    child: InkWell(
                                      onTap: () async {
                                        final File? newImage = await uploadController.pickImage();
                                        if (newImage != null) {
                                          setState(() {
                                            pickedImage = newImage;
                                          });
                                        }
                                      },
                                      child: Center(
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: Colors.white70,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.camera_alt, size: 40, color: Colors.black87),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Meal Name
                    Obx(() {
                      if (isEditing.value) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: pillDecoration(color: Colors.white),
                              child: TextField(
                                controller: mealNameController,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(border: InputBorder.none, hintText: 'Meal Name'),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                decoration: pillDecoration(color: Colors.white),
                                child: Row(
                                  children: [
                                    const Icon(Icons.restaurant_menu, color: Colors.orange),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        mealNameController.text.isNotEmpty ? mealNameController.text : (_cachedMeal['strMeal'] ?? 'No name'),
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: _enterEditMode,
                            ),
                          ],
                        );
                      }
                    }),
                    const SizedBox(height: 12),
                    // Calories & Time
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: pillDecoration(color: Colors.white),
                            child: Row(
                              children: [
                                const Icon(Icons.local_fire_department, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _cachedMeal['strCalories'] != null && _cachedMeal['strCalories'].toString().isNotEmpty
                                        ? '${_cachedMeal['strCalories']}'
                                        : 'Calories',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: pillDecoration(color: Colors.white),
                            child: Row(
                              children: [
                                const Icon(Icons.timer, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _cachedMeal['strTime'] != null && _cachedMeal['strTime'].toString().isNotEmpty
                                        ? '${_cachedMeal['strTime']} mins'
                                        : 'Time',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Ingredients Header
                    const Text('Ingredients', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Obx(() {
                      if (isEditing.value) {
                        return Column(
                          children: [
                            ...List.generate(ingredientNameControllers.length, (idx) {
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: pillDecoration(color: Colors.white),
                                child: Row(
                                  children: [
                                    _ingredientCircle(ingredientNameControllers[idx].text),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          TextField(
                                            controller: ingredientNameControllers[idx],
                                            decoration: const InputDecoration(border: InputBorder.none, hintText: 'Ingredient name'),
                                          ),
                                          const SizedBox(height: 6),
                                          TextField(
                                            controller: ingredientMeasureControllers[idx],
                                            decoration: const InputDecoration(border: InputBorder.none, hintText: 'Measure (e.g. 2 tbsp)'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              ingredientNameControllers[idx].dispose();
                                              ingredientMeasureControllers[idx].dispose();
                                              ingredientNameControllers.removeAt(idx);
                                              ingredientMeasureControllers.removeAt(idx);
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, color: Colors.green),
                                          onPressed: () {
                                            setState(() {
                                              ingredientNameControllers.add(TextEditingController());
                                              ingredientMeasureControllers.add(TextEditingController());
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.3))),
                                onPressed: () {
                                  setState(() {
                                    ingredientNameControllers.add(TextEditingController());
                                    ingredientMeasureControllers.add(TextEditingController());
                                  });
                                },
                                child: const Text('Add Ingredient', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: ingredients.map((ing) {
                            final name = (ing['ingredient'] ?? '').toString();
                            final measure = (ing['measure'] ?? '').toString();
                            return Container(
                              width: (screenW - 64) / 3,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _ingredientCircle(name),
                                  const SizedBox(height: 8),
                                  Text(name.isNotEmpty ? name : '-', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                  const SizedBox(height: 6),
                                  Text(measure.isNotEmpty ? measure : '', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      }
                    }),
                    const SizedBox(height: 12),
                    // Instructions
                    const Text('Instructions', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Obx(() {
                      if (isEditing.value) {
                        return Column(
                          children: [
                            ...List.generate(instructionControllers.length, (idx) {
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: pillDecoration(color: Colors.white),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.orange,
                                      child: Text(
                                        '${idx + 1}',
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              offset: const Offset(0, 2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: TextField(
                                          controller: instructionControllers[idx],
                                          maxLines: null,
                                          style: const TextStyle(fontSize: 14),
                                          decoration: const InputDecoration(
                                            hintText: 'Instruction',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              instructionControllers[idx].dispose();
                                              instructionControllers.removeAt(idx);
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, color: Colors.green),
                                          onPressed: () {
                                            setState(() {
                                              instructionControllers.add(TextEditingController());
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.3))),
                                onPressed: () {
                                  setState(() {
                                    instructionControllers.add(TextEditingController());
                                  });
                                },
                                child: const Text('Add Instruction', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // <-- Tambahkan Obx Save & Cancel di sini -->
                            Obx(() {
                              if (!isEditing.value) return const SizedBox.shrink();

                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                                          onPressed: isSaving.value ? null : _saveRecipe,
                                          child: isSaving.value
                                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator())
                                              : const Text('Save', style: TextStyle(color: Color(0xFFFE8A6D))),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.3))),
                                          onPressed: _cancelEdit,
                                          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              );
                            }),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(instructions.length, (idx) {
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    offset: const Offset(0, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.orange,
                                    child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      instructions[idx],
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        );
                      }
                    }),
                    const SizedBox(height: 12),
                    if (_cachedMeal['strTags'] != null &&
                      _cachedMeal['strTags'].toString().trim().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: pillDecoration(color: Colors.white),
                      child: Row(
                        children: [
                          const Icon(Icons.tag, color: Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _cachedMeal['strTags'],
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_cachedMeal['strYoutube'] != null &&
                      _cachedMeal['strYoutube'].toString().trim().isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        // buka link youtube
                        final url = _cachedMeal['strYoutube'];
                        uploadController.launchYoutubeUrl(url); // bikin function di controller
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: pillDecoration(color: Colors.white),
                        child: Row(
                          children: [
                            const Icon(Icons.play_circle_fill, color: Colors.red),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Watch on YouTube",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // builds the dashed/placeholder photo box
  Widget _emptyPhotoBox(double width) {
    return Container(
      width: double.infinity,
      height: 260,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      color: const Color(0xFFFE8A6D),
      child: Center(
        child: Container(
          width: width - 60,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white, width: 2, style: BorderStyle.solid),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.camera_alt_outlined, size: 48, color: Colors.white70),
                SizedBox(height: 8),
                Text('Tap to add a photo', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Ingredient image circle
  Widget _ingredientCircle(String? ingredient) {
    final name = (ingredient ?? '').trim();
    if (name.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(color: Color(0xFFF6F6F6), shape: BoxShape.circle),
        child: const Icon(Icons.kitchen, color: Colors.orange),
      );
    }

    final encoded = Uri.encodeComponent(name);
    final ingredientImageUrl = 'https://www.themealdb.com/images/ingredients/$encoded.png';

    return ClipOval(
      child: Container(
        width: 48,
        height: 48,
        color: Colors.white,
        child: Image.network(
          ingredientImageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFF6F6F6),
              child: const Icon(Icons.kitchen, color: Colors.orange),
            );
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchMealData(GetStorage box) async {
    final isConnected = await uploadController.checkInternetConnection();
    if (isConnected) {
      final snapshot = await FirebaseFirestore.instance.collection('meals').doc(widget.mealId).get();
      return snapshot.data() ?? {};
    } else {
      final localMeal = box.read('pendingMeal');
      if (localMeal != null) {
        return json.decode(localMeal) as Map<String, dynamic>;
      } else {
        throw Exception('No meal data available locally.');
      }
    }
  }

  void _confirmDelete(BuildContext context) {
  Get.defaultDialog(
    title: 'Confirm Delete',
    middleText: 'Are you sure you want to delete this recipe?',
    contentPadding: const EdgeInsets.all(20),
    actions: [
      Expanded(
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          onPressed: () => Get.back(),
          child: const Text(
            'No',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      const SizedBox(width: 10), // jarak antar tombol
      Expanded(
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          onPressed: () async {
            final isConnected = await uploadController.checkInternetConnection();
            if (isConnected) {
              await uploadController.deleteMeal(widget.mealId, null);
            } else {
              await uploadController.deleteMealLocallyAndUI(widget.mealId);
            }
            Get.back();
            Get.back();
          },
          child: const Text(
            'Yes',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    ],
  );
}
}
