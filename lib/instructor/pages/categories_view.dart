import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fluttertest/instructor/services/category_service.dart';
import 'dart:math';

class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> categories = [];
  List<Color> categoryColors = [
    Colors.purple[400]!,
    Colors.amber[400]!,
    Colors.blue[400]!,
    Colors.green[400]!,
    Colors.red[400]!,
    Colors.teal[400]!,
  ];

  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _categoryDescController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use CategoryService to get categories
      final result = await CategoryService.getCategories();

      // Debug log
      print("Categories fetch result: $result");

      if (result['success'] == true) {
        final categoriesData = result['categories'] as List;
        print("Categories data: $categoriesData");
        
        setState(() {
          categories = List<Map<String, dynamic>>.from(
            categoriesData.map((category) {
              // Get tags from the category object - could be in 'tags' field or subCategories
              List<String> tags = [];
              if (category['tags'] is List) {
                tags = List<String>.from(category['tags']);
              } else if (category['subCategories'] is List) {
                tags = (category['subCategories'] as List)
                  .map((sub) => sub['name'].toString())
                  .toList();
              }

              return {
                'name': category['name'] ?? 'Unknown',
                'abbr': _getAbbreviation(category['name'] ?? 'Unknown'),
                'subCategories': tags.length,
                'color':
                    categoryColors[Random().nextInt(categoryColors.length)],
                'description':
                    category['description'] ?? 'No description available',
                'tags': tags,
                'id': category['_id'] ?? '', // Store the ID for future operations
              };
            }),
          );
          _isLoading = false;
        });
      } else {
        throw Exception(
          'Failed to load categories: ${result['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('Error fetching categories: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load categories: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () {
                _fetchCategories();
              },
            ),
          ),
        );
      }
      
      setState(() {
        // Use an empty list instead of sample data
        categories = [];
        _isLoading = false;
      });
    }
  }

  String _getAbbreviation(String name) {
    if (name.isEmpty) return '';

    final words = name.split(' ');
    if (words.length == 1) {
      return name.substring(0, min(2, name.length)).toUpperCase();
    }

    return words
        .map((word) => word.isNotEmpty ? word[0] : '')
        .join('')
        .toUpperCase();
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _categoryDescController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog(BuildContext context) {
    _categoryNameController.clear();
    _categoryDescController.clear();
    _tagsController.clear();
    List<String> selectedTags = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 16),
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagsController,
                            decoration: const InputDecoration(
                              hintText: 'Enter tag',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                setState(() {
                                  selectedTags.add(value);
                                  _tagsController.clear();
                                });
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Color(0xFF5F299E)),
                          onPressed: () {
                            if (_tagsController.text.isNotEmpty) {
                              setState(() {
                                selectedTags.add(_tagsController.text);
                                _tagsController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Display selected tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: selectedTags.map((tag) {
                        return Chip(
                          label: Text(
                            tag,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.grey[200],
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              selectedTags.remove(tag);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
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
                      this.setState(() {
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
                          'subCategories': selectedTags.length,
                          'color': Colors.purple[400]!,
                          'description': _categoryDescController.text.isEmpty
                              ? 'New Category Description'
                              : _categoryDescController.text,
                          'tags': selectedTags,
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
      },
    );
  }

  void _showEditCategoryDialog(BuildContext context, int index) {
    _categoryNameController.text = categories[index]['name'];
    _categoryDescController.text = categories[index]['description'];
    _tagsController.clear();
    List<String> selectedTags = List<String>.from(categories[index]['tags']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 16),
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagsController,
                            decoration: const InputDecoration(
                              hintText: 'Enter tag',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                setState(() {
                                  selectedTags.add(value);
                                  _tagsController.clear();
                                });
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Color(0xFF5F299E)),
                          onPressed: () {
                            if (_tagsController.text.isNotEmpty) {
                              setState(() {
                                selectedTags.add(_tagsController.text);
                                _tagsController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Display selected tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: selectedTags.map((tag) {
                        return Chip(
                          label: Text(
                            tag,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.grey[200],
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              selectedTags.remove(tag);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
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
                      this.setState(() {
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
                        categories[index]['tags'] = selectedTags;
                        categories[index]['subCategories'] =
                            selectedTags.length;
                      });
                      Navigator.of(context).pop();
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F299E)),
        ),
      );
    }

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
          child: categories.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No Categories Found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add categories to organize your courses',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showAddCategoryDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5F299E),
                        ),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add Your First Category', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive grid: Adjust crossAxisCount based on available width
                    final width = constraints.maxWidth;
                    // Use more columns on larger screens
                    final crossAxisCount = width < 600
                        ? 2
                        : width < 900
                        ? 3
                        : 4;

                    return MasonryGridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                ),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          child: Text(
                            category['description'],
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Subcategory Tags - Show all tags
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            // Show all tags instead of limiting
                            children: (category['tags'] as List<String>).map((
                              tag,
                            ) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
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
                        // Add some padding at the bottom
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
