/// Delivery Address Model for checkout order fulfillment.
class DeliveryAddress {
  final String id;
  final String name;
  final String phone;
  final String houseNumber;
  final String street;
  final String city;
  final String state;
  final String pinCode;
  final String tag; // 'Home', 'Work', 'Other'
  final bool isDefault;

  const DeliveryAddress({
    required this.id,
    required this.name,
    required this.phone,
    required this.houseNumber,
    required this.street,
    required this.city,
    required this.state,
    required this.pinCode,
    this.tag = 'Home',
    this.isDefault = false,
  });

  String get formattedAddress =>
      '$houseNumber, $street, $city, $state - $pinCode';

  DeliveryAddress copyWith({
    String? id,
    String? name,
    String? phone,
    String? houseNumber,
    String? street,
    String? city,
    String? state,
    String? pinCode,
    String? tag,
    bool? isDefault,
  }) {
    return DeliveryAddress(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      houseNumber: houseNumber ?? this.houseNumber,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      tag: tag ?? this.tag,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  static List<DeliveryAddress> defaultAddresses() => [
        const DeliveryAddress(
          id: 'addr_home',
          name: 'Yashveer Soni',
          phone: '+91 98765 43210',
          houseNumber: 'Flat 402, Royal Residency',
          street: 'Shipra Path, Mansarovar',
          city: 'Jaipur',
          state: 'Rajasthan',
          pinCode: '302020',
          tag: 'Home',
          isDefault: true,
        ),
        const DeliveryAddress(
          id: 'addr_work',
          name: 'Yashveer Soni',
          phone: '+91 98765 43210',
          houseNumber: 'Plot 12, Tower B, Level 3',
          street: 'World Trade Park, Malviya Nagar',
          city: 'Jaipur',
          state: 'Rajasthan',
          pinCode: '302017',
          tag: 'Work',
          isDefault: false,
        ),
      ];
}
