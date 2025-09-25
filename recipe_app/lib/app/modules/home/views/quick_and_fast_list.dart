// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:recipe_app/app/modules/home/controllers/home_controller.dart';
// import 'package:recipe_app/app/modules/home/views/recipe_view.dart';
// import 'package:iconsax/iconsax.dart';

// class QuickAndFastList extends StatelessWidget {
//   const QuickAndFastList({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final HomeController homeController = Get.find<HomeController>();
//     final primaryColor = Theme.of(context).primaryColor;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               "Quick & Fast",
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: primaryColor,
//               ),
//             ),
//             OutlinedButton(
//               onPressed: () => Get.toNamed('/quick-foods'),
//               style: OutlinedButton.styleFrom(
//                 backgroundColor: Colors.white,
//                 side: BorderSide(color: primaryColor),
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               ),
//               child: Text(
//                 "View all",
//                 style: TextStyle(color: primaryColor),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 20),
//         Obx(() {
//           if (homeController.filteredMeals.isEmpty) {
//             return const Center(child: Text("No meals available for this category."));
//           }

//           return SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: List.generate(
//                 homeController.filteredMeals.length,
//                 (index) {
//                   final meal = homeController.filteredMeals[index];
//                   return GestureDetector(
//                     onTap: () => Get.to(RecipeView(food: meal)),
//                     child: Container(
//                       margin: const EdgeInsets.only(right: 10),
//                       width: 200,
//                       child: Stack(
//                         children: [
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Container(
//                                 width: double.infinity,
//                                 height: 130,
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(15),
//                                 ),
//                                 child: Image.network(
//                                   meal['strMealThumb'] ?? '',
//                                   fit: BoxFit.cover,
//                                   errorBuilder: (context, error, stackTrace) {
//                                     return const Icon(
//                                       Icons.error_outline,
//                                       size: 60,
//                                       color: Colors.red,
//                                     );
//                                   },
//                                   loadingBuilder: (context, child, loadingProgress) {
//                                     if (loadingProgress == null) return child;
//                                     return const Center(
//                                       child: CircularProgressIndicator(),
//                                     );
//                                   },
//                                 ),
//                               ),
//                               const SizedBox(height: 10),
//                               Text(
//                                 meal['strMeal'] ?? 'Unknown Meal', // Check null for meal name
//                                 style: const TextStyle(
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               const SizedBox(height: 10),
//                               Row(
//                                 children: [
//                                   const Icon(Iconsax.flash_1, size: 18, color: Colors.grey),
//                                   Text(
//                                     meal['calories'] != null
//                                         ? "${meal['calories']} Cal"
//                                         : "Unknown Cal",
//                                     style: const TextStyle(fontSize: 12, color: Colors.grey),
//                                   ),
//                                   const Text(" · ", style: TextStyle(color: Colors.grey)),
//                                   const Icon(Iconsax.clock, size: 18, color: Colors.grey),
//                                   Text(
//                                     meal['time'] != null
//                                         ? "${meal['time']} Min"
//                                         : "Unknown Time",
//                                     style: const TextStyle(fontSize: 12, color: Colors.grey),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                           Positioned(
//                             top: 1,
//                             right: 1,
//                             child: IconButton(
//                               onPressed: () {},
//                               style: IconButton.styleFrom(
//                                 backgroundColor: Colors.white,
//                                 fixedSize: const Size(30, 30),
//                               ),
//                               iconSize: 20,
//                               icon: const Icon(Iconsax.heart),
//                               color: primaryColor,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           );
//         }),
//       ],
//     );
//   }
// }
