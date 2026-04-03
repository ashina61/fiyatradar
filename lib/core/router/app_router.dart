import 'package:go_router/go_router.dart';

import '../../features/add_price/presentation/add_price_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/product_detail/presentation/product_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../shared/widgets/app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
        GoRoute(path: '/add-price', builder: (_, __) => const AddPriceScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
    GoRoute(path: '/detail', builder: (_, __) => const ProductDetailScreen()),
    GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
  ],
);
