import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:recipe_app/app/modules/favorite/controllers/favorite_controller.dart'; // Import FavoriteController
import 'package:recipe_app/app/modules/home/controllers/rating_controller.dart';
import 'package:recipe_app/app/modules/home/controllers/recipe_controller.dart'; // Import RecipeController
import 'package:recipe_app/app/modules/home/views/find_place_widget.dart';
import 'package:recipe_app/app/routes/app_pages.dart';

class RecipeView extends StatefulWidget {
  final Map<String, dynamic> food;

  RecipeView({Key? key, required this.food}) : super(key: key);

  @override
  _RecipeViewState createState() => _RecipeViewState();
}

class _RecipeViewState extends State<RecipeView> {
  final FavoriteController favoriteController = Get.find<FavoriteController>();
  final RecipeController recipeController = Get.find<RecipeController>();
   final RatingController ratingController = Get.put(RatingController());
  int servings = 1; // Initial serving size
  final primaryColor = Get.theme.primaryColor;
  String? userEmail;
  int _currentRating = 0;
  final TextEditingController _reviewController = TextEditingController();

 @override
  void initState() {
    super.initState();
    if (widget.food['idMeal'] != null) {
      // Fetch data from API and Firebase
      recipeController.fetchRecipe(widget.food['idMeal']);
      recipeController.fetchRecipeFromFirebase(widget.food['idMeal']);
    }
  }
  
  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use either API or Firebase ingredients based on available data
    final ingredients = recipeController.ingredients.isNotEmpty
        ? recipeController.ingredients
        : recipeController.firebaseIngredients;

