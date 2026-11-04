import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/views/signin_view.dart';
import '../../features/auth/presentation/views/complete_profile_view.dart';
import '../../features/appointments/presentation/clinic_appointment_view.dart';
import '../../features/auth/presentation/views/splash_view.dart';
import '../../features/hair_test/presentation/views/assessment_result_view.dart';
import '../../features/hair_test/presentation/views/hair_test_view.dart';
import '../../features/home/presentation/views/home_view.dart';
import '../../features/profile/presentation/views/profile_view.dart';
import '../../features/profile/presentation/views/settings_view.dart';
import '../../features/profile/presentation/views/update_profile_view.dart';
import '../../features/reviews/presentation/views/reviews_view.dart';
import '../../features/shell/presentation/views/main_shell_view.dart';
import '../../features/shop/data/models/product_model.dart';
import '../../features/shop/presentation/views/cart_view.dart';
import '../../features/shop/presentation/views/notifications_view.dart';
import '../../features/shop/presentation/views/checkout_view.dart';
import '../../features/shop/presentation/views/product_details_view.dart';
import '../../features/shop/presentation/views/products_view.dart';
import '../../features/static/domain/policy_models.dart';
import '../../features/static/presentation/views/about_view.dart';
import '../../features/static/presentation/views/contact_view.dart';
import '../../features/static/presentation/views/policy_page_view.dart';
import '../../features/treatment/presentation/views/treatment_details_view.dart';
import '../../features/videos/presentation/views/videos_view.dart';
import '../widgets/assessment_gate.dart';
import '../widgets/auth_gate.dart';
import '../../features/care/presentation/views/diet_plan_view.dart';
import '../../features/care/presentation/views/order_tracking_view.dart';
import '../../features/care/presentation/views/progress_tracking_view.dart';
import '../../features/care/presentation/views/reminders_view.dart';
import '../../features/care/presentation/views/routine_tracker_view.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashView(),
      ),
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
                builder: (context, state) {
                  final initialVideoId =
                      state.uri.queryParameters['videoId'] ??
                      (state.extra is String ? state.extra as String : null);
                  return VideosView(initialVideoId: initialVideoId);
                },
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
        path: RouteNames.home,
        redirect: (context, state) => RouteNames.mainShell,
      ),
      GoRoute(
        path: RouteNames.hairTest,
        builder: (context, state) => const HairTestView(),
      ),
      GoRoute(
        path: RouteNames.assessmentResult,
        builder: (context, state) =>
            AssessmentRequiredRoute(child: const AssessmentResultView()),
      ),
      GoRoute(
        path: RouteNames.updateProfile,
        builder: (context, state) => const AuthRequiredRoute(
          routePath: RouteNames.updateProfile,
          child: UpdateProfileView(),
        ),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const AuthRequiredRoute(
          routePath: RouteNames.settings,
          child: SettingsView(),
        ),
      ),
      GoRoute(
        path: RouteNames.treatmentDetails,
        builder: (context, state) => AuthRequiredRoute(
          routePath: RouteNames.treatmentDetails,
          child: AssessmentRequiredRoute(child: const TreatmentDetailsView()),
        ),
      ),
      GoRoute(
        path: RouteNames.cart,
        builder: (context, state) {
          final items = state.extra as List<Map<String, dynamic>>?;
          return CartView(initialItems: items);
        },
      ),
      GoRoute(
        path: RouteNames.notifications,
        builder: (context, state) => const NotificationsView(),
      ),
      GoRoute(
        path: RouteNames.productDetails,
        redirect: (context, state) =>
            state.extra is ProductItem ? null : RouteNames.products,
        builder: (context, state) {
          final product = state.extra as ProductItem;
          return ProductDetailsView(initialProduct: product);
        },
      ),
      GoRoute(
        path: RouteNames.productById,
        builder: (context, state) {
          final id = state.pathParameters['productId'];
          final product = ProductItem.findById(id);
          return ProductDetailsView(
            productId: id,
            initialProduct: product,
          );
        },
      ),
      GoRoute(
        path: RouteNames.checkout,
        builder: (context, state) => const AuthRequiredRoute(
          routePath: RouteNames.checkout,
          child: CheckoutView(),
        ),
      ),
      GoRoute(
        path: RouteNames.products,
        builder: (context, state) => const ProductsView(),
      ),
      GoRoute(
        path: RouteNames.signin,
        builder: (context, state) => const SigninView(),
      ),
      GoRoute(
        path: RouteNames.completeProfile,
        builder: (context, state) => const CompleteProfileView(),
      ),
      GoRoute(
        path: RouteNames.about,
        builder: (context, state) => const AboutView(),
      ),
      GoRoute(
        path: RouteNames.contact,
        builder: (context, state) => const ContactView(),
      ),
      GoRoute(
        path: RouteNames.routine,
        builder: (context, state) => AuthRequiredRoute(
          routePath: RouteNames.routine,
          child: AssessmentRequiredRoute(child: const RoutineTrackerView()),
        ),
      ),
      GoRoute(
        path: RouteNames.progress,
        builder: (context, state) => AuthRequiredRoute(
          routePath: RouteNames.progress,
          child: AssessmentRequiredRoute(
            child: ProgressTrackingView(
              autoOpenAddCheckIn: state.extra is bool && state.extra == true,
            ),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.clinicAppointment,
        builder: (context, state) => const AuthRequiredRoute(
          routePath: RouteNames.clinicAppointment,
          child: ClinicAppointmentView(),
        ),
      ),
      GoRoute(
        path: RouteNames.dietPlan,
        builder: (context, state) => AuthRequiredRoute(
          routePath: RouteNames.dietPlan,
          child: AssessmentRequiredRoute(child: const DietPlanView()),
        ),
      ),
      GoRoute(
        path: RouteNames.reminders,
        builder: (context, state) => AuthRequiredRoute(
          routePath: RouteNames.reminders,
          child: AssessmentRequiredRoute(child: const RemindersView()),
        ),
      ),
      GoRoute(
        path: RouteNames.orders,
        builder: (context, state) => const AuthRequiredRoute(
          routePath: RouteNames.orders,
          child: OrderTrackingView(),
        ),
      ),
      GoRoute(
        path: RouteNames.policy,
        builder: (context, state) {
          final policyType =
              state.extra as PolicyType? ??
              PolicyType.fromSlug(state.uri.queryParameters['type']);
          return PolicyPageView(initialType: policyType);
        },
      ),
      GoRoute(
        path: RouteNames.privacyPolicy,
        builder: (context, state) =>
            const PolicyPageView(initialType: PolicyType.privacyPolicy),
      ),
      GoRoute(
        path: RouteNames.terms,
        builder: (context, state) =>
            const PolicyPageView(initialType: PolicyType.termsAndConditions),
      ),
      GoRoute(
        path: RouteNames.returnsRefunds,
        builder: (context, state) =>
            const PolicyPageView(initialType: PolicyType.returnsAndRefunds),
      ),
      GoRoute(
        path: RouteNames.cancellationPolicy,
        builder: (context, state) =>
            const PolicyPageView(initialType: PolicyType.cancellationPolicy),
      ),
    ],
  );
}
