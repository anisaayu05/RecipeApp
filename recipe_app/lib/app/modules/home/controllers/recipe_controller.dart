import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class RecipeController extends GetxController {
  var isLoading = true.obs;
  var ingredients = <Map<String, String>>[].obs;
  var firebaseIngredients = <Map<String, String>>[].obs;
  
  // Fetch recipe data from API
  Future<void> fetchRecipe(String mealId) async {
    final url = "https://www.themealdb.com/api/json/v1/1/lookup.php?i=$mealId";
    
    try {
      isLoading(true);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meal = data['meals'][0];

        // Extracting ingredients and measures from API
        List<Map<String, String>> tempIngredients = [];
        for (int i = 1; i <= 20; i++) {
          final ingredient = meal['strIngredient$i'];
          final measure = meal['strMeasure$i'];

          if (ingredient != null && ingredient.isNotEmpty) {
            tempIngredients.add({
              'ingredient': ingredient,
              'measure': measure ?? 'No measure',  // Default if measure is missing
            });
          }
        }

        ingredients.value = tempIngredients;  // Store ingredients from API
      }
    } catch (e) {
      print("Error fetching recipe: $e");
    } finally {
      isLoading(false);
    }
  }
  
    Future<void> fetchRecipeFromFirebase(String mealId) async {
    try {
      isLoading(true);

      final docSnapshot = await FirebaseFirestore.instance
          .collection('meals')
          .doc(mealId)  // Assuming mealId is the document ID
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();

        // Parsing ingredients from Firebase
        List<Map<String, String>> tempIngredients = [];
        for (int i = 1; i <= 20; i++) {
          final ingredientKey = 'strIngredient$i';
          final measureKey = 'strMeasure$i';

          final ingredient = data?[ingredientKey];
          final measure = data?[measureKey];

          if (ingredient != null && ingredient.isNotEmpty) {
            tempIngredients.add({
              'ingredient': ingredient,
              'measure': measure ?? 'No measure',  // Default if measure is missing
            });
          }
        }

        firebaseIngredients.value = tempIngredients;  // Store ingredients from Firebase
      } else {
        print('No recipe found in Firebase.');
      }
    } catch (e) {
      print("Error fetching recipe from Firebase: $e");
    } finally {
      isLoading(false);
}
}
}