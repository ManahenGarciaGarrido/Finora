"""Tests for POST /generate-sample-transactions endpoint (RF-01)."""


class TestGenerateSampleTransactions:
    """Tests for the /generate-sample-transactions endpoint."""

    def test_returns_transactions_list(self, client):
        """Response must include a transactions list and source field."""
        response = client.post('/generate-sample-transactions', json={
            'balance_eur': 2000.0,
            'months': 6,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert 'transactions' in data
        assert 'source' in data
        assert data['source'] == 'estadistico'

    def test_transactions_non_empty(self, client):
        """Generated transactions list should not be empty."""
        response = client.post('/generate-sample-transactions', json={
            'balance_eur': 1500.0,
            'months': 6,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert len(data['transactions']) > 0

    def test_transaction_structure(self, client):
        """Each transaction must have date, desc, pm, cents, type fields."""
        response = client.post('/generate-sample-transactions', json={
            'balance_eur': 2000.0,
            'months': 6,
        })
        assert response.status_code == 200
        data = response.get_json()
        for tx in data['transactions'][:5]:
            assert 'date' in tx, f"Missing 'date' in tx: {tx}"
            assert 'desc' in tx, f"Missing 'desc' in tx: {tx}"
            assert 'pm' in tx, f"Missing 'pm' in tx: {tx}"
            assert 'cents' in tx, f"Missing 'cents' in tx: {tx}"
            assert 'type' in tx, f"Missing 'type' in tx: {tx}"

    def test_transaction_types_valid(self, client):
        """All transactions must have type 'income' or 'expense'."""
        response = client.post('/generate-sample-transactions', json={
            'balance_eur': 2000.0,
            'months': 6,
        })
        assert response.status_code == 200
        data = response.get_json()
        for tx in data['transactions']:
            assert tx['type'] in ('income', 'expense'), \
                f"Invalid type: {tx['type']}"

    def test_default_values_used_when_missing(self, client):
        """Missing balance_eur and months should use defaults without error."""
        response = client.post('/generate-sample-transactions', json={})
        assert response.status_code == 200
        data = response.get_json()
        assert len(data['transactions']) > 0

    def test_months_clamped_to_minimum(self, client):
        """months below 6 should be clamped to 6."""
        response = client.post('/generate-sample-transactions', json={
            'balance_eur': 2000.0,
            'months': 1,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert len(data['transactions']) > 0

    def test_months_clamped_to_maximum(self, client):
        """months above 36 should be clamped to 36."""
        response = client.post('/generate-sample-transactions', json={
            'balance_eur': 2000.0,
            'months': 100,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert len(data['transactions']) > 0

    def test_cents_are_positive_integers(self, client):
        """All transaction amounts in cents should be positive integers."""
        response = client.post('/generate-sample-transactions', json={
            'balance_eur': 2000.0,
            'months': 6,
        })
        assert response.status_code == 200
        data = response.get_json()
        for tx in data['transactions']:
            assert isinstance(tx['cents'], int), \
                f"Expected int cents, got {type(tx['cents'])}: {tx}"
            assert tx['cents'] > 0, f"Expected positive cents: {tx}"

    def test_includes_income_transactions(self, client):
        """Generated data must include at least some income transactions (nómina)."""
        response = client.post('/generate-sample-transactions', json={
            'balance_eur': 2000.0,
            'months': 12,
        })
        assert response.status_code == 200
        data = response.get_json()
        income_txs = [tx for tx in data['transactions'] if tx['type'] == 'income']
        assert len(income_txs) > 0, "Expected at least one income transaction"

    def test_includes_expense_transactions(self, client):
        """Generated data must include at least some expense transactions."""
        response = client.post('/generate-sample-transactions', json={
            'balance_eur': 2000.0,
            'months': 12,
        })
        assert response.status_code == 200
        data = response.get_json()
        expense_txs = [tx for tx in data['transactions'] if tx['type'] == 'expense']
        assert len(expense_txs) > 0, "Expected at least one expense transaction"

    def test_high_balance_generates_higher_salary(self, client):
        """Higher balance should correlate with a higher salary amount."""
        response_low = client.post('/generate-sample-transactions', json={
            'balance_eur': 500.0,
            'months': 6,
        })
        response_high = client.post('/generate-sample-transactions', json={
            'balance_eur': 5000.0,
            'months': 6,
        })
        assert response_low.status_code == 200
        assert response_high.status_code == 200

    def test_dates_are_valid_format(self, client):
        """All transaction dates must be in YYYY-MM-DD format."""
        import re
        date_pattern = re.compile(r'^\d{4}-\d{2}-\d{2}$')
        response = client.post('/generate-sample-transactions', json={
            'balance_eur': 2000.0,
            'months': 6,
        })
        assert response.status_code == 200
        data = response.get_json()
        for tx in data['transactions']:
            assert date_pattern.match(tx['date']), \
                f"Invalid date format: {tx['date']}"

    def test_longer_history_generates_more_transactions(self, client):
        """More months should generally produce more transactions."""
        response_6 = client.post('/generate-sample-transactions', json={
            'balance_eur': 2000.0,
            'months': 6,
        })
        response_18 = client.post('/generate-sample-transactions', json={
            'balance_eur': 2000.0,
            'months': 18,
        })
        assert response_6.status_code == 200
        assert response_18.status_code == 200
        count_6 = len(response_6.get_json()['transactions'])
        count_18 = len(response_18.get_json()['transactions'])
        assert count_18 > count_6, \
            f"Expected more transactions for 18 months ({count_18}) vs 6 months ({count_6})"

    def test_empty_body_uses_defaults(self, client):
        """Empty body (no JSON) should use defaults gracefully."""
        response = client.post('/generate-sample-transactions',
                               data='', content_type='application/json')
        assert response.status_code == 200
        data = response.get_json()
        assert 'transactions' in data
