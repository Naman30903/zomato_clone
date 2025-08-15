import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import '../bloc/menu_mgmt_bloc.dart';

class MenuManagementScreen extends StatefulWidget {
  final String restaurantId;

  const MenuManagementScreen({Key? key, required this.restaurantId})
    : super(key: key);

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  FoodCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    context.read<MenuMgmtBloc>().add(FetchMenuItems(widget.restaurantId));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Menu Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(
            child: BlocConsumer<MenuMgmtBloc, MenuMgmtState>(
              listener: (context, state) {
                if (state is MenuItemAdded) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${state.menuItem.name} added to menu'),
                    ),
                  );
                } else if (state is MenuItemUpdated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${state.menuItem.name} updated')),
                  );
                } else if (state is MenuItemDeleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Menu item deleted')),
                  );
                } else if (state is MenuMgmtError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is MenuMgmtLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is MenuMgmtLoaded) {
                  if (state.menuItems.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildMenuItemsList(state.menuItems);
                } else if (state is MenuMgmtError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<MenuMgmtBloc>().add(
                              FetchMenuItems(widget.restaurantId),
                            );
                          },
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddEditItemDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search menu items...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<MenuMgmtBloc>().add(
                FetchMenuItems(widget.restaurantId),
              );
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: EdgeInsets.zero,
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            context.read<MenuMgmtBloc>().add(
              SearchMenuItems(widget.restaurantId, value),
            );
          } else {
            context.read<MenuMgmtBloc>().add(
              FetchMenuItems(widget.restaurantId),
            );
          }
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryChip(null, 'All'),
          ...FoodCategory.values.map((category) {
            return _buildCategoryChip(category, _formatCategoryName(category));
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(FoodCategory? category, String label) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });

          if (category == null) {
            context.read<MenuMgmtBloc>().add(
              FetchMenuItems(widget.restaurantId),
            );
          } else {
            context.read<MenuMgmtBloc>().add(
              FilterMenuByCategory(widget.restaurantId, category),
            );
          }
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        checkmarkColor: Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No menu items found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCategory != null
                ? 'Try a different category'
                : 'Add your first menu item',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (_selectedCategory != null) {
                setState(() {
                  _selectedCategory = null;
                });
                context.read<MenuMgmtBloc>().add(
                  FetchMenuItems(widget.restaurantId),
                );
              } else {
                _showAddEditItemDialog();
              }
            },
            icon: Icon(_selectedCategory != null ? Icons.refresh : Icons.add),
            label: Text(
              _selectedCategory != null ? 'Show All Items' : 'Add Menu Item',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemsList(List<MenuItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildMenuItemCard(item);
      },
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item image with availability badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    item.imageUrls.isNotEmpty
                        ? item.imageUrls
                        : 'https://via.placeholder.com/400x225?text=No+Image',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: item.isAvailable ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item.isAvailable ? 'Available' : 'Unavailable',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 16,
                        width: 16,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: item.isVegetarian
                                ? Colors.green
                                : Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.circle,
                            size: 8,
                            color: item.isVegetarian
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and price
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '₹${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  item.description,
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Categories
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.categories.map((category) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _formatCategoryName(category),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Toggle availability
                    OutlinedButton.icon(
                      onPressed: () {
                        _toggleItemAvailability(item);
                      },
                      icon: Icon(
                        item.isAvailable
                            ? Icons.cancel_outlined
                            : Icons.check_circle_outline,
                      ),
                      label: Text(
                        item.isAvailable
                            ? 'Mark Unavailable'
                            : 'Mark Available',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Edit
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        _showAddEditItemDialog(menuItem: item);
                      },
                      tooltip: 'Edit item',
                    ),
                    // Delete
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      onPressed: () {
                        _showDeleteConfirmationDialog(item);
                      },
                      tooltip: 'Delete item',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleItemAvailability(MenuItem item) {
    final updatedItem = item.copyWith(isAvailable: !item.isAvailable);
    context.read<MenuMgmtBloc>().add(UpdateMenuItem(updatedItem));
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Menu Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sort By',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              ListTile(
                title: const Text('Price (Low to High)'),
                leading: const Icon(Icons.arrow_upward),
                onTap: () {
                  Navigator.pop(context);
                  // Implement sorting
                },
              ),
              ListTile(
                title: const Text('Price (High to Low)'),
                leading: const Icon(Icons.arrow_downward),
                onTap: () {
                  Navigator.pop(context);
                  // Implement sorting
                },
              ),
              ListTile(
                title: const Text('Name (A-Z)'),
                leading: const Icon(Icons.sort_by_alpha),
                onTap: () {
                  Navigator.pop(context);
                  // Implement sorting
                },
              ),
              ListTile(
                title: const Text('Most Recent'),
                leading: const Icon(Icons.access_time),
                onTap: () {
                  Navigator.pop(context);
                  // Implement sorting
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Text(
          'Are you sure you want to delete "${item.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<MenuMgmtBloc>().add(DeleteMenuItem(item.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _showAddEditItemDialog({MenuItem? menuItem}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditMenuItemForm(
        restaurantId: widget.restaurantId,
        menuItem: menuItem,
      ),
    );
  }

  String _formatCategoryName(FoodCategory category) {
    final name = category.toString().split('.').last;
    if (name == 'nonVeg') return 'Non-Veg';

    // Convert camelCase to Title Case with spaces
    return name
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .capitalize();
  }
}

// Form for adding/editing menu items
class AddEditMenuItemForm extends StatefulWidget {
  final String restaurantId;
  final MenuItem? menuItem;

  const AddEditMenuItemForm({
    Key? key,
    required this.restaurantId,
    this.menuItem,
  }) : super(key: key);

  @override
  State<AddEditMenuItemForm> createState() => _AddEditMenuItemFormState();
}

class _AddEditMenuItemFormState extends State<AddEditMenuItemForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageUrlController;

  bool _isVegetarian = false;
  bool _isVegan = false;
  bool _isGlutenFree = false;
  bool _isAvailable = true;

  final List<FoodCategory> _selectedCategories = [];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing values if editing
    _nameController = TextEditingController(text: widget.menuItem?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.menuItem?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.menuItem?.price.toString() ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.menuItem?.imageUrls ?? '',
    );

    if (widget.menuItem != null) {
      _isVegetarian = widget.menuItem!.isVegetarian;
      _isVegan = widget.menuItem!.isVegan;
      _isGlutenFree = widget.menuItem!.isGlutenFree;
      _isAvailable = widget.menuItem!.isAvailable;
      _selectedCategories.addAll(widget.menuItem!.categories);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Form title
              Center(
                child: Text(
                  widget.menuItem == null
                      ? 'Add New Menu Item'
                      : 'Edit Menu Item',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description*',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Price field
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (₹)*',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  try {
                    final price = double.parse(value);
                    if (price <= 0) {
                      return 'Price must be greater than zero';
                    }
                  } catch (e) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Image URL field
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  border: OutlineInputBorder(),
                  hintText: 'https://example.com/image.jpg',
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Categories',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              // Categories chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FoodCategory.values.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(_formatCategoryName(category)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(category);
                        } else {
                          _selectedCategories.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              const Text(
                'Dietary Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              // Dietary checkboxes
              CheckboxListTile(
                title: const Text('Vegetarian'),
                value: _isVegetarian,
                onChanged: (value) {
                  setState(() {
                    _isVegetarian = value ?? false;
                    // If not vegetarian, can't be vegan
                    if (!_isVegetarian) {
                      _isVegan = false;
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              CheckboxListTile(
                title: const Text('Vegan'),
                value: _isVegan,
                onChanged: _isVegetarian
                    ? (value) {
                        setState(() {
                          _isVegan = value ?? false;
                        });
                      }
                    : null,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              CheckboxListTile(
                title: const Text('Gluten Free'),
                value: _isGlutenFree,
                onChanged: (value) {
                  setState(() {
                    _isGlutenFree = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              CheckboxListTile(
                title: const Text('Available'),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value ?? true;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.menuItem == null ? 'ADD ITEM' : 'UPDATE ITEM',
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one category')),
        );
        return;
      }

      try {
        final price = double.parse(_priceController.text);
        final now = DateTime.now();

        final menuItem = MenuItem(
          id:
              widget.menuItem?.id ??
              'temp_${DateTime.now().millisecondsSinceEpoch}',
          name: _nameController.text,
          description: _descriptionController.text,
          price: price,
          restaurantId: widget.restaurantId,
          imageUrls: _imageUrlController.text,
          isAvailable: _isAvailable,
          categories: _selectedCategories,
          isVegetarian: _isVegetarian,
          isVegan: _isVegan,
          isGlutenFree: _isGlutenFree,
          createdAt: widget.menuItem?.createdAt ?? now,
          updatedAt: now,
        );

        if (widget.menuItem == null) {
          // Add new item
          context.read<MenuMgmtBloc>().add(AddMenuItem(menuItem));
        } else {
          // Update existing item
          context.read<MenuMgmtBloc>().add(UpdateMenuItem(menuItem));
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  String _formatCategoryName(FoodCategory category) {
    final name = category.toString().split('.').last;
    if (name == 'nonVeg') return 'Non-Veg';

    // Convert camelCase to Title Case with spaces
    return name
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .capitalize();
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
  }
}
