import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DeviceState {
  final bool alarm;
  final bool armed;
  final bool intrusion;
  final int lastSeen;
  final int rssi;
  final String ip;
  final String mac;
  final String name;

  DeviceState({
    this.alarm = false,
    this.armed = false,
    this.intrusion = false,
    this.lastSeen = 0,
    this.rssi = -90,
    this.ip = 'N/A',
    this.mac = 'N/A',
    this.name = '',
  });

  bool get isConnected => (DateTime.now().millisecondsSinceEpoch - lastSeen) < 300000;
}

class AlarmEvent {
  final String id;
  final String deviceId;
  final String eventType;
  final bool eventValue;
  final int timestamp;
  final String message;

  AlarmEvent({
    required this.id,
    required this.deviceId,
    required this.eventType,
    required this.eventValue,
    required this.timestamp,
    this.message = '',
  });
}

class AppNotification {
  final String message;
  final String type; // success, danger, warning, info
  final DateTime time;

  AppNotification({required this.message, required this.type, DateTime? time})
      : time = time ?? DateTime.now();
}

class DatabaseService extends ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, bool> userPermissions = {};
  Map<String, DeviceState> devicesState = {};
  Map<String, Map<String, bool>> sensorStates = {};
  List<AlarmEvent> currentData = [];
  Map<String, dynamic>? userData;
  bool webhookReady = false;
  final List<AppNotification> notifications = [];

  final List<StreamSubscription> _subscriptions = [];
  Timer? _refreshTimer;

  bool get isAdmin => userData?['role'] == 'admin';

  List<String> get authorizedChips =>
      userPermissions.entries.where((e) => e.value == true).map((e) => e.key).toList();

  void addNotification(String message, String type) {
    notifications.insert(0, AppNotification(message: message, type: type));
    if (notifications.length > 50) notifications.removeLast();
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_auth.currentUser == null) return;

    await _loadUserData();
    await _loadPermissions();
    await _loadDevicesState();
    await _loadAlarmData();
    _startListeners();

    // Webhook ready después de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      webhookReady = true;
    });

    // Auto refresh cada 15 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (_auth.currentUser != null) {
        await _loadPermissions();
        await _loadDevicesState();
        await _loadAlarmData();
        notifyListeners();
      }
    });

    addNotification('✅ Sistema conectado y funcionando', 'success');
  }

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser!.uid;
    final snap = await _db.child('users/$uid').get();
    if (snap.exists) {
      userData = Map<String, dynamic>.from(snap.value as Map);
    }
    notifyListeners();
  }

  Future<void> _loadPermissions() async {
    final uid = _auth.currentUser!.uid;
    final snap = await _db.child('users/$uid/chips').get();
    if (snap.exists) {
      final data = snap.value as Map;
      userPermissions = data.map((k, v) => MapEntry(k.toString(), v == true));
    }
    notifyListeners();
  }

  Future<void> _loadDevicesState() async {
    final snap = await _db.child('devices').get();
    if (!snap.exists) return;

    final devices = snap.value as Map;
    for (var entry in devices.entries) {
      final chipId = entry.key.toString();
      if (userPermissions[chipId] != true) continue;

      final data = entry.value as Map;
      final state = data['state'] as Map? ?? {};
      final sensors = data['sensors'] as Map?;

      devicesState[chipId] = DeviceState(
        alarm: state['alarm_active'] == true,
        armed: state['system_armed'] == true,
        intrusion: state['any_intrusion'] == true,
        lastSeen: (data['last_seen'] as int?) ?? 0,
        rssi: (data['rssi'] as int?) ?? -90,
        ip: (data['ip_address'] as String?) ?? 'N/A',
        mac: (data['mac_address'] as String?) ?? 'N/A',
        name: (data['name'] as String?) ?? chipId,
      );

      if (sensors != null) {
        sensorStates[chipId] = {};
        for (var sEntry in sensors.entries) {
          sensorStates[chipId]![sEntry.key.toString()] = sEntry.value == true;
        }
      }
    }
    notifyListeners();
  }

  Future<void> _loadAlarmData() async {
    currentData.clear();
    for (var chipId in authorizedChips) {
      final snap = await _db.child('alarm_events/$chipId').limitToLast(10).get();
      if (!snap.exists) continue;

      final events = snap.value as Map;
      for (var entry in events.entries) {
        final data = entry.value as Map;
        if (data['event_type']?.toString().contains('test') == true) continue;

        currentData.add(AlarmEvent(
          id: '${chipId}_${entry.key}',
          deviceId: chipId,
          eventType: data['event_type']?.toString() ?? '',
          eventValue: data['event_value'] == true,
          timestamp: int.tryParse(entry.key.toString()) ?? DateTime.now().millisecondsSinceEpoch,
          message: data['message']?.toString() ?? '',
        ));
      }
    }
    currentData.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  void _startListeners() {
    // Listener de permisos
    final uid = _auth.currentUser!.uid;
    _subscriptions.add(
      _db.child('users/$uid/chips').onValue.listen((event) {
        if (event.snapshot.exists) {
          final data = event.snapshot.value as Map;
          userPermissions = data.map((k, v) => MapEntry(k.toString(), v == true));
          notifyListeners();
        }
      }),
    );

    // Listener de cambios en dispositivos
    _subscriptions.add(
      _db.child('devices').onChildChanged.listen((event) {
        final chipId = event.snapshot.key!;
        if (userPermissions[chipId] != true) return;

        final data = event.snapshot.value as Map;
        final state = data['state'] as Map? ?? {};
        final sensors = data['sensors'] as Map?;

        devicesState[chipId] = DeviceState(
          alarm: state['alarm_active'] == true,
          armed: state['system_armed'] == true,
          intrusion: state['any_intrusion'] == true,
          lastSeen: (data['last_seen'] as int?) ?? 0,
          rssi: (data['rssi'] as int?) ?? -90,
          ip: (data['ip_address'] as String?) ?? 'N/A',
          mac: (data['mac_address'] as String?) ?? 'N/A',
          name: (data['name'] as String?) ?? chipId,
        );

        if (sensors != null) {
          sensorStates[chipId] = {};
          for (var sEntry in sensors.entries) {
            sensorStates[chipId]![sEntry.key.toString()] = sEntry.value == true;
          }
        }

        if (state['alarm_active'] == true) {
          addNotification('🚨 $chipId: ALARMA ACTIVADA', 'danger');
        }

        notifyListeners();
      }),
    );

    // Listeners de eventos de alarma por chip
    for (var chipId in authorizedChips) {
      _subscriptions.add(
        _db.child('alarm_events/$chipId').limitToLast(1).onChildAdded.listen((event) {
          final data = event.snapshot.value as Map;
          if (data['event_type']?.toString().contains('test') == true) return;

          final newEvent = AlarmEvent(
            id: '${chipId}_${event.snapshot.key}',
            deviceId: chipId,
            eventType: data['event_type']?.toString() ?? '',
            eventValue: data['event_value'] == true,
            timestamp: int.tryParse(event.snapshot.key ?? '') ?? DateTime.now().millisecondsSinceEpoch,
            message: data['message']?.toString() ?? '',
          );

          if (!currentData.any((e) => e.id == newEvent.id)) {
            currentData.insert(0, newEvent);
            if (currentData.length > 100) currentData.removeLast();

            final eventName = getEventDisplayName(newEvent.eventType);
            final state = newEvent.eventValue ? 'ACTIVADO' : 'DESACTIVADO';
            addNotification('📢 $chipId: $eventName - $state',
                newEvent.eventValue ? 'danger' : 'success');

            if (webhookReady) {
              _sendWebhookNotification(chipId, data);
            }

            notifyListeners();
          }
        }),
      );
    }
  }

  Future<void> _sendWebhookNotification(String chipId, Map eventData) async {
    try {
      final urlSnap = await _db.child('config/webhookUrl').get();
      final webhookUrl = urlSnap.value?.toString() ?? '';
      if (webhookUrl.isEmpty) return;

      final usersSnap = await _db.child('users').get();
      if (!usersSnap.exists) return;

      final allUsers = usersSnap.value as Map;
      final notifyUsers = <Map<String, String>>[];

      for (var entry in allUsers.entries) {
        final uData = entry.value as Map;
        final chips = uData['chips'] as Map? ?? {};
        if (chips[chipId] == true && uData['status'] == 'active') {
          notifyUsers.add({
            'email': uData['email']?.toString() ?? '',
            'phone': uData['phone']?.toString() ?? '',
            'displayName': uData['displayName']?.toString() ?? '',
          });
        }
      }

      if (notifyUsers.isEmpty) return;

      final payload = {
        'chipId': chipId,
        'event_type': eventData['event_type'],
        'event_value': eventData['event_value'],
        'message': eventData['message'] ?? '',
        'timestamp': DateTime.now().toIso8601String(),
        'users': notifyUsers,
      };

      await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (e) {
      debugPrint('Error enviando webhook: $e');
    }
  }

  // ==================== COMANDOS ====================

  Future<void> sendCommand(String chipId, String command) async {
    if (_auth.currentUser == null) return;
    if (userPermissions[chipId] != true) {
      addNotification('🔒 No tienes acceso al dispositivo $chipId', 'warning');
      return;
    }

    try {
      await _db.child('devices_commands/$chipId').push().set({
        'command': command,
        'timestamp': ServerValue.timestamp,
        'executed': false,
        'status': 'pending',
        'sent_by': _auth.currentUser!.email ?? 'usuario',
      });
      addNotification('📤 Comando enviado a $chipId: $command', 'success');
    } catch (e) {
      addNotification('❌ Error enviando comando', 'danger');
    }
  }

  Future<void> toggleSensor(String chipId, String sensorName) async {
    if (userPermissions[chipId] != true) {
      addNotification('🔒 No tienes acceso al dispositivo $chipId', 'warning');
      return;
    }

    final currentState = sensorStates[chipId]?[sensorName] ?? false;
    final command = currentState ? 'DESACTIVAR_SENSOR' : 'ACTIVAR_SENSOR';

    try {
      await _db.child('devices_commands/$chipId').push().set({
        'device_id': chipId,
        'command': command,
        'sensor': sensorName,
        'timestamp': ServerValue.timestamp,
        'executed': false,
        'status': 'pending',
        'sent_by': _auth.currentUser!.email ?? 'usuario',
      });

      // Feedback local
      sensorStates[chipId] ??= {};
      sensorStates[chipId]![sensorName] = !currentState;
      notifyListeners();

      addNotification(
          '🔧 $chipId: ${sensorName.toUpperCase()} ${currentState ? "desactivado" : "activado"}',
          'info');
    } catch (e) {
      addNotification('❌ Error cambiando sensor', 'danger');
    }
  }

  // ==================== ADMIN ====================

  Future<Map<String, dynamic>> loadAdminData() async {
    final usersSnap = await _db.child('users').get();
    final devicesSnap = await _db.child('devices').get();

    final users = <Map<String, dynamic>>[];
    if (usersSnap.exists) {
      final data = usersSnap.value as Map;
      for (var entry in data.entries) {
        final u = Map<String, dynamic>.from(entry.value as Map);
        u['uid'] = entry.key.toString();
        users.add(u);
      }
    }
    users.sort((a, b) {
      final da = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });

    final allChipIds = <String>[];
    if (devicesSnap.exists) {
      final devices = devicesSnap.value as Map;
      allChipIds.addAll(devices.keys.map((k) => k.toString()));
    }

    return {
      'users': users,
      'allChipIds': allChipIds,
    };
  }

  Future<String> loadWebhookUrl() async {
    final snap = await _db.child('config/webhookUrl').get();
    return snap.value?.toString() ?? '';
  }

  Future<void> saveWebhookUrl(String url) async {
    await _db.child('config').update({'webhookUrl': url});
  }

  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    await _db.child('users/$uid').update(updates);
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final snap = await _db.child('users/$uid').get();
    if (!snap.exists) return null;
    return Map<String, dynamic>.from(snap.value as Map);
  }

  // ==================== PROFILE ====================

  Future<void> updateProfile({String? displayName, String? phone}) async {
    final uid = _auth.currentUser!.uid;
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (phone != null) updates['phone'] = phone;
    await _db.child('users/$uid').update(updates);
    await _loadUserData();
  }

  // ==================== HELPERS ====================

  static String getEventDisplayName(String eventType) {
    const names = {
      'estado/armado': 'ARMADO SISTEMA',
      'estado/alarma': 'ALARMA',
      'sensores/c1': 'CERCO 1',
      'sensores/c2': 'CERCO 2',
      'sensores/c3': 'CERCO 3',
      'sensores/c4': 'CERCO 4',
      'sensores/c5': 'CERCO 5',
      'estado/evento': 'EVENTO SISTEMA',
    };
    return names[eventType] ?? eventType;
  }

  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
