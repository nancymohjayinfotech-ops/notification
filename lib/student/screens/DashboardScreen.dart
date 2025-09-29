import 'package:flutter/material.dart';
import 'SubCategoryScreen.dart';

class DashboardScreen extends StatelessWidget {
  final List<Category> categories = [
    Category(name: "Electronics", icon: Icons.electrical_services),
    Category(name: "Fashion", icon: Icons.shopping_bag),
    Category(name: "Groceries", icon: Icons.local_grocery_store),
    Category(name: "Books", icon: Icons.book),
    Category(name: "Home Decor", icon: Icons.chair),
    Category(name: "Toys", icon: Icons.toys),
  ];

  DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.orange.shade400,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Categories",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 4 / 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubCategoryScreen(category: category.name),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.orange.shade100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(category.icon, size: 40, color: Colors.deepOrange),
                          const SizedBox(height: 12),
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Category {
  final String name;
  final IconData icon;

  Category({required this.name, required this.icon});
}
