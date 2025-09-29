import 'package:flutter/material.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final List<String> _tabs = ['Course List', 'Categories'];
  int _currentTabIndex = 0;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        backgroundColor: const Color(0xFF5F299E),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Custom Tab Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: _tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final title = entry.value;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentTabIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentTabIndex == index
                            ? const Color(0xFF5F299E)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _currentTabIndex == index
                            ? [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _currentTabIndex == index
                              ? Colors.white
                              : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Tab Content
          Expanded(
            child: _currentTabIndex == 0
                ? const CourseListView()
                : const CategoriesView(),
          ),
        ],
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                _showAddDialog(context);
              },
              backgroundColor: const Color(0xFF5F299E),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddDialog(BuildContext context) {
    _nameController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Course'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Enter course name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  // Add logic to create new course
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class CourseListView extends StatelessWidget {
  const CourseListView({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample course data
    final List<Map<String, dynamic>> courses = [
      {
        'title': 'Flutter Development Masterclass',
        'category': 'Mobile Development',
        'students': 42,
        'image': 'assets/images/developer.png',
        'price': '\$99.99',
        'status': 'Published',
      },
      {
        'title': 'Advanced React & Node.js',
        'category': 'Web Development',
        'students': 28,
        'image': 'assets/images/devop.png',
        'price': '\$89.99',
        'status': 'Published',
      },
      {
        'title': 'UI/UX Design Fundamentals',
        'category': 'Design',
        'students': 35,
        'image': 'assets/images/digital.jpg',
        'price': '\$79.99',
        'status': 'Published',
      },
      {
        'title': 'Python for Data Science',
        'category': 'Data Science',
        'students': 50,
        'image': 'assets/images/developer.png',
        'price': '\$109.99',
        'status': 'Draft',
      },
      {
        'title': 'Machine Learning Fundamentals',
        'category': 'AI & Machine Learning',
        'students': 22,
        'image': 'assets/images/devop.png',
        'price': '\$129.99',
        'status': 'Draft',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    course['image'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Course Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Category: ${course['category']}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${course['students']} students enrolled',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Price: ${course['price']}',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Status Chip and Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Status Chip
                          Chip(
                            label: Text(
                              course['status'],
                              style: TextStyle(
                                fontSize: 12,
                                color: course['status'] == 'Published'
                                    ? Colors.green[800]
                                    : Colors.orange[800],
                              ),
                            ),
                            backgroundColor: course['status'] == 'Published'
                                ? Colors.green[100]
                                : Colors.orange[100],
                          ),
                          // Action Buttons
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                color: const Color(0xFF5F299E),
                                onPressed: () {
                                  // Edit course
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                color: Colors.red[400],
                                onPressed: () {
                                  // Delete course
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  // Sample categories data based on the image
  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Graphics Design',
      'abbr': 'GD',
      'subCategories': 4,
      'color': Colors.purple[400]!,
      'description':
          'Website Design & Develop the website with web applications',
      'tags': [
        'Photoshop',
        'Adobe Illustrator',
        'Logo Design',
        'Drawing',
        'Figma',
      ],
    },
    {
      'name': 'Web Development',
      'abbr': 'WD',
      'subCategories': 5,
      'color': Colors.amber[400]!,
      'description':
          'Website Design & Develop the website with web applications',
      'tags': [
        'Responsive Design',
        'Wordpress Customization',
        'Theme Development',
        'Bootstrap',
        'HTML & CSS Grid',
      ],
    },
    {
      'name': 'Mobile Application',
      'abbr': 'MA',
      'subCategories': 4,
      'color': Colors.cyan[400]!,
      'description':
          'Website Design & Develop the website with web applications',
      'tags': [
        'Mobile App Design',
        'User Interface',
        'Design Thinking',
        'Prototyping',
      ],
    },
    {
      'name': 'Graphics Design',
      'abbr': 'GD',
      'subCategories': 4,
      'color': Colors.purple[400]!,
      'description':
          'Website Design & Develop the website with web applications',
      'tags': [
        'Photoshop',
        'Adobe Illustrator',
        'Logo Design',
        'Drawing',
        'Figma',
      ],
    },
    {
      'name': 'Web Development',
      'abbr': 'WD',
      'subCategories': 5,
      'color': Colors.amber[400]!,
      'description':
          'Website Design & Develop the website with web applications',
      'tags': [
        'Responsive Design',
        'Wordpress Customization',
        'Theme Development',
        'Bootstrap',
        'HTML & CSS Grid',
      ],
    },
    {
      'name': 'Mobile Application',
      'abbr': 'MA',
      'subCategories': 4,
      'color': Colors.cyan[400]!,
      'description':
          'Website Design & Develop the website with web applications',
      'tags': [
        'Mobile App Design',
        'User Interface',
        'Design Thinking',
        'Prototyping',
      ],
    },
  ];

  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _categoryDescController = TextEditingController();

  @override
  void dispose() {
    _categoryNameController.dispose();
    _categoryDescController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog(BuildContext context) {
    _categoryNameController.clear();
    _categoryDescController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryNameController,
                decoration: const InputDecoration(
                  hintText: 'Enter category name',
                  labelText: 'Category Name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _categoryDescController,
                decoration: const InputDecoration(
                  hintText: 'Enter category description',
                  labelText: 'Description',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (_categoryNameController.text.isNotEmpty) {
                  setState(() {
                    String name = _categoryNameController.text;
                    String abbr = name
                        .split(' ')
                        .map((word) => word.isNotEmpty ? word[0] : '')
                        .take(2)
                        .join('')
                        .toUpperCase();

                    categories.add({
                      'name': name,
                      'abbr': abbr,
                      'subCategories': 0,
                      'color': Colors.purple[400]!,
                      'description': _categoryDescController.text.isEmpty
                          ? 'New Category Description'
                          : _categoryDescController.text,
                      'tags': [],
                    });
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditCategoryDialog(BuildContext context, int index) {
    _categoryNameController.text = categories[index]['name'];
    _categoryDescController.text = categories[index]['description'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryNameController,
                decoration: const InputDecoration(
                  hintText: 'Enter category name',
                  labelText: 'Category Name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _categoryDescController,
                decoration: const InputDecoration(
                  hintText: 'Enter category description',
                  labelText: 'Description',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () {
                if (_categoryNameController.text.isNotEmpty) {
                  setState(() {
                    String name = _categoryNameController.text;
                    String abbr = name
                        .split(' ')
                        .map((word) => word.isNotEmpty ? word[0] : '')
                        .take(2)
                        .join('')
                        .toUpperCase();

                    categories[index]['name'] = name;
                    categories[index]['abbr'] = abbr;
                    categories[index]['description'] =
                        _categoryDescController.text;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text(
            'Are you sure you want to delete ${categories[index]['name']}?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                setState(() {
                  categories.removeAt(index);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Category Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              _showAddCategoryDialog(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F299E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        // Categories Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75, // Taller cards to fit content
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Header
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: category['color'],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Square with abbreviation
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              category['abbr'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: category['color'],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Category name and subcategories count
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${category['subCategories']} SubCategories',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // More options icon
                          PopupMenuButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditCategoryDialog(context, index);
                              } else if (value == 'delete') {
                                _showDeleteConfirmation(context, index);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Category Description
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        category['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                    ),
                    // Subcategory Tags
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: (category['tags'] as List<String>).map((
                            tag,
                          ) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[800],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
