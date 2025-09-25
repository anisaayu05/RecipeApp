import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:recipe_app/app/modules/favorite/controllers/favorite_controller.dart'; // Import FavoriteController
import 'package:recipe_app/app/modules/home/controllers/recipe_controller.dart'; // Import RecipeController
import 'package:recipe_app/app/routes/app_pages.dart';
import 'package:recipe_app/dependency_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Inisialisasi Firebase
  await GetStorage.init(); // Inisialisasi GetStorage

  Get.put(FavoriteController());
  Get.put(RecipeController());
  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug
      title: "Recipe App",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      theme: ThemeData(
        // Define the color scheme for the app
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color.fromARGB(255, 255, 81, 0), // Set primary color
          secondary: Colors.white, // Set secondary color if needed
        ),
        scaffoldBackgroundColor: Colors.white, // Set background color to pure white

        // Customize the AppBar color
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 255, 81, 0), // Set AppBar color to match primary color
        ),

        // Customize button themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 81, 0), // Set ElevatedButton color
            foregroundColor: Colors.white, // Set text color for ElevatedButton
          ),
        ),

        // Customize text button themes
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 81, 0), // Set TextButton text color
          ),
        ),

        // FloatingActionButton uses the primary color by default
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color.fromARGB(255, 255, 81, 0), // Set FAB color
        ),
      ),
    ),
  );
  DependencyInjection.init();
}
