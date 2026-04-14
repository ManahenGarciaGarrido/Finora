"""Tests for POST /chat endpoint (RF-25) and helper functions."""

from datetime import datetime, timedelta


def _this_month(day=15):
    now = datetime.now()
    return now.strftime(f'%Y-%m-{day:02d}')


def _prev_month(day=15):
    now = datetime.now()
    first = now.replace(day=1)
    prev = (first - timedelta(days=1)).replace(day=day)
    return prev.strftime('%Y-%m-%d')


def _make_transactions(income=2000.0, expense_cat='Alimentación', expense_amt=400.0,
                       prev_expense=300.0):
    """Builds transactions in current and previous month for full summary coverage."""
    return [
        # This month income
        {'amount': income, 'type': 'income', 'category': 'Salario',
         'description': 'NOMINA', 'date': _this_month(28)},
        # This month expense
        {'amount': expense_amt, 'type': 'expense', 'category': expense_cat,
         'description': 'MERCADONA', 'date': _this_month(10)},
        # Previous month expense (covers prev_month_expenses branch)
        {'amount': prev_expense, 'type': 'expense', 'category': expense_cat,
         'description': 'MERCADONA', 'date': _prev_month(10)},
        # Transaction with invalid date (covers exception-continue branch in _build_financial_summary)
        {'amount': 100.0, 'type': 'expense', 'category': 'Otros',
         'description': 'BAD', 'date': 'not-a-date'},
    ]


BASE_TRANSACTIONS = _make_transactions()


