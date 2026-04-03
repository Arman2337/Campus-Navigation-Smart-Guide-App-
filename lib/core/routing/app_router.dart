import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/map/map_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/saved/saved_locations_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/navigation/navigation_screen.dart';
import '../../screens/navigation/ar_navigation_screen.dart';
import '../../screens/location_detail/location_detail_screen.dart';
import '../../screens/admin/add_location_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final status = authProvider.status;
        final location = state.uri.toString();

        final isAuth = status == AuthStatus.authenticated;
        final isInitial = status == AuthStatus.initial;

        final publicRoutes = [
          '/splash',
          '/onboarding',
          '/login',
          '/register',
          '/forgot-password',
        ];
        final isPublicRoute = publicRoutes.any((r) => location.startsWith(r));

        if (isInitial) return null;
        if (!isAuth && !isPublicRoute) return '/login';
        if (isAuth && (location == '/login' || location == '/register')) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return MainShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/map',
              builder: (context, state) => const MapScreen(),
            ),
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),
            GoRoute(
              path: '/saved',
              builder: (context, state) => const SavedLocationsScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/location/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return LocationDetailScreen(locationId: id);
          },
        ),
        GoRoute(
          path: '/navigate/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return NavigationScreen(locationId: id);
          },
        ),
        GoRoute(
          path: '/ar-navigate/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ARNavigationScreen(locationId: id);
          },
        ),
        GoRoute(
          path: '/add-location',
          builder: (context, state) => const AddLocationScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Page not found: ${state.uri}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<String> _routes = ['/home', '/map', '/search', '/saved', '/profile'];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
            context.go(_routes[index]);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark
              ? const Color(0xFF1E1E2E)
              : Colors.white,
          selectedItemColor: const Color(0xFF1A73E8),
          unselectedItemColor: isDark ? Colors.white38 : Colors.grey,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline),
              activeIcon: Icon(Icons.bookmark),
              label: 'Saved',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
