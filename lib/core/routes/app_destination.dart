import 'route_names.dart';

/// The supported destinations for app content and notification actions.
/// Unknown targets resolve to a safe screen rather than an arbitrary URL.
class AppDestination {
  final String type;
  final String? screen;
  final String? entityId;

  const AppDestination.screen(String name)
    : type = 'screen',
      screen = name,
      entityId = null;

  const AppDestination.product(String id)
    : type = 'product',
      screen = null,
      entityId = id;

  factory AppDestination.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] ?? json['destination_type'];
    if (rawType == 'product') {
      final id = json['entityId'] ?? json['entity_id'] ?? json['productId'] ?? '';
      return AppDestination.product(id is String ? id : id.toString());
    }
    if (rawType == 'screen' || json.containsKey('screen')) {
      final screen = json['screen'] ?? json['target'] ?? '';
      return AppDestination.screen(screen is String ? screen : screen.toString());
    }
    return const AppDestination.screen('');
  }

  factory AppDestination.fromNotificationData(Map<String, dynamic> data) {
    return AppDestination.fromJson(data);
  }

  String? get location {
    if (type == 'product') {
      final id = entityId;
      if (id == null || !RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(id)) {
        return null;
      }
      return RouteNames.productPath(id);
    }
    final normalized = (screen ?? '').trim().toLowerCase().replaceAll('-', '_');
    return switch (normalized) {
      'home' || 'dashboard' || 'main' => RouteNames.mainShell,
      'hair_test' || 'hairtest' || 'test' || 'assessment' => RouteNames.hairTest,
      'product' || 'products' || 'shop' || 'store' || 'catalog' => RouteNames.products,
      'video' || 'videos' || 'reels' || 'stories' => RouteNames.videos,
      'review' || 'reviews' => RouteNames.reviews,
      'notification' || 'notifications' || 'inbox' || 'alerts' => RouteNames.notifications,
      'profile' || 'account' || 'routine' || 'care_plan' || 'careplan' => RouteNames.profile,
      'order' || 'orders' || 'my_orders' => RouteNames.orders,
      'appointment' || 'appointments' || 'clinic_appointment' || 'consultation' => RouteNames.clinicAppointment,
      'cart' || 'bag' => RouteNames.cart,
      'reminder' || 'reminders' => RouteNames.reminders,
      'diet' || 'diet_plan' || 'dietplan' => RouteNames.dietPlan,
      'privacy' || 'privacy_policy' => RouteNames.privacyPolicy,
      'terms' || 'terms_and_conditions' => RouteNames.terms,
      'assessment_result' => RouteNames.assessmentResult,
      _ => null,
    };
  }

  String get fallbackLocation =>
      type == 'product' ? RouteNames.products : RouteNames.mainShell;

  static final Set<String> _knownStaticRoutes = {
    RouteNames.mainShell,
    RouteNames.splash,
    RouteNames.home,
    RouteNames.reviews,
    RouteNames.hairTest,
    RouteNames.videos,
    RouteNames.profile,
    RouteNames.settings,
    RouteNames.updateProfile,
    RouteNames.treatmentDetails,
    RouteNames.cart,
    RouteNames.notifications,
    RouteNames.productDetails,
    RouteNames.checkout,
    RouteNames.signin,
    RouteNames.otp,
    RouteNames.completeProfile,
    RouteNames.about,
    RouteNames.contact,
    RouteNames.routine,
    RouteNames.progress,
    RouteNames.clinicAppointment,
    RouteNames.dietPlan,
    RouteNames.reminders,
    RouteNames.orders,
    RouteNames.orderTracking,
    RouteNames.policy,
    RouteNames.privacyPolicy,
    RouteNames.terms,
    RouteNames.returnsRefunds,
    RouteNames.cancellationPolicy,
    RouteNames.products,
    RouteNames.assessmentResult,
  };

  /// Validates whether a candidate URI path exists in the app's routing table.
  static bool isValidRoute(String? path) {
    if (path == null || path.trim().isEmpty) return false;
    final clean = path.trim();
    if (_knownStaticRoutes.contains(clean)) return true;
    if (clean.startsWith('/products/')) {
      final id = clean.substring('/products/'.length);
      return id.isNotEmpty && RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(id);
    }
    return false;
  }

  /// Resolves a candidate destination into a guaranteed valid route.
  /// If the target route does not exist or is malformed, falls back safely to
  /// [fallback] rather than throwing or crashing GoRouter.
  static String resolveSafeLocation(
    String? candidateLocation, {
    String fallback = RouteNames.notifications,
  }) {
    if (isValidRoute(candidateLocation)) {
      return candidateLocation!;
    }
    return fallback;
  }
}
