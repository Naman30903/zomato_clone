import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class RestaurantListEvent extends Equatable {
  const RestaurantListEvent();

  @override
  List<Object?> get props => [];
}

class FetchRestaurants extends RestaurantListEvent {
  const FetchRestaurants();
}

class SearchRestaurants extends RestaurantListEvent {
  final String query;

  const SearchRestaurants(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterRestaurantsByCategory extends RestaurantListEvent {
  final RestaurantCategory category;

  const FilterRestaurantsByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

// States
abstract class RestaurantListState extends Equatable {
  const RestaurantListState();

  @override
  List<Object?> get props => [];
}

class RestaurantListInitial extends RestaurantListState {}

class RestaurantListLoading extends RestaurantListState {}

class RestaurantListLoaded extends RestaurantListState {
  final List<Restaurant> restaurants;
  final RestaurantCategory? selectedCategory;
  final String? searchQuery;

  const RestaurantListLoaded({
    required this.restaurants,
    this.selectedCategory,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [restaurants, selectedCategory, searchQuery];
}

class RestaurantListError extends RestaurantListState {
  final String message;

  const RestaurantListError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class RestaurantListBloc
    extends Bloc<RestaurantListEvent, RestaurantListState> {
  final RestaurantRepo restaurantRepo;

  RestaurantListBloc({required this.restaurantRepo})
    : super(RestaurantListInitial()) {
    on<FetchRestaurants>(_onFetchRestaurants);
    on<SearchRestaurants>(_onSearchRestaurants);
    on<FilterRestaurantsByCategory>(_onFilterRestaurantsByCategory);
  }

  Future<void> _onFetchRestaurants(
    FetchRestaurants event,
    Emitter<RestaurantListState> emit,
  ) async {
    emit(RestaurantListLoading());

    try {
      final restaurants = await restaurantRepo.getRestaurants();
      emit(RestaurantListLoaded(restaurants: restaurants));
    } catch (e) {
      emit(RestaurantListError('Failed to load restaurants: ${e.toString()}'));
    }
  }

  Future<void> _onSearchRestaurants(
    SearchRestaurants event,
    Emitter<RestaurantListState> emit,
  ) async {
    emit(RestaurantListLoading());

    try {
      final restaurants = await restaurantRepo.searchRestaurants(event.query);
      emit(
        RestaurantListLoaded(
          restaurants: restaurants,
          searchQuery: event.query,
        ),
      );
    } catch (e) {
      emit(
        RestaurantListError('Failed to search restaurants: ${e.toString()}'),
      );
    }
  }

  Future<void> _onFilterRestaurantsByCategory(
    FilterRestaurantsByCategory event,
    Emitter<RestaurantListState> emit,
  ) async {
    emit(RestaurantListLoading());

    try {
      final restaurants = await restaurantRepo.getRestaurantsByCategory(
        event.category,
      );
      emit(
        RestaurantListLoaded(
          restaurants: restaurants,
          selectedCategory: event.category,
        ),
      );
    } catch (e) {
      emit(
        RestaurantListError('Failed to filter restaurants: ${e.toString()}'),
      );
    }
  }
}
