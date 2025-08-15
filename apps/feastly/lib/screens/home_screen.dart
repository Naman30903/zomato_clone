import 'package:feastly/bloc/restuartant_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  RestaurantCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    context.read<RestaurantListBloc>().add(const FetchRestaurants());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildCategoryFilter(),
            _buildRestaurantList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivering to',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  Text(
                    'Current Location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ],
          ),
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                // Navigate to profile screen
                context.go('/profile');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for restaurants, cuisines...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<RestaurantListBloc>().add(const FetchRestaurants());
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
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            context.read<RestaurantListBloc>().add(SearchRestaurants(value));
          } else {
            context.read<RestaurantListBloc>().add(const FetchRestaurants());
          }
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Categories',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: RestaurantCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedCategory = null;
                          context.read<RestaurantListBloc>().add(
                            const FetchRestaurants(),
                          );
                        } else {
                          _selectedCategory = category;
                          context.read<RestaurantListBloc>().add(
                            FilterRestaurantsByCategory(category),
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
                          _formatCategoryName(category),
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

  Widget _buildRestaurantList() {
    return Expanded(
      child: BlocBuilder<RestaurantListBloc, RestaurantListState>(
        builder: (context, state) {
          if (state is RestaurantListLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is RestaurantListLoaded) {
            if (state.restaurants.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No restaurants found',
                      style: Theme.of(context).textTheme.headlineSmall,
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
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = state.restaurants[index];
                return _buildRestaurantCard(restaurant);
              },
            );
          } else if (state is RestaurantListError) {
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
                      context.read<RestaurantListBloc>().add(
                        const FetchRestaurants(),
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
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    final imageUrl = restaurant.imageUrls.isNotEmpty
        ? restaurant.imageUrls.first
        : 'https://via.placeholder.com/400x200?text=No+Image';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to restaurant detail screen
          context.go('/restaurant/${restaurant.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 64),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          ' (${restaurant.numberOfRatings})',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (restaurant.isOpen)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'OPEN',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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
                  Text(
                    restaurant.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          restaurant.address,
                          style: TextStyle(color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: restaurant.categories.map((category) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _formatCategoryName(category),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(RestaurantCategory category) {
    switch (category) {
      case RestaurantCategory.fastFood:
        return Icons.fastfood;
      case RestaurantCategory.casual:
        return Icons.restaurant;
      case RestaurantCategory.fineDining:
        return Icons.restaurant_menu;
      case RestaurantCategory.cafe:
        return Icons.coffee;
      case RestaurantCategory.bakery:
        return Icons.cake;
      case RestaurantCategory.buffet:
        return Icons.dinner_dining;
      case RestaurantCategory.cloudKitchen:
        return Icons.cloud;
      default:
        return Icons.restaurant;
    }
  }

  String _formatCategoryName(RestaurantCategory category) {
    final name = category.toString().split('.').last;
    if (name == 'fastFood') return 'Fast Food';
    if (name == 'fineDining') return 'Fine Dining';
    if (name == 'cloudKitchen') return 'Cloud Kitchen';

    return name[0].toUpperCase() + name.substring(1);
  }
}
