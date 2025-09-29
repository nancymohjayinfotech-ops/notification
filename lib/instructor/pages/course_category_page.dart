import 'package:flutter/material.dart';
import 'dart:math' show min;
import 'package:fluttertest/instructor/services/categories_service.dart';

class CourseCategory {
  final String name;
  final String abbreviation;
  final Color color;
  final int subCategoriesCount;
  final String description;
  final List<String> tags;

  CourseCategory({
    required this.name,
    required this.abbreviation,
    required this.color,
    required this.subCategoriesCount,
    required this.description,
    required this.tags,
  });
}

class CourseCategoryPage extends StatefulWidget {
  const CourseCategoryPage({super.key});

  @override
  State<CourseCategoryPage> createState() => _CourseCategoryPageState();
}

class _CourseCategoryPageState extends State<CourseCategoryPage> {
  final CategoriesService _categoriesService = CategoriesService();
  List<CategoryWithCount> _apiCategories = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  Future<void> _fetchCategoriesWithCounts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final categories = await _categoriesService.getCategoriesWithCounts();
      
      setState(() {
        _apiCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load categories: $e';
      });
      print('Error loading categories: $e');
    }
  }
  
  // Mock data for fallback
  List<CourseCategory> categories = [
    CourseCategory(
      name: 'Graphics Design',
      abbreviation: 'GD',
      color: Colors.purple,
      subCategoriesCount: 4,
      description: 'Website Design & Develop the website with web applications',
      tags: [
        'Photoshop',
        'Adobe Illustrator',
        'Logo Design',
        'Drawing',
        'Figma',
      ],
    ),
    CourseCategory(
      name: 'Web Development',
      abbreviation: 'WD',
      color: Colors.amber,
      subCategoriesCount: 5,
      description: 'Website Design & Develop the website with web applications',
      tags: [
        'Responsive Design',
        'Wordpress Customization',
        'Theme Development',
        'Bootstrap',
        'HTML & CSS Grid',
      ],
    ),
    CourseCategory(
      name: 'Mobile Application',
      abbreviation: 'MA',
      color: Colors.cyan,
      subCategoriesCount: 4,
      description: 'Website Design & Develop the website with web applications',
      tags: [
        'Mobile App Design',
        'User Interface',
        'Design Thinking',
        'Prototyping',
      ],
    ),
    CourseCategory(
      name: 'Graphics Design',
      abbreviation: 'GD',
      color: Colors.purple,
      subCategoriesCount: 4,
      description: 'Website Design & Develop the website with web applications',
      tags: [
        'Photoshop',
        'Adobe Illustrator',
        'Logo Design',
        'Drawing',
        'Figma',
      ],
    ),
    CourseCategory(
      name: 'Web Development',
      abbreviation: 'WD',
      color: Colors.amber,
      subCategoriesCount: 5,
      description: 'Website Design & Develop the website with web applications',
      tags: [
        'Responsive Design',
        'Wordpress Customization',
        'Theme Development',
        'Bootstrap',
        'HTML & CSS Grid',
      ],
    ),
    CourseCategory(
      name: 'Mobile Application',
      abbreviation: 'MA',
      color: Colors.cyan,
      subCategoriesCount: 4,
      description: 'Website Design & Develop the website with web applications',
      tags: [
        'Mobile App Design',
        'User Interface',
        'Design Thinking',
        'Prototyping',
      ],
    ),
  ];

  List<CourseCategory> filteredCategories = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    filteredCategories = List.from(categories);
    _fetchCategoriesWithCounts();
  }

  void filterCategories(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredCategories = List.from(categories);
      } else {
        filteredCategories = categories
            .where(
              (category) =>
                  category.name.toLowerCase().contains(query.toLowerCase()) ||
                  category.tags.any(
                    (tag) => tag.toLowerCase().contains(query.toLowerCase()),
                  ),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Category'),
        backgroundColor: const Color(0xFF5F299E),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CategorySearchDelegate(
                  categories: categories,
                  onSearch: filterCategories,
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchCategoriesWithCounts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with count and filter
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[100],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _apiCategories.isEmpty
                                ? 'You have total ${categories.length} Categories'
                                : 'You have total ${_apiCategories.length} Categories',
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showFilterDialog(context);
                            },
                            icon: const Icon(Icons.filter_list, size: 18),
                            label: const Text('Filtered By'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // API Categories Section (if available)
                    if (_apiCategories.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Categories from API',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _fetchCategoriesWithCounts,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Refresh'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: const Color(0xFF5F299E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 140,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _apiCategories.length,
                                itemBuilder: (context, index) {
                                  final category = _apiCategories[index];
                                  return Card(
                                    elevation: 4,
                                    margin: const EdgeInsets.only(right: 16, bottom: 8),
                                    child: Container(
                                      width: 180,
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: Colors.primaries[index % Colors.primaries.length],
                                                child: Text(category.name.substring(0, 1)),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  category.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Icon(Icons.book, size: 16),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Courses: ${category.courseCount}',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'ID: ${category.id.substring(0, min(8, category.id.length))}...',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                            overflow: TextOverflow.ellipsis,
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

                    // Original Categories Grid
                    Expanded(
                      child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                final category = filteredCategories[index];
                return _buildCategoryCard(category);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCategoryDialog(context);
        },
        backgroundColor: const Color(0xFF5F299E),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryCard(CourseCategory category) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: category.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      category.abbreviation,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: Colors.grey[700]),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditCategoryDialog(context, category);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context, category);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              category.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${category.subCategoriesCount} SubCategories',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Text(
              category.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: category.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    List<String> allTags = [];

    // Gather all unique tags
    for (var category in categories) {
      for (var tag in category.tags) {
        if (!allTags.contains(tag)) {
          allTags.add(tag);
        }
      }
    }

    // Track selected tags
    List<String> selectedTags = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filter Categories'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter by tags:'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allTags.map((tag) {
                      bool isSelected = selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedTags.add(tag);
                            } else {
                              selectedTags.remove(tag);
                            }
                          });
                        },
                        selectedColor: const Color(0xFF5F299E).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF5F299E),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (selectedTags.isEmpty) {
                      filteredCategories = List.from(categories);
                    } else {
                      filteredCategories = categories
                          .where(
                            (category) => category.tags.any(
                              (tag) => selectedTags.contains(tag),
                            ),
                          )
                          .toList();
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedTags = [];
                    filteredCategories = List.from(categories);
                  });
                  Navigator.pop(context);
                },
                child: const Text('Clear'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final subCategoriesController = TextEditingController(text: '0');
    List<String> tags = [];
    final tagController = TextEditingController();
    Color selectedColor = Colors.blue;
    String abbreviation = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Category'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        setDialogState(() {
                          abbreviation = value
                              .split(' ')
                              .map(
                                (word) => word.isNotEmpty
                                    ? word[0].toUpperCase()
                                    : '',
                              )
                              .join();
                          if (abbreviation.length > 2) {
                            abbreviation = abbreviation.substring(0, 2);
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: subCategoriesController,
                          decoration: const InputDecoration(
                            labelText: 'Sub-categories',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            abbreviation,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Color:'),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          [
                            Colors.blue,
                            Colors.red,
                            Colors.green,
                            Colors.orange,
                            Colors.purple,
                            Colors.teal,
                            Colors.pink,
                            Colors.amber,
                            Colors.cyan,
                          ].map((color) {
                            return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    selectedColor = color;
                                  });
                                },
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: selectedColor == color
                                        ? Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tagController,
                          decoration: const InputDecoration(
                            labelText: 'Add Tag',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (tagController.text.isNotEmpty) {
                            setDialogState(() {
                              tags.add(tagController.text);
                              tagController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: () {
                          setDialogState(() {
                            tags.remove(tag);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.isEmpty ||
                      descriptionController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all required fields'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final newCategory = CourseCategory(
                    name: nameController.text,
                    abbreviation: abbreviation,
                    color: selectedColor,
                    subCategoriesCount:
                        int.tryParse(subCategoriesController.text) ?? 0,
                    description: descriptionController.text,
                    tags: tags,
                  );

                  setState(() {
                    categories.add(newCategory);
                    filteredCategories = List.from(categories);
                  });

                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, CourseCategory category) {
    final nameController = TextEditingController(text: category.name);
    final descriptionController = TextEditingController(
      text: category.description,
    );
    final subCategoriesController = TextEditingController(
      text: category.subCategoriesCount.toString(),
    );
    List<String> tags = List.from(category.tags);
    final tagController = TextEditingController();
    Color selectedColor = category.color;
    String abbreviation = category.abbreviation;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Category'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        setDialogState(() {
                          abbreviation = value
                              .split(' ')
                              .map(
                                (word) => word.isNotEmpty
                                    ? word[0].toUpperCase()
                                    : '',
                              )
                              .join();
                          if (abbreviation.length > 2) {
                            abbreviation = abbreviation.substring(0, 2);
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: subCategoriesController,
                          decoration: const InputDecoration(
                            labelText: 'Sub-categories',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            abbreviation,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Color:'),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          [
                            Colors.blue,
                            Colors.red,
                            Colors.green,
                            Colors.orange,
                            Colors.purple,
                            Colors.teal,
                            Colors.pink,
                            Colors.amber,
                            Colors.cyan,
                          ].map((color) {
                            return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    selectedColor = color;
                                  });
                                },
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: selectedColor == color
                                        ? Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tagController,
                          decoration: const InputDecoration(
                            labelText: 'Add Tag',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (tagController.text.isNotEmpty) {
                            setDialogState(() {
                              tags.add(tagController.text);
                              tagController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: () {
                          setDialogState(() {
                            tags.remove(tag);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.isEmpty ||
                      descriptionController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all required fields'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setState(() {
                    final index = categories.indexOf(category);
                    if (index != -1) {
                      categories[index] = CourseCategory(
                        name: nameController.text,
                        abbreviation: abbreviation,
                        color: selectedColor,
                        subCategoriesCount:
                            int.tryParse(subCategoriesController.text) ?? 0,
                        description: descriptionController.text,
                        tags: tags,
                      );
                      filteredCategories = List.from(categories);
                    }
                  });

                  Navigator.pop(context);
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, CourseCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}" category?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                categories.remove(category);
                filteredCategories = List.from(categories);
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class CategorySearchDelegate extends SearchDelegate<String> {
  final List<CourseCategory> categories;
  final Function(String) onSearch;

  CategorySearchDelegate({required this.categories, required this.onSearch});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    close(context, query);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? []
        : categories
              .where(
                (category) =>
                    category.name.toLowerCase().contains(query.toLowerCase()) ||
                    category.tags.any(
                      (tag) => tag.toLowerCase().contains(query.toLowerCase()),
                    ),
              )
              .toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        final category = suggestionList[index];
        return ListTile(
          leading: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: category.color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                category.abbreviation,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          title: Text(category.name),
          subtitle: Text('${category.subCategoriesCount} SubCategories'),
          onTap: () {
            query = category.name;
            showResults(context);
          },
        );
      },
    );
  }
}
