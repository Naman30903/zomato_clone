import 'dart:async';
import 'package:core/src/models/user.dart';
import 'package:core/src/models/enums.dart';
import 'package:core/src/repositories/auth_repo.dart';

class MockAuthRepo implements AuthRepo {
  final List<User> _users = [
    User(
      id: '1',
      name: 'John Doe',
      email: 'customer@example.com',
      role: UserRole.customer,
      phoneNumber: '1234567890',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    User(
      id: '2',
      name: 'Restaurant Owner',
      email: 'restaurant@example.com',
      role: UserRole.restaurantOwner,
      phoneNumber: '0987654321',
      addresses: ['456 Food Ave'],
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    User(
      id: '3',
      name: 'Delivery Person',
      email: 'delivery@example.com',
      role: UserRole.deliveryPerson,
      phoneNumber: '5556667777',
      addresses: ['789 Delivery Rd'],
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  User? _currentUser;
  final _authStateController = StreamController<User?>.broadcast();

  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<User> signIn(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final user = _users.firstWhere(
      (user) => user.email == email,
      orElse: () => throw Exception('Invalid credentials'),
    );

    _currentUser = user;
    _authStateController.add(user);
    return user;
  }

  @override
  Future<User> signUp(
    String name,
    String email,
    String password,
    UserRole role,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    // Check if email already exists
    if (_users.any((user) => user.email == email)) {
      throw Exception('Email already in use');
    }

    final newUser = User(
      id: 'user_${_users.length + 1}',
      name: name,
      email: email,
      role: role,
      phoneNumber: '',
      addresses: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _users.add(newUser);
    _currentUser = newUser;
    _authStateController.add(newUser);
    return newUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<User> updateProfile(User user) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _users.indexWhere((u) => u.id == user.id);
    if (index == -1) {
      throw Exception('User not found');
    }

    final updatedUser = user.copyWith(updatedAt: DateTime.now());
    _users[index] = updatedUser;

    if (_currentUser?.id == user.id) {
      _currentUser = updatedUser;
      _authStateController.add(updatedUser);
    }

    return updatedUser;
  }

  @override
  Future<bool> resetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return _users.any((user) => user.email == email);
  }

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  // Clean up resources
  void dispose() {
    _authStateController.close();
  }
}
