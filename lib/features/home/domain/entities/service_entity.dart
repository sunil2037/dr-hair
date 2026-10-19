class ServiceEntity {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double rating;
  final int reviewsCount;
  final String price;

  const ServiceEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.reviewsCount,
    required this.price,
  });
}
