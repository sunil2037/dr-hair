import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/views/otp_view.dart';
import '../../features/auth/presentation/views/signin_view.dart';
import '../../features/hair_test/presentation/views/hair_test_view.dart';
import '../../features/home/presentation/views/home_view.dart';
import '../../features/profile/presentation/views/profile_view.dart';
import '../../features/profile/presentation/views/update_profile_view.dart';
import '../../features/reviews/presentation/views/reviews_view.dart';
import '../../features/shell/presentation/views/main_shell_view.dart';
import '../../features/shop/presentation/views/cart_view.dart';
import '../../features/shop/presentation/views/checkout_view.dart';
import '../../features/shop/presentation/views/product_details_view.dart';
import '../../features/static/presentation/views/about_view.dart';
import '../../features/static/presentation/views/contact_view.dart';
import '../../features/treatment/presentation/views/treatment_details_view.dart';
import '../../features/videos/presentation/views/videos_view.dart';
import '../../features/care/presentation/views/care_feature_views.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.mainShell,
    routes: [
      // Persistent Bottom Navigation Shell via StatefulShellRoute (4 main tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellView(navigationShell: navigationShell);
        },
        branches: [
          // 0. Home Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.mainShell,
                builder: (context, state) => HomeView(
                  onStartHairTest: () => context.push(RouteNames.hairTest),
                ),
              ),
            ],
          ),

          // 1. Reviews Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.reviews,
                builder: (context, state) => const ReviewsView(),
              ),
            ],
          ),

          // 2. Videos Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.videos,
                builder: (context, state) => const VideosView(),
              ),
            ],
          ),

          // 3. Profile Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.profile,
                builder: (context, state) => const ProfileView(),
              ),
            ],
          ),
        ],
      ),

      // Standalone full-screen routes that push over the shell (NO bottom nav, NO shell navbar)
      GoRoute(
        path: RouteNames.hairTest,
        builder: (context, state) => const HairTestView(),
      ),
      GoRoute(
        path: RouteNames.updateProfile,
        builder: (context, state) => const UpdateProfileView(),
      ),
      GoRoute(
        path: RouteNames.treatmentDetails,
        builder: (context, state) => const TreatmentDetailsView(),
      ),
      GoRoute(
        path: RouteNames.cart,
        builder: (context, state) => const CartView(),
      ),
      GoRoute(
        path: RouteNames.productDetails,
        builder: (context, state) => const ProductDetailsView(),
      ),
      GoRoute(
        path: RouteNames.checkout,
        builder: (context, state) => CheckoutView(
          amount: state.extra as int? ?? 2048,
        ),
      ),
      GoRoute(
        path: RouteNames.signin,
        builder: (context, state) => const SigninView(),
      ),
      GoRoute(
        path: RouteNames.otp,
        builder: (context, state) {
          final identifier = state.extra as String? ?? '';
          return OtpView(identifier: identifier);
        },
      ),
      GoRoute(
        path: RouteNames.about,
        builder: (context, state) => const AboutView(),
      ),
      GoRoute(
        path: RouteNames.contact,
        builder: (context, state) => const ContactView(),
      ),
      GoRoute(path: RouteNames.routine, builder: (context, state) => const RoutineTrackerView()),
      GoRoute(path: RouteNames.progress, builder: (context, state) => const ProgressTrackingView()),
      GoRoute(path: RouteNames.coachBooking, builder: (context, state) => const CoachBookingView()),
      GoRoute(path: RouteNames.dietPlan, builder: (context, state) => const DietPlanView()),
      GoRoute(path: RouteNames.reminders, builder: (context, state) => const RemindersView()),
      GoRoute(path: RouteNames.orders, builder: (context, state) => const OrderTrackingView()),
    ],
  );
}
