import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class UploadController extends GetxController {
  final picker = ImagePicker();

  final mealNameController = TextEditingController();
  final caloriesController = TextEditingController();
  final timeController = TextEditingController();
  final tagsController = TextEditingController();
  final youtubeLinkController = TextEditingController();
  final currentIngredientNameController = TextEditingController();
  final currentMeasureController = TextEditingController();
  final currentInstructionController = TextEditingController();

  Rx<String?> imageUrl = Rx<String?>(null);
  RxList<String> instructions = RxList<String>([]);
  RxList<Map<String, dynamic>> ingredients = RxList<Map<String, dynamic>>([]);

  RxString selectedCategory = ''.obs;
  RxString selectedArea = ''.obs;

  RxList<String> categories = RxList<String>([]);
  RxList<String> areas = RxList<String>([]);
  RxList<String> ingredientList = RxList<String>([]);

  // Mengambil dan menampilkan `savedMeals` langsung dari Firestore
  RxList<Map<String, dynamic>> savedMeals = RxList<Map<String, dynamic>>([]);

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    fetchAreas();
    fetchIngredients();
    loadSavedMealsFromFirestore();
  }

  Future<void> fetchCategories() async {
    final response = await http.get(
        Uri.parse('https://www.themealdb.com/api/json/v1/1/list.php?c=list'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List categoriesData = data['meals'];
      categories.addAll(categoriesData
          .map((category) => category['strCategory'] as String)
          .toList());
    } else {
      Get.snackbar('Error', 'Failed to fetch categories.');
    }
  }

  Future<void> deleteMeal(String mealId, String? imageUrl) async {
    try {
      await FirebaseFirestore.instance.collection('meals').doc(mealId).delete();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await deleteImageFromFirebaseStorage(imageUrl);
      }
      await loadSavedMealsFromFirestore();
      Get.snackbar('Deleted', 'Recipe has been deleted successfully.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete recipe: $e');
    }
  }

  Future<void> deleteImageFromFirebaseStorage(String imageUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error while deleting image from Firebase Storage: $e');
    }
  }

  Future<void> fetchAreas() async {
    final response = await http.get(
        Uri.parse('https://www.themealdb.com/api/json/v1/1/list.php?a=list'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List areasData = data['meals'];
      areas.addAll(areasData.map((area) => area['strArea'] as String).toList());
    } else {
      Get.snackbar('Error', 'Failed to fetch areas.');
    }
  }

  Future<void> fetchIngredients() async {
  final connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) {
    Get.snackbar('Error', 'No internet connection');
    return;
  }

  try {
    final response = await http.get(
      Uri.parse('https://www.themealdb.com/api/json/v1/1/list.php?i=list')
    ).timeout(const Duration(seconds: 10)); // Timeout 10 detik
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List ingredientsData = data['meals'];
      ingredientList.addAll(ingredientsData
          .map((ingredient) => ingredient['strIngredient'] as String)
          .toList());
    } else {
      Get.snackbar('Error', 'Failed to fetch ingredients. Status: ${response.statusCode}');
    }
  } catch (e) {
    Get.snackbar('Error', 'Failed to fetch ingredients. Exception: $e');
  }
}

  // Selalu ambil data `savedMeals` langsung dari Firestore
  Future<void> loadSavedMealsFromFirestore() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('meals')
        .where('type', isEqualTo: 'uploadRecipe') // Filter berdasarkan tipe
        .get();

    final meals = querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['idMeal'] = doc.id;
      return data;
    }).toList();
    savedMeals.value = meals.cast<Map<String, dynamic>>();
  }

  Future<void> pickImage() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        imageUrl.value = pickedFile.path;
      } else {
        Get.snackbar('No Image Selected', 'Please select an image.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e');
    }
  }

  Future<String?> uploadImageToFirebase(String mealId) async {
    if (imageUrl.value == null) {
      Get.snackbar('Error', 'No image selected to upload.');
      return null;
    }

    try {
      final file = File(imageUrl.value!);
      final storageRef =
          FirebaseStorage.instance.ref().child('uploads/$mealId.jpg');

      await storageRef.putFile(file);
      String downloadURL = await storageRef.getDownloadURL();
      return downloadURL;
    } catch (e) {
      Get.snackbar('Upload Error', e.toString());
      return null;
    }
  }

  Future<void> updateImage(String mealId, String? oldImageUrl) async {
    try {
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await deleteImageFromFirebaseStorage(oldImageUrl);
      }

      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        Get.snackbar('No Image Selected', 'Please select an image.');
        return;
      }

      final file = File(pickedFile.path);
      final storageRef =
          FirebaseStorage.instance.ref().child('uploads/$mealId.jpg');
      await storageRef.putFile(file);

      final newImageUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance.collection('meals').doc(mealId).update({
        'strMealThumb': newImageUrl,
      });

      Get.snackbar('Success', 'Recipe image updated successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update recipe image: $e');
    }
  }

  Future<void> addIngredient() async {
    final ingredientName = currentIngredientNameController.text.trim();
    final measure = currentMeasureController.text.trim();

    if (ingredientName.isNotEmpty && measure.isNotEmpty) {
      final ingredientImageUrl =
          'https://www.themealdb.com/images/ingredients/${Uri.encodeComponent(ingredientName)}.png';

      ingredients.add({
        'ingredient': ingredientName,
        'measure': measure,
        'image': ingredientImageUrl,
      });

      currentIngredientNameController.clear();
      currentMeasureController.clear();
    } else {
      Get.snackbar('Error', 'Please enter both ingredient and measure.');
    }
  }

  void removeIngredient(int index) {
    ingredients.removeAt(index);
  }

  void addInstruction() {
    final instruction = currentInstructionController.text.trim();
    if (instruction.isNotEmpty) {
      instructions.add(instruction);
      currentInstructionController.clear();
    } else {
      Get.snackbar('Error', 'Please enter an instruction.');
    }
  }

  void removeInstruction(int index) {
    instructions.removeAt(index);
  }

  Future<void> saveMeal() async {
    final meal = {
      "strMeal": mealNameController.text.trim(),
      "strCalories": caloriesController.text.trim(),
      "strTime": timeController.text.trim(),
      "strCategory": selectedCategory.value,
      "strArea": selectedArea.value,
      "strInstructions": instructions.join("\n"),
      "strMealThumb": imageUrl.value,
      "strTags": tagsController.text.trim(),
      "strYoutube": youtubeLinkController.text.trim(),
      "ingredients": ingredients,
      "type": "uploadRecipe", // Menandai data dari uploadRecipe
    };

    await saveMealToFirestore(meal);

    clearFields();
    Get.snackbar('Success', 'Recipe saved successfully!');
    await loadSavedMealsFromFirestore();
  }

  Future<void> saveMealToFirestore(Map<String, dynamic> meal) async {
    final docRef = FirebaseFirestore.instance.collection('meals').doc();
    final mealId = docRef.id;

    final downloadUrl = await uploadImageToFirebase(mealId);
    if (downloadUrl == null) return;

    meal["strMealThumb"] = downloadUrl;

    try {
      await docRef.set(meal);
      Get.snackbar('Success', 'Recipe saved to Firestore successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to save recipe to Firestore: $e');
    }
  }

  void clearFields() {
    mealNameController.clear();
    caloriesController.clear();
    timeController.clear();
    tagsController.clear();
    youtubeLinkController.clear();
    currentIngredientNameController.clear();
    currentMeasureController.clear();
    currentInstructionController.clear();
    imageUrl.value = null;
    instructions.clear();
    ingredients.clear();
    selectedCategory.value = '';
    selectedArea.value = '';
  }
}
