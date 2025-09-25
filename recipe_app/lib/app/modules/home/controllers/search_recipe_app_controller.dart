import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SearchRecipeAppController extends GetxController {
  var searchText = ''.obs;
  var filteredMeals = [].obs; // Untuk menyimpan hasil pencarian dari API
  var isListening = false.obs; // Menandakan apakah pencarian suara aktif
  stt.SpeechToText _speech = stt.SpeechToText(); // Inisialisasi SpeechToText

Future<void> searchMeals(String query) async {
    if (query.isEmpty) {
      filteredMeals.clear(); // Kosongkan hasil pencarian jika query kosong
      return;
    }

    // Mengambil data dari API
    await _searchMealsFromApi(query);

    // Mengambil data dari Firebase
    await _searchMealsFromFirebase(query);
  }



Future<void> _searchMealsFromApi(String query) async {
    final url = 'https://www.themealdb.com/api/json/v1/1/search.php?s=$query';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        // Jika ada hasil dari API, tambahkan ke filteredMeals
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          filteredMeals.assignAll(data['meals']);
        }
      } else {
        Get.snackbar('Error', 'Failed to fetch data from API');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
  // Fungsi untuk mencari makanan berdasarkan input pengguna
  Future<void> _searchMealsFromFirebase(String query) async {
  try {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('meals')
        .where('strMeal', isGreaterThanOrEqualTo: query)
        .where('strMeal', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      var mealsFromFirebase = querySnapshot.docs.map((doc) {
        var data = doc.data();

        // Cek data yang diambil dari Firestore
        print('Data from Firestore: $data');

        // Parsing ingredients from Firestore
        List<Map<String, String>> ingredients = [];
        for (int i = 1; i <= 20; i++) {
          String ingredientKey = 'strIngredient$i';
          String measureKey = 'strMeasure$i';

          // Ambil ingredient dan measure dari data Firestore
          final ingredient = data[ingredientKey];
          final measure = data[measureKey];
          

          if (ingredient != null && ingredient.isNotEmpty) {
            ingredients.add({
              'ingredient': ingredient,
              'measure': measure ?? 'No measure',  // Default jika measure kosong
            });
          }
        }

        // Kembalikan data resep dengan ingredients yang telah diproses
        return {
          'idMeal': doc.id,
          'strMeal': data['strMeal'] ?? 'Unknown Meal',
          'strMealThumb': data['strMealThumb'] ?? 'default_image_url',
          'strCategory': data['strCategory'] ?? 'Unknown Category',
          'strCalories': data['strCalories'] ?? 'Unknown Calories',
          'strInstructions': data['strInstructions'] ?? 'No instructions available',
          'ingredients': ingredients,
          'strArea': data['strArea'] ?? 'Unknown Area',
          'strTime': data['strTime'] ?? 'Unknown Time',
        };
      }).toList();

      filteredMeals.assignAll(mealsFromFirebase);  // Menyimpan data yang sudah diproses
    } else {
      Get.snackbar('No Results', 'No meals found in Firebase.');
    }
  } catch (e) {
    Get.snackbar('Error', 'Failed to fetch data from Firebase: $e');
  }
}

  // Fungsi untuk memperbarui teks pencarian
  void updateSearchText(String text) {
    searchText.value = text;
    searchMeals(text); // Panggil fungsi pencarian saat teks berubah
  }

  bool get isSearching => searchText.isNotEmpty;

  // Fungsi untuk memulai pencarian suara
  Future<void> startVoiceSearch() async {
    bool available = await _speech.initialize(); // Inisialisasi speech to text
    if (available) {
      isListening.value = true; // Mengatur status mendengarkan menjadi true
      _speech.listen(onResult: (result) {
        String recognizedText = result.recognizedWords;
        updateSearchText(recognizedText); // Update pencarian dengan teks yang diucapkan

        // Hentikan pendengaran otomatis setelah mendapatkan hasil
        if (recognizedText.isNotEmpty) {
          stopVoiceSearch();
        }
      });
    } else {
      Get.snackbar('Error', 'Speech recognition not available');
    }
  }

  // Fungsi untuk menghentikan pencarian suara
  void stopVoiceSearch() {
    isListening.value = false; // Mengatur status mendengarkan menjadi false
    _speech.stop();
}
}