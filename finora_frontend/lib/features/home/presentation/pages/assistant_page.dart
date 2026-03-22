/// RF-25 / HU-12 / CU-04: Asistente conversacional IA financiero
/// RF-26 / HU-13: Análisis de affordability "¿Puedo permitírmelo?"
/// RF-27 / HU-14: Recomendaciones proactivas de optimización financiera
///
/// Página de chat con el asistente IA Finora.
/// Permite al usuario hacer preguntas en lenguaje natural sobre sus finanzas.
library;

import 'package:flutter/material.dart';

import 'package:finora_frontend/core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/responsive/breakpoints.dart';

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
  final ApiClient _apiClient = sl<ApiClient>();

  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final List<Map<String, String>> _history = [];
  bool _loadingRecs = false;

  /// Financial context fetched from backend — injected into Gemini system prompt
  String? _financialContext;

  @override
  void initState() {
    super.initState();
    _fetchFinancialContext(); // fire-and-forget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final s = AppLocalizations.of(context);
        setState(() {
          _messages.add(
            ChatMessage(
              id: 'welcome',
              content: s.finnWelcomeMessage,
              isUser: false,
              timestamp: DateTime.now(),
              intent: 'general',
            ),
          );
        });
      }
    });
  }

  Future<void> _fetchFinancialContext() async {
    try {
      final resp = await _apiClient.get(ApiEndpoints.aiContext);
      final d = resp.data as Map<String, dynamic>;
      final cs = CurrencyService();
      final balance = cs.format((d['balance_total'] as num).toDouble());
      final income = cs.format((d['income_30d'] as num).toDouble());
      final expenses = cs.format((d['expenses_30d'] as num).toDouble());
      final cats = (d['top_categories'] as List? ?? [])
          .map((c) => '${c['category']} (${cs.format((c['total'] as num).toDouble())})')
          .join(', ');
      _financialContext =
          'Balance total: $balance | Ingresos (30d): $income | Gastos (30d): $expenses'
          '${cats.isNotEmpty ? ' | Top categorías: $cats' : ''}';
      // ignore: empty_catches
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  List<String> _getLocalizedSuggestions() {
    final s = AppLocalizations.of(context);
    return [
      s.suggestionSpentMonth,
      s.suggestionTopCategory,
      s.suggestionGoalsProgress,
      s.suggestionAffordabilityExample,
      s.suggestionSavingTips,
      s.suggestionCurrentBalance,
    ];
  }

  Future<void> _sendMessage(String text) async {
    final msg = text.trim();
    if (msg.isEmpty || _isTyping) return;

    final s = AppLocalizations.of(context);
    _inputController.clear();
    setState(() {
      _messages.add(ChatMessage.user(msg));
      _isTyping = true;
    });
    _scrollToBottom();

    final lowerMsg = msg.toLowerCase();
    final isAffordability = s.affordabilityKeywords.any(lowerMsg.contains);

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
        final locale = AppSettingsService().currentLocaleCode;
        final ctx = _financialContext != null
            ? '\n\nDatos financieros actuales del usuario: $_financialContext'
            : '';
        final systemPrompt = locale == 'en'
            ? '''You are Finn, the personal finance assistant built into the Finora app. Think of yourself as a knowledgeable friend who genuinely understands money — not a corporate bot reading from a script. You are smart, warm, direct, and occasionally a bit witty. You speak naturally, like a real person would in a conversation.

Your main focus is personal finance: budgets, spending habits, income, savings, investments, debt, financial goals. But you're not rigid. If someone asks something outside finance, engage briefly and naturally, then bring it back to what you can actually help with — don't just refuse with a canned message.

When you have the user's financial data, use it to give specific, personalised answers. Don't start every reply with "Based on your data..." — just weave it in naturally when relevant.

Keep responses conversational and appropriately concise. Ask follow-up questions when it helps. Share your actual opinion when asked.${ctx.replaceAll('Ingresos', 'Income').replaceAll('Gastos', 'Expenses').replaceAll('Balance total', 'Total balance').replaceAll('Top categorías', 'Top categories')}'''
            : '''Eres Finn, el asistente financiero integrado en la app Finora. Piensa en ti mismo como un amigo inteligente que entiende de verdad el dinero — no un bot corporativo leyendo un guion. Eres listo, cercano, directo y con cierto sentido del humor cuando viene al caso. Hablas con naturalidad, como lo haría una persona real en una conversación.

Tu especialidad son las finanzas personales: presupuestos, hábitos de gasto, ingresos, ahorro, inversiones, deudas, objetivos financieros. Pero no eres rígido. Si alguien te pregunta algo fuera de las finanzas, responde brevemente y con naturalidad, y luego reconduces hacia lo que puedes ayudar de verdad — no rechaces con un mensaje de plantilla.

Cuando tengas los datos financieros del usuario, úsalos para dar respuestas concretas y personalizadas. No empieces cada respuesta con "Según tus datos..." — intégralo de forma natural cuando sea relevante.

Mantén las respuestas conversacionales y apropiadamente concisas. Haz preguntas de seguimiento cuando ayude. Da tu opinión real cuando te la pidan.$ctx''';
        try {
          final resp = await _apiClient.post(
            '/ai/chat',
            data: {
              'message': msg,
              'history': _history,
              'systemPrompt': systemPrompt,
            },
          );
          final text = (resp.data as Map<String, dynamic>)['response'] as String;
          response = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: text,
            isUser: false,
            timestamp: DateTime.now(),
            intent: 'general',
          );
        } catch (_) {
          response = await _aiService.chatWithAssistant(
            msg,
            history: _history,
            language: locale,
          );
        }
      }

      _history.add({'role': 'user', 'content': msg});
      _history.add({'role': 'assistant', 'content': response.content});
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
              content: s.assistantConnectionError,
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

  Future<void> _loadRecommendations() async {
    if (_loadingRecs) return;
    setState(() => _loadingRecs = true);
    try {
      final locale = AppSettingsService().currentLocaleCode;
      final result = await _aiService.getRecommendations(
        months: 3,
        language: locale,
      );
      if (mounted) {
        final recSummary = _buildRecsMessage(result);
        setState(() {
          _loadingRecs = false;
          _messages.add(recSummary);
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _loadingRecs = false);
    }
  }

  ChatMessage _buildRecsMessage(RecommendationsResult result) {
    final s = AppLocalizations.of(context);
    final sb = StringBuffer();
    sb.writeln(s.aiRecsHeader);
    if (result.recommendations.isEmpty) {
      sb.writeln(s.aiRecsBalanced);
    } else {
      sb.writeln(s.aiFinancialScore(result.financialScore));
      sb.writeln(s.aiPotentialSavingMonthly(_fmt(result.totalPotentialSaving)));
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

  String _fmt(double v) => CurrencyService().format(v);

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
    final responsive = ResponsiveUtils(context);
    final body = Column(
      children: [
        Expanded(child: _buildMessageList()),
        if (_isTyping) _buildTypingIndicator(),
        _buildInputArea(),
      ],
    );
    if (responsive.isTablet) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: _buildAppBar(),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: body,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(),
      body: body,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final s = AppLocalizations.of(context);
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
                s.assistantOnlineStatus,
                style: AppTypography.labelSmall(color: AppColors.success),
              ),
            ],
          ),
        ],
      ),
      actions: [
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
          tooltip: s.seeRecommendations,
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
        if (_messages.length == 1 && index == 1) {
          return _buildSuggestionChips();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = _getLocalizedSuggestions();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((s) {
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

    final s = AppLocalizations.of(context);
    if (result.isYes) {
      verdictColor = AppColors.success;
      verdictIcon = Icons.check_circle_rounded;
      verdictLabel = s.affordabilityYes;
    } else if (result.isNo) {
      verdictColor = AppColors.error;
      verdictIcon = Icons.cancel_rounded;
      verdictLabel = s.affordabilityNo;
    } else {
      verdictColor = AppColors.warning;
      verdictIcon = Icons.warning_rounded;
      verdictLabel = s.affordabilityMaybe;
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
                CurrencyService().format(result.amount, decimals: 0),
                style: AppTypography.titleMedium(color: verdictColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _affordabilityRow(
            s.availableBalanceLabel,
            _fmt(result.availableBalance),
          ),
          _affordabilityRow(
            s.balanceAfterPurchase,
            _fmt(result.balanceAfter),
            valueColor: result.balanceAfter < 0 ? AppColors.error : null,
          ),
          if (result.monthlySurplus > 0)
            _affordabilityRow(
              s.monthlySurplusLabel,
              _fmt(result.monthlySurplus),
            ),
          if (result.monthsToSave != null)
            _affordabilityRow(
              s.couldSaveIn,
              '${result.monthsToSave} ${s.monthCountLabel(result.monthsToSave!)}',
              valueColor: AppColors.primary,
            ),
          if (result.impactOnGoals.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              s.impactOnGoalsLabel,
              style: AppTypography.labelSmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
            ...result.impactOnGoals.map(
              (g) => _affordabilityRow(
                g.goalName,
                g.monthsDelayed > 0
                    ? "+${g.monthsDelayed} ${s.monthCountLabel(g.monthsDelayed)}"
                    : s.noImpactLabel,
                valueColor: g.monthsDelayed > 0
                    ? AppColors.warning
                    : AppColors.success,
              ),
            ),
          ],
          if (result.alternatives.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              s.alternativesLabel,
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
    final s = AppLocalizations.of(context);
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
                  hintText: s.typeYourQuestion,
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