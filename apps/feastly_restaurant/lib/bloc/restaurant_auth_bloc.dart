import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:core/core.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LogIn extends AuthEvent {
  final String email;
  final String password;

  const LogIn({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SignUp extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final UserRole role;

  const SignUp({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [name, email, password, role];
}

class LogOut extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepo authRepo;

  AuthBloc({required this.authRepo}) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LogIn>(_onLogIn);
    on<SignUp>(_onSignUp);
    on<LogOut>(_onLogOut);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepo.getCurrentUser();
      if (user != null) {
        if (user.role != UserRole.restaurantOwner) {
          await authRepo.signOut();
          emit(Unauthenticated());
          return;
        }
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogIn(LogIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepo.signIn(event.email, event.password);

      // Verify the user has the correct role
      if (user.role != UserRole.restaurantOwner) {
        await authRepo.signOut();
        emit(const AuthError('This account is not a restaurant owner account'));
        return;
      }

      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignUp(SignUp event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepo.signUp(
        event.name,
        event.email,
        event.password,
        UserRole.restaurantOwner,
      );

      // Verify the user has the correct role
      if (user.role != UserRole.restaurantOwner) {
        await authRepo.signOut();
        emit(const AuthError('This account is not a restaurant owner account'));
        return;
      }

      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogOut(LogOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepo.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