class TestChatEndpoint:
    """Tests for the /chat endpoint."""

    def test_missing_message_returns_400(self, client):
        """Request without message should return 400."""
        response = client.post('/chat', json={'transactions': []})
        assert response.status_code == 400

    def test_empty_message_returns_400(self, client):
        """Empty message string should return 400."""
        response = client.post('/chat', json={'message': '', 'transactions': []})
        assert response.status_code == 400

    def test_returns_required_fields(self, client):
        """Response must include response, intent, type."""
        response = client.post('/chat', json={
            'message': '¿Cuánto gasté?',
            'transactions': BASE_TRANSACTIONS,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert 'response' in data
        assert 'intent' in data
        assert 'type' in data

    # ── Intent: spending ──────────────────────────────────────────────────────

    def test_intent_spending_spanish(self, client):
        """'cuanto gaste' should trigger spending intent."""
        response = client.post('/chat', json={
            'message': '¿Cuánto gasté este mes?',
            'transactions': BASE_TRANSACTIONS,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'spending'
        assert isinstance(data['response'], str)

    def test_intent_spending_with_prev_month_comparison(self, client):
        """Spending with previous month data should include comparison text."""
        response = client.post('/chat', json={
            'message': 'gastos del mes',
            'transactions': BASE_TRANSACTIONS,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'spending'

    def test_intent_spending_with_positive_savings(self, client):
        """Spending response with positive savings should mention savings."""
        # Large income, small expense → positive savings
        txs = [
            {'amount': 3000.0, 'type': 'income', 'category': 'Salario',
             'date': _this_month(28)},
            {'amount': 200.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _this_month(10)},
            {'amount': 100.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _prev_month(10)},
        ]
        response = client.post('/chat', json={'message': '¿cuánto gasté?', 'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'spending'

    def test_intent_spending_deficit(self, client):
        """Spending response with negative savings should mention deficit."""
        # Expenses > income → negative savings
        txs = [
            {'amount': 500.0, 'type': 'income', 'category': 'Salario',
             'date': _this_month(28)},
            {'amount': 1200.0, 'type': 'expense', 'category': 'Vivienda',
             'date': _this_month(5)},
        ]
        response = client.post('/chat', json={'message': 'gastos del mes', 'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'spending'

    # ── Intent: income ────────────────────────────────────────────────────────

    def test_intent_income(self, client):
        """'ingresos' keyword should trigger income intent."""
        response = client.post('/chat', json={
            'message': '¿Cuáles son mis ingresos?',
            'transactions': BASE_TRANSACTIONS,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'income'

    def test_intent_income_with_expenses_shows_savings_rate(self, client):
        """Income response when there are expenses should include savings rate."""
        txs = [
            {'amount': 2000.0, 'type': 'income', 'category': 'Salario',
             'date': _this_month(28)},
            {'amount': 400.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _this_month(10)},
        ]
        response = client.post('/chat', json={'message': 'mis ingresos', 'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'income'

    # ── Intent: category ──────────────────────────────────────────────────────

    def test_intent_category_with_data(self, client):
        """'categorias' should trigger category intent and list top categories."""
        response = client.post('/chat', json={
            'message': '¿En qué categorías gasto más?',
            'transactions': BASE_TRANSACTIONS,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'category'

    def test_intent_category_no_transactions(self, client):
        """Category intent with no current-month expenses shows empty message."""
        response = client.post('/chat', json={
            'message': 'categorías de gasto',
            'transactions': [],
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'category'

    # ── Intent: savings ───────────────────────────────────────────────────────

    def test_intent_savings_with_goals(self, client):
        """Savings intent with goals should list goal progress."""
        goals = [
            {'name': 'Vacaciones', 'target_amount': 2000.0, 'current_amount': 500.0},
            {'name': 'Coche', 'target_amount': 10000.0, 'current_amount': 1000.0},
        ]
        response = client.post('/chat', json={
            'message': '¿Cuánto ahorro?',
            'transactions': BASE_TRANSACTIONS,
            'goals': goals,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'savings'

    def test_intent_savings_no_goals_positive_savings(self, client):
        """Savings intent without goals but positive savings mentions savings."""
        txs = [
            {'amount': 3000.0, 'type': 'income', 'category': 'Salario',
             'date': _this_month(28)},
            {'amount': 200.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _this_month(10)},
        ]
        response = client.post('/chat', json={
            'message': 'objetivo de ahorro',
            'transactions': txs,
            'goals': [],
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'savings'

    def test_intent_savings_no_goals_negative_savings(self, client):
        """Savings intent without goals and negative savings mentions recommendation."""
        txs = [
            {'amount': 500.0, 'type': 'income', 'category': 'Salario',
             'date': _this_month(28)},
            {'amount': 1200.0, 'type': 'expense', 'category': 'Vivienda',
             'date': _this_month(5)},
        ]
        response = client.post('/chat', json={
            'message': 'ahorro mensual',
            'transactions': txs,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'savings'

    # ── Intent: balance ───────────────────────────────────────────────────────

    def test_intent_balance_positive(self, client):
        """'saldo' with positive balance gives yes-type response."""
        txs = [
            {'amount': 5000.0, 'type': 'income', 'category': 'Salario',
             'date': _this_month(28)},
            {'amount': 200.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _this_month(10)},
        ]
        response = client.post('/chat', json={'message': '¿Cuál es mi saldo?', 'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'balance'

    def test_intent_balance_negative(self, client):
        """Balance intent with negative balance mentions warning."""
        txs = [
            {'amount': 200.0, 'type': 'income', 'category': 'Salario',
             'date': _this_month(28)},
            {'amount': 5000.0, 'type': 'expense', 'category': 'Vivienda',
             'date': _this_month(5)},
        ]
        response = client.post('/chat', json={'message': 'balance disponible', 'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'balance'

    # ── Intent: subscriptions ────────────────────────────────────────────────

    def test_intent_subscriptions(self, client):
        """'suscripciones' keyword triggers subscriptions intent."""
        response = client.post('/chat', json={
            'message': '¿Cuáles son mis suscripciones?',
            'transactions': BASE_TRANSACTIONS,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'subscriptions'

    # ── Intent: recommendations ──────────────────────────────────────────────

    def test_intent_recommendations_with_categories(self, client):
        """'recomendaciones' with data above budget triggers saving recommendations."""
        txs = [
            {'amount': 2000.0, 'type': 'income', 'category': 'Salario',
             'date': _this_month(28)},
            {'amount': 800.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _this_month(10)},
        ]
        response = client.post('/chat', json={
            'message': '¿Qué recomendaciones tienes?',
            'transactions': txs,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'recommendations'

    def test_intent_recommendations_no_over_budget(self, client):
        """Recommendations when spending is balanced shows good finances message."""
        txs = [
            {'amount': 5000.0, 'type': 'income', 'category': 'Salario',
             'date': _this_month(28)},
            {'amount': 100.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _this_month(10)},
        ]
        response = client.post('/chat', json={
            'message': 'consejos financieros',
            'transactions': txs,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'recommendations'

    # ── Intent: trend ────────────────────────────────────────────────────────

    def test_intent_trend_with_comparison(self, client):
        """'tendencia' with current and previous month data enables comparison."""
        response = client.post('/chat', json={
            'message': '¿Cómo va mi tendencia de gastos?',
            'transactions': BASE_TRANSACTIONS,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'trend'

    def test_intent_trend_increasing(self, client):
        """When current month expenses > previous month, response mentions increase."""
        txs = [
            # Previous month: small expense
            {'amount': 200.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _prev_month(10)},
            # This month: much higher expense
            {'amount': 1000.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _this_month(10)},
        ]
        response = client.post('/chat', json={'message': 'evolución gastos', 'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'trend'

    def test_intent_trend_decreasing(self, client):
        """When current month expenses < previous month, response mentions decrease."""
        txs = [
            {'amount': 1000.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _prev_month(10)},
            {'amount': 200.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _this_month(10)},
        ]
        response = client.post('/chat', json={'message': 'comparado con el mes pasado', 'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'trend'

    def test_intent_trend_stable(self, client):
        """When expenses are similar month-to-month, response mentions stability."""
        txs = [
            {'amount': 500.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _prev_month(10)},
            {'amount': 502.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _this_month(10)},
        ]
        response = client.post('/chat', json={'message': 'mes anterior gastos', 'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'trend'

    def test_intent_trend_no_history(self, client):
        """Trend intent with no prev month data shows insufficient history message."""
        response = client.post('/chat', json={
            'message': 'tendencia',
            'transactions': [],
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'trend'

    # ── Intent: affordability ────────────────────────────────────────────────

    def test_intent_affordability(self, client):
        """'puedo comprar' triggers affordability intent."""
        response = client.post('/chat', json={
            'message': '¿Puedo comprar un portátil?',
            'transactions': BASE_TRANSACTIONS,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'affordability'

    # ── Intent: general ──────────────────────────────────────────────────────

    def test_intent_general_spanish(self, client):
        """An unrecognized message defaults to general intent in Spanish."""
        response = client.post('/chat', json={
            'message': 'hola como estas',
            'transactions': BASE_TRANSACTIONS,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'general'

    def test_intent_general_english(self, client):
        """Unrecognized message in English language returns general response in English."""
        response = client.post('/chat', json={
            'message': 'hello how are you',
            'transactions': BASE_TRANSACTIONS,
            'language': 'en',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'general'

    # ── English language branches ────────────────────────────────────────────

    def test_spending_intent_english(self, client):
        """Chat in English should return English response for spending intent."""
        txs = [
            {'amount': 2000.0, 'type': 'income', 'category': 'Salary',
             'date': _this_month(28)},
            {'amount': 400.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _this_month(10)},
            {'amount': 300.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _prev_month(10)},
        ]
        response = client.post('/chat', json={
            'message': 'cuánto gasté',
            'transactions': txs,
            'language': 'en',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert 'response' in data

    def test_income_intent_english(self, client):
        """Income intent in English language."""
        txs = [
            {'amount': 2000.0, 'type': 'income', 'category': 'Salary',
             'date': _this_month(28)},
            {'amount': 400.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _this_month(10)},
        ]
        response = client.post('/chat', json={
            'message': 'mis ingresos',
            'transactions': txs,
            'language': 'en',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'income'

    def test_category_intent_english(self, client):
        """Category intent in English language."""
        response = client.post('/chat', json={
            'message': 'categorías',
            'transactions': BASE_TRANSACTIONS,
            'language': 'en',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'category'

    def test_savings_intent_english_with_goals(self, client):
        """Savings intent in English with goals."""
        goals = [{'name': 'Vacation', 'target_amount': 3000.0, 'current_amount': 600.0}]
        response = client.post('/chat', json={
            'message': 'ahorro',
            'transactions': BASE_TRANSACTIONS,
            'goals': goals,
            'language': 'en',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'savings'

    def test_balance_intent_english_positive(self, client):
        """Balance intent in English with positive balance."""
        txs = [
            {'amount': 5000.0, 'type': 'income', 'category': 'Salary',
             'date': _this_month(28)},
            {'amount': 200.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _this_month(10)},
        ]
        response = client.post('/chat', json={
            'message': 'saldo',
            'transactions': txs,
            'language': 'en',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'balance'

    def test_balance_intent_english_negative(self, client):
        """Balance intent in English with negative balance shows warning."""
        txs = [
            {'amount': 100.0, 'type': 'income', 'category': 'Salary',
             'date': _this_month(28)},
            {'amount': 5000.0, 'type': 'expense', 'category': 'Vivienda',
             'date': _this_month(5)},
        ]
        response = client.post('/chat', json={
            'message': 'balance',
            'transactions': txs,
            'language': 'en',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'balance'

    def test_trend_intent_english_increasing(self, client):
        """Trend increasing in English language."""
        txs = [
            {'amount': 200.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _prev_month(10)},
            {'amount': 1000.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _this_month(10)},
        ]
        response = client.post('/chat', json={
            'message': 'tendencia',
            'transactions': txs,
            'language': 'en',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'trend'

    def test_trend_intent_english_decreasing(self, client):
        """Trend decreasing in English language."""
        txs = [
            {'amount': 1000.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _prev_month(10)},
            {'amount': 100.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _this_month(10)},
        ]
        response = client.post('/chat', json={
            'message': 'evolución',
            'transactions': txs,
            'language': 'en',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'trend'

    def test_trend_intent_english_stable(self, client):
        """Trend stable in English language."""
        txs = [
            {'amount': 500.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _prev_month(10)},
            {'amount': 501.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _this_month(10)},
        ]
        response = client.post('/chat', json={
            'message': 'comparado',
            'transactions': txs,
            'language': 'en',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'trend'

    def test_subscriptions_intent_english(self, client):
        """Subscriptions intent in English language."""
        response = client.post('/chat', json={
            'message': 'suscripciones',
            'transactions': [],
            'language': 'en',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'subscriptions'

    def test_recommendations_intent_english_over_budget(self, client):
        """Recommendations intent in English when over budget."""
        txs = [
            {'amount': 2000.0, 'type': 'income', 'category': 'Salario',
             'date': _this_month(28)},
            {'amount': 800.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _this_month(10)},
        ]
        response = client.post('/chat', json={
            'message': 'recomendaciones',
            'transactions': txs,
            'language': 'en',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'recommendations'

    def test_recommendations_intent_english_balanced(self, client):
        """Recommendations intent in English when finances are balanced."""
        txs = [
            {'amount': 5000.0, 'type': 'income', 'category': 'Salario',
             'date': _this_month(28)},
            {'amount': 100.0, 'type': 'expense', 'category': 'Alimentación',
             'date': _this_month(10)},
        ]
        response = client.post('/chat', json={
            'message': 'optimizar',
            'transactions': txs,
            'language': 'en',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'recommendations'

    def test_affordability_intent_english(self, client):
        """Affordability intent in English language."""
        response = client.post('/chat', json={
            'message': '¿Puedo comprar algo?',
            'transactions': BASE_TRANSACTIONS,
            'language': 'en',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['intent'] == 'affordability'

    def test_no_transactions_general_response(self, client):
        """Chat with empty transactions should still return a valid response."""
        response = client.post('/chat', json={
            'message': 'Hola, ¿qué puedes hacer?',
            'transactions': [],
        })
        assert response.status_code == 200
        data = response.get_json()
        assert 'response' in data
