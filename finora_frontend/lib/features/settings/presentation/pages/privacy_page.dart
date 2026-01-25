import 'package:flutter/material.dart';

import '../../domain/entities/consent.dart';

/// Página de Privacidad y GDPR
///
/// Muestra la política de privacidad, permite gestionar consentimientos
/// y acceder a las funciones de exportación y eliminación de datos.
class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _isLoading = true;
  final Map<ConsentType, bool> _consents = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Inicializar consentimientos por defecto
    for (final type in ConsentType.values) {
      _consents[type] = type.isRequired;
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad y Datos'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGDPRInfoCard(),
                  const SizedBox(height: 24),
                  _buildConsentsSection(),
                  const SizedBox(height: 24),
                  _buildUserRightsSection(),
                  const SizedBox(height: 24),
                  _buildDPOContactSection(),
                  const SizedBox(height: 24),
                  _buildDangerZoneSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildGDPRInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Cumplimiento GDPR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Finora cumple con el Reglamento General de Protección de Datos (GDPR) '
              'de la Unión Europea. Tus datos están protegidos y tienes control total '
              'sobre ellos.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showPrivacyPolicy,
              icon: const Icon(Icons.description),
              label: const Text('Ver Política de Privacidad'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle_outline),
                SizedBox(width: 8),
                Text(
                  'Gestión de Consentimientos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Controla qué datos recopilamos y cómo los usamos.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...ConsentType.values.map((type) => _buildConsentTile(type)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveConsents,
                child: const Text('Guardar Preferencias'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentTile(ConsentType type) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(type.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type.description, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                type.legalBasis,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).primaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          value: _consents[type] ?? false,
          onChanged: type.isRequired
              ? null // Los requeridos no se pueden desactivar
              : (value) {
                  setState(() {
                    _consents[type] = value;
                  });
                },
          secondary: type.isRequired
              ? const Chip(
                  label: Text('Requerido', style: TextStyle(fontSize: 10)),
                  backgroundColor: Colors.orange,
                  labelStyle: TextStyle(color: Colors.white),
                )
              : null,
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildUserRightsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.gavel),
                SizedBox(width: 8),
                Text(
                  'Tus Derechos GDPR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRightTile(
              icon: Icons.download,
              title: 'Derecho de Acceso',
              subtitle: 'Obtén una copia de todos tus datos',
              onTap: _exportUserData,
            ),
            _buildRightTile(
              icon: Icons.edit,
              title: 'Derecho de Rectificación',
              subtitle: 'Corrige datos inexactos',
              onTap: () => _navigateToProfile(),
            ),
            _buildRightTile(
              icon: Icons.history,
              title: 'Historial de Consentimientos',
              subtitle: 'Consulta los cambios en tus preferencias',
              onTap: _showConsentHistory,
            ),
            _buildRightTile(
              icon: Icons.info_outline,
              title: 'Información de Tratamiento',
              subtitle: 'Conoce cómo procesamos tus datos',
              onTap: _showDataProcessingInfo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDPOContactSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.contact_mail),
                SizedBox(width: 8),
                Text(
                  'Delegado de Protección de Datos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Nuestro DPO está disponible para atender tus consultas sobre privacidad:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const ListTile(
              leading: Icon(Icons.email),
              title: Text('dpo@finora.app'),
              subtitle: Text('Tiempo de respuesta: máximo 30 días'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Responsabilidades del DPO:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            ...[
              'Supervisar el cumplimiento del GDPR',
              'Gestionar las solicitudes de los interesados',
              'Comunicarse con la autoridad de control',
              'Evaluar el impacto de las actividades de tratamiento',
            ].map(
              (r) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(r, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneSection() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Zona de Peligro',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Estas acciones son irreversibles. Procede con precaución.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmDeleteAccount,
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text(
                  'Eliminar mi cuenta',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Política de Privacidad',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: const [_PrivacyPolicyContent()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveConsents() {
    // Aquí se guardarían los consentimientos via el usecase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferencias guardadas correctamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportUserData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar mis datos'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Se generará un archivo con todos tus datos personales '
              'según el Artículo 20 del GDPR (Derecho de Portabilidad).',
            ),
            SizedBox(height: 16),
            Text(
              'El archivo incluirá:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Información personal'),
            Text('• Historial de consentimientos'),
            Text('• Datos financieros'),
            Text('• Registro de actividad'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Aquí se ejecutaría el usecase de exportación
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Exportación iniciada. Recibirás el archivo pronto.',
                  ),
                ),
              );
            },
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile() {
    // Navegar a la página de perfil
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Navegando a perfil...')));
  }

  void _showConsentHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historial de Consentimientos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no hay cambios registrados en tus preferencias de consentimiento.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDataProcessingInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Información de Tratamiento',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: const [_DataProcessingContent()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Eliminar Cuenta'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas eliminar tu cuenta?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Esta acción es IRREVERSIBLE y eliminará:',
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 8),
            Text('• Toda tu información personal'),
            Text('• Historial de transacciones'),
            Text('• Cuentas bancarias conectadas'),
            Text('• Objetivos de ahorro'),
            Text('• Preferencias y configuraciones'),
            SizedBox(height: 16),
            Text(
              'Según el Artículo 17 del GDPR (Derecho al Olvido), '
              'algunos datos pueden conservarse por requisitos legales.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Para confirmar, escribe "ELIMINAR" en el campo de abajo:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Escribe ELIMINAR',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Razón para eliminar (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text == 'ELIMINAR') {
                Navigator.pop(context);
                // Aquí se ejecutaría el usecase de eliminación
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cuenta eliminada. Gracias por usar Finora.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Escribe "ELIMINAR" para confirmar'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar Definitivamente'),
          ),
        ],
      ),
    );
  }
}

