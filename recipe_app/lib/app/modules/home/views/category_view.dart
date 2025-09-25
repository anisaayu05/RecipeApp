// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:recipe_app/app/modules/home/controllers/home_controller.dart';

// class CategoryView extends StatelessWidget {
//   const CategoryView({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final HomeController controller = Get.find<HomeController>();

//     return SizedBox(
//       height: 100,
//       child: Obx(() {
//         if (controller.categories.isEmpty) {
//           return const Center(
//             child: CircularProgressIndicator(),
//           );
//         }
//         return ListView.builder(
//           scrollDirection: Axis.horizontal,
//           itemCount: controller.categories.length,
//           itemBuilder: (context, index) {
//             final category = controller.categories[index];
//             return GestureDetector(
//               onTap: () {
//                 // Only trigger when the user taps, avoiding state change during build
//                 controller.setActiveCategory(category['strCategory']);
//               },
//               child: Container(
//                 margin: const EdgeInsets.only(right: 10),
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(15),
//                   color: controller.currentCategory.value == category['strCategory']
//                       ? Colors.orange
//                       : Colors.white,
//                   border: Border.all(
//                     color: Colors.grey.shade300,
//                     width: 1,
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Image.network(
//                       category['strCategoryThumb'],
//                       height: 50,
//                       width: 50,
//                     ),
//                     const SizedBox(height: 5),
//                     Text(
//                       category['strCategory'],
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       }),
//     );
//   }
// }
