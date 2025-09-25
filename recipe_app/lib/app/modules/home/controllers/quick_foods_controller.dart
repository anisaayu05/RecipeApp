import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuickFoodsController extends GetxController {
  var quickFoods = [].obs;

  @override
  void onInit() {
    fetchQuickFoods();
    super.onInit();
  }

  Future<void> fetchQuickFoods() async {
    const url = 'https://www.themealdb.com/api/json/v1/1/filter.php?c=Seafood';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        quickFoods.value = data['meals'];
      } else {
        Get.snackbar('Error', 'Failed to fetch quick foods');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
}
