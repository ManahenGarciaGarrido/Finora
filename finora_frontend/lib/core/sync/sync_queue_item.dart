/// Modelo para operaciones pendientes de sincronización (RNF-15)
///
/// Cada item representa una acción CRUD que se realizó offline
/// y debe enviarse al servidor cuando haya conexión.
class SyncQueueItem {
  final String id;
  final String action; // 'create', 'update', 'delete'
  final String entityType; // 'transaction'
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;

  const SyncQueueItem({
    required this.id,
    required this.action,
    required this.entityType,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  static const int maxRetries = 3;

  bool get hasExceededRetries => retryCount >= maxRetries;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'entity_type': entityType,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] ?? '',
      action: map['action'] ?? '',
      entityType: map['entity_type'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      retryCount: map['retry_count'] ?? 0,
    );
  }

  SyncQueueItem copyWithRetry() {
    return SyncQueueItem(
      id: id,
      action: action,
      entityType: entityType,
      data: data,
      createdAt: createdAt,
      retryCount: retryCount + 1,
    );
  }
}
