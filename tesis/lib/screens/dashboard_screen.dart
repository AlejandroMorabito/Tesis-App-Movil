import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'control_modal.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  final DatabaseService dbService;
  const DashboardScreen({super.key, required this.dbService});

  @override
  Widget build(BuildContext context) {
    final authorized = dbService.authorizedChips;

    if (authorized.isEmpty) return _buildNoAccess();
    if (dbService.isAdmin) return _buildAdminDashboard(context);
    return _buildUserDashboard(context);
  }

  Widget _buildNoAccess() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔒', style: TextStyle(fontSize: 64)),
            SizedBox(height: 20),
            Text('No tienes acceso a dispositivos', style: TextStyle(fontSize: 18, color: Color(0xFF666666))),
            SizedBox(height: 10),
            Text('Contacta al administrador para obtener permisos',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDashboard(BuildContext context) {
    final authorized = dbService.authorizedChips;
    final totalDispositivos = authorized.length;
    final alarmasActivas = authorized.where((c) => dbService.devicesState[c]?.alarm == true).length;
    final sistemasArmados = authorized.where((c) => dbService.devicesState[c]?.armed == true).length;
    int sensoresActivos = 0;
    final totalSensores = authorized.length * 5;
    for (var chipId in authorized) {
      final sensors = dbService.sensorStates[chipId] ?? {};
      for (var i = 1; i <= 5; i++) {
        if (sensors['c$i'] == true) sensoresActivos++;
      }
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final conectados = authorized.where((c) {
      final ls = dbService.devicesState[c]?.lastSeen ?? 0;
      return (now - ls) < 300000;
    }).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 Dashboard',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 16),

          // Resumen
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📊 RESUMEN',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                Text('$totalDispositivos dispositivo(s) bajo tu control',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                const SizedBox(height: 12),

                // Stat cards 2x2
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.4,
                  children: [
                    _StatCard('📱 Dispositivos', '$totalDispositivos',
                        '$conectados/$totalDispositivos online', const Color(0xFF3498DB)),
                    _StatCard('🚨 Alarmas', '$alarmasActivas',
                        alarmasActivas > 0 ? '¡ATENCIÓN!' : 'Todo en orden',
                        alarmasActivas > 0 ? const Color(0xFFDC3545) : const Color(0xFF28A745)),
                    _StatCard('🛡️ Sistemas', '$sistemasArmados',
                        sistemasArmados > 0 ? 'Vigilando' : 'Inactivos',
                        sistemasArmados > 0 ? const Color(0xFF28A745) : const Color(0xFF6C757D)),
                    _StatCard('🔋 Cercos', '$sensoresActivos/$totalSensores',
                        sensoresActivos > 0 ? 'Activos' : 'Normales',
                        sensoresActivos > 0 ? const Color(0xFFDC3545) : const Color(0xFF28A745)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Estado detallado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('📈', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estado Detallado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text('Tus dispositivos en tiempo real', style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...authorized.map((chipId) => _buildDeviceCard(context, chipId)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nota
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: alarmasActivas > 0 ? const Color(0xFFFFF5F5) : const Color(0xFFE8F5E8),
              borderRadius: BorderRadius.circular(10),
              border: Border(
                left: BorderSide(color: alarmasActivas > 0 ? const Color(0xFFDC3545) : const Color(0xFF28A745), width: 4),
              ),
            ),
            child: Row(
              children: [
                Text(alarmasActivas > 0 ? '⚠️' : '✅', style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alarmasActivas > 0 ? '¡ATENCIÓN!' : 'TODO EN ORDEN',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        alarmasActivas > 0
                            ? '$alarmasActivas alarma(s) activa(s)'
                            : 'Todos los dispositivos funcionan correctamente',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, String chipId) {
    final device = dbService.devicesState[chipId] ?? DeviceState();
    final sensors = dbService.sensorStates[chipId] ?? {};
    final deviceName = device.name.isNotEmpty ? device.name : chipId;

    String estado; Color estadoColor; String estadoIcon;
    if (device.alarm) {
      estado = 'ALARMA'; estadoColor = const Color(0xFFDC3545); estadoIcon = '🚨';
    } else if (device.intrusion) {
      estado = 'INTRUSIÓN'; estadoColor = const Color(0xFFFF9500); estadoIcon = '⚠️';
    } else if (device.armed) {
      estado = 'ARMADO'; estadoColor = const Color(0xFF28A745); estadoIcon = '🛡️';
    } else {
      estado = 'DESARMADO'; estadoColor = const Color(0xFF6C757D); estadoIcon = '🔓';
    }

    final sensoresActivosChip = List.generate(5, (i) => sensors['c${i + 1}'] == true).where((v) => v).length;
    final conectado = (DateTime.now().millisecondsSinceEpoch - device.lastSeen) < 300000;

    return GestureDetector(
      onTap: () => _openControl(context, chipId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: estadoColor, width: 4)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deviceName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      Text(chipId, style: const TextStyle(fontSize: 10, color: Color(0xFF888888), fontFamily: 'monospace')),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: estadoColor, borderRadius: BorderRadius.circular(12)),
                  child: Text('$estadoIcon $estado',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Conexión
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: conectado ? const Color(0xFF28A745) : const Color(0xFFDC3545),
                  ),
                ),
                const SizedBox(width: 6),
                Text(conectado ? 'Conectado' : 'Desconectado',
                    style: TextStyle(fontSize: 11, color: conectado ? const Color(0xFF28A745) : const Color(0xFFDC3545))),
                const Spacer(),
                // Cercos
                Text('Cercos: $sensoresActivosChip/5', style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                const SizedBox(width: 8),
                // Mini indicators
                ...List.generate(5, (i) => Container(
                  width: 6, height: 14, margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: sensors['c${i + 1}'] == true ? const Color(0xFFDC3545) : const Color(0xFF28A745),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminDashboard(BuildContext context) {
    final eventsShown = dbService.currentData.length;
    final authorized = dbService.authorizedChips;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 Dashboard Admin',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 16),

          // Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(child: _MiniStat('Eventos', '$eventsShown', Colors.white)),
                Expanded(child: _MiniStat('Dispositivos', '${authorized.length}', const Color(0xFF3498DB))),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Events
          if (dbService.currentData.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(children: [
                  Text('📭', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 10),
                  Text('No hay eventos', style: TextStyle(color: Color(0xFF666666))),
                ]),
              ),
            )
          else
            ...dbService.currentData.take(20).map((event) {
              final eventName = DatabaseService.getEventDisplayName(event.eventType);
              final isActive = event.eventValue;
              final eventColor = isActive ? const Color(0xFFDC3545) : const Color(0xFF28A745);
              final date = DateTime.fromMillisecondsSinceEpoch(event.timestamp);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: eventColor, width: 3)),
                ),
                child: Row(
                  children: [
                    Text(isActive ? '🔴' : '🟢', style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(eventName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('📱 ${event.deviceId}', style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                        ],
                      ),
                    ),
                    Text(DateFormat('dd/MM HH:mm').format(date),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  void _openControl(BuildContext context, String chipId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
      builder: (_) => ControlModal(chipId: chipId, dbService: dbService),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, subtitle;
  final Color color;
  const _StatCard(this.label, this.value, this.subtitle, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}