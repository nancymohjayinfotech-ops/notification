import 'package:flutter/material.dart';

class SubCategoryScreen extends StatelessWidget {
  final String category;

  const SubCategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final subcategories = getSubcategories(category);

    return Scaffold(
      appBar: AppBar(
        title: Text("$category Subcategories"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      // body: ListView.builder(
      //   padding: const EdgeInsets.all(16),
      //   itemCount: subcategories.length,
      //   itemBuilder: (context, index) {
      //     return Card(
      //       margin: const EdgeInsets.only(bottom: 12),
      //       elevation: 3,
      //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      //       child: ListTile(
      //         leading: const Icon(Icons.arrow_right, color: Colors.orange),
      //         title: Text(subcategories[index]),
      //         onTap: () {
      //           // Navigate or show details here
      //           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //             content: Text("Clicked on ${subcategories[index]}"),
      //           ));
      //         },
      //       ),
      //     );
      //   },
      // ),
    );
  }

  List<String> getSubcategories(String category) {
    switch (category) {
      case 'Electronics':
        return ['Mobiles', 'Laptops', 'Cameras', 'Accessories'];
      case 'Fashion':
        return ['Men', 'Women', 'Kids', 'Shoes'];
      case 'Groceries':
        return ['Fruits', 'Vegetables', 'Snacks', 'Drinks'];
      case 'Books':
        return ['Fiction', 'Non-Fiction', 'Comics', 'Educational'];
      case 'Home Decor':
        return ['Furniture', 'Wall Art', 'Lights', 'Curtains'];
      case 'Toys':
        return ['Action Figures', 'Puzzles', 'Educational Toys', 'Board Games'];
      default:
        return ['Unknown Category'];
    }
  }
}
