import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'config.dart';
import 'models.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: '${AppConfig.apiBaseUrl}/api',
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 20),
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  String? _token;

  String? get token => _token;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove('token');
    } else {
      await prefs.setString('token', token);
    }
  }

  String _message(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'ເຊື່ອມຕໍ່ເຊີບເວີບໍ່ສຳເລັດ';
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiException(_message(e));
    }
  }

  Future<({String token, AppUser user})> login(String email, String password) {
    return _guard(() async {
      final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
      return (token: res.data['token'] as String, user: AppUser.fromJson(res.data['user'] as Map<String, dynamic>));
    });
  }

  Future<({String token, AppUser user})> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) {
    return _guard(() async {
      final res = await _dio.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password, 'role': role, 'phone': phone},
      );
      return (token: res.data['token'] as String, user: AppUser.fromJson(res.data['user'] as Map<String, dynamic>));
    });
  }

  Future<AppUser> me() {
    return _guard(() async {
      final res = await _dio.get('/auth/me');
      return AppUser.fromJson(res.data['user'] as Map<String, dynamic>);
    });
  }

  Future<List<Map<String, dynamic>>> notifications({int? before, int limit = 20}) {
    return _guard(() async {
      final res = await _dio.get('/notifications', queryParameters: {'limit': limit, 'before': ?before});
      return (res.data['notifications'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
  }

  Future<int> notificationUnreadCount() => _guard(() async {
    final res = await _dio.get('/notifications/unread-count');
    return (res.data['count'] as num).toInt();
  });

  Future<void> markNotificationRead(int id) => _guard(() async { await _dio.patch('/notifications/$id/read'); });
  Future<void> markAllNotificationsRead() => _guard(() async { await _dio.patch('/notifications/read-all'); });

  Future<List<Room>> searchRooms({String? q, String? province, String? district, num? minPrice, num? maxPrice}) {
    return _guard(() async {
      final res = await _dio.get(
        '/rooms',
        queryParameters: {
          if (q != null && q.isNotEmpty) 'q': q,
          if (province != null && province.isNotEmpty) 'province': province,
          if (district != null && district.isNotEmpty) 'district': district,
          'minPrice': ?minPrice,
          'maxPrice': ?maxPrice,
        },
      );
      return (res.data['rooms'] as List).map((e) => Room.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<Room> roomDetail(int id) {
    return _guard(() async {
      final res = await _dio.get('/rooms/$id');
      return Room.fromJson(res.data['room'] as Map<String, dynamic>);
    });
  }

  Future<bool> notificationRoomExists(int id) async {
    try { await roomDetail(id); return true; } catch (_) { return false; }
  }

  Future<bool> notificationPropertyExists(int id) async {
    try {
      await _guard(() async { await _dio.get('/properties/$id'); });
      return true;
    } catch (_) { return false; }
  }

  Future<List<Amenity>> amenities() {
    return _guard(() async {
      final res = await _dio.get('/amenities');
      return (res.data['amenities'] as List).map((e) => Amenity.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<Booking> createBooking(int roomId) {
    return _guard(() async {
      final res = await _dio.post('/bookings', data: {'room_id': roomId});
      return Booking.fromJson(res.data['booking'] as Map<String, dynamic>);
    });
  }

  Future<List<Booking>> myBookings() {
    return _guard(() async {
      final res = await _dio.get('/bookings/my');
      return (res.data['bookings'] as List).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<List<Booking>> ownerBookings() {
    return _guard(() async {
      final res = await _dio.get('/bookings/owner');
      return (res.data['bookings'] as List).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<Booking> confirmBooking(int id) {
    return _guard(() async {
      final res = await _dio.patch('/bookings/$id/confirm');
      return Booking.fromJson(res.data['booking'] as Map<String, dynamic>);
    });
  }

  Future<Booking> rejectBooking(int id) {
    return _guard(() async {
      final res = await _dio.patch('/bookings/$id/reject');
      return Booking.fromJson(res.data['booking'] as Map<String, dynamic>);
    });
  }

  Future<Booking> cancelBooking(int id) {
    return _guard(() async {
      final res = await _dio.patch('/bookings/$id/cancel');
      return Booking.fromJson(res.data['booking'] as Map<String, dynamic>);
    });
  }

  Future<bool> isFavorite(int roomId) {
    return _guard(() async {
      final res = await _dio.get('/favorites/$roomId', queryParameters: {'check': '1'});
      return res.data['favorited'] == true;
    });
  }

  Future<void> addFavorite(int roomId) {
    return _guard(() async {
      await _dio.post('/favorites/$roomId');
    });
  }

  Future<void> removeFavorite(int roomId) {
    return _guard(() async {
      await _dio.delete('/favorites/$roomId');
    });
  }

  Future<void> deleteRoom(int id) => _guard(() async { await _dio.delete('/rooms/$id'); });
  Future<void> deleteProperty(int id) => _guard(() async { await _dio.delete('/properties/$id'); });
  Future<void> deleteRoomImage(int roomId, int imageId) =>
      _guard(() async { await _dio.delete('/rooms/$roomId/images/$imageId'); });
  Future<void> deleteAccount() => _guard(() async { await _dio.delete('/auth/me'); });
  Future<void> adminDeleteUser(int id) => _guard(() async { await _dio.delete('/admin/users/$id'); });

  Future<List<Room>> myFavorites() {
    return _guard(() async {
      final res = await _dio.get('/favorites/my');
      return (res.data['favorites'] as List)
          .map((e) => Room.fromJson((e as Map<String, dynamic>)['room'] as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<Property>> myProperties() {
    return _guard(() async {
      final res = await _dio.get('/properties/my');
      return (res.data['properties'] as List).map((e) => Property.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<Property> createProperty(Map<String, dynamic> body) {
    return _guard(() async {
      final res = await _dio.post('/properties', data: body);
      return Property.fromJson(res.data['property'] as Map<String, dynamic>);
    });
  }

  Future<Room> addRoom(int propertyId, Map<String, dynamic> body) {
    return _guard(() async {
      final res = await _dio.post('/properties/$propertyId/rooms', data: body);
      return Room.fromJson(res.data['room'] as Map<String, dynamic>);
    });
  }

  Future<Room> updateRoom(int roomId, Map<String, dynamic> body) {
    return _guard(() async {
      final res = await _dio.put('/rooms/$roomId', data: body);
      return Room.fromJson(res.data['room'] as Map<String, dynamic>);
    });
  }

  Future<void> uploadRoomImages(int roomId, List<XFile> files) {
    return _guard(() async {
      final form = FormData();
      for (final file in files) {
        final bytes = await file.readAsBytes();
        form.files.add(MapEntry('images', MultipartFile.fromBytes(bytes, filename: file.name)));
      }
      await _dio.post('/rooms/$roomId/images', data: form);
    });
  }

  Future<Map<String, int>> adminStats() {
    return _guard(() async {
      final res = await _dio.get('/admin/stats');
      return (res.data['stats'] as Map).map((k, v) => MapEntry('$k', v as int));
    });
  }

  Future<List<Property>> pendingProperties() {
    return _guard(() async {
      final res = await _dio.get('/admin/properties/pending');
      return (res.data['properties'] as List).map((e) => Property.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<List<Property>> allProperties() {
    return _guard(() async {
      final res = await _dio.get('/properties', queryParameters: {'all': '1'});
      return (res.data['properties'] as List).map((e) => Property.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<void> approveProperty(int id) {
    return _guard(() async {
      await _dio.patch('/admin/properties/$id/approve');
    });
  }

  Future<void> rejectProperty(int id) {
    return _guard(() async {
      await _dio.patch('/admin/properties/$id/reject');
    });
  }

  Future<List<AppUser>> adminUsers() {
    return _guard(() async {
      final res = await _dio.get('/admin/users');
      return (res.data['users'] as List).map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
    });
  }
}
