import 'package:get/get.dart';

import '../controllers/meal_plan_controller.dart';

class MealPlanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MealPlanController>(() => MealPlanController());
  }
}