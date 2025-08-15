import 'package:feastly/bloc/cart_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'package:feastly/bloc/menu_bloc.dart';
import 'package:go_router/go_router.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  FoodCategory? _selectedCategory;
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarCollapsed = false;

  @override
  void initState() {
    super.initState();
    context.read<MenuBloc>().add(FetchMenuItems(widget.restaurantId));

    // Add listener to track scroll for collapsible app bar
    _scrollController.addListener(() {
      setState(() {
        _isAppBarCollapsed = _scrollController.offset > 200;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        final restaurant = state is MenuLoaded ? state.restaurant : null;

        return Scaffold(
          body: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(restaurant),
            ],
            body: _buildBody(state),
          ),
          floatingActionButton:
              state is MenuLoaded && (state.menuItems.isNotEmpty)
              ? FloatingActionButton.extended(
                  onPressed: () => context.go('/cart'),
                  label: const Text('View Cart'),
                  icon: const Icon(Icons.shopping_cart),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                )
              : null,
        );
      },
    );
  }

  Widget _buildSliverAppBar(Restaurant? restaurant) {
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      title: _isAppBarCollapsed
          ? Text(
              restaurant?.name ?? 'Restaurant Details',
              style: const TextStyle(fontWeight: FontWeight.bold),
            )
          : null,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isAppBarCollapsed
                ? Colors.transparent
                : Colors.white.withValues(alpha: .9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back,
            color: _isAppBarCollapsed ? Colors.white : Colors.black,
          ),
        ),
        onPressed: () => context.go('/home'),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isAppBarCollapsed
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: .9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border,
              color: _isAppBarCollapsed ? Colors.white : Colors.black,
            ),
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isAppBarCollapsed
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: .9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.share,
              color: _isAppBarCollapsed ? Colors.white : Colors.black,
            ),
          ),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: restaurant != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  // Restaurant Image
                  Image.network(
                    restaurant.imageUrls.isNotEmpty
                        ? restaurant.imageUrls.first
                        : 'https://via.placeholder.com/800x400?text=Restaurant',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.restaurant,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  // Gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                  // Restaurant info at the bottom of the image
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                restaurant.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    restaurant.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          restaurant.categories
                              .map((c) => _formatCategoryName(c))
                              .join(' • '),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Container(color: Colors.grey[300]),
      ),
    );
  }

  Widget _buildBody(MenuState state) {
    if (state is MenuLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is MenuError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<MenuBloc>().add(
                  FetchMenuItems(widget.restaurantId),
                );
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    } else if (state is MenuLoaded) {
      final restaurant = state.restaurant;

      if (restaurant == null) {
        return const Center(child: Text('Restaurant information not found'));
      }

      return CustomScrollView(
        slivers: [
          // Restaurant info section
          SliverToBoxAdapter(child: _buildRestaurantInfo(restaurant)),

          // Search bar
          SliverToBoxAdapter(child: _buildSearchBar()),

          // Food categories filter
          SliverToBoxAdapter(child: _buildCategoryFilter(state.menuItems)),

          // Menu items list
          state.menuItems.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.no_food, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No menu items found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (state.searchQuery != null)
                          Text(
                            'Try a different search term',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        if (state.selectedCategory != null)
                          Text(
                            'Try a different category',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildMenuItem(state.menuItems[index]),
                    childCount: state.menuItems.length,
                  ),
                ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildRestaurantInfo(Restaurant restaurant) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.description,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.isOpen ? 'Open Now' : 'Closed',
                          style: TextStyle(
                            color: restaurant.isOpen
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.delivery_dining, size: 16),
                        const SizedBox(width: 4),
                        const Text('30-45 min'),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${restaurant.numberOfRatings}+ ratings',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoButton(Icons.directions, 'Directions'),
              _buildInfoButton(Icons.bookmark_border, 'Save'),
              _buildInfoButton(Icons.call, 'Call'),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  restaurant.address,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoButton(IconData icon, String label) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search in menu',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<MenuBloc>().add(FetchMenuItems(widget.restaurantId));
            },
          ),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) {
          if (value.isEmpty) {
            context.read<MenuBloc>().add(FetchMenuItems(widget.restaurantId));
          }
        },
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            context.read<MenuBloc>().add(
              SearchMenuItems(widget.restaurantId, value),
            );
          } else {
            context.read<MenuBloc>().add(FetchMenuItems(widget.restaurantId));
          }
          // Hide keyboard explicitly
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  Widget _buildCategoryFilter(List<MenuItem> menuItems) {
    // Extract unique categories from menu items
    final categories = <FoodCategory>{};
    for (final item in menuItems) {
      categories.addAll(item.categories);
    }

    return SizedBox(
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Menu Categories',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedCategory = null;
                          context.read<MenuBloc>().add(
                            FetchMenuItems(widget.restaurantId),
                          );
                        } else {
                          _selectedCategory = category;
                          context.read<MenuBloc>().add(
                            FilterMenuByCategory(widget.restaurantId, category),
                          );
                        }
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getCategoryIcon(category),
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatFoodCategoryName(category),
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(MenuItem menuItem) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _showMenuItemDetails(menuItem);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 18,
                          width: 18,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: menuItem.isVegetarian
                                  ? Colors.green
                                  : Colors.red,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.circle,
                              size: 10,
                              color: menuItem.isVegetarian
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            menuItem.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Price
                    Text(
                      '₹${menuItem.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Description
                    Text(
                      menuItem.description,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Food categories as tags
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: menuItem.categories
                          .take(3)
                          .map(
                            (category) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatFoodCategoryName(category),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      menuItem.imageUrls.isNotEmpty
                          ? menuItem.imageUrls
                          : 'https://via.placeholder.com/100',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.fastfood),
                      ),
                    ),
                  ),
                  // Add button
                  Transform.translate(
                    offset: const Offset(0, 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        iconSize: 18,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: const EdgeInsets.all(4),
                        onPressed: () {
                          context.read<CartBloc>().add(
                            AddCartItem(menuItem: menuItem, quantity: 1),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${menuItem.name} added to cart'),
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: 'View Cart',
                                onPressed: () => context.go('/cart'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenuItemDetails(MenuItem menuItem) {
    final parentContext = context;
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle indicator
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            // Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                menuItem.imageUrls.isNotEmpty
                    ? menuItem.imageUrls
                    : 'https://via.placeholder.com/800x400',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.fastfood, size: 64, color: Colors.grey),
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and veg/non-veg indicator
                      Row(
                        children: [
                          Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: menuItem.isVegetarian
                                    ? Colors.green
                                    : Colors.red,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.circle,
                                size: 12,
                                color: menuItem.isVegetarian
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              menuItem.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Price
                      Text(
                        '₹${menuItem.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        menuItem.description,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 16),
                      // Categories
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: menuItem.categories.map((category) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatFoodCategoryName(category),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // Dietary information
                      const Text(
                        'Dietary Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildDietaryInfo(
                            'Vegetarian',
                            menuItem.isVegetarian,
                          ),
                          const SizedBox(width: 16),
                          _buildDietaryInfo('Vegan', menuItem.isVegan),
                          const SizedBox(width: 16),
                          _buildDietaryInfo(
                            'Gluten Free',
                            menuItem.isGlutenFree,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Add to cart button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: ElevatedButton(
                onPressed: () {
                  // Close modal first
                  Navigator.pop(context);

                  // Add to cart using CartBloc
                  context.read<CartBloc>().add(
                    AddCartItem(menuItem: menuItem, quantity: 1),
                  );
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text('${menuItem.name} added to cart'),
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'View Cart',
                        onPressed: () => parentContext.go('/cart'),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('ADD TO CART'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietaryInfo(String label, bool value) {
    return Row(
      children: [
        Icon(
          value ? Icons.check_circle : Icons.cancel,
          color: value ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  IconData _getCategoryIcon(FoodCategory category) {
    switch (category) {
      case FoodCategory.breakfast:
        return Icons.free_breakfast;
      case FoodCategory.lunch:
        return Icons.lunch_dining;
      case FoodCategory.dinner:
        return Icons.dinner_dining;
      case FoodCategory.snacks:
        return Icons.restaurant;
      case FoodCategory.beverages:
        return Icons.local_drink;
      case FoodCategory.desserts:
        return Icons.cake;
      case FoodCategory.veg:
        return Icons.eco;
      case FoodCategory.nonVeg:
        return Icons.fastfood;
      case FoodCategory.vegan:
        return Icons.spa;
      default:
        return Icons.restaurant_menu;
    }
  }

  String _formatFoodCategoryName(FoodCategory category) {
    final name = category.toString().split('.').last;
    if (name == 'nonVeg') return 'Non-Veg';

    return name[0].toUpperCase() + name.substring(1);
  }

  String _formatCategoryName(RestaurantCategory category) {
    final name = category.toString().split('.').last;
    if (name == 'fastFood') return 'Fast Food';
    if (name == 'fineDining') return 'Fine Dining';
    if (name == 'cloudKitchen') return 'Cloud Kitchen';

    return name[0].toUpperCase() + name.substring(1);
  }
}
