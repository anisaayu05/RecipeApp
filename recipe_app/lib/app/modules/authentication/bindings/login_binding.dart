import 'package:get/get.dart';
import 'package:recipe_app/app/modules/authentication/controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
      () => LoginController(),
    );
  }
}