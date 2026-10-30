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
}
