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
    if (json['type'] == 'product') {
      final id = json['entityId'];
      return AppDestination.product(id is String ? id : '');
    }
    if (json['type'] == 'screen') {
      final screen = json['screen'];
      return AppDestination.screen(screen is String ? screen : '');
    }
    return const AppDestination.screen('');
  }

  String? get location {
    if (type == 'product') {
      final id = entityId;
      if (id == null || !RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(id)) {
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
      _ => null,
    };
  }

  String get fallbackLocation =>
      type == 'product' ? RouteNames.products : RouteNames.mainShell;
}
