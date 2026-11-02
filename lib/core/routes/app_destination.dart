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
    return switch (screen) {
      'home' => RouteNames.mainShell,
      'hair_test' => RouteNames.hairTest,
      'products' => RouteNames.products,
      'videos' => RouteNames.videos,
      'reviews' => RouteNames.reviews,
      'notifications' => RouteNames.notifications,
      'profile' => RouteNames.profile,
      'orders' => RouteNames.orders,
      'clinic_appointment' => RouteNames.clinicAppointment,
      'cart' => RouteNames.cart,
      'reminders' => RouteNames.reminders,
      'diet_plan' => RouteNames.dietPlan,
      _ => null,
    };
  }

  String get fallbackLocation =>
      type == 'product' ? RouteNames.products : RouteNames.mainShell;
}
