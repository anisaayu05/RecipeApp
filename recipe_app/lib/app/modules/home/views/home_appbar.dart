import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_app/app/modules/home/controllers/home_controller.dart';

class HomeAppbar extends StatelessWidget {
  const HomeAppbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome text with username
                Obx(() {
                  return Text(
                    'Hello, ${controller.fullName.value}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey,
                    ),
                  );
                }),
                SizedBox(height: 8),
                Obx(() => RichText(
                      text: TextSpan(
                        text: "What would you like\n",
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text:
                                "to cook today, ${controller.userName.value.split(' ').first}?",
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        Obx(() {
          return CircleAvatar(
            radius: 25,
            backgroundImage: controller.profileImageUrl.value.isNotEmpty
                ? NetworkImage(controller.profileImageUrl.value)
                : const AssetImage('assets/images/default_profile.png') as ImageProvider,
          );
        }),
      ],
    ));
  }
}
