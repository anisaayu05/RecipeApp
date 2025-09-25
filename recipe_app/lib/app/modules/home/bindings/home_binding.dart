import 'package:get/get.dart';
import 'package:recipe_app/app/modules/home/controllers/home_controller.dart';
import 'package:recipe_app/app/modules/home/controllers/quick_foods_controller.dart';
import 'package:recipe_app/app/modules/favorite/controllers/favorite_controller.dart';
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<QuickFoodsController>(() => QuickFoodsController());
    Get.lazyPut<FavoriteController>(() => FavoriteController()); 
  }
}
