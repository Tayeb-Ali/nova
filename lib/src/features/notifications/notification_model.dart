import "package:flutter/foundation.dart";

/// One entry in the in-app notification center.
///
/// Immutable value object: identity is [id], not the instance.
@immutable
class AppNotification {
  /// Unique id (FCM message id or a locally generated timestamp key).
  final String id;

  /// Short headline shown in the list and in the system tray.
  final String title;

  /// Longer detail text.
  final String body;

  /// Origin bucket: `fcm`, `runtime`, `general`, ...
  final String type;

  /// Optional in-app route (e.g. `/settings`) opened on tap.
  final String? route;

  /// Whether the user has opened (acknowledged) this entry.
  final bool read;

  /// When the notification was created (UTC or local, preserved as-is).
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type = "general",
    this.route,
    this.read = false,
    required this.createdAt,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? route,
    bool? read,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      route: route ?? this.route,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json["id"] as String? ?? "",
      title: json["title"] as String? ?? "",
      body: json["body"] as String? ?? "",
      type: json["type"] as String? ?? "general",
      route: json["route"] as String?,
      read: json["read"] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json["createdAt"] as String? ?? "") ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "id": id,
      "title": title,
      "body": body,
      "type": type,
      "route": route,
      "read": read,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is AppNotification && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => "AppNotification($id, $title)";
}
