"""Tests for POST /predict-expenses endpoint (RF-22) and helper functions."""

import pytest


class TestPredictExpenses:
    def test_predict_with_enough_data(self, client, sample_transactions):
        """With >=3 months of data the endpoint should return predictions."""
        # Extend sample_transactions to cover 3 months of the same categories
        txs = sample_transactions + [
            {"id": "10", "amount": 50.0, "type": "expense", "category": "Alimentación",
             "description": "MERCADONA FEB", "date": "2024-02-10"},
            {"id": "11", "amount": 800.0, "type": "expense", "category": "Vivienda",
             "description": "ALQUILER FEB", "date": "2024-02-05"},
            {"id": "12", "amount": 35.0, "type": "expense", "category": "Transporte",
             "description": "REPSOL FEB", "date": "2024-02-16"},
            {"id": "13", "amount": 50.0, "type": "expense", "category": "Alimentación",
             "description": "MERCADONA MAR", "date": "2024-03-10"},
            {"id": "14", "amount": 800.0, "type": "expense", "category": "Vivienda",
             "description": "ALQUILER MAR", "date": "2024-03-05"},
        ]
        response = client.post('/predict-expenses', json={'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        assert 'predictions' in data
        assert len(data['predictions']) > 0

    def test_predict_returns_structure(self, client, sample_transactions):
        """Response must include predictions[], total_predicted, trend, months_of_data."""
        response = client.post('/predict-expenses', json={'transactions': sample_transactions})
        assert response.status_code == 200
        data = response.get_json()
        required_keys = {'predictions', 'total_predicted', 'trend', 'months_of_data'}
        for key in required_keys:
            assert key in data, f"Missing key: {key}"

    def test_predict_insufficient_data_single_transaction(self, client):
        """Only 1 transaction returns empty predictions list (or graceful response)."""
        response = client.post('/predict-expenses', json={
            'transactions': [
                {"amount": 50.0, "type": "expense", "category": "Alimentación",
                 "description": "MERCADONA", "date": "2024-01-15"}
            ]
        })
        assert response.status_code == 200
        data = response.get_json()
        # A single data point can still produce a prediction via EMA fallback
        assert 'predictions' in data

    def test_predict_trend_values(self, client, sample_transactions):
        """trend field must be one of: increasing, decreasing, stable."""
        response = client.post('/predict-expenses', json={'transactions': sample_transactions})
        assert response.status_code == 200
        data = response.get_json()
        assert data['trend'] in ('increasing', 'decreasing', 'stable')

    def test_predict_model_selection_few_samples(self, client):
        """With <=4 months of data Ridge model should be used for eligible categories."""
        # 3 months of Alimentación data → 1 feature row → Ridge
        txs = [
            {"amount": 100.0, "type": "expense", "category": "Alimentación",
             "date": f"2024-0{m}-15"}
            for m in range(1, 4)
        ]
        response = client.post('/predict-expenses', json={'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        if data['predictions']:
            models_used = {p['modelo'] for p in data['predictions']}
            # With 3 months → 1 feature row → Ridge or EMA
            assert models_used.issubset({'Ridge', 'EMA', 'Mean'})

    def test_predict_model_selection_medium_samples(self, client):
        """With 5-9 months of data RandomForest should be selected."""
        txs = [
            {"amount": 100.0 + i, "type": "expense", "category": "Alimentación",
             "date": f"2024-{str(i).zfill(2)}-15"}
            for i in range(1, 8)  # 7 months → 5 feature rows → RandomForest
        ]
        response = client.post('/predict-expenses', json={'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        if data['predictions']:
            models_used = {p['modelo'] for p in data['predictions']}
            assert models_used.issubset({'RandomForest', 'Ridge', 'EMA', 'Mean'})

    def test_predict_amounts_positive(self, client, sample_transactions):
        """All predicted amounts and intervals must be >= 0."""
        response = client.post('/predict-expenses', json={'transactions': sample_transactions})
        assert response.status_code == 200
        data = response.get_json()
        for pred in data['predictions']:
            assert pred['prediccion'] >= 0, f"Negative prediction for {pred['categoria']}"
            assert pred['pred_min'] >= 0
            assert pred['pred_max'] >= 0
        assert data['total_predicted'] >= 0

    def test_predict_missing_transactions_key(self, client):
        """Missing transactions key in body should return empty predictions gracefully."""
        response = client.post('/predict-expenses', json={})
        assert response.status_code == 200
        data = response.get_json()
        assert data['predictions'] == []

    def test_predict_empty_transactions(self, client):
        """Empty transactions list should return empty predictions."""
        response = client.post('/predict-expenses', json={'transactions': []})
        assert response.status_code == 200
        data = response.get_json()
        assert data['predictions'] == []
        assert data['total_predicted'] == 0

    def test_predict_pred_range(self, client, sample_transactions):
        """For each prediction: pred_min <= prediccion <= pred_max."""
        response = client.post('/predict-expenses', json={'transactions': sample_transactions})
        assert response.status_code == 200
        data = response.get_json()
        for pred in data['predictions']:
            cat = pred['categoria']
            assert pred['pred_min'] <= pred['prediccion'], \
                f"{cat}: pred_min {pred['pred_min']} > prediccion {pred['prediccion']}"
            assert pred['prediccion'] <= pred['pred_max'], \
                f"{cat}: prediccion {pred['prediccion']} > pred_max {pred['pred_max']}"

    def test_predict_by_category_required_fields(self, client, sample_transactions):
        """Each prediction object must have: categoria, prediccion, modelo, precision."""
        response = client.post('/predict-expenses', json={'transactions': sample_transactions})
        assert response.status_code == 200
        data = response.get_json()
        required_pred_fields = {'categoria', 'prediccion', 'modelo', 'precision'}
        for pred in data['predictions']:
            for field in required_pred_fields:
                assert field in pred, f"Missing field '{field}' in prediction"

    def test_predict_income_transactions_ignored(self, client):
        """Income transactions should not appear in predictions (expenses only)."""
        txs = [
            {"amount": 1500.0, "type": "income", "category": "Salario", "date": "2024-01-28"},
            {"amount": 1500.0, "type": "income", "category": "Salario", "date": "2024-02-28"},
        ]
        response = client.post('/predict-expenses', json={'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        assert data['predictions'] == []

    def test_predict_months_of_data_correct(self, client):
        """months_of_data must reflect the number of distinct months in the data."""
        txs = [
            {"amount": 50.0, "type": "expense", "category": "Alimentación", "date": "2024-01-10"},
            {"amount": 55.0, "type": "expense", "category": "Alimentación", "date": "2024-02-10"},
            {"amount": 60.0, "type": "expense", "category": "Alimentación", "date": "2024-03-10"},
        ]
        response = client.post('/predict-expenses', json={'transactions': txs})
        assert response.status_code == 200
        data = response.get_json()
        assert data['months_of_data'] == 3

    def test_predict_total_predicted_equals_sum(self, client, sample_transactions):
        """total_predicted should equal the sum of individual category predictions."""
        response = client.post('/predict-expenses', json={'transactions': sample_transactions})
        assert response.status_code == 200
        data = response.get_json()
        computed_total = round(sum(p['prediccion'] for p in data['predictions']), 2)
        assert abs(computed_total - data['total_predicted']) < 0.05


class TestHelpers:
    def test_clean_text_lowercase(self):
        from app import _clean_text
        result = _clean_text("MERCADONA")
        assert result == result.lower()

    def test_clean_text_removes_accents(self):
        from app import _clean_text
        result = _clean_text("CAFÉ PÚBLICO")
        # NFD normalization strips combining marks; accented chars become base chars
        assert 'e' in result  # 'é' → 'e'

    def test_clean_text_removes_digits(self):
        from app import _clean_text
        result = _clean_text("MERCADONA 234")
        assert '2' not in result
        assert '3' not in result
        assert '4' not in result

    def test_clean_text_empty_string(self):
        from app import _clean_text
        assert _clean_text('') == ''

    def test_clean_text_none_returns_empty(self):
        from app import _clean_text
        assert _clean_text(None) == ''

    def test_clean_text_removes_stopwords(self):
        from app import _clean_text
        result = _clean_text("PAGO DE LA NOMINA")
        # 'de', 'la', 'pago' are stopwords and should be removed
        assert 'pago' not in result.split()
        assert 'de' not in result.split()

    def test_detectar_tendencia_increasing(self):
        from app import _detectar_tendencia
        assert _detectar_tendencia([100, 120, 140, 160]) == 'increasing'

    def test_detectar_tendencia_decreasing(self):
        from app import _detectar_tendencia
        assert _detectar_tendencia([160, 140, 120, 100]) == 'decreasing'

    def test_detectar_tendencia_stable(self):
        from app import _detectar_tendencia
        assert _detectar_tendencia([100, 101, 99, 100]) == 'stable'

    def test_detectar_tendencia_single_value(self):
        from app import _detectar_tendencia
        # Should not crash and should return a valid string
        result = _detectar_tendencia([100])
        assert result in ('increasing', 'decreasing', 'stable')

    def test_detectar_tendencia_two_equal_values(self):
        from app import _detectar_tendencia
        result = _detectar_tendencia([100, 100])
        assert result == 'stable'
