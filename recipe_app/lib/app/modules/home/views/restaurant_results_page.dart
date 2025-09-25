import 'package:flutter/material.dart';

class RestaurantResultsPage extends StatelessWidget {
  final String foodName;
  final List<Map<String, String>> restaurants;

  const RestaurantResultsPage({
    Key? key,
    required this.foodName,
    required this.restaurants,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hasil untuk \"$foodName\""),
      ),
      body: restaurants.isNotEmpty
          ? ListView.builder(
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = restaurants[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: const Icon(Icons.restaurant, color: Colors.blue),
                    title: Text(restaurant['name'] ?? 'Unknown'),
                    subtitle:
                        Text(restaurant['address'] ?? 'Alamat tidak tersedia'),
                  ),
                );
              },
            )
          : const Center(
              child: Text(
                "Tidak ada restoran ditemukan.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
    );
  }
}
