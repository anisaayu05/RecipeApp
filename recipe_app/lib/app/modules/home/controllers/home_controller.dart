import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class HomeController extends GetxController {
  var categories = [].obs; // List of all categories
  var filteredMeals = [].obs; // List of filtered meals based on category
  var currentCategory = ''.obs; // Holds the active category
  var allMeals = [].obs; // List of all meals for filtering
  var currentIndex = 0.obs;

  // User info
  RxString fullName = ''.obs;
  RxString userName = "User".obs; // Name of the logged-in user
  RxString profileImageUrl = ''.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    fetchCategories(); // Fetch categories when the controller is initialized
    fetchAllMeals(); // Fetch all meals for the "All" category
    _fetchUserData(); // Fetch the logged-in user's name and profile image
  }

  // Fetch the logged-in user's name, username, and profile image from Firestore
  Future<void> _fetchUserData() async {
    try {
      String userId = _auth.currentUser?.uid ?? '';
      if (userId.isNotEmpty) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
        fullName.value = userDoc['name'] ?? 'User'; // Full name
        userName.value = userDoc['username'] ?? '@user'; // Username
        profileImageUrl.value = userDoc['profileImage'] ?? ''; // Profile image URL
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  // Fetch categories from TheMealDB API and add the "All" category as default
  Future<void> fetchCategories() async {
    const url = 'https://www.themealdb.com/api/json/v1/1/categories.php';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        categories.assignAll(data['categories']);
        categories.insert(0, {
          'strCategory': 'All',
          'strCategoryThumb': '',
        });
        currentCategory.value = 'All';
        fetchAllMeals();
      } else {
        Get.snackbar('Error', 'Failed to fetch categories');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  // Fetch all meals from TheMealDB API
  Future<void> fetchAllMeals() async {
    const url = 'https://www.themealdb.com/api/json/v1/1/search.php?s=';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var meals = data['meals'] ?? [];
        allMeals.assignAll(meals);
        filteredMeals.assignAll(allMeals);
      } else {
        Get.snackbar('Error', 'Failed to fetch meals');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  // Fetch meals based on selected category
  Future<void> fetchMealsByCategory(String category) async {
    if (category == 'All') {
      filteredMeals.assignAll(allMeals);
    } else {
      const url = 'https://www.themealdb.com/api/json/v1/1/search.php?s=';
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          var meals = data['meals'] ?? [];
          filteredMeals.assignAll(
              meals.where((meal) => meal['strCategory'] == category).toList());
        } else {
          Get.snackbar('Error', 'Failed to fetch meals');
        }
      } catch (e) {
        Get.snackbar('Error', e.toString());
      }
    }
  }

  // Set active category and fetch meals for that category
  void setActiveCategory(String category) {
    currentCategory.value = category;
    fetchMealsByCategory(category);
  }

  // Function to change tab index
  void changeTabIndex(int index) {
    currentIndex.value = index;
  }
}