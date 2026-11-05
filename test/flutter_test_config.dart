import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_hair/core/network/dio_client.dart';

class _HermeticTestHttpClientAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;

    // Return mock responses matching standard backend response envelopes
    Map<String, dynamic> responseData;

    if (path.contains('/api/v1/patient/appointments')) {
      responseData = {
        'status': 'success',
        'data': {
          'items': <dynamic>[],
          'total': 0,
        },
      };
    } else if (path.contains('/api/v1/patient/addresses')) {
      responseData = {
        'status': 'success',
        'data': <dynamic>[],
      };
    } else if (path.contains('/api/v1/patient/orders')) {
      responseData = {
        'status': 'success',
        'data': {
          'items': <dynamic>[],
          'total': 0,
        },
      };
    } else if (path.contains('/api/v1/cart')) {
      responseData = {
        'status': 'success',
        'data': {
          'items': <dynamic>[],
          'subtotal': 0,
          'total': 0,
        },
      };
    } else if (path.contains('/api/v1/products')) {
      responseData = {
        'status': 'success',
        'data': {
          'items': <dynamic>[],
          'total': 0,
        },
      };
    } else if (path.contains('/api/v1/categories') || path.contains('/categories')) {
      responseData = {
        'status': 'success',
        'data': {
          'products': <dynamic>[],
          'videos': <dynamic>[],
          'services': <dynamic>[],
        },
      };
    } else if (path.contains('/api/v1/videos')) {
      final category = options.queryParameters['category']?.toString();
      final items = <Map<String, dynamic>>[
        {
          'id': 'vid-1',
          'public_id': 'cloud-1',
          'author_name': 'Yashveer Soni',
          'author_handle': '@yashveer.soni',
          'category': 'Hair Fall',
          'tag': 'Hair Fall',
          'secure_url': 'https://res.cloudinary.com/demo/video/upload/so_0/sample.mp4',
          'thumbnail_url': 'https://images.unsplash.com/photo-1',
        },
        {
          'id': 'vid-2',
          'public_id': 'cloud-2',
          'author_name': 'Ananya Mehra',
          'author_handle': '@ananya.mehra',
          'category': 'Dandruff',
          'tag': 'Dandruff',
          'secure_url': 'https://res.cloudinary.com/demo/video/upload/so_0/dog.mp4',
          'thumbnail_url': 'https://images.unsplash.com/photo-2',
        },
      ];
      final filtered = (category != null && category.isNotEmpty && category != 'All')
          ? items.where((it) => it['category'] == category).toList()
          : items;
      responseData = {
        'status': 'success',
        'data': {
          'items': filtered,
          'total': filtered.length,
          'has_more': false,
          'page': 1,
        },
      };
    } else {
      responseData = {
        'status': 'success',
        'data': <String, dynamic>{},
      };
    }

    final jsonStr = jsonEncode(responseData);
    return ResponseBody.fromString(
      jsonStr,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  DioClient.mockAdapter = _HermeticTestHttpClientAdapter();

  const storageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final inMemoryStorage = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(storageChannel, (MethodCall call) async {
    if (call.method == 'read') {
      final key = call.arguments?['key'] as String?;
      return inMemoryStorage[key];
    }
    if (call.method == 'write') {
      final key = call.arguments?['key'] as String?;
      final value = call.arguments?['value'] as String?;
      if (key != null && value != null) inMemoryStorage[key] = value;
      return null;
    }
    if (call.method == 'delete') {
      final key = call.arguments?['key'] as String?;
      if (key != null) inMemoryStorage.remove(key);
      return null;
    }
    if (call.method == 'deleteAll') {
      inMemoryStorage.clear();
      return null;
    }
    if (call.method == 'containsKey') {
      final key = call.arguments?['key'] as String?;
      return inMemoryStorage.containsKey(key);
    }
    return null;
  });

  const googleSignInChannel =
      MethodChannel('plugins.flutter.io/google_sign_in');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(googleSignInChannel, (MethodCall call) async {
    return null;
  });

  await testMain();
}
