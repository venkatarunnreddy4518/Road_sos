// lib/data/models/service_request.dart
class HelperLocation {
  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  HelperLocation({required this.latitude, required this.longitude, required this.recordedAt});

  factory HelperLocation.fromJson(Map<String, dynamic> j) => HelperLocation(
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        recordedAt: DateTime.parse(j['recorded_at']),
      );
}

/// Lifecycle states mirror the backend request_status enum.
enum RequestStatus { requested, accepted, onTheWay, arrived, completed, cancelled }

RequestStatus requestStatusFromString(String s) {
  switch (s) {
    case 'requested':
      return RequestStatus.requested;
    case 'accepted':
      return RequestStatus.accepted;
    case 'on_the_way':
      return RequestStatus.onTheWay;
    case 'arrived':
      return RequestStatus.arrived;
    case 'completed':
      return RequestStatus.completed;
    case 'cancelled':
      return RequestStatus.cancelled;
    default:
      return RequestStatus.requested;
  }
}

extension RequestStatusX on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.requested:
        return 'Requested';
      case RequestStatus.accepted:
        return 'Accepted';
      case RequestStatus.onTheWay:
        return 'On the way';
      case RequestStatus.arrived:
        return 'Arrived';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isTerminal =>
      this == RequestStatus.completed || this == RequestStatus.cancelled;
}

class ServiceRequest {
  final String id;
  final String seekerUserId;
  final String categoryId;
  final String? targetHelperId;
  final String? helperId;
  final RequestStatus status;
  final double pickupLat;
  final double pickupLng;
  final String? note;
  final String? seekerName;
  final String? helperName;
  final double? fareAmount;
  final DateTime? requestedAt;
  final HelperLocation? helperLocation;

  ServiceRequest({
    required this.id,
    required this.seekerUserId,
    required this.categoryId,
    this.targetHelperId,
    this.helperId,
    required this.status,
    required this.pickupLat,
    required this.pickupLng,
    this.note,
    this.seekerName,
    this.helperName,
    this.fareAmount,
    this.requestedAt,
    this.helperLocation,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> j) => ServiceRequest(
        id: j['id'],
        seekerUserId: j['seeker_user_id'],
        categoryId: j['category_id'],
        targetHelperId: j['target_helper_id'],
        helperId: j['helper_id'],
        status: requestStatusFromString(j['status']),
        pickupLat: (j['pickup_lat'] as num).toDouble(),
        pickupLng: (j['pickup_lng'] as num).toDouble(),
        note: j['note'],
        seekerName: j['seeker_name'],
        helperName: j['helper_name'],
        fareAmount: (j['fare_amount'] as num?)?.toDouble(),
        requestedAt: j['requested_at'] == null ? null : DateTime.parse(j['requested_at']),
        helperLocation: j['helper_location'] == null
            ? null
            : HelperLocation.fromJson(Map<String, dynamic>.from(j['helper_location'])),
      );
}
