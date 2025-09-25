import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/meal_plan_controller.dart';

class MealPlanView extends StatefulWidget {
  const MealPlanView({Key? key}) : super(key: key);

  @override
  State<MealPlanView> createState() => _MealPlanViewState();
}

class _MealPlanViewState extends State<MealPlanView> {
  final controller = Get.put(MealPlanController());
  Map<String, dynamic>? selectedMealData;

  @override
  void initState() {
    super.initState();
    controller.fetchMeals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Meal Planner', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        leading: selectedMealData != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    selectedMealData = null;
                  });
                },
              )
            : null,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return selectedMealData != null ? _buildMealDetailView() : _buildMealListView();
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewMeal,
        child: const Icon(Icons.add),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }

  Widget _buildMealListView() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      children: controller.mealsByDay.entries.expand((entry) {
        String day = entry.key;
        List<Map<String, dynamic>> meals = entry.value;

        return [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              day,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
          ),
          ...meals.map((meal) => _buildMealCard(day, meal)).toList(),
        ];
      }).toList(),
    );
  }

  Widget _buildMealCard(String day, Map<String, dynamic> meal) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            meal['strMealThumb'],
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          meal['strMeal'],
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (String result) {
            if (result == 'edit') _editMeal(day, meal);
            if (result == 'delete') _deleteMeal(day, meal);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
            const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () async {
          var mealDetail = await controller.fetchMealDetail(meal['idMeal']);
          setState(() {
            selectedMealData = mealDetail;
          });
        },
      ),
    );
  }

  Widget _buildMealDetailView() {
    List<String> instructions = selectedMealData?['strInstructions']?.split('\n') ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              selectedMealData?['strMealThumb'] ?? '',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            selectedMealData?['strMeal'] ?? 'Meal Detail',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrange),
          ),
          const SizedBox(height: 20),
          const Text('Ingredients:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildIngredientsList(),
          const SizedBox(height: 20),
          const Text('Instructions:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildInstructionsList(instructions),
        ],
      ),
    );
  }

  Widget _buildIngredientsList() {
    List<String> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      String? ingredient = selectedMealData?['strIngredient$i'];
      if (ingredient != null && ingredient.isNotEmpty) {
        ingredients.add(ingredient);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ingredients.map((ingredient) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            '• $ingredient',
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInstructionsList(List<String> instructions) {
    return Column(
      children: instructions.map((instruction) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            instruction,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        );
      }).toList(),
    );
  }

void _addNewMeal() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      String selectedDay = controller.mealsByDay.keys.first;
      Map<String, dynamic>? selectedMeal;
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Center(
              child: Text(
                'Add New Meal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            content: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Day',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      value: selectedDay,
                      items: controller.mealsByDay.keys.map((String day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(day),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedDay = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Meal',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      value: selectedMeal?['idMeal'],
                      hint: const Text('Select a meal'),
                      items: controller.availableMeals.map((Map<String, dynamic> meal) {
                        return DropdownMenuItem<String>(
                          value: meal['idMeal'],
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Text(
                              meal['strMeal'],
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedMeal = controller.availableMeals
                                .firstWhere((meal) => meal['idMeal'] == newValue);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(padding: const EdgeInsets.all(8)),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.all(8),
                ),
                child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  if (selectedMeal != null) {
                    await controller.addMeal(selectedDay, selectedMeal!);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Meal added successfully')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a meal')),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}

void _editMeal(String day, Map<String, dynamic> meal) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      Map<String, dynamic> selectedMeal = Map.from(meal);
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Center(
              child: Text(
                'Edit Meal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select New Meal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    value: selectedMeal['idMeal'],
                    items: controller.availableMeals.map((Map<String, dynamic> meal) {
                      return DropdownMenuItem<String>(
                        value: meal['idMeal'],
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: Text(
                            meal['strMeal'],
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedMeal = controller.availableMeals
                              .firstWhere((meal) => meal['idMeal'] == newValue);
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  int index = controller.mealsByDay[day]!.indexOf(meal);
                  await controller.updateMeal(day, index, selectedMeal);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Meal updated successfully')),
                  );
                },
              ),
            ],
          );
        },
      );
    },
  );
}



 void _deleteMeal(String day, Map<String, dynamic> meal) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red.shade600),
            const SizedBox(width: 10),
            const Text(
              'Delete Meal',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            text: 'Are you sure you want to delete ',
            style: const TextStyle(color: Colors.black, fontSize: 16),
            children: [
              TextSpan(
                text: meal['strMeal'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              backgroundColor: Colors.grey.shade200,
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              backgroundColor: Colors.red.shade600,
            ),
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              await controller.deleteMeal(day, meal['idMeal']);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Meal deleted successfully'),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      );
    },
  );
}
}
