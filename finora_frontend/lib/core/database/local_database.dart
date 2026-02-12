import 'package:hive_flutter/hive_flutter.dart';

/// Servicio de base de datos local con Hive (RNF-15)
///
/// Gestiona el almacenamiento persistente de transacciones, categorías
/// y la cola de sincronización para funcionamiento offline.
class LocalDatabase {
  static const String _transactionsBox = 'transactions';
  static const String _categoriesBox = 'categories';
  static const String _syncQueueBox = 'sync_queue';
  static const String _metadataBox = 'app_metadata';

  bool _initialized = false;

  /// Inicializa Hive y abre los boxes necesarios
  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<Map>(_transactionsBox),
      Hive.openBox<Map>(_categoriesBox),
      Hive.openBox<Map>(_syncQueueBox),
      Hive.openBox(_metadataBox),
    ]);
    _initialized = true;
  }

  // ============================================
  // TRANSACCIONES
  // ============================================

  Box<Map> get _transactions => Hive.box<Map>(_transactionsBox);

  /// Guarda una transacción en la BD local
  Future<void> saveTransaction(Map<String, dynamic> transaction) async {
    final id = transaction['id']?.toString();
    if (id == null) return;
    await _transactions.put(id, transaction);
  }

  /// Guarda múltiples transacciones (reemplaza todas)
  Future<void> saveAllTransactions(List<Map<String, dynamic>> transactions) async {
    await _transactions.clear();
    for (final t in transactions) {
      final id = t['id']?.toString();
      if (id != null) {
        await _transactions.put(id, t);
      }
    }
  }

  /// Obtiene todas las transacciones
  List<Map<String, dynamic>> getAllTransactions() {
    return _transactions.values
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  /// Elimina una transacción por ID
  Future<void> deleteTransaction(String id) async {
    await _transactions.delete(id);
  }

  /// Actualiza una transacción existente
  Future<void> updateTransaction(String id, Map<String, dynamic> data) async {
    await _transactions.put(id, data);
  }

  // ============================================
  // CATEGORÍAS
  // ============================================

  Box<Map> get _categories => Hive.box<Map>(_categoriesBox);

  /// Guarda todas las categorías
  Future<void> saveAllCategories(List<Map<String, dynamic>> categories) async {
    await _categories.clear();
    for (int i = 0; i < categories.length; i++) {
      await _categories.put(i.toString(), categories[i]);
    }
  }

  /// Obtiene todas las categorías
  List<Map<String, dynamic>> getAllCategories() {
    return _categories.values
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  // ============================================
  // COLA DE SINCRONIZACIÓN
  // ============================================

  Box<Map> get _syncQueue => Hive.box<Map>(_syncQueueBox);

  /// Añade un item a la cola de sincronización
  Future<void> addToSyncQueue(Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    await _syncQueue.put(id, item);
  }

  /// Obtiene todos los items de la cola de sincronización
  List<Map<String, dynamic>> getSyncQueue() {
    return _syncQueue.values
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  /// Elimina un item de la cola
  Future<void> removeFromSyncQueue(String id) async {
    await _syncQueue.delete(id);
  }

  /// Actualiza un item en la cola
  Future<void> updateSyncQueueItem(String id, Map<String, dynamic> item) async {
    await _syncQueue.put(id, item);
  }

  /// Limpia toda la cola
  Future<void> clearSyncQueue() async {
    await _syncQueue.clear();
  }

  /// Número de items pendientes en la cola
  int get pendingSyncCount => _syncQueue.length;

  // ============================================
  // METADATA
  // ============================================

  Box get _metadata => Hive.box(_metadataBox);

  /// Guarda la fecha de última sincronización
  Future<void> setLastSyncTime(DateTime time) async {
    await _metadata.put('last_sync', time.toIso8601String());
  }

  /// Obtiene la fecha de última sincronización
  DateTime? getLastSyncTime() {
    final value = _metadata.get('last_sync');
    if (value != null) return DateTime.tryParse(value);
    return null;
  }

  /// Limpia todos los datos locales (para logout)
  Future<void> clearAll() async {
    await _transactions.clear();
    await _categories.clear();
    await _syncQueue.clear();
    await _metadata.clear();
  }
}
