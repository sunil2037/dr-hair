import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Clinical category entity for product root causes, video reels, services, and hair concerns.
class CategoryItem {
  final String id;
  final String name;
  final String slug;
  final String type;
  final String iconName;
  final String? badge;
  final String? description;
  final int itemCount;
  final String? imageUrl;
  final String? price;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    this.type = 'product',
    this.iconName = 'layout-grid',
    this.badge,
    this.description,
    this.itemCount = 0,
    this.imageUrl,
    this.price,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      type: (json['type'] ?? 'product').toString(),
      iconName: (json['icon'] ?? 'layout-grid').toString(),
      badge: json['badge'] as String?,
      description: json['description'] as String?,
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String?,
      price: json['price'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'type': type,
      'icon': iconName,
      if (badge != null) 'badge': badge,
      if (description != null) 'description': description,
      'item_count': itemCount,
      if (imageUrl != null) 'image_url': imageUrl,
      if (price != null) 'price': price,
    };
  }

  IconData get icon {
    switch (iconName.toLowerCase()) {
      case 'sparkles':
        return LucideIcons.sparkles;
      case 'shield-check':
      case 'shieldcheck':
        return LucideIcons.shieldCheck;
      case 'apple':
        return LucideIcons.apple;
      case 'brain':
        return LucideIcons.brain;
      case 'activity':
        return LucideIcons.activity;
      case 'flower-2':
      case 'flower2':
        return LucideIcons.flower2;
      case 'dna':
        return LucideIcons.dna;
      case 'film':
        return LucideIcons.film;
      case 'trending-up':
      case 'trendingup':
        return LucideIcons.trendingUp;
      case 'stethoscope':
        return LucideIcons.stethoscope;
      case 'camera':
        return LucideIcons.camera;
      case 'user-check':
      case 'usercheck':
        return LucideIcons.userCheck;
      case 'syringe':
        return LucideIcons.syringe;
      case 'zap':
        return LucideIcons.zap;
      case 'leaf':
        return LucideIcons.leaf;
      case 'layout-grid':
      case 'layoutgrid':
      default:
        return LucideIcons.layoutGrid;
    }
  }

  static List<CategoryItem> defaultProductCategories() => const [
    CategoryItem(id: 'all', name: 'All', slug: 'all', iconName: 'layout-grid'),
    CategoryItem(id: 'hair', name: 'Hair', slug: 'hair', iconName: 'sparkles'),
    CategoryItem(id: 'dandruff', name: 'Dandruff', slug: 'dandruff', iconName: 'shield-check'),
    CategoryItem(id: 'gut', name: 'Gut', slug: 'gut', iconName: 'apple'),
    CategoryItem(id: 'stress', name: 'Stress', slug: 'stress', iconName: 'brain'),
    CategoryItem(id: 'thyroid', name: 'Thyroid', slug: 'thyroid', iconName: 'activity'),
    CategoryItem(id: 'pcos', name: 'PCOS', slug: 'pcos', iconName: 'flower-2'),
    CategoryItem(id: 'hormone', name: 'Hormone', slug: 'hormone', iconName: 'dna'),
  ];
}

