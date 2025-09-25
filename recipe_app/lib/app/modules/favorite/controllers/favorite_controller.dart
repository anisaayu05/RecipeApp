import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FavoriteController extends GetxController {
  var favoriteMeals = <Map<String, dynamic>>[].obs; // List to store favorite meals
  final storage = GetStorage(); // Initialize GetStorage for persistent storage

  @override
  void onInit() {
    super.onInit();
    loadFavorites(); // Load favorites from storage when the controller is initialized
  }

  // Load favorite meals from persistent storage
  void loadFavorites() {
    List storedFavorites = storage.read<List>('favoriteMeals') ?? [];
    favoriteMeals.assignAll(storedFavorites.cast<Map<String, dynamic>>());
  }

  // Save favorite meals to persistent storage
  void saveFavorites() {
    storage.write('favoriteMeals', favoriteMeals.toList());
  }

  // Toggle the favorite status of a meal
  Future<void> toggleFavorite(Map<String, dynamic> meal) async {
    // Check if meal is already in favorites
    if (isFavorite(meal['idMeal'])) {
      favoriteMeals.removeWhere((favMeal) => favMeal['idMeal'] == meal['idMeal']);
    } else {
      // Fetch full meal details if only idMeal is available
      if (meal.length == 1) {
        meal = (await fetchMealById(meal['idMeal']))!;
      }
      favoriteMeals.add(meal);
    }
    saveFavorites(); // Save updated favorite meals to storage
  }

  // Check if a meal is already in favorites by its idMeal
  bool isFavorite(String idMeal) {
    return favoriteMeals.any((favMeal) => favMeal['idMeal'] == idMeal);
  }

  // Fetch full meal details by id if the app only has the idMeal stored
  Future<Map<String, dynamic>?> fetchMealById(String idMeal) async {
    const apiUrl = 'https://www.themealdb.com/api/json/v1/1/lookup.php?i='; 
    final response = await http.get(Uri.parse('$apiUrl$idMeal'));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return data['meals']?.first;
    } else {
      Get.snackbar('Error', 'Failed to fetch meal details');
      return null;
    }
  }

  // Get all favorite meals
  List<Map<String, dynamic>> getFavorites() {
    return favoriteMeals;
  }
}
