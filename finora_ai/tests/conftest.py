import pytest
import sys
import os

# Add parent dir to path so app can be imported
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import app as flask_app


@pytest.fixture
def app():
    flask_app.config['TESTING'] = True
    yield flask_app


@pytest.fixture
def client(app):
    return app.test_client()


@pytest.fixture
def sample_transactions():
    """Various categories spanning 3 months of data."""
    return [
        {"id": "1", "amount": 45.30, "type": "expense", "category": "Alimentación",
         "description": "MERCADONA 234 VALENCIA", "date": "2024-01-15"},
        {"id": "2", "amount": 30.00, "type": "expense", "category": "Transporte",
         "description": "REPSOL GASOLINERA", "date": "2024-01-16"},
        {"id": "3", "amount": 12.99, "type": "expense", "category": "Ocio",
         "description": "NETFLIX", "date": "2024-01-01"},
        {"id": "4", "amount": 12.99, "type": "expense", "category": "Ocio",
         "description": "NETFLIX", "date": "2024-02-01"},
        {"id": "5", "amount": 12.99, "type": "expense", "category": "Ocio",
         "description": "NETFLIX", "date": "2024-03-01"},
        {"id": "6", "amount": 1500.0, "type": "income", "category": "Salario",
         "description": "NOMINA EMPRESA SL", "date": "2024-01-28"},
        {"id": "7", "amount": 800.0, "type": "expense", "category": "Vivienda",
         "description": "ALQUILER ENERO", "date": "2024-01-05"},
        {"id": "8", "amount": 200.0, "type": "expense", "category": "Alimentación",
         "description": "CARREFOUR SUPERMERCADO", "date": "2024-01-20"},
        {"id": "9", "amount": 500.0, "type": "expense", "category": "Alimentación",
         "description": "LIDL COMPRA", "date": "2024-01-25"},  # anomaly (too high)
    ]


@pytest.fixture
def monthly_income():
    return 1500.0
