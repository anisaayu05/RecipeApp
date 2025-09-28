import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../connection/controllers/connection_controller.dart';

class UploadController extends GetxController {
  final picker = ImagePicker();
  final box = GetStorage();
  var isLoading = false.obs;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final mealNameController = TextEditingController();
  final caloriesController = TextEditingController();
  final timeController = TextEditingController();
  final tagsController = TextEditingController();
  final youtubeLinkController = TextEditingController();
  final currentIngredientNameController = TextEditingController();
  final currentMeasureController = TextEditingController();
  final currentInstructionController = TextEditingController();

  Rx<String?> localImagePath = Rx<String?>(null); 
  Rx<String?> imageUrl = Rx<String?>(null); 
  RxList<String> instructions = RxList<String>([]);
  RxList<Map<String, dynamic>> ingredients = RxList<Map<String, dynamic>>([]);

  RxString selectedCategory = ''.obs;
  RxString selectedArea = ''.obs;

  RxList<String> categories = RxList<String>([]);
  RxList<String> areas = RxList<String>([]);
  RxList<String> ingredientList = RxList<String>([]);
  var isGlutenFree = false.obs;

  bool validateForm() {
    if (mealNameController.text.trim().isEmpty ||
        caloriesController.text.trim().isEmpty ||
        timeController.text.trim().isEmpty ||
        selectedCategory.value.isEmpty ||
        selectedArea.value.isEmpty ||
        ingredients.isEmpty ||
        instructions.isEmpty ||
        imageUrl.value == null) {
      Get.snackbar('Error', 'Please fill in all required fields ❌');
      return false;
    }
    return true;
  }

  RxList<Map<String, dynamic>> savedMeals = RxList<Map<String, dynamic>>([]);
  final ConnectionController connectionController = Get.find<ConnectionController>();
  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    fetchAreas();
    fetchIngredients();
    loadSavedMealsFromFirestore();
    checkOfflineDataAndUpload();
    
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('meals')
          .where('uid', isEqualTo: uid)
          .get();

      // Map semua dokumen ke Map<String, dynamic> dan simpan di RxList
      savedMeals.value =
          snapshot.docs.map((doc) => {'idMeal': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error fetching meals: $e');
    }
  }

