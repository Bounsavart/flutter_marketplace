class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.favoriteCount = 0,
    this.bookingCount = 0,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final int favoriteCount;
  final int bookingCount;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
      favoriteCount: json['favoriteCount'] as int? ?? 0,
      bookingCount: json['bookingCount'] as int? ?? 0,
    );
  }
}

class Amenity {
  const Amenity({required this.id, required this.name});
  final int id;
  final String name;
  factory Amenity.fromJson(Map<String, dynamic> json) => Amenity(id: json['id'] as int, name: json['name'] as String);
}

class RoomImage {
  const RoomImage({required this.id, required this.imageUrl});
  final int id;
  final String imageUrl;
  factory RoomImage.fromJson(Map<String, dynamic> json) =>
      RoomImage(id: json['id'] as int, imageUrl: json['image_url'] as String);
}

class PropertyOwner {
  const PropertyOwner({required this.id, required this.name, this.phone, this.email});
  final int id;
  final String name;
  final String? phone;
  final String? email;
  factory PropertyOwner.fromJson(Map<String, dynamic> json) => PropertyOwner(
    id: json['id'] as int,
    name: json['name'] as String,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
  );
}

class Property {
  const Property({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.province,
    required this.district,
    required this.address,
    required this.approvalStatus,
    this.description,
    this.latitude,
    this.longitude,
    this.owner,
    this.rooms = const [],
  });

  final int id;
  final int ownerId;
  final String name;
  final String? description;
  final String province;
  final String district;
  final String address;
  final double? latitude;
  final double? longitude;
  final String approvalStatus;
  final PropertyOwner? owner;
  final List<Room> rooms;

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as int,
      ownerId: json['owner_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      province: json['province'] as String,
      district: json['district'] as String,
      address: json['address'] as String,
      latitude: json['latitude'] == null ? null : double.tryParse('${json['latitude']}'),
      longitude: json['longitude'] == null ? null : double.tryParse('${json['longitude']}'),
      approvalStatus: json['approval_status'] as String,
      owner: json['owner'] is Map<String, dynamic>
          ? PropertyOwner.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
      rooms: (json['rooms'] as List<dynamic>? ?? []).map((e) => Room.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class Room {
  const Room({
    required this.id,
    required this.propertyId,
    required this.roomNumber,
    required this.roomType,
    required this.price,
    required this.status,
    this.description,
    this.distanceKm,
    this.images = const [],
    this.amenities = const [],
    this.property,
  });

  final int id;
  final int propertyId;
  final String roomNumber;
  final String roomType;
  final double price;
  final String status;
  final String? description;
  final double? distanceKm;
  final List<RoomImage> images;
  final List<Amenity> amenities;
  final Property? property;

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as int,
      propertyId: json['property_id'] as int,
      roomNumber: json['room_number'] as String,
      roomType: json['room_type'] as String,
      price: double.tryParse('${json['price']}') ?? 0,
      status: json['status'] as String,
      description: json['description'] as String?,
      distanceKm: json['distance_km'] == null ? null : double.tryParse('${json['distance_km']}'),
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => RoomImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      amenities: (json['amenities'] as List<dynamic>? ?? [])
          .map((e) => Amenity.fromJson(e as Map<String, dynamic>))
          .toList(),
      property: json['property'] is Map<String, dynamic>
          ? Property.fromJson(json['property'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Booking {
  const Booking({
    required this.id,
    required this.roomId,
    required this.tenantId,
    required this.status,
    required this.createdAt,
    this.room,
    this.tenant,
  });

  final int id;
  final int roomId;
  final int tenantId;
  final String status;
  final DateTime createdAt;
  final Room? room;
  final PropertyOwner? tenant;

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int,
      roomId: json['room_id'] as int,
      tenantId: json['tenant_id'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      room: json['room'] is Map<String, dynamic> ? Room.fromJson(json['room'] as Map<String, dynamic>) : null,
      tenant: json['tenant'] is Map<String, dynamic>
          ? PropertyOwner.fromJson(json['tenant'] as Map<String, dynamic>)
          : null,
    );
  }
}
