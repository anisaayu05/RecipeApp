import 'package:get/get.dart';
import 'package:recipe_app/app/modules/upload/controllers/upload_controller.dart';

class UploadBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UploadController>(() => UploadController());
  }
}
