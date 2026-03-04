/// RF-25 / HU-12 / CU-04: Asistente conversacional IA financiero
/// RF-26 / HU-13: Análisis de affordability "¿Puedo permitírmelo?"
/// RF-27 / HU-14: Recomendaciones proactivas de optimización financiera
///
/// Página de chat con el asistente IA Finora.
/// Permite al usuario hacer preguntas en lenguaje natural sobre sus finanzas.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/ai_service.dart';

// Paleta del asistente
const _kAssistantColor = Color(0xFF6C63FF);
const _kAssistantSoft = Color(0xFFF0EFFE);

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage>
    with TickerProviderStateMixin {
  final AiService _aiService = sl<AiService>();

  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  // HU-12: historial para contexto
  final List<Map<String, String>> _history = [];

  // RF-27: recomendaciones cargadas bajo demanda
  bool _loadingRecs = false;

  // Preguntas sugeridas (CU-04: "Sugerencias de preguntas frecuentes")
  static const _suggestions = [
    '¿Cuánto gasté este mes?',
    '¿En qué categoría gasto más?',
    '¿Cómo van mis objetivos de ahorro?',
    '¿Puedo comprar un portátil de 800€?',
    'Dame consejos para ahorrar',
    '¿Cuál es mi saldo actual?',
  ];

  @override
  void initState() {
    super.initState();
    // Mensaje de bienvenida inicial
    _messages.add(
      ChatMessage(
        id: 'welcome',
        content:
            '¡Hola! Soy **Finn**, tu asistente financiero de Finora.\n\n'
            'Puedo ayudarte a entender tus finanzas, analizar tus gastos '
            'y responder preguntas como *"¿cuánto gasté este mes?"* o '
            '*"¿puedo permitirme un viaje de 500€?"*.\n\n'
            '¿En qué puedo ayudarte hoy?',
        isUser: false,
        timestamp: DateTime.now(),
        intent: 'general',
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final msg = text.trim();
    if (msg.isEmpty || _isTyping) return;

    _inputController.clear();
    setState(() {
      _messages.add(ChatMessage.user(msg));
      _isTyping = true;
    });
    _scrollToBottom();

    // Detectar si es una pregunta de affordability
    final lowerMsg = msg.toLowerCase();
    final isAffordability = _kAffordabilityKeywords.any(lowerMsg.contains);

    try {
      ChatMessage response;
      if (isAffordability) {
        final result = await _aiService.checkAffordability(msg);
        response = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: result.recommendation,
          isUser: false,
          timestamp: DateTime.now(),
          intent: 'affordability',
          affordabilityResult: result,
        );
      } else {
        response = await _aiService.chatWithAssistant(msg, history: _history);
      }

      // HU-12: mantener historial de conversación
      _history.add({'role': 'user', 'content': msg});
      _history.add({'role': 'assistant', 'content': response.content});
      // Limitar historial a últimas 10 interacciones (5 pares)
      if (_history.length > 20) {
        _history.removeRange(0, 2);
      }

      if (mounted) {
        setState(() {
          _messages.add(response);
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content:
                  'Lo siento, no pude conectar con el asistente. Verifica tu conexión e inténtalo de nuevo.',
              isUser: false,
              timestamp: DateTime.now(),
              intent: 'error',
            ),
          );
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  static const _kAffordabilityKeywords = [
    'puedo comprar',
    'puedo permitir',
    'me puedo',
    'puedo pagar',
    'puedo darme',
    'puedo costear',
    'tengo para',
    'me alcanza',
  ];

  Future<void> _loadRecommendations() async {
    if (_loadingRecs) return;
    setState(() => _loadingRecs = true);
    try {
      final result = await _aiService.getRecommendations(months: 3);
      if (mounted) {
        setState(() {
          _loadingRecs = false;
        });
        // Añadir mensaje con resumen de recomendaciones al chat
        final recSummary = _buildRecsMessage(result);
        setState(() => _messages.add(recSummary));
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _loadingRecs = false);
    }
  }

  ChatMessage _buildRecsMessage(RecommendationsResult result) {
    final sb = StringBuffer();
    sb.writeln('Aquí tienes tus recomendaciones de optimización financiera:');
    if (result.recommendations.isEmpty) {
      sb.writeln(
        '\n✅ ¡Tus finanzas están bien equilibradas! No tengo recomendaciones urgentes.',
      );
    } else {
      sb.writeln(
        '\n📊 **Puntuación financiera: ${result.financialScore}/100**',
      );
      sb.writeln(
        '💰 Ahorro potencial: ${_fmt(result.totalPotentialSaving)}/mes\n',
      );
      for (int i = 0; i < result.recommendations.length && i < 5; i++) {
        final r = result.recommendations[i];
        final emoji = r.priority == 'high' ? '🔴' : '🟡';
        sb.writeln('$emoji **${r.title}**');
        sb.writeln('   ${r.description}\n');
      }
    }
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: sb.toString().trimRight(),
      isUser: false,
      timestamp: DateTime.now(),
      intent: 'recommendations',
    );
  }

  String _fmt(double v) => '${v.toStringAsFixed(2)}€';

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_isTyping) _buildTypingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.textPrimaryLight,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kAssistantColor, Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Finn',
                style: AppTypography.titleSmall(
                  color: AppColors.textPrimaryLight,
                ),
              ),
              Text(
                'Asistente IA · En línea',
                style: AppTypography.labelSmall(color: AppColors.success),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // RF-27: botón para cargar recomendaciones
        IconButton(
          icon: _loadingRecs
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kAssistantColor,
                  ),
                )
              : const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: _kAssistantColor,
                ),
          tooltip: 'Ver recomendaciones',
          onPressed: _loadingRecs ? null : _loadRecommendations,
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + ((_messages.length == 1) ? 1 : 0),
      itemBuilder: (context, index) {
        // Mostrar sugerencias después del mensaje de bienvenida
        if (_messages.length == 1 && index == 1) {
          return _buildSuggestionChips();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildSuggestionChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _suggestions.map((s) {
          return InkWell(
            onTap: () => _sendMessage(s),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _kAssistantSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _kAssistantColor.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                s,
                style: AppTypography.bodySmall(color: _kAssistantColor),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.isUser) {
      return _buildUserBubble(message);
    }
    return _buildAssistantBubble(message);
  }

  Widget _buildUserBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _kAssistantColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                message.content,
                style: AppTypography.bodyMedium(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: _kAssistantColor.withValues(alpha: 0.15),
            child: const Icon(
              Icons.person_rounded,
              size: 18,
              color: _kAssistantColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kAssistantColor, Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(color: AppColors.gray100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildMessageContent(message),
                ),
                // Tarjeta de affordability si aplica
                if (message.affordabilityResult != null)
                  _buildAffordabilityCard(message.affordabilityResult!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message) {
    // Renderizado simple de markdown básico (bold **)
    final text = message.content;
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      if (i.isOdd) {
        spans.add(
          TextSpan(
            text: parts[i],
            style: AppTypography.bodyMedium(
              color: AppColors.textPrimaryLight,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        );
      } else {
        // Manejar cursiva (*texto*)
        final italicParts = parts[i].split('*');
        for (int j = 0; j < italicParts.length; j++) {
          spans.add(
            TextSpan(
              text: italicParts[j],
              style: AppTypography.bodyMedium(color: AppColors.textPrimaryLight)
                  .copyWith(
                    fontStyle: j.isOdd ? FontStyle.italic : FontStyle.normal,
                  ),
            ),
          );
        }
      }
    }
    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildAffordabilityCard(AffordabilityResult result) {
    final Color verdictColor;
    final IconData verdictIcon;
    final String verdictLabel;

    if (result.isYes) {
      verdictColor = AppColors.success;
      verdictIcon = Icons.check_circle_rounded;
      verdictLabel = 'Sí puedes';
    } else if (result.isNo) {
      verdictColor = AppColors.error;
      verdictIcon = Icons.cancel_rounded;
      verdictLabel = 'No puedes';
    } else {
      verdictColor = AppColors.warning;
      verdictIcon = Icons.warning_rounded;
      verdictLabel = 'Con precaución';
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: verdictColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: verdictColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Veredicto
          Row(
            children: [
              Icon(verdictIcon, color: verdictColor, size: 22),
              const SizedBox(width: 8),
              Text(
                verdictLabel,
                style: AppTypography.titleSmall(color: verdictColor),
              ),
              const Spacer(),
              Text(
                '${result.amount.toStringAsFixed(0)}€',
                style: AppTypography.titleMedium(color: verdictColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Métricas clave
          _affordabilityRow(
            'Balance disponible',
            _fmt(result.availableBalance),
          ),
          _affordabilityRow(
            'Balance tras compra',
            _fmt(result.balanceAfter),
            valueColor: result.balanceAfter < 0 ? AppColors.error : null,
          ),
          if (result.monthlySurplus > 0)
            _affordabilityRow('Superávit mensual', _fmt(result.monthlySurplus)),
          if (result.monthsToSave != null)
            _affordabilityRow(
              'Podrías ahorrar en',
              '${result.monthsToSave} mes(es)',
              valueColor: AppColors.primary,
            ),
          // Impacto en objetivos
          if (result.impactOnGoals.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Impacto en objetivos:',
              style: AppTypography.labelSmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
            ...result.impactOnGoals.map(
              (g) => _affordabilityRow(
                g.goalName,
                g.monthsDelayed > 0
                    ? "+${g.monthsDelayed} mes(es)"
                    : "Sin impacto",
                valueColor: g.monthsDelayed > 0
                    ? AppColors.warning
                    : AppColors.success,
              ),
            ),
          ],
          // Alternativas
          if (result.alternatives.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Alternativas:',
              style: AppTypography.labelSmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
            ...result.alternatives.map(
              (a) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(color: AppColors.textSecondaryLight),
                    ),
                    Expanded(
                      child: Text(
                        a,
                        style: AppTypography.bodySmall(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _affordabilityRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
          ),
          Text(
            value,
            style: AppTypography.bodySmall(
              color: valueColor ?? AppColors.textPrimaryLight,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // HU-12: Typing indicator mientras IA procesa
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kAssistantColor, Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.gray100),
            ),
            child: _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.gray100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocus,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Escribe tu pregunta...',
                  hintStyle: AppTypography.bodyMedium(color: AppColors.gray400),
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            // Botón de enviar
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kAssistantColor, Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isTyping
                      ? null
                      : () => _sendMessage(_inputController.text),
                  child: const Center(
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Typing dots animation (HU-12: typing indicator) ─────────────────────────

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      )..repeat(reverse: true, period: Duration(milliseconds: 800 + i * 150));
    });
    _animations = _controllers.map((c) {
      return Tween<double>(
        begin: 0,
        end: -6,
      ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut));
    }).toList();

    // Escalonar el inicio de cada dot
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _kAssistantColor.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
