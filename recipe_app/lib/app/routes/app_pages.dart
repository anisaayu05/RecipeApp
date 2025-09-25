import 'package:get/get.dart';
import 'package:recipe_app/app/modules/Profile/bindings/profile_binding.dart';
import 'package:recipe_app/app/modules/Profile/views/profile_view.dart';
import 'package:recipe_app/app/modules/authentication/bindings/login_binding.dart';
import 'package:recipe_app/app/modules/authentication/bindings/register_binding.dart';
import 'package:recipe_app/app/modules/authentication/views/login_view.dart';
import 'package:recipe_app/app/modules/authentication/views/register_view.dart';
import 'package:recipe_app/app/modules/favorite/bindings/favorite_binding.dart'; // Import FavoriteBinding
import 'package:recipe_app/app/modules/favorite/views/favorite_view.dart'; // Import FavoriteView
import 'package:recipe_app/app/modules/home/bindings/home_binding.dart';
import 'package:recipe_app/app/modules/home/views/home_view.dart';
import 'package:recipe_app/app/modules/home/views/start_cooking_view.dart'; // Import StartCookingView
import 'package:recipe_app/app/modules/home/views/view_all_page.dart'; // Import ViewAllPage
import 'package:recipe_app/app/modules/meal_plan/bindings/meal_plan_binding.dart';
import 'package:recipe_app/app/modules/meal_plan/views/meal_plan_view.dart';
import 'package:recipe_app/app/modules/upload/bindings/upload_binding.dart'; // Import UploadBinding
import 'package:recipe_app/app/modules/upload/views/upload_view.dart'; // Import UploadView

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: _Paths.LOGIN,
      page: () => LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    // Tambahkan halaman untuk View All
    GetPage(
      name: _Paths.VIEW_ALL, // Route untuk View All
      page: () => ViewAllPage(categoryName: Get.parameters['category'] ?? 'All'),
      binding: HomeBinding(),
    ),
    // Tambahkan halaman untuk Favorite
    GetPage(
      name: _Paths.FAVORITE, // Route untuk Favorite
      page: () => const FavoriteView(),
      binding: FavoriteBinding(),
    ),
    // Tambahkan halaman untuk Start Cooking
    GetPage(
      name: _Paths.START_COOKING, // Route untuk Start Cooking
      page: () => StartCookingView(food: Get.arguments), // Mengirim data 'food' ke halaman
    ),
    // Tambahkan halaman untuk Upload Recipe
    GetPage(
      name: _Paths.UPLOAD, // Route untuk Upload
      page: () => UploadView(), // Page untuk Upload Recipe
      binding: UploadBinding(), // Binding untuk Upload
    ),
    GetPage(
      name: _Paths.MEAL_PLAN, // Tambahkan page MealPlanView
      page: () => MealPlanView(),
      binding: MealPlanBinding(), // Tambahkan binding untuk Meal Plan
    ),
    GetPage(
      name: Routes.PROFILE,
      page: () => ProfileView(), // Tambahkan rute untuk ProfileView
      binding: ProfileBinding(),
    ),
  ];
}
