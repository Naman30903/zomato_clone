import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class MenuMgmtEvent extends Equatable {
  const MenuMgmtEvent();

  @override
  List<Object?> get props => [];
}

class FetchMenuItems extends MenuMgmtEvent {
  final String restaurantId;
  const FetchMenuItems(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}

class AddMenuItem extends MenuMgmtEvent {
  final MenuItem menuItem;
  const AddMenuItem(this.menuItem);

  @override
  List<Object?> get props => [menuItem];
}

class UpdateMenuItem extends MenuMgmtEvent {
  final MenuItem menuItem;
  const UpdateMenuItem(this.menuItem);

  @override
  List<Object?> get props => [menuItem];
}

class DeleteMenuItem extends MenuMgmtEvent {
  final String menuItemId;
  const DeleteMenuItem(this.menuItemId);

  @override
  List<Object?> get props => [menuItemId];
}

class SearchMenuItems extends MenuMgmtEvent {
  final String restaurantId;
  final String query;
  const SearchMenuItems(this.restaurantId, this.query);

  @override
  List<Object?> get props => [restaurantId, query];
}

class FilterMenuByCategory extends MenuMgmtEvent {
  final String restaurantId;
  final FoodCategory category;
  const FilterMenuByCategory(this.restaurantId, this.category);

  @override
  List<Object?> get props => [restaurantId, category];
}

// States
abstract class MenuMgmtState extends Equatable {
  const MenuMgmtState();

  @override
  List<Object?> get props => [];
}

class MenuMgmtInitial extends MenuMgmtState {}

class MenuMgmtLoading extends MenuMgmtState {}

class MenuMgmtLoaded extends MenuMgmtState {
  final List<MenuItem> menuItems;
  final FoodCategory? selectedCategory;
  final String? searchQuery;

  const MenuMgmtLoaded({
    required this.menuItems,
    this.selectedCategory,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [menuItems, selectedCategory, searchQuery];
}

class MenuItemAdded extends MenuMgmtState {
  final MenuItem menuItem;
  const MenuItemAdded(this.menuItem);

  @override
  List<Object?> get props => [menuItem];
}

class MenuItemUpdated extends MenuMgmtState {
  final MenuItem menuItem;
  const MenuItemUpdated(this.menuItem);

  @override
  List<Object?> get props => [menuItem];
}

class MenuItemDeleted extends MenuMgmtState {
  final String menuItemId;
  const MenuItemDeleted(this.menuItemId);

  @override
  List<Object?> get props => [menuItemId];
}

class MenuMgmtError extends MenuMgmtState {
  final String message;
  const MenuMgmtError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class MenuMgmtBloc extends Bloc<MenuMgmtEvent, MenuMgmtState> {
  final MenuRepo menuRepo;
  StreamSubscription? _menuItemsSubscription;

  MenuMgmtBloc({required this.menuRepo}) : super(MenuMgmtInitial()) {
    on<FetchMenuItems>(_onFetchMenuItems);
    on<AddMenuItem>(_onAddMenuItem);
    on<UpdateMenuItem>(_onUpdateMenuItem);
    on<DeleteMenuItem>(_onDeleteMenuItem);
    on<SearchMenuItems>(_onSearchMenuItems);
    on<FilterMenuByCategory>(_onFilterMenuByCategory);
  }

  Future<void> _onFetchMenuItems(
    FetchMenuItems event,
    Emitter<MenuMgmtState> emit,
  ) async {
    emit(MenuMgmtLoading());
    try {
      final menuItems = await menuRepo.getMenuItems(event.restaurantId);
      emit(MenuMgmtLoaded(menuItems: menuItems));
    } catch (e) {
      emit(MenuMgmtError('Failed to load menu items: ${e.toString()}'));
    }
  }

  Future<void> _onAddMenuItem(
    AddMenuItem event,
    Emitter<MenuMgmtState> emit,
  ) async {
    // Store the current state to revert back if needed
    final currentState = state;
    try {
      emit(MenuMgmtLoading());
      final menuItem = await menuRepo.createMenuItem(event.menuItem);
      emit(MenuItemAdded(menuItem));

      // Refresh the menu items list
      if (currentState is MenuMgmtLoaded) {
        emit(
          MenuMgmtLoaded(
            menuItems: [...currentState.menuItems, menuItem],
            selectedCategory: currentState.selectedCategory,
            searchQuery: currentState.searchQuery,
          ),
        );
      } else {
        // If we don't have a previous loaded state, fetch all items
        add(FetchMenuItems(event.menuItem.restaurantId));
      }
    } catch (e) {
      emit(MenuMgmtError('Failed to add menu item: ${e.toString()}'));
      // Revert to previous state
      if (currentState is MenuMgmtLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onUpdateMenuItem(
    UpdateMenuItem event,
    Emitter<MenuMgmtState> emit,
  ) async {
    final currentState = state;
    try {
      emit(MenuMgmtLoading());
      final menuItem = await menuRepo.updateMenuItem(event.menuItem);
      emit(MenuItemUpdated(menuItem));

      // Update the menu items list
      if (currentState is MenuMgmtLoaded) {
        final updatedItems = currentState.menuItems.map((item) {
          return item.id == menuItem.id ? menuItem : item;
        }).toList();

        emit(
          MenuMgmtLoaded(
            menuItems: updatedItems,
            selectedCategory: currentState.selectedCategory,
            searchQuery: currentState.searchQuery,
          ),
        );
      } else {
        add(FetchMenuItems(event.menuItem.restaurantId));
      }
    } catch (e) {
      emit(MenuMgmtError('Failed to update menu item: ${e.toString()}'));
      if (currentState is MenuMgmtLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onDeleteMenuItem(
    DeleteMenuItem event,
    Emitter<MenuMgmtState> emit,
  ) async {
    final currentState = state;
    try {
      emit(MenuMgmtLoading());
      await menuRepo.deleteMenuItem(event.menuItemId);
      emit(MenuItemDeleted(event.menuItemId));

      // Update the menu items list
      if (currentState is MenuMgmtLoaded) {
        final updatedItems = currentState.menuItems
            .where((item) => item.id != event.menuItemId)
            .toList();

        emit(
          MenuMgmtLoaded(
            menuItems: updatedItems,
            selectedCategory: currentState.selectedCategory,
            searchQuery: currentState.searchQuery,
          ),
        );
      }
    } catch (e) {
      emit(MenuMgmtError('Failed to delete menu item: ${e.toString()}'));
      if (currentState is MenuMgmtLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onSearchMenuItems(
    SearchMenuItems event,
    Emitter<MenuMgmtState> emit,
  ) async {
    emit(MenuMgmtLoading());
    try {
      final menuItems = await menuRepo.searchMenuItems(
        event.restaurantId,
        event.query,
      );
      emit(MenuMgmtLoaded(menuItems: menuItems, searchQuery: event.query));
    } catch (e) {
      emit(MenuMgmtError('Failed to search menu items: ${e.toString()}'));
    }
  }

  Future<void> _onFilterMenuByCategory(
    FilterMenuByCategory event,
    Emitter<MenuMgmtState> emit,
  ) async {
    emit(MenuMgmtLoading());
    try {
      final menuItems = await menuRepo.getMenuItemsByCategory(
        event.restaurantId,
        event.category,
      );
      emit(
        MenuMgmtLoaded(menuItems: menuItems, selectedCategory: event.category),
      );
    } catch (e) {
      emit(MenuMgmtError('Failed to filter menu items: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _menuItemsSubscription?.cancel();
    return super.close();
  }
}
