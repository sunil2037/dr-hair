import 'package:flutter/foundation.dart';

@immutable
class ReviewModel {
  final String id;
  final String name;
  final int rating;
  final String category;
  final String treatment;
  final String duration;
  final String comment;
  final bool verified;
  final String avatar;

  const ReviewModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.category,
    this.treatment = 'Hair Treatment',
    this.duration = '',
    required this.comment,
    this.verified = true,
    this.avatar = '',
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating'];
    final ratingNum = rawRating is num
        ? rawRating.round()
        : int.tryParse(rawRating?.toString() ?? '5') ?? 5;

    return ReviewModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Verified Patient',
      rating: ratingNum.clamp(1, 5),
      category: json['category']?.toString() ?? 'General',
      treatment: json['treatment']?.toString() ??
          (json['category'] != null ? '${json['category']} Care' : 'Hair Treatment'),
      duration: json['duration']?.toString() ?? '',
      comment: json['message']?.toString() ?? json['comment']?.toString() ?? '',
      verified: json['verified'] == true || json['status'] == 'active',
      avatar: json['avatar']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rating': rating,
        'category': category,
        'treatment': treatment,
        'duration': duration,
        'comment': comment,
        'verified': verified,
        'avatar': avatar,
      };

  static const List<ReviewModel> defaultReviews = [
    ReviewModel(
      id: 'rev_1',
      name: 'Yashveer Soni',
      rating: 5,
      category: 'Hair Fall',
      treatment: 'Stage 3 Receding Hairline',
      duration: 'Used for 5 months',
      comment:
          'DrHair completely reversed my hairline thinning. Following the customized routine faithfully with the topical booster made a night and day difference.',
      verified: true,
      avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=300',
    ),
    ReviewModel(
      id: 'rev_2',
      name: 'Rahul Sharma',
      rating: 5,
      category: 'Regrowth',
      treatment: 'Crown Thinning & Density Loss',
      duration: 'Used for 4 months',
      comment:
          'I was skeptical after trying various store shampoos. But having a doctor analyze my scalp photos and formulate specific serums stopped my daily hair shed by week 4.',
      verified: true,
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=300',
    ),
    ReviewModel(
      id: 'rev_3',
      name: 'Ananya Mehra',
      rating: 4,
      category: 'Dandruff',
      treatment: 'Dry Flaking & Follicle Weakness',
      duration: 'Used for 2 months',
      comment:
          'Cleared stubborn scalp buildup and dandruff within 3 weeks. Hair roots feel significantly cleaner and thicker now.',
      verified: true,
      avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=300',
    ),
    ReviewModel(
      id: 'rev_4',
      name: 'Vikram Malhotra',
      rating: 5,
      category: 'Regrowth',
      treatment: 'Crown Thinning & DHT Regimen',
      duration: 'Used for 6 months',
      comment:
          'I noticed a visible improvement in my hair thickness over the months. Consistency with the daily scalp booster was key.',
      verified: true,
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=300',
    ),
    ReviewModel(
      id: 'rev_5',
      name: 'Sneha Kapoor',
      rating: 5,
      category: 'Hair Fall',
      treatment: 'Post-Stress Hair Shedding',
      duration: 'Used for 3 months',
      comment:
          'Hair shedding reduced noticeably after several weeks of routine care. The serum is lightweight and easy to apply.',
      verified: true,
      avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=300',
    ),
  ];
}
