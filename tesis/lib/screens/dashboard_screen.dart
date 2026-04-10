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

    if (authorized.isEmpty) {
      return _buildNoAccess();
    }

    if (dbService.isAdmin) {
      return _buildAdminDashboard(context);
    }
    return _buildUserDashboard(context);
  }

  Widget _buildNoAccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            const Text('No tienes acceso a dispositivos',
                style: TextStyle(fontSize: 18, color: Color(0xFF666666))),
            const SizedBox(height: 10),
            const Text('Contacta al administrador para obtener permisos',
                style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Text('⚠️', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text('Información:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    '1. Contacta al administrador\n'
                    '2. Los permisos se asignan por dispositivo\n'
                    '3. Dispositivos registrados: ${dbService.userPermissions.length}\n'
                    '4. Con acceso: ${dbService.authorizedChips.length}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 20),

          // Resumen
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('📊 RESUMEN DE TUS DISPOSITIVOS',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text('🏠 $totalDispositivos dispositivo(s)',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _StatCardsGrid(
                  cards: [
                    _StatCardData('📱 DISPOSITIVOS', '$totalDispositivos',
                        '${conectados == totalDispositivos ? '🟢' : '⚠️'} $conectados/$totalDispositivos conectados',
                        const Color(0xFF3498DB)),
                    _StatCardData('🚨 ALARMAS', '$alarmasActivas ${alarmasActivas > 0 ? '🔴' : '🟢'}',
                        alarmasActivas > 0 ? '¡ATENCIÓN REQUERIDA!' : 'Todo en orden',
                        alarmasActivas > 0 ? const Color(0xFFDC3545) : const Color(0xFF4CD964)),
                    _StatCardData('🛡️ SISTEMAS', '$sistemasArmados ${sistemasArmados > 0 ? '🔒' : '🔓'}',
                        sistemasArmados > 0 ? 'Vigilando' : 'Inactivos',
                        sistemasArmados > 0 ? const Color(0xFF28A745) : const Color(0xFF6C757D)),
                    _StatCardData('🔋 CERCOS', '$sensoresActivos/$totalSensores',
                        sensoresActivos > 0 ? '$sensoresActivos activos' : 'Todos normales',
                        sensoresActivos > 0 ? const Color(0xFFDC3545) : const Color(0xFF28A745)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // Estado detallado
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)]),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(colors: [Color(0xFF3498DB), Color(0xFF2980B9)]),
                      ),
                      child: const Center(child: Text('📈', style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estado Detallado del Sistema',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                        Text('Información en tiempo real de todos tus dispositivos',
                            style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...authorized.map((chipId) => _buildDeviceDetailCard(context, chipId)),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // Nota informativa
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: alarmasActivas > 0 ? const Color(0xFFFFF5F5) : const Color(0xFFE8F5E8),
              borderRadius: BorderRadius.circular(10),
              border: Border(
                left: BorderSide(
                  color: alarmasActivas > 0 ? const Color(0xFFDC3545) : const Color(0xFF28A745),
                  width: 4,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: alarmasActivas > 0 ? const Color(0xFFDC3545) : const Color(0xFF28A745),
                  ),
                  child: Center(
                    child: Text(alarmasActivas > 0 ? '⚠️' : '✅', style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alarmasActivas > 0 ? '¡ATENCIÓN REQUERIDA!' : 'TODO EN ORDEN',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        alarmasActivas > 0
                            ? 'Tienes $alarmasActivas alarma(s) activa(s) que requieren atención inmediata.'
                            : 'Todos tus dispositivos están funcionando correctamente.',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                      ),
                      const SizedBox(height: 8),
                      const Text('💡 Haz clic en cualquier dispositivo para controlarlo',
                          style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
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

  Widget _buildDeviceDetailCard(BuildContext context, String chipId) {
    final device = dbService.devicesState[chipId] ?? DeviceState();
    final sensors = dbService.sensorStates[chipId] ?? {};
    final deviceName = device.name.isNotEmpty ? device.name : chipId;

    String estado = 'DESCONOCIDO';
    Color estadoColor = const Color(0xFF6C757D);
    String estadoIcon = '❓';

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
    final now = DateTime.now().millisecondsSinceEpoch;
    final conectado = (now - device.lastSeen) < 300000;

    return GestureDetector(
      onTap: () => _openControl(context, chipId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4))],
          border: Border(left: BorderSide(color: estadoColor, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deviceName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(chipId, style: const TextStyle(fontSize: 11, color: Color(0xFF666666), fontFamily: 'monospace')),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: estadoColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text('$estadoIcon $estado',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Conexión
            Row(
              children: [
                const Text('📡 CONEXIÓN', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                const Spacer(),
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: conectado ? const Color(0xFF4CD964) : const Color(0xFFDC3545),
                    boxShadow: [BoxShadow(
                      color: conectado ? const Color(0xFF4CD964) : const Color(0xFFDC3545),
                      blurRadius: 10,
                    )],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  conectado ? 'CONECTADO' : 'DESCONECTADO',
                  style: TextStyle(
                    fontSize: 13,
                    color: conectado ? const Color(0xFF28A745) : const Color(0xFFDC3545),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Cercos
            Row(
              children: [
                const Text('🔋 CERCOS', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                const Spacer(),
                Text(
                  '$sensoresActivosChip/5',
                  style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold,
                    color: sensoresActivosChip > 0 ? const Color(0xFFDC3545) : const Color(0xFF28A745),
                  ),
                ),
                const SizedBox(width: 10),
                Row(
                  children: List.generate(5, (i) {
                    final active = sensors['c${i + 1}'] == true;
                    return Container(
                      width: 8, height: 20, margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFFDC3545) : const Color(0xFF28A745),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('📶 ${device.rssi} dBm', style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                Text('📍 ${device.ip}', style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminDashboard(BuildContext context) {
    final authorized = dbService.authorizedChips;
    final eventsShown = dbService.currentData.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 20),

          // Admin summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📊 RESUMEN DE EVENTOS',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 15),
                _StatCardsGrid(
                  cards: [
                    _StatCardData('EVENTOS VISIBLES', '$eventsShown', 'Últimos 10', Colors.white, isTranslucent: true),
                    _StatCardData('DISPOSITIVOS', '${authorized.length}', 'Con acceso', const Color(0xFF3498DB), isTranslucent: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Events header
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: const Border(left: BorderSide(color: Color(0xFF667EEA), width: 4)),
            ),
            child: const Row(
              children: [
                Text('📝 EVENTOS DEL SISTEMA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Events list
          if (dbService.currentData.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  children: [
                    Text('📭', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 15),
                    Text('No hay eventos en el sistema', style: TextStyle(fontSize: 16, color: Color(0xFF666666))),
                  ],
                ),
              ),
            )
          else
            ...dbService.currentData.take(20).map((event) => _buildEventCard(context, event)),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, AlarmEvent event) {
    final eventName = DatabaseService.getEventDisplayName(event.eventType);
    final isActive = event.eventValue;
    final eventColor = isActive ? const Color(0xFFDC3545) : const Color(0xFF28A745);
    final date = DateTime.fromMillisecondsSinceEpoch(event.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: eventColor, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Text(isActive ? '🔴' : '🟢', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(eventName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: eventColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isActive ? 'ACTIVADO' : 'DESACTIVADO',
                        style: TextStyle(color: eventColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text('📱 ${event.deviceId}', style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
              ],
            ),
          ),
          Text(
            DateFormat('dd/MM HH:mm').format(date),
            style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }

  void _openControl(BuildContext context, String chipId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (_) => ControlModal(chipId: chipId, dbService: dbService),
    );
  }
}

class _StatCardData {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final bool isTranslucent;

  _StatCardData(this.label, this.value, this.subtitle, this.color, {this.isTranslucent = false});
}

class _StatCardsGrid extends StatelessWidget {
  final List<_StatCardData> cards;
  const _StatCardsGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: cards.map((card) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width > 600) ? 180 : (MediaQuery.of(context).size.width - 80) / 2,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: card.isTranslucent ? Colors.white.withOpacity(0.15) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: card.isTranslucent ? null : Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              children: [
                Text(card.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: card.isTranslucent ? Colors.white.withOpacity(0.9) : null,
                    )),
                const SizedBox(height: 10),
                Text(card.value,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: card.color)),
                const SizedBox(height: 5),
                Text(card.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: card.isTranslucent ? Colors.white.withOpacity(0.8) : const Color(0xFF666666),
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
