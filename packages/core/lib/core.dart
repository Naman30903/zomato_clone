// packages/core/lib/core.dart

// 📦 Models
export 'src/models/user.dart';
export 'src/models/restaurant.dart';
export 'src/models/menu_item.dart';
export 'src/models/cart_item.dart';
export 'src/models/order.dart';
export 'src/models/enums.dart';

// 📦 Repository Interfaces
export 'src/repositories/auth_repo.dart';
export 'src/repositories/restaurant_repo.dart';
export 'src/repositories/menu_repo.dart';
export 'src/repositories/order_repo.dart';

// 📦 Mock Repository Implementations
export 'src/repositories/mock/mock_auth_repo.dart';
export 'src/repositories/mock/mock_restaurant_repo.dart';
export 'src/repositories/mock/mock_menu_repo.dart';
export 'src/repositories/mock/mock_order_repo.dart';
export 'src/repositories/firebase/firebase_auth_repo.dart';

// 📦 Shared BLoCs
export 'src/blocs/auth_bloc.dart';
export 'src/blocs/order_tracking_bloc.dart';

// 📦 Utilities
export 'src/utils/formatters.dart';
export 'src/utils/validators.dart';
export 'src/utils/helpers.dart';

// 📦 Services
export 'src/services/app_config.dart';
export 'src/services/logger_service.dart';

// 📦 Errors
export 'src/errors/app_exception.dart';

// Add new UI exports
export 'src/ui/login_screen.dart';
export 'src/ui/signup_screen.dart';
