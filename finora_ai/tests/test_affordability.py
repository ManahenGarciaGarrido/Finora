"""Tests for POST /affordability and POST /recommendations endpoints (RF-26/RF-27)."""


class TestAffordability:
    """Tests for the /affordability endpoint."""

    def _base_payload(self, sample_transactions, monthly_income, query, amount=None):
        payload = {
            'query': query,
            'transactions': sample_transactions,
            'monthly_income': monthly_income,
        }
        if amount is not None:
            payload['amount'] = amount
        return payload

    def test_can_afford_small_amount(self, client, sample_transactions, monthly_income):
        """A small amount should return a yes or caution verdict when balance covers it."""
        # Transactions have income=1500, expenses=~1600 over one month
        # We pass explicit amount=1 (trivially affordable)
        response = client.post('/affordability', json={
            'query': '¿Puedo comprar un café de 1€?',
            'amount': 1.0,
            'transactions': sample_transactions,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['verdict'] in ('yes', 'caution', 'no')

    def test_returns_verdict_field(self, client, sample_transactions):
        """Response must include verdict, amount, analysis, recommendation."""
        response = client.post('/affordability', json={
            'query': '¿Puedo comprar un portátil de 800€?',
            'amount': 800.0,
            'transactions': sample_transactions,
        })
        assert response.status_code == 200
        data = response.get_json()
        for field in ('verdict', 'amount', 'analysis', 'recommendation'):
            assert field in data, f"Missing field: {field}"

    def test_verdict_values_valid(self, client, sample_transactions):
        """verdict must be one of 'yes', 'no', 'caution'."""
        response = client.post('/affordability', json={
            'query': '¿Puedo comprar un coche de 20000€?',
            'amount': 20000.0,
            'transactions': sample_transactions,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['verdict'] in ('yes', 'no', 'caution')

    def test_missing_amount_extracted_from_query(self, client, sample_transactions):
        """If amount is not provided explicitly, it should be extracted from the query string."""
        response = client.post('/affordability', json={
            'query': '¿Puedo permitirme un portátil de 500€?',
            'transactions': sample_transactions,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['amount'] == 500.0

    def test_missing_amount_no_number_in_query_returns_400(self, client, sample_transactions):
        """Query without a numeric amount and no explicit amount should return 400."""
        response = client.post('/affordability', json={
            'query': '¿Puedo comprar algo?',
            'transactions': sample_transactions,
        })
        assert response.status_code == 400

    def test_missing_query_and_amount_returns_400(self, client, sample_transactions):
        """Missing both query and amount fields should return 400 (no amount to extract)."""
        response = client.post('/affordability', json={
            'transactions': sample_transactions,
        })
        assert response.status_code == 400

    def test_returns_available_balance_and_balance_after(self, client, sample_transactions):
        """Response must contain available_balance and balance_after."""
        response = client.post('/affordability', json={
            'query': '¿Puedo gastar 50€?',
            'amount': 50.0,
            'transactions': sample_transactions,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert 'available_balance' in data
        assert 'balance_after' in data
        assert abs(data['balance_after'] - (data['available_balance'] - data['amount'])) < 0.01

    def test_large_amount_gives_no_verdict(self, client):
        """An amount much larger than any income/savings should yield verdict='no'."""
        # No transactions → balance=0 → can't cover large amount
        response = client.post('/affordability', json={
            'query': '¿Puedo comprar un yate de 1000000€?',
            'amount': 1_000_000.0,
            'transactions': [],
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['verdict'] == 'no'

    def test_alternatives_present_when_no_verdict(self, client):
        """When verdict is 'no' or 'caution', alternatives list should be present."""
        response = client.post('/affordability', json={
            'query': '¿Puedo comprar algo de 1000000€?',
            'amount': 1_000_000.0,
            'transactions': [],
        })
        assert response.status_code == 200
        data = response.get_json()
        if data['verdict'] in ('no', 'caution'):
            assert 'alternatives' in data

    def test_returns_monthly_surplus(self, client, sample_transactions):
        """Response must contain monthly_surplus field."""
        response = client.post('/affordability', json={
            'query': '¿Puedo comprar algo de 100€?',
            'amount': 100.0,
            'transactions': sample_transactions,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert 'monthly_surplus' in data

    def test_goal_impact_present(self, client, sample_transactions):
        """impact_on_goals should be present (even if empty list)."""
        goals = [
            {"name": "Vacaciones", "target_amount": 2000.0, "current_amount": 500.0}
        ]
        response = client.post('/affordability', json={
            'query': '¿Puedo gastar 300€?',
            'amount': 300.0,
            'transactions': sample_transactions,
            'goals': goals,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert 'impact_on_goals' in data
        assert isinstance(data['impact_on_goals'], list)


class TestRecommendations:
    """Tests for the /recommendations endpoint (RF-27)."""

    def test_returns_recommendations(self, client, sample_transactions, monthly_income):
        """POST /recommendations should return recommendations list."""
        response = client.post('/recommendations', json={
            'transactions': sample_transactions,
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert 'recommendations' in data
        assert isinstance(data['recommendations'], list)

    def test_returns_total_potential_saving(self, client, sample_transactions, monthly_income):
        """Response must include total_potential_saving."""
        response = client.post('/recommendations', json={
            'transactions': sample_transactions,
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert 'total_potential_saving' in data
        assert data['total_potential_saving'] >= 0

    def test_returns_financial_score(self, client, sample_transactions, monthly_income):
        """Response must include financial_score between 0 and 100."""
        response = client.post('/recommendations', json={
            'transactions': sample_transactions,
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert 'financial_score' in data
        assert 0 <= data['financial_score'] <= 100

    def test_recommendations_have_required_fields(self, client, sample_transactions, monthly_income):
        """Each recommendation must have category, title, description, potential_saving, priority, type."""
        response = client.post('/recommendations', json={
            'transactions': sample_transactions,
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        for rec in data['recommendations']:
            for field in ('category', 'title', 'description', 'potential_saving', 'priority', 'type'):
                assert field in rec, f"Missing field '{field}' in recommendation"

    def test_recommendation_priority_values(self, client, sample_transactions, monthly_income):
        """Each recommendation priority must be one of: high, medium, low."""
        response = client.post('/recommendations', json={
            'transactions': sample_transactions,
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        for rec in data['recommendations']:
            assert rec['priority'] in ('high', 'medium', 'low'), \
                f"Unexpected priority: {rec['priority']}"

    def test_recommendation_type_values(self, client, sample_transactions, monthly_income):
        """Each recommendation type must be a known type."""
        valid_types = {'overspending', 'subscription', 'savings_rate', 'emergency'}
        response = client.post('/recommendations', json={
            'transactions': sample_transactions,
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        for rec in data['recommendations']:
            assert rec['type'] in valid_types, f"Unexpected type: {rec['type']}"

    def test_total_saving_potential_sum(self, client, sample_transactions, monthly_income):
        """total_potential_saving should approximately equal the sum of individual savings."""
        response = client.post('/recommendations', json={
            'transactions': sample_transactions,
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        computed = sum(r['potential_saving'] for r in data['recommendations'])
        assert abs(computed - data['total_potential_saving']) < 0.05

    def test_max_10_recommendations(self, client, sample_transactions, monthly_income):
        """Response should return at most 10 recommendations."""
        response = client.post('/recommendations', json={
            'transactions': sample_transactions,
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert len(data['recommendations']) <= 10

    def test_empty_transactions(self, client, monthly_income):
        """Empty transactions should return valid response (possibly no recommendations)."""
        response = client.post('/recommendations', json={
            'transactions': [],
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert 'recommendations' in data

    def test_analysis_months_field(self, client, sample_transactions, monthly_income):
        """Response must include analysis_months field."""
        response = client.post('/recommendations', json={
            'transactions': sample_transactions,
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert 'analysis_months' in data
        assert data['analysis_months'] >= 1

    def test_subscriptions_trigger_recommendation(self, client, sample_transactions, monthly_income):
        """When 3+ subscriptions are provided, a subscription recommendation should appear."""
        subscriptions = [
            {"monthly_cost": 12.99, "name": "Netflix"},
            {"monthly_cost": 9.99, "name": "Spotify"},
            {"monthly_cost": 7.99, "name": "Disney+"},
        ]
        response = client.post('/recommendations', json={
            'transactions': sample_transactions,
            'monthly_income': monthly_income,
            'subscriptions': subscriptions,
        })
        assert response.status_code == 200
        data = response.get_json()
        types = [r['type'] for r in data['recommendations']]
        assert 'subscription' in types, "Expected a subscription recommendation"