    return Scaffold(
  backgroundColor: Colors.white,
  body: Stack(
    children: [
      SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120), // Beri ruang untuk tombol dan FindPlace
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderImage(),
            const SizedBox(height: 20),
            _buildMealTitle(),
            const SizedBox(height: 10),
            _buildCaloriesAndTime(),
            const SizedBox(height: 20),
            _buildRatingSummary(),
            const SizedBox(height: 20),
            _buildServingsControl(),
            const SizedBox(height: 20),
            _buildIngredientsSection(ingredients),
            const SizedBox(height: 20),
            // Widget untuk FindPlace
           
          ],
        ),
      ),
      _buildStartCookingButton(),
    ],
  ),
);

  }

  Widget _buildHeaderImage() {
    return Stack(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            image: DecorationImage(
              image: NetworkImage(widget.food['strMealThumb'] ?? ''),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.7),
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(CupertinoIcons.chevron_back, color: primaryColor),
                ),
              ),
              Obx(() {
                final isFavorite = favoriteController
                    .isFavorite(widget.food['idMeal'] ?? '');
                return CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.7),
                  child: IconButton(
                    onPressed: () {
                      favoriteController.toggleFavorite(widget.food);
                    },
                    icon: Icon(
                      isFavorite ? Iconsax.heart5 : Iconsax.heart,
                      color: primaryColor,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealTitle() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Nama Makanan
        Expanded(
          child: Text(
            widget.food['strMeal'] ?? 'Unknown Meal',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis, // Untuk teks yang terlalu panjang
          ),
        ),

        // Ikon Peta dengan Fungsi onPress
        GestureDetector(
          onTap: () {
            // Panggil FindPlace saat ikon ditekan
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FindPlace(
                  foodName: widget.food['strMeal'] ?? 'Unknown',
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.map_rounded,
              color: Colors.orange,
              size: 28,
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildCaloriesAndTime() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.flash_1, size: 20, color: Colors.grey),
              const SizedBox(width: 5),
              Text(
                widget.food['calories'] != null
                    ? "${widget.food['calories']} Cal"
                    : "Calories info not available",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Iconsax.clock, size: 20, color: Colors.grey),
              const SizedBox(width: 5),
              Text(
                widget.food['time'] != null
                    ? "${widget.food['time']} Min"
                    : "Time info not available",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return GestureDetector(
      onTap: _showReviewsModal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Obx(() => Row(
          children: [
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < ratingController.averageRating.value.round()
                      ? Iconsax.star1
                      : Iconsax.star,
                  color: Colors.yellow.shade700,
                  size: 25,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "${ratingController.averageRating.value.toStringAsFixed(1)}/5 (${ratingController.totalRatings.value} ratings)",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        )),
      ),
    );
  }

  void _showReviewsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Reviews",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Obx(() {
                if (ratingController.reviews.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "No reviews available.",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: ListView.builder(
                    itemCount: ratingController.reviews.length,
                    itemBuilder: (context, index) {
                      final review = ratingController.reviews[index];
                      final isCurrentUser =
                          review['userEmail'] == userEmail;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        color: isCurrentUser
                            ? Colors.orange.shade50
                            : Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          leading: CircleAvatar(
                            backgroundColor: Colors.yellow.shade700,
                            child: Text(
                              review['rating']?.toString() ?? '0',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review['userEmail'] ?? 'Unknown user',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                review['review'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    starIndex < (review['rating'] ?? 0)
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.yellow.shade700,
                                    size: 20,
                                  );
                                }),
                              ),
                            ],
                          ),
                          trailing: isCurrentUser
                              ? PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (String value) {
                                    if (value == 'Edit') {
                                      _showRatingModal(
                                          isEditing: true, review: review);
                                    } else if (value == 'Delete') {
                                      ratingController.deleteReview(
                                          review['id'], context);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return {'Edit', 'Delete'}
                                        .map((String choice) {
                                      return PopupMenuItem<String>(
                                        value: choice,
                                        child: Text(choice),
                                      );
                                    }).toList();
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                );
              }),
              const SizedBox(height: 10),
              if (!_currentUserHasReview())
                Center(
                  child: ElevatedButton(
                    onPressed: () => _showRatingModal(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                    ),
                    child: const Text(
                      "Add Your Review",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  bool _currentUserHasReview() {
    return ratingController.reviews
        .any((review) => review['userEmail'] == userEmail);
  }

  void _showRatingModal(
      {bool isEditing = false, Map<String, dynamic>? review}) {
    if (isEditing && review != null) {
      _currentRating = review['rating'] ?? 0;
      _reviewController.text = review['review'] ?? '';
    } else {
      _currentRating = 0;
      _reviewController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? "Edit Your Review" : "Rate & Review",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      onPressed: () {
                        setState(() {
                          _currentRating = index + 1;
                        });
                      },
                      icon: Icon(
                        index < _currentRating
                            ? Iconsax.star1
                            : Iconsax.star,
                        color: Colors.yellow.shade700,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: _reviewController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Write a review...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (isEditing && review != null) {
                        ratingController.updateReview(
                          review['id'],
                          _currentRating,
                          _reviewController.text,
                          context,
                        );
                      } else {
                        ratingController.submitReview(
                          widget.food['idMeal'] ?? '',
                          _currentRating,
                          _reviewController.text,
                          context,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    child: Text(
                      isEditing ? "Update" : "Submit",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServingsControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "How many servings?",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if (servings > 1) servings--;
                  });
                },
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                "$servings",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    servings++;
                  });
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(List<Map<String, String>> ingredients) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ingredients",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: List.generate(ingredients.length, (index) {
              final ingredient = ingredients[index]['ingredient'];
              final measure = ingredients[index]['measure'];
              final scaledMeasure = _scaleMeasure(measure, servings);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: NetworkImage(
                                "https://www.themealdb.com/images/ingredients/${ingredient}-Small.png"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ingredient ?? "Unknown",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        scaledMeasure,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStartCookingButton() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Get.toNamed(Routes.START_COOKING, arguments: widget.food);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            shadowColor: Colors.transparent,
          ),
          child: const Text(
            "Start Cooking",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  String _scaleMeasure(String? measure, int servings) {
    if (measure == null || measure.isEmpty) return "";
    return "$measure x $servings";
}
}