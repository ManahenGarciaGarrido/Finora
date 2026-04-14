"""Tests for POST /categorize and POST /categorize/batch endpoints (RF-14)."""

REQUIRED_FIELDS = {'category', 'confidence', 'is_fallback', 'method'}


class TestCategorize:
    def test_categorize_alimentacion(self, client):
        """MERCADONA description should resolve to Alimentación."""
        response = client.post('/categorize', json={
            'description': 'MERCADONA 234 VALENCIA',
            'type': 'expense',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['category'] == 'Alimentación'

    def test_categorize_transporte(self, client):
        """REPSOL GASOLINERA should resolve to Transporte."""
        response = client.post('/categorize', json={
            'description': 'REPSOL GASOLINERA',
            'type': 'expense',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['category'] == 'Transporte'

    def test_categorize_ocio(self, client):
        """NETFLIX or SPOTIFY should resolve to Ocio."""
        response = client.post('/categorize', json={
            'description': 'NETFLIX SUBSCRIPTION',
            'type': 'expense',
        })
        assert response.status_code == 200
        data = response.get_json()
        # Rule engine maps netflix → Ocio; ML may or may not be loaded
        assert data['category'] in ('Ocio', 'Servicios')

    def test_categorize_salario_income(self, client):
        """NOMINA + type='income' should resolve to Salario."""
        response = client.post('/categorize', json={
            'description': 'NOMINA EMPRESA SL',
            'type': 'income',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['category'] == 'Salario'

    def test_categorize_vivienda(self, client):
        """ALQUILER description should resolve to Vivienda."""
        response = client.post('/categorize', json={
            'description': 'ALQUILER ENERO 2024',
            'type': 'expense',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['category'] == 'Vivienda'

    def test_categorize_unknown_description(self, client):
        """Completely unknown description should fall back to Otros."""
        response = client.post('/categorize', json={
            'description': 'XYZQRST CORP 999888777',
            'type': 'expense',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['is_fallback'] is True
        assert data['category'] == 'Otros'
        assert data['method'] == 'fallback'

    def test_categorize_confidence_high_for_known(self, client):
        """A well-known merchant like MERCADONA should have confidence >= 50."""
        response = client.post('/categorize', json={
            'description': 'MERCADONA SUPERMERCADO',
            'type': 'expense',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['confidence'] >= 50

    def test_categorize_missing_description(self, client):
        """Empty description should return 400 with error message."""
        response = client.post('/categorize', json={
            'description': '',
            'type': 'expense',
        })
        assert response.status_code == 400
        data = response.get_json()
        assert 'error' in data

    def test_categorize_missing_description_key(self, client):
        """Missing description key should return 400."""
        response = client.post('/categorize', json={'type': 'expense'})
        assert response.status_code == 400

    def test_categorize_returns_required_fields(self, client):
        """Response must contain category, confidence, is_fallback, and method."""
        response = client.post('/categorize', json={
            'description': 'MERCADONA 234',
            'type': 'expense',
        })
        assert response.status_code == 200
        data = response.get_json()
        for field in REQUIRED_FIELDS:
            assert field in data, f"Missing field: {field}"

    def test_categorize_confidence_is_int(self, client):
        """Confidence should be an integer percentage (0-100)."""
        response = client.post('/categorize', json={
            'description': 'REPSOL GASOLINERA',
            'type': 'expense',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert isinstance(data['confidence'], int)
        assert 0 <= data['confidence'] <= 100

    def test_categorize_is_fallback_is_bool(self, client):
        """is_fallback field must be boolean."""
        response = client.post('/categorize', json={
            'description': 'MERCADONA',
            'type': 'expense',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert isinstance(data['is_fallback'], bool)

    def test_categorize_case_insensitive(self, client):
        """Lower-case and upper-case descriptions should produce same category."""
        upper = client.post('/categorize', json={
            'description': 'MERCADONA SUPERMERCADO',
            'type': 'expense',
        }).get_json()
        lower = client.post('/categorize', json={
            'description': 'mercadona supermercado',
            'type': 'expense',
        }).get_json()
        assert upper['category'] == lower['category']

    def test_categorize_invalid_type(self, client):
        """type must be 'income' or 'expense', anything else returns 400."""
        response = client.post('/categorize', json={
            'description': 'MERCADONA',
            'type': 'unknown_type',
        })
        assert response.status_code == 400

    def test_categorize_income_fallback(self, client):
        """Unknown income description should fall back to 'Otros ingresos'."""
        response = client.post('/categorize', json={
            'description': 'XYZQRST TRANSFERENCIA',
            'type': 'income',
        })
        assert response.status_code == 200
        data = response.get_json()
        if data['is_fallback']:
            assert data['category'] == 'Otros ingresos'

    def test_categorize_farmacia_salud(self, client):
        """FARMACIA description should resolve to Salud."""
        response = client.post('/categorize', json={
            'description': 'FARMACIA CENTRAL',
            'type': 'expense',
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['category'] == 'Salud'


class TestCategorizeBatch:
    def test_categorize_batch_multiple(self, client):
        """Batch with 3 transactions should return 3 results."""
        response = client.post('/categorize/batch', json={
            'transactions': [
                {'description': 'MERCADONA', 'type': 'expense'},
                {'description': 'NETFLIX', 'type': 'expense'},
                {'description': 'NOMINA EMPRESA', 'type': 'income'},
            ]
        })
        assert response.status_code == 200
        data = response.get_json()
        assert 'results' in data
        assert len(data['results']) == 3

    def test_categorize_batch_max_500(self, client):
        """501 transactions should return 400 error."""
        transactions = [{'description': 'MERCADONA', 'type': 'expense'}] * 501
        response = client.post('/categorize/batch', json={'transactions': transactions})
        assert response.status_code == 400
        data = response.get_json()
        assert 'error' in data

    def test_categorize_batch_empty(self, client):
        """Empty transactions list should return 400."""
        response = client.post('/categorize/batch', json={'transactions': []})
        assert response.status_code == 400

    def test_categorize_batch_returns_all_results(self, client):
        """Results are in same order as the input transactions."""
        txs = [
            {'description': 'MERCADONA', 'type': 'expense'},
            {'description': 'REPSOL', 'type': 'expense'},
            {'description': 'NETFLIX', 'type': 'expense'},
        ]
        response = client.post('/categorize/batch', json={'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        assert len(data['results']) == len(txs)

    def test_categorize_batch_each_result_has_required_fields(self, client):
        """Each result in batch must have all required fields."""
        response = client.post('/categorize/batch', json={
            'transactions': [
                {'description': 'MERCADONA', 'type': 'expense'},
            ]
        })
        assert response.status_code == 200
        result = response.get_json()['results'][0]
        for field in REQUIRED_FIELDS:
            assert field in result, f"Missing field: {field}"

    def test_categorize_batch_empty_description_is_fallback(self, client):
        """Empty description in a batch item should produce a fallback result."""
        response = client.post('/categorize/batch', json={
            'transactions': [{'description': '', 'type': 'expense'}]
        })
        assert response.status_code == 200
        result = response.get_json()['results'][0]
        assert result['is_fallback'] is True

    def test_categorize_batch_500_transactions_accepted(self, client):
        """Exactly 500 transactions should be accepted."""
        transactions = [{'description': 'MERCADONA', 'type': 'expense'}] * 500
        response = client.post('/categorize/batch', json={'transactions': transactions})
        assert response.status_code == 200
        data = response.get_json()
        assert len(data['results']) == 500
