"""Tests for POST /detect-subscriptions endpoint (RF-24 / HU-11)."""


class TestSubscriptions:
    def test_detects_monthly_netflix(self, client):
        """Netflix at same price monthly (30-day interval) should be detected as subscription."""
        txs = [
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-01-01"},
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-02-01"},
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-03-02"},
        ]
        response = client.post('/detect-subscriptions', json={'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        names = [s['name'].upper() for s in data['subscriptions']]
        assert any('NETFLIX' in n for n in names), \
            f"NETFLIX not found in detected subscriptions: {names}"

    def test_requires_min_2_occurrences(self, client):
        """A single transaction should not be flagged as a subscription."""
        txs = [
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-01-01"},
        ]
        response = client.post('/detect-subscriptions', json={'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        assert data['total_subscriptions'] == 0

    def test_amount_variation_tolerance(self, client):
        """Amounts within 10% variation should still be detected as subscription."""
        txs = [
            {"amount": 10.00, "type": "expense", "category": "Servicios",
             "description": "MOVISTAR MOVIL", "date": "2024-01-05"},
            {"amount": 10.50, "type": "expense", "category": "Servicios",
             "description": "MOVISTAR MOVIL", "date": "2024-02-05"},
            {"amount": 10.25, "type": "expense", "category": "Servicios",
             "description": "MOVISTAR MOVIL", "date": "2024-03-05"},
        ]
        response = client.post('/detect-subscriptions', json={'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        # variation ~5% → should be detected
        assert data['total_subscriptions'] >= 1

    def test_high_amount_variation_not_subscription(self, client):
        """Amounts with >10% variation should NOT be detected as subscription."""
        txs = [
            {"amount": 10.00, "type": "expense", "category": "Alimentación",
             "description": "MERCADONA", "date": "2024-01-05"},
            {"amount": 50.00, "type": "expense", "category": "Alimentación",
             "description": "MERCADONA", "date": "2024-02-05"},
            {"amount": 100.00, "type": "expense", "category": "Alimentación",
             "description": "MERCADONA", "date": "2024-03-05"},
        ]
        response = client.post('/detect-subscriptions', json={'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        # >10% variation → not a subscription
        assert data['total_subscriptions'] == 0

    def test_returns_total_monthly_cost(self, client):
        """Response must include total_monthly_cost field."""
        txs = [
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-01-01"},
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-02-01"},
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-03-02"},
        ]
        response = client.post('/detect-subscriptions', json={'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        assert 'total_monthly_cost' in data
        assert data['total_monthly_cost'] >= 0

    def test_returns_total_annual_cost(self, client):
        """Response must include total_annual_cost = total_monthly_cost * 12."""
        txs = [
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-01-01"},
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-02-01"},
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-03-02"},
        ]
        response = client.post('/detect-subscriptions', json={'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        assert 'total_annual_cost' in data
        assert abs(data['total_annual_cost'] - data['total_monthly_cost'] * 12) < 0.01

    def test_detects_period_monthly(self, client):
        """30-day intervals should be classified as period='monthly'."""
        txs = [
            {"amount": 9.99, "type": "expense", "category": "Servicios",
             "description": "SPOTIFY PREMIUM", "date": "2024-01-10"},
            {"amount": 9.99, "type": "expense", "category": "Servicios",
             "description": "SPOTIFY PREMIUM", "date": "2024-02-10"},
            {"amount": 9.99, "type": "expense", "category": "Servicios",
             "description": "SPOTIFY PREMIUM", "date": "2024-03-11"},
        ]
        response = client.post('/detect-subscriptions', json={'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        for sub in data['subscriptions']:
            if 'SPOTIFY' in sub['name'].upper():
                assert sub['periodicity'] == 'monthly'
                break

    def test_detects_period_weekly(self, client):
        """7-day intervals should be classified as period='weekly'."""
        txs = [
            {"amount": 5.00, "type": "expense", "category": "Servicios",
             "description": "WEEKLY SERVICE", "date": "2024-01-01"},
            {"amount": 5.00, "type": "expense", "category": "Servicios",
             "description": "WEEKLY SERVICE", "date": "2024-01-08"},
            {"amount": 5.00, "type": "expense", "category": "Servicios",
             "description": "WEEKLY SERVICE", "date": "2024-01-15"},
        ]
        response = client.post('/detect-subscriptions', json={'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        weekly_subs = [s for s in data['subscriptions'] if s['periodicity'] == 'weekly']
        assert len(weekly_subs) > 0, "Expected at least one weekly subscription"

    def test_empty_transactions(self, client):
        """Empty transactions list should return empty subscriptions."""
        response = client.post('/detect-subscriptions', json={'transactions': []})
        assert response.status_code == 200
        data = response.get_json()
        assert data['subscriptions'] == []
        assert data['total_subscriptions'] == 0
        assert data['total_monthly_cost'] == 0

    def test_subscription_has_required_fields(self, client):
        """Each detected subscription must contain name, amount, periodicity, next_charge."""
        txs = [
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-01-01"},
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-02-01"},
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-03-02"},
        ]
        response = client.post('/detect-subscriptions', json={'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        for sub in data['subscriptions']:
            for field in ('name', 'amount', 'periodicity', 'next_charge', 'monthly_cost'):
                assert field in sub, f"Missing field '{field}' in subscription"

    def test_income_transactions_ignored(self, client):
        """Income transactions should not be considered for subscription detection."""
        txs = [
            {"amount": 1500.0, "type": "income", "category": "Salario",
             "description": "NOMINA", "date": "2024-01-28"},
            {"amount": 1500.0, "type": "income", "category": "Salario",
             "description": "NOMINA", "date": "2024-02-28"},
            {"amount": 1500.0, "type": "income", "category": "Salario",
             "description": "NOMINA", "date": "2024-03-28"},
        ]
        response = client.post('/detect-subscriptions', json={'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        assert data['total_subscriptions'] == 0

    def test_missing_transactions_key(self, client):
        """Missing transactions key should return empty subscriptions gracefully."""
        response = client.post('/detect-subscriptions', json={})
        assert response.status_code == 200
        data = response.get_json()
        assert data['total_subscriptions'] == 0

    def test_multiple_subscriptions_detected(self, client):
        """Two different subscriptions in same data should both be detected."""
        txs = [
            # Netflix x3
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-01-01"},
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-02-01"},
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-03-02"},
            # Spotify x3
            {"amount": 9.99, "type": "expense", "category": "Ocio",
             "description": "SPOTIFY PREMIUM", "date": "2024-01-05"},
            {"amount": 9.99, "type": "expense", "category": "Ocio",
             "description": "SPOTIFY PREMIUM", "date": "2024-02-05"},
            {"amount": 9.99, "type": "expense", "category": "Ocio",
             "description": "SPOTIFY PREMIUM", "date": "2024-03-06"},
        ]
        response = client.post('/detect-subscriptions', json={'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        assert data['total_subscriptions'] >= 2

    def test_total_monthly_cost_equals_sum(self, client):
        """total_monthly_cost should equal the sum of individual subscription monthly_cost."""
        txs = [
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-01-01"},
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-02-01"},
            {"amount": 12.99, "type": "expense", "category": "Ocio",
             "description": "NETFLIX", "date": "2024-03-02"},
        ]
        response = client.post('/detect-subscriptions', json={'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        computed = sum(s['monthly_cost'] for s in data['subscriptions'])
        assert abs(computed - data['total_monthly_cost']) < 0.01