/// Widget que muestra el contenido de la política de privacidad
class _PrivacyPolicyContent extends StatelessWidget {
  const _PrivacyPolicyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          '1. Introducción',
          'Esta Política de Privacidad describe cómo Finora ("nosotros", "nuestro" o "la Aplicación") '
              'recopila, usa, almacena y protege su información personal de acuerdo con el Reglamento '
              'General de Protección de Datos (GDPR) de la Unión Europea.',
        ),
        _buildSection(
          '2. Datos que recopilamos',
          'Recopilamos los siguientes tipos de datos:\n'
              '• Datos de identificación: nombre, email, teléfono\n'
              '• Datos financieros: transacciones, saldos, categorías de gasto\n'
              '• Datos de uso: interacciones con la app, preferencias\n'
              '• Datos técnicos: dispositivo, sistema operativo, IP',
        ),
        _buildSection(
          '3. Base legal para el tratamiento',
          'Procesamos sus datos personales bajo las siguientes bases legales:\n'
              '• Ejecución de contrato: para proporcionar nuestros servicios\n'
              '• Consentimiento: para marketing y análisis\n'
              '• Interés legítimo: para seguridad y prevención de fraude\n'
              '• Obligación legal: para cumplir requisitos regulatorios',
        ),
        _buildSection(
          '4. Conservación de datos',
          'Conservamos sus datos personales durante el tiempo necesario:\n'
              '• Datos de cuenta: mientras la cuenta esté activa + 5 años\n'
              '• Datos financieros: 7 años por requisitos legales\n'
              '• Datos de marketing: hasta retirada del consentimiento\n'
              '• Logs de seguridad: 2 años',
        ),
        _buildSection(
          '5. Sus derechos',
          'Bajo el GDPR, usted tiene los siguientes derechos:\n'
              '• Derecho de acceso: obtener copia de sus datos\n'
              '• Derecho de rectificación: corregir datos inexactos\n'
              '• Derecho de supresión: eliminar sus datos ("derecho al olvido")\n'
              '• Derecho de portabilidad: recibir sus datos en formato estructurado\n'
              '• Derecho de oposición: oponerse al tratamiento\n'
              '• Derecho a retirar el consentimiento: en cualquier momento\n'
              '• Derecho a presentar reclamación: ante la autoridad de control',
        ),
        _buildSection(
          '6. Seguridad de los datos',
          'Implementamos medidas técnicas y organizativas apropiadas:\n'
              '• Cifrado AES-256 para datos en reposo\n'
              '• TLS 1.3 para datos en tránsito\n'
              '• Almacenamiento seguro con Keychain/KeyStore\n'
              '• Autenticación multifactor disponible\n'
              '• Auditorías de seguridad regulares',
        ),
        _buildSection(
          '7. Contacto',
          'Para ejercer sus derechos o realizar consultas sobre privacidad, '
              'contacte a nuestro Delegado de Protección de Datos (DPO):\n\n'
              'Email: dpo@finora.app\n'
              'Tiempo de respuesta: máximo 30 días',
        ),
        const SizedBox(height: 16),
        Text(
          'Última actualización: Enero 2024',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }
}

/// Widget que muestra información sobre el tratamiento de datos
class _DataProcessingContent extends StatelessWidget {
  const _DataProcessingContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPurpose(
          'Gestión de cuenta',
          'Crear y mantener su cuenta de usuario',
          'Ejecución de contrato',
          ['Datos de identificación', 'Credenciales'],
          'Mientras la cuenta esté activa + 5 años',
        ),
        _buildPurpose(
          'Análisis financiero',
          'Proporcionar análisis de sus finanzas personales',
          'Ejecución de contrato',
          ['Transacciones', 'Saldos', 'Categorías'],
          '7 años (requisito legal)',
        ),
        _buildPurpose(
          'Mejora del servicio',
          'Analizar uso para mejorar la experiencia',
          'Interés legítimo / Consentimiento',
          ['Datos de uso', 'Preferencias'],
          '2 años',
        ),
        _buildPurpose(
          'Comunicaciones',
          'Enviar notificaciones y marketing',
          'Consentimiento',
          ['Email', 'Preferencias de comunicación'],
          'Hasta retirada de consentimiento',
        ),
        _buildPurpose(
          'Seguridad',
          'Prevenir fraude y proteger la plataforma',
          'Interés legítimo',
          ['Logs de acceso', 'IP', 'Dispositivo'],
          '2 años',
        ),
        const SizedBox(height: 24),
        const Text(
          'Minimización de datos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Solo recopilamos datos estrictamente necesarios:\n'
          '• Campos opcionales claramente identificados\n'
          '• No recopilamos datos sensibles innecesarios\n'
          '• Revisión periódica de necesidad de datos',
        ),
      ],
    );
  }

  Widget _buildPurpose(
    String purpose,
    String description,
    String legalBasis,
    List<String> categories,
    String retention,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              purpose,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(color: Colors.grey)),
            const Divider(),
            _buildInfoRow('Base legal', legalBasis),
            _buildInfoRow('Datos', categories.join(', ')),
            _buildInfoRow('Retención', retention),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