  Future<bool> checkInternetConnection() async {
  try {
    print("🔍 Memeriksa koneksi internet...");
    final result = await InternetAddress.lookup('example.com');
    
    // Debug: Menampilkan status koneksi
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      print("🌐 Koneksi internet terdeteksi: Tersambung ke 'example.com'.");
      return true;
    } else {
      print("🚫 Koneksi internet gagal: Tidak ada alamat yang ditemukan.");
      return false;
    }
  } catch (_) {
    // Debug: Menangani jika ada error dalam pengecekan
    print("⚠️ Error saat memeriksa koneksi internet: ${_.toString()}");
    return false;
  }
}

  Future<File?> pickImage() async {
  try {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageUrl.value = pickedFile.path;
      return File(pickedFile.path);
    } else {
      Get.snackbar('No Image Selected', 'Please select an image.');
      return null;
    }
  } catch (e) {
    Get.snackbar('Error', 'Failed to pick image: $e');
    return null;
  }
}

 Future<String?> uploadImageToFirebase(String mealId) async {
  if (imageUrl.value == null) {
    Get.snackbar('Error', 'No image selected to upload.');
    return null;
  }

  try {
    final current = imageUrl.value!;
    if (current.startsWith('http')) return current;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final file = File(current);
    if (!await file.exists()) return null;

    String ext = current.split('.').last;
    if (ext.isEmpty || ext.length > 5) ext = 'jpg';

    final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
    final storagePath = 'uploads/$uid/$mealId/$uniqueId.$ext';

    final storageRef = FirebaseStorage.instance.ref().child(storagePath);
    final uploadTask = storageRef.putFile(
      file,
      SettableMetadata(contentType: 'image/$ext'),
    );

    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  } catch (e) {
    Get.snackbar('Upload Error', e.toString());
    return null;
  }
}

  Future<void> updateMealNameLocally(String mealId, String newMealName) async {
  try {
    // Menyimpan perubahan nama menu secara lokal
    final savedMealsData = box.read('savedMeals') ?? [];
    final updatedMealsData = savedMealsData.map((meal) {
      if (meal['idMeal'] == mealId) {
        meal['strMeal'] = newMealName; // Update nama menu
      }
      return meal;
    }).toList();

    // Menyimpan kembali data yang sudah diupdate ke penyimpanan lokal
    await box.write('savedMeals', updatedMealsData);

    // Menampilkan notifikasi bahwa nama menu berhasil diubah secara lokal
    Get.snackbar('Offline Mode', 'Recipe name updated locally.');
  } catch (e) {
    print('Error updating meal name locally: $e');
    Get.snackbar('Error', 'Failed to update recipe name locally.');
  }
}

  Future<void> deleteMealLocallyAndUI(String mealId) async {
    try {
      // Hapus meal dari UI
      savedMeals.removeWhere((meal) => meal['idMeal'] == mealId);

      // Hapus meal dari penyimpanan lokal
      final savedMealsData = box.read('savedMeals') ?? [];
      final updatedMealsData = savedMealsData.where((meal) => meal['idMeal'] != mealId).toList();

      // Menyimpan kembali data yang sudah diupdate ke penyimpanan lokal
      await box.write('savedMeals', updatedMealsData);

      // Notifikasi bahwa meal berhasil dihapus secara lokal
      Get.snackbar('Offline Mode', 'Recipe deleted locally.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete recipe locally.');
    }
  }


  Future<void> updateImage(String mealId, File file, {String? oldImageUrl}) async {
  try {
    // Jangan panggil picker lagi, gunakan file yang dikirim
    if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
      await deleteImageFromFirebaseStorage(oldImageUrl);
    }

    final storageRef = FirebaseStorage.instance.ref().child('uploads/$mealId.jpg');
    await storageRef.putFile(file);
    final newImageUrl = await storageRef.getDownloadURL();

    await FirebaseFirestore.instance.collection('meals').doc(mealId).update({
      'strMealThumb': newImageUrl,
    });

    int index = savedMeals.indexWhere((m) => m['idMeal'] == mealId);
    if (index != -1) {
      savedMeals[index]['strMealThumb'] = newImageUrl;
      savedMeals.refresh();
    }

    imageUrl.value = newImageUrl; // Update image di UI
    Get.snackbar('Success', 'Recipe image updated successfully!');
  } catch (e) {
    Get.snackbar('Error', 'Failed to update recipe image: $e');
  }
}

  Future<void> saveImageUrlToFirestore(String downloadUrl) async {
  try {
    final docRef = FirebaseFirestore.instance.collection('meals').doc();
    await docRef.set({
      'imageUrl': downloadUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
    Get.snackbar('Success', 'Image URL saved to Firestore.');
  } catch (e) {
    Get.snackbar('Error', 'Failed to save image URL to Firestore: $e');
  }
}

Future<void> uploadImageIfNeeded(String mealId) async {
    final localImagePath = box.read('pendingMeal')?['imageLocalPath'];
    if (localImagePath != null) {
      try {
        final file = File(localImagePath);
        final storageRef = FirebaseStorage.instance.ref().child('uploads/$mealId.jpg');
        
        await storageRef.putFile(file);
        final downloadURL = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance.collection('meals').doc(mealId).update({
          'strMealThumb': downloadURL,
        });

        await box.remove('pendingMeal');
      } catch (e) {
        print("🚫 Error saat mengupload gambar: $e");
        Get.snackbar('Upload Error', 'Error uploading image: $e');
      }
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

Future<void> saveMealLocally(Map<String, dynamic> mealData) async {
  try {
    // Menyimpan data meal dan gambar secara lokal
    await box.write('pendingMeal', json.encode(mealData));  
    
    // Mengambil kembali data yang disimpan untuk memastikan bahwa data berhasil disimpan
    final savedData = box.read('pendingMeal');
    print("❌Saved meal data: $savedData");  // Menampilkan data yang disimpan di konsol
    
    // Menampilkan snackbar dengan informasi data yang disimpan
    Get.snackbar(
      'Offline 📴', 
      'Recipe saved locally. It will upload once connected 📶. Saved data: $savedData', 
      snackPosition: SnackPosition.BOTTOM, 
      colorText: Colors.green, 
      backgroundColor: Colors.white.withOpacity(0.7),
    );
  } catch (e) {
    print('Error saving meal locally: $e');  // Log error jika gagal menyimpan
    
    // Menampilkan snackbar jika gagal menyimpan
    Get.snackbar(
      'Error ❌', 
      'Failed to save recipe locally. Please try again ⚠️.',
      snackPosition: SnackPosition.BOTTOM, 
      colorText: Colors.white, 
      backgroundColor: Colors.red.withOpacity(0.8),
    );
  }
}

// Method untuk update instructions
  Future<void> updateInstructions(String mealId, List<String> instructions) async {
    await FirebaseFirestore.instance.collection('meals').doc(mealId).update({
      'instructions': instructions,
    });

    final index = savedMeals.indexWhere((meal) => meal['idMeal'] == mealId);
    if (index != -1) {
      savedMeals[index]['instructions'] = instructions;
      savedMeals.refresh();
    }
  }

  // Method untuk update ingredients
  Future<void> updateIngredients(String mealId, List<Map<String, dynamic>> ingredients) async {
    await FirebaseFirestore.instance.collection('meals').doc(mealId).update({
      'ingredients': ingredients,
    });

    final index = savedMeals.indexWhere((meal) => meal['idMeal'] == mealId);
    if (index != -1) {
      savedMeals[index]['ingredients'] = ingredients;
      savedMeals.refresh();
    }
  }

 Future<void> saveMeal() async {
    if (!validateForm()) return; // ✅ Stop kalau ada yang kosong

    isLoading.value = true; // ✅ Tampilkan loading
    try {
      final mealData = {
        'strMeal': mealNameController.text.trim(),
        'strCalories': caloriesController.text.trim(),
        'strTime': timeController.text.trim(),
        'strCategory': selectedCategory.value,
        'strArea': selectedArea.value,
        'strInstructions': instructions.join("\n"),
        'strMealThumb': imageUrl.value,
        'strTags': tagsController.text.trim(),
        'strYoutube': youtubeLinkController.text.trim(),
        'ingredients': ingredients,
        'type': 'uploadRecipe',
        'strIsGlutenFree': isGlutenFree.value,
      };

      bool isConnected = await checkInternetConnection();
      if (isConnected) {
        await saveMealToFirestore(mealData);
        Get.snackbar('Success', 'Recipe saved successfully! 🎉');
      } else {
        await saveMealLocally(mealData);
        Get.snackbar('Offline Mode', 'Recipe saved locally. 🔒');
      }

      clearFields();
      await loadMeals();
    } catch (e) {
      Get.snackbar('Error', 'An error occurred while saving the recipe ❌');
    } finally {
      isLoading.value = false; // ✅ Sembunyikan loading
    }
  }

Future<void> saveImageLocally(XFile pickedFile) async {
    try {
      final String localImagePath = pickedFile.path;
      await box.write('localImagePath', localImagePath);

      final mealData = {
        'strMeal': mealNameController.text.trim(),
        'strCalories': caloriesController.text.trim(),
        'strTime': timeController.text.trim(),
        'strCategory': selectedCategory.value,
        'strArea': selectedArea.value,
        'strInstructions': instructions.join("\n"),
        'strMealThumb': localImagePath,
        'strTags': tagsController.text.trim(),
        'strYoutube': youtubeLinkController.text.trim(),
        'ingredients': ingredients,
        'type': 'uploadRecipe',
      };

      await box.write('pendingMeal', json.encode(mealData));

      Get.snackbar('Offline Mode', 'Recipe saved locally with image.');
    } catch (e) {
      print("Error saving image locally: $e");
      Get.snackbar('Error', 'Failed to save image locally.');
    }
  }


Future<void> loadMeals() async {
  bool isConnected = await checkInternetConnection();
  if (isConnected) {
    // Jika terhubung ke internet, muat data dari Firestore
    await loadSavedMealsFromFirestore();  
  } else {
    // Jika offline, muat data lokal
    await loadSavedMealsFromLocal();
  }
}

Future<void> loadSavedMealsFromLocal() async {
  // Memuat data yang tersimpan secara lokal
  final savedMeal = box.read('pendingMeal');
  if (savedMeal != null) {
    final mealData = json.decode(savedMeal);
    savedMeals.add(mealData);  // Menambahkan data lokal yang tersimpan
  }
}

 Future<void> checkOfflineDataAndUpload() async {
  bool isConnected = await checkInternetConnection();
  if (isConnected) {
    // Upload data yang tersimpan secara lokal
    final savedMeal = box.read('pendingMeal');
    if (savedMeal != null) {
      final mealData = json.decode(savedMeal);
      await saveMealToFirestore(mealData);
      box.remove('pendingMeal');  // Menghapus data setelah berhasil di-upload
      Get.snackbar('Success', 'Offline data uploaded successfully.');
    }

    // Menghapus data yang telah dihapus secara offline
    final deletedMeals = box.read('deletedMeals') ?? [];
    for (var mealId in deletedMeals) {
      try {
        await FirebaseFirestore.instance.collection('meals').doc(mealId).delete();
        Get.snackbar('Deleted', 'Recipe with ID $mealId deleted from Firestore.');
      } catch (e) {
        Get.snackbar('Error', 'Failed to delete recipe with ID $mealId from Firestore.');
      }
    }

    // Hapus daftar deletedMeals setelah berhasil dihapus dari Firestore
    await box.remove('deletedMeals');
  } else {
    // Jika offline, tetap clear fields setelah menyimpan data
    Get.snackbar('Offline Mode', 'Recipe saved locally.');
    clearFields();  // Tetap bersihkan form meskipun offline
  }
}


  Future<String?> saveMealToFirestore(Map<String, dynamic> meal) async {
  final docRef = FirebaseFirestore.instance.collection('meals').doc();
  final mealId = docRef.id;

  final uid = FirebaseAuth.instance.currentUser?.uid;

  final downloadUrl = await uploadImageToFirebase(mealId);

  meal['idMeal'] = mealId;
  meal['uid'] = uid;
  meal['strMealThumb'] = downloadUrl ?? '';

  try {
    await docRef.set(meal);
    Get.snackbar('Success', 'Recipe saved to Firestore successfully!');
    return mealId; // ✅ kembalikan ID
  } catch (e) {
    Get.snackbar('Error', 'Failed to save recipe: $e');
    return null;
  }
}


Future<void> checkMealExistsAndUpdateImage(String mealId) async {
  final docSnapshot = await FirebaseFirestore.instance
      .collection('meals')
      .doc(mealId)
      .get();

  if (!docSnapshot.exists) {
    Get.snackbar('Error', 'Cannot update image: meal not found in Firestore.');
    return;
  }
}

void updateMealField(int index, String field, String newValue) {
  if (field == 'ingredient') {
    if (index < ingredients.length) {
      ingredients[index]['ingredient'] = newValue;
    }
  } else if (field == 'measure') {
    if (index < ingredients.length) {
      ingredients[index]['measure'] = newValue;
    }
  } else if (field == 'instruction') {
    if (index < instructions.length) {
      instructions[index] = newValue;
    }
  }
}

Future<void> uploadIngredientImage(int index) async {
  try {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && index < ingredients.length) {
      final file = File(pickedFile.path);
      final ingredientName = ingredients[index]['ingredient'] ?? 'ingredient';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('ingredient_images/$ingredientName.png');

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();
      ingredients[index]['image'] = downloadUrl;
      Get.snackbar('Success', 'Ingredient image updated!');
    }
  } catch (e) {
    Get.snackbar('Error', 'Failed to upload ingredient image: $e');
  }
}

Future<void> updateMealName(String mealId, String newName) async {
    await FirebaseFirestore.instance.collection('meals').doc(mealId).update({
      'strMeal': newName,
    });

    // Update local RxList supaya Obx rebuild otomatis
    final index = savedMeals.indexWhere((meal) => meal['idMeal'] == mealId);
    if (index != -1) {
      savedMeals[index]['strMeal'] = newName;
      savedMeals.refresh(); // penting biar UI rebuild
    }
  }

  
 void clearFields() {
  print('Clearing fields...'); 
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
