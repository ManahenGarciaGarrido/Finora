"""Tests for POST /savings and POST /evaluate-savings-goal endpoints (RF-21)."""

import pytest


class TestSavings:
    def test_savings_returns_recommendations(self, client, sample_transactions, monthly_income):
        """Response must contain recommendations, savings_potential, score, savings_capacity."""
        response = client.post('/savings', json={
            'transactions': sample_transactions,
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert 'recommendations' in data
        assert 'savings_potential' in data
        assert 'score' in data
        assert 'savings_capacity' in data

    def test_savings_high_spending_category(self, client, monthly_income):
        """When Alimentación exceeds 15% of income a recommendation should be generated."""
        # 400€ is ~27% of 1500€ income → above 15% reference + 20% margin
        txs = [
            {"amount": 400.0, "type": "expense", "category": "Alimentación",
             "date": "2024-01-15"},
            {"amount": 1500.0, "type": "income", "category": "Salario",
             "date": "2024-01-28"},
        ]
        response = client.post('/savings', json={
            'transactions': txs,
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        categories = [r['category'] for r in data['recommendations']]
        assert 'Alimentación' in categories

    def test_savings_score_range(self, client, sample_transactions, monthly_income):
        """Financial health score must be an integer between 0 and 100."""
        response = client.post('/savings', json={
            'transactions': sample_transactions,
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert isinstance(data['score'], int)
        assert 0 <= data['score'] <= 100

    def test_savings_capacity_structure(self, client, sample_transactions, monthly_income):
        """savings_capacity must contain ahorro_bruto and disponible."""
        response = client.post('/savings', json={
            'transactions': sample_transactions,
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        capacity = data['savings_capacity']
        assert 'ahorro_bruto' in capacity
        assert 'disponible' in capacity

    def test_savings_missing_income_uses_default(self, client, sample_transactions):
        """Missing monthly_income should not crash — defaults to 0 or transactions data."""
        response = client.post('/savings', json={'transactions': sample_transactions})
        assert response.status_code == 200
        data = response.get_json()
        assert 'score' in data

    def test_savings_empty_transactions(self, client, monthly_income):
        """Empty transactions list should return a valid response (no crash)."""
        response = client.post('/savings', json={
            'transactions': [],
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert 'recommendations' in data
        assert data['recommendations'] == []

    def test_savings_missing_transactions_key(self, client, monthly_income):
        """Missing transactions key defaults to empty list (graceful fallback)."""
        response = client.post('/savings', json={'monthly_income': monthly_income})
        assert response.status_code == 200
        data = response.get_json()
        # Should still return a valid structure (empty path)
        assert 'savings_potential' in data

    def test_savings_recommendation_has_required_fields(self, client, monthly_income):
        """Each recommendation must have category, current_spend, suggested_budget, potential_saving, message."""
        txs = [
            {"amount": 500.0, "type": "expense", "category": "Alimentación",
             "date": "2024-01-15"},
            {"amount": 1500.0, "type": "income", "category": "Salario",
             "date": "2024-01-28"},
        ]
        response = client.post('/savings', json={
            'transactions': txs,
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        for rec in data['recommendations']:
            for field in ('category', 'current_spend', 'suggested_budget', 'potential_saving', 'message'):
                assert field in rec, f"Missing field '{field}' in recommendation"

    def test_savings_potential_non_negative(self, client, sample_transactions, monthly_income):
        """savings_potential must be >= 0."""
        response = client.post('/savings', json={
            'transactions': sample_transactions,
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['savings_potential'] >= 0

    def test_savings_monthly_summary_present(self, client, sample_transactions, monthly_income):
        """monthly_summary should be present with ingreso_promedio, gasto_promedio, meses_analizados."""
        response = client.post('/savings', json={
            'transactions': sample_transactions,
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert 'monthly_summary' in data
        summary = data['monthly_summary']
        assert 'ingreso_promedio' in summary
        assert 'gasto_promedio' in summary
        assert 'meses_analizados' in summary

    def test_savings_max_5_recommendations(self, client, monthly_income):
        """Response should return at most 5 recommendations."""
        # Many categories over budget
        txs = [
            {"amount": 500.0, "type": "expense", "category": cat, "date": "2024-01-15"}
            for cat in ("Alimentación", "Vivienda", "Transporte", "Ocio", "Salud", "Educación", "Ropa")
        ] + [{"amount": 1500.0, "type": "income", "category": "Salario", "date": "2024-01-28"}]
        response = client.post('/savings', json={
            'transactions': txs,
            'monthly_income': monthly_income,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert len(data['recommendations']) <= 5


class TestEvaluateSavingsGoal:
    def _base_payload(self, sample_transactions, monthly_income, monto_total, plazo_meses):
        return {
            'transactions': sample_transactions,
            'monthly_income': monthly_income,
            'goal': {'monto_total': monto_total, 'plazo_meses': plazo_meses},
        }

    def test_returns_required_fields(self, client, sample_transactions, monthly_income):
        """Response must contain es_realista, ahorro_necesario, ahorro_recomendado, alternativas, capacidad."""
        payload = self._base_payload(sample_transactions, monthly_income, 500.0, 12)
        response = client.post('/evaluate-savings-goal', json=payload)
        assert response.status_code == 200
        data = response.get_json()
        for field in ('es_realista', 'ahorro_necesario', 'ahorro_recomendado', 'alternativas', 'capacidad'):
            assert field in data, f"Missing field: {field}"

    def test_realistic_goal(self, client, monthly_income):
        """A small goal relative to savings capacity should be es_realista=True."""
        # High income, low expenses → large capacity
        txs = [
            {"amount": 3000.0, "type": "income", "category": "Salario", "date": "2024-01-28"},
            {"amount": 200.0, "type": "expense", "category": "Alimentación", "date": "2024-01-15"},
        ]
        payload = {
            'transactions': txs,
            'monthly_income': 3000.0,
            'goal': {'monto_total': 100.0, 'plazo_meses': 6},
        }
        response = client.post('/evaluate-savings-goal', json=payload)
        assert response.status_code == 200
        data = response.get_json()
        assert data['es_realista'] is True

    def test_unrealistic_goal(self, client, sample_transactions, monthly_income):
        """A very large goal in a short timeframe should be es_realista=False."""
        payload = self._base_payload(sample_transactions, monthly_income, 100000.0, 1)
        response = client.post('/evaluate-savings-goal', json=payload)
        assert response.status_code == 200
        data = response.get_json()
        assert data['es_realista'] is False

    def test_returns_ahorro_necesario(self, client, monthly_income):
        """ahorro_necesario should equal monto_total / plazo_meses."""
        txs = [
            {"amount": 2000.0, "type": "income", "category": "Salario", "date": "2024-01-28"},
            {"amount": 500.0, "type": "expense", "category": "Alimentación", "date": "2024-01-15"},
        ]
        payload = {
            'transactions': txs,
            'monthly_income': 2000.0,
            'goal': {'monto_total': 1200.0, 'plazo_meses': 12},
        }
        response = client.post('/evaluate-savings-goal', json=payload)
        assert response.status_code == 200
        data = response.get_json()
        assert abs(data['ahorro_necesario'] - 100.0) < 0.01  # 1200/12 = 100

    def test_alternatives_when_unrealistic(self, client, sample_transactions, monthly_income):
        """When goal is unrealistic, alternativas list should be non-empty."""
        payload = self._base_payload(sample_transactions, monthly_income, 50000.0, 1)
        response = client.post('/evaluate-savings-goal', json=payload)
        assert response.status_code == 200
        data = response.get_json()
        if not data['es_realista']:
            assert len(data['alternativas']) > 0

    def test_missing_goal_monto_returns_400(self, client, sample_transactions, monthly_income):
        """Missing or zero monto_total should return 400."""
        payload = {
            'transactions': sample_transactions,
            'monthly_income': monthly_income,
            'goal': {'monto_total': 0, 'plazo_meses': 12},
        }
        response = client.post('/evaluate-savings-goal', json=payload)
        assert response.status_code == 400

    def test_goal_zero_months_no_division_error(self, client, sample_transactions, monthly_income):
        """plazo_meses=0 should not cause a division-by-zero crash."""
        payload = self._base_payload(sample_transactions, monthly_income, 1000.0, 0)
        response = client.post('/evaluate-savings-goal', json=payload)
        # Should respond without a 500 server error
        assert response.status_code in (200, 400)

    def test_capacidad_has_ahorro_bruto_and_disponible(self, client, sample_transactions, monthly_income):
        """capacidad in response must contain ahorro_bruto and disponible."""
        payload = self._base_payload(sample_transactions, monthly_income, 600.0, 6)
        response = client.post('/evaluate-savings-goal', json=payload)
        assert response.status_code == 200
        data = response.get_json()
        assert 'ahorro_bruto' in data['capacidad']
        assert 'disponible' in data['capacidad']

    def test_no_transactions_uses_monthly_income(self, client, monthly_income):
        """With no transactions, monthly_income is used as the income baseline."""
        payload = {
            'transactions': [],
            'monthly_income': monthly_income,
            'goal': {'monto_total': 300.0, 'plazo_meses': 3},
        }
        response = client.post('/evaluate-savings-goal', json=payload)
        assert response.status_code == 200
        data = response.get_json()
        assert 'es_realista' in data
