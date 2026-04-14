"""Tests for GET /health endpoint."""


def test_health_ok(client):
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'ok'
    assert 'model_loaded' in data
    assert 'vectorizer_loaded' in data


def test_health_returns_model_status(client):
    response = client.get('/health')
    data = response.get_json()
    # model_loaded and vectorizer_loaded must be booleans
    assert isinstance(data['model_loaded'], bool)
    assert isinstance(data['vectorizer_loaded'], bool)


def test_health_returns_service_name(client):
    response = client.get('/health')
    data = response.get_json()
    assert data.get('service') == 'finora-ai'


def test_health_returns_version(client):
    response = client.get('/health')
    data = response.get_json()
    assert 'version' in data
    assert isinstance(data['version'], str)
    assert len(data['version']) > 0
