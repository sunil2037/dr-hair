import 'package:flutter_test/flutter_test.dart';
import 'package:dr_hair/core/routes/app_destination.dart';

void main() {
  test('product destination resolves an ID based route', () {
    final destination = AppDestination.fromJson({
      'type': 'product',
      'entityId': 'follicle-booster-serum',
      'fallback': 'products',
    });
    expect(destination.location, '/products/follicle-booster-serum');
    expect(destination.fallbackLocation, '/products');

    final upperCaseDestination = AppDestination.fromJson({
      'type': 'product',
      'entityId': 'PRD-17412345',
    });
    expect(upperCaseDestination.location, '/products/PRD-17412345');

    final underscoreDestination = AppDestination.fromJson({
      'type': 'product',
      'entityId': 'prd_custom_101',
    });
    expect(underscoreDestination.location, '/products/prd_custom_101');
  });

  test('unknown and malformed destinations cannot create routes', () {
    expect(AppDestination.fromJson({'type': 'booking'}).location, isNull);
    expect(
      AppDestination.fromJson({'type': 'product', 'entityId': '../profile'})
          .location,
      isNull,
    );
  });

  test('clinic appointment destination uses the single doctor screen', () {
    expect(
      AppDestination.fromJson({
        'type': 'screen',
        'screen': 'clinic_appointment',
      }).location,
      '/clinic-appointment',
    );
  });

  test('screen aliases resolve correctly to canonical routes', () {
    expect(
      AppDestination.fromJson({'screen': 'consultation'}).location,
      '/clinic-appointment',
    );
    expect(
      AppDestination.fromJson({'screen': 'appointments'}).location,
      '/clinic-appointment',
    );
    expect(
      AppDestination.fromJson({'screen': 'reels'}).location,
      '/videos',
    );
    expect(
      AppDestination.fromJson({'screen': 'care_plan'}).location,
      '/profile',
    );
    expect(
      AppDestination.fromJson({'screen': 'assessment'}).location,
      '/hair-test',
    );
  });

  test('safe route resolver handles invalid and non-existent locations', () {
    expect(AppDestination.isValidRoute('/clinic-appointment'), isTrue);
    expect(AppDestination.isValidRoute('/products/follicle-booster'), isTrue);
    expect(AppDestination.isValidRoute('/invalid-route-123'), isFalse);
    expect(AppDestination.isValidRoute(''), isFalse);
    expect(AppDestination.isValidRoute(null), isFalse);

    // Resolves valid routes as-is
    expect(
      AppDestination.resolveSafeLocation('/clinic-appointment'),
      '/clinic-appointment',
    );
    expect(
      AppDestination.resolveSafeLocation('/products/serum-101'),
      '/products/serum-101',
    );

    // Resolves unknown or malformed routes to safe fallback
    expect(
      AppDestination.resolveSafeLocation('/unknown/screen/does_not_exist'),
      '/notifications',
    );
    expect(
      AppDestination.resolveSafeLocation(null),
      '/notifications',
    );
    expect(
      AppDestination.resolveSafeLocation('', fallback: '/'),
      '/',
    );
  });
}
