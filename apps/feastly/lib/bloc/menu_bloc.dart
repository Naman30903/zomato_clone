import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class MenuEvent extends Equatable {
  const MenuEvent();

  @override
  List<Object?> get props => [];
}

class FetchMenuItems extends MenuEvent {
  final String restaurantId;

  const FetchMenuItems(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}

class SearchMenuItems extends MenuEvent {
  final String restaurantId;
  final String query;

  const SearchMenuItems(this.restaurantId, this.query);

  @override
  List<Object?> get props => [restaurantId, query];
}

class FilterMenuByCategory extends MenuEvent {
  final String restaurantId;
  final FoodCategory category;

  const FilterMenuByCategory(this.restaurantId, this.category);

  @override
  List<Object?> get props => [restaurantId, category];
}

// States
abstract class MenuState extends Equatable {
  const MenuState();

  @override
  List<Object?> get props => [];
}

class MenuInitial extends MenuState {}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final List<MenuItem> menuItems;
  final FoodCategory? selectedCategory;
  final String? searchQuery;
  final Restaurant? restaurant;

  const MenuLoaded({
    required this.menuItems,
    this.selectedCategory,
    this.searchQuery,
    this.restaurant,
  });

  @override
  List<Object?> get props => [
    menuItems,
    selectedCategory,
    searchQuery,
    restaurant,
  ];
}

class MenuError extends MenuState {
  final String message;

  const MenuError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final MenuRepo menuRepo;
  final RestaurantRepo restaurantRepo;

  MenuBloc({required this.menuRepo, required this.restaurantRepo})
    : super(MenuInitial()) {
    on<FetchMenuItems>(_onFetchMenuItems);
    on<SearchMenuItems>(_onSearchMenuItems);
    on<FilterMenuByCategory>(_onFilterMenuByCategory);
  }

  Future<void> _onFetchMenuItems(
    FetchMenuItems event,
    Emitter<MenuState> emit,
  ) async {
    emit(MenuLoading());

    try {
      final menuItems = await menuRepo.getMenuItems(event.restaurantId);
      final restaurant = await restaurantRepo.getRestaurantById(
        event.restaurantId,
      );

      emit(MenuLoaded(menuItems: menuItems, restaurant: restaurant));
    } catch (e) {
      emit(MenuError('Failed to load menu items: ${e.toString()}'));
    }
  }

  Future<void> _onSearchMenuItems(
    SearchMenuItems event,
    Emitter<MenuState> emit,
  ) async {
    emit(MenuLoading());

    try {
      final menuItems = await menuRepo.searchMenuItems(
        event.restaurantId,
        event.query,
      );
      final restaurant = await restaurantRepo.getRestaurantById(
        event.restaurantId,
      );

      emit(
        MenuLoaded(
          menuItems: menuItems,
          searchQuery: event.query,
          restaurant: restaurant,
        ),
      );
    } catch (e) {
      emit(MenuError('Failed to search menu items: ${e.toString()}'));
    }
  }

  Future<void> _onFilterMenuByCategory(
    FilterMenuByCategory event,
    Emitter<MenuState> emit,
  ) async {
    emit(MenuLoading());

    try {
      final menuItems = await menuRepo.getMenuItemsByCategory(
        event.restaurantId,
        event.category,
      );
      final restaurant = await restaurantRepo.getRestaurantById(
        event.restaurantId,
      );

      emit(
        MenuLoaded(
          menuItems: menuItems,
          selectedCategory: event.category,
          restaurant: restaurant,
        ),
      );
    } catch (e) {
      emit(MenuError('Failed to filter menu items: ${e.toString()}'));
    }
  }
}
