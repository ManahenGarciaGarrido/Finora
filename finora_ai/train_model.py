"""
Scripts de entrenamiento de modelos de Finora AI.

Entrena y persiste:
1. RF-14: TF-IDF + RandomForest para categorización automática de transacciones
2. RF-22: Valida que scikit-learn puede entrenar Ridge/RF/GBM (los modelos de predicción
          de gastos se entrenan on-demand por usuario en app.py, no se persisten)

Ejecutar manualmente: python train_model.py
Se llama automáticamente desde entrypoint.sh si no existen los modelos.
"""

import os
import re
import string
import unicodedata
import random
import joblib
import logging

import numpy as np

logger = logging.getLogger(__name__)

MODEL_DIR = os.path.join(os.path.dirname(__file__), 'models')
VECTORIZER_PATH = os.path.join(MODEL_DIR, 'tfidf_vectorizer.joblib')
MODEL_PATH = os.path.join(MODEL_DIR, 'model.joblib')

SPANISH_STOPWORDS = {
    "de", "la", "el", "en", "un", "una", "los", "las", "con",
    "del", "al", "es", "por", "para", "como", "sa", "sl", "slu",
    "pago", "compra", "cargo", "abono", "ref", "num", "op",
}


def clean_text(text):
    if not text:
        return ''
    text = text.lower()
    text = unicodedata.normalize('NFD', text)
    text = ''.join(c for c in text if unicodedata.category(c) != 'Mn')
    text = re.sub(r'\d+', ' ', text)
    text = text.translate(str.maketrans('', '', string.punctuation))
    tokens = [w for w in text.split() if w not in SPANISH_STOPWORDS and len(w) > 2]
    return ' '.join(tokens)


def generate_training_data():
    """Genera datos sintéticos de entrenamiento (igual que notebook RF-14)."""
    raw_data = {
        'Alimentación': [
            'MERCADONA MADRID', 'MERCADONA BARCELONA', 'CARREFOUR EXPRESS',
            'LIDL TIENDA 123', 'ALDI SUPERMERCADO', 'DIA SUPERMERCADO',
            'EROSKI CITY', 'HIPERCOR ALIMENTACION', 'CONSUM TIENDA',
            'AHORRAMAS COMPRA', 'SUPERMERCADO EL CORTE', 'FRUTERIA GARCIA',
            'PANADERIA SAN JOSE', 'CARNICERIA RODRIGUEZ', 'COMPRA ONLINE AMAZON FRESH',
            'LEROY MERLIN ALIMENTACION', 'ALCAMPO HIPERMERCADO',
        ],
        'Transporte': [
            'REPSOL GASOLINERA', 'CEPSA COMBUSTIBLE', 'BP GASOLINA',
            'GALP STATION', 'PARKING MADRID CENTRO', 'TAXI CABIFY',
            'UBER SPAIN', 'RENFE CERCANIAS', 'METRO MADRID',
            'EMT BUS MADRID', 'VUELING AIRLINES', 'IBERIA EXPRESS',
            'RYANAIR FLIGHT', 'BLABLACAR VIAJE', 'ALQUILER COCHE',
            'AUTOPISTA PEAJE', 'PARKING PLAZA MAYOR',
        ],
        'Ocio': [
            'NETFLIX SUBSCRIPTION', 'SPOTIFY PREMIUM', 'AMAZON PRIME VIDEO',
            'DISNEY PLUS', 'HBO MAX', 'CINE MARK ENTRADA',
            'TEATRO REAL MADRID', 'RESTAURANTE LA PALOMA', 'BAR CERVECERIA',
            'CAFETERIA STARBUCKS', 'HELADERIA AMORINO', 'PIZZERIA TELEPIZZA',
            'STEAM GAMES', 'PLAYSTATION STORE', 'NINTENDO ESHOP',
            'TICKETMASTER CONCIERTO', 'EVENTBRITE EVENTO',
        ],
        'Salud': [
            'FARMACIA CENTRAL', 'FARMACIA GARCIA LOPEZ', 'PARAFARMACIA',
            'CLINICA DENTAL', 'DENTISTA DR PEREZ', 'FISIOTERAPIA',
            'HOSPITAL UNIVERSITARIO', 'SANITAS SEGUROS', 'ADESLAS PRIMA',
            'ASISA MENSUALIDAD', 'ANALISIS LABORATORIO', 'CONSULTA MEDICA',
            'OPTICA 2000', 'CENTRO SALUD', 'PSICOLOGIA CONSULTA',
        ],
        'Vivienda': [
            'ALQUILER PISO ENERO', 'HIPOTECA BANCO SANTANDER',
            'COMUNIDAD PROPIETARIOS', 'IBERDROLA FACTURA LUZ',
            'ENDESA ELECTRICIDAD', 'NATURGY GAS NATURAL',
            'CANAL ISABEL II AGUA', 'AYUNTAMIENTO IBI',
            'SEGURO HOGAR MAPFRE', 'REPARACION FONTANERIA',
            'MUEBLES IKEA', 'LEROY MERLIN BRICOLAGE',
        ],
        'Servicios': [
            'MOVISTAR FACTURA', 'VODAFONE MENSUAL', 'ORANGE FIBRA',
            'MASMOVIL MOVIL', 'JAZZTEL INTERNET', 'PEPEPHONE',
            'SEGURO AUTO MAPFRE', 'AXA SEGUROS', 'ZURICH VIDA',
            'AMAZON WEB SERVICES', 'GOOGLE WORKSPACE', 'DROPBOX',
            'MICROSOFT 365', 'ADOBE CREATIVE', 'SUSCRIPCION PERIODICO',
        ],
        'Educación': [
            'UNIVERSIDAD COMPLUTENSE MATRICULA', 'COLEGIO SAN IGNACIO',
            'ACADEMIA IDIOMAS', 'CURSO UDEMY', 'COURSERA SUBSCRIPTION',
            'FNAC LIBROS', 'CASA DEL LIBRO', 'AMAZON BOOKS',
            'UNED MATRICULA', 'MASTER UNIVERSITARIO', 'FORMACION EMPRESA',
            'GYM WELLNESS', 'CLASES PARTICULARES',
        ],
        'Ropa': [
            'ZARA ROPA', 'H&M TIENDA', 'MANGO FASHION',
            'PRIMARK SHOPPING', 'PULL AND BEAR', 'BERSHKA',
            'STRADIVARIUS', 'MASSIMO DUTTI', 'NIKE STORE',
            'ADIDAS OUTLET', 'PUMA TIENDA', 'CALZADOS PILAR',
            'EL CORTE INGLES MODA', 'ZAPATOS ONLINE',
        ],
        'Salario': [
            'NOMINA EMPRESA SA', 'SALARIO MENSUAL', 'PAGO NOMINA',
            'REMUNERACION MENSUAL', 'EMPRESA SL NOMINA', 'PAYROLL',
            'MENSUALIDAD CONTRATO', 'INGRESO EMPRESA',
        ],
        'Freelance': [
            'FACTURA CLIENTE', 'HONORARIOS PROFESIONALES', 'FREELANCE PROYECTO',
            'COMISION VENTA', 'LIQUIDACION SERVICIOS', 'TRANSFER CLIENTE',
            'PRESTACION SERVICIOS', 'CONSULTING FEE',
        ],
    }

    descriptions, labels = [], []
    for category, examples in raw_data.items():
        for example in examples:
            descriptions.append(example)
            labels.append(category)
            for _ in range(3):
                suffix = random.choice([
                    '',
                    f' {random.randint(1, 999):03d}',
                    f' REF{random.randint(100, 999)}',
                    f' {random.choice(["MADRID","BARCELONA","VALENCIA","SEVILLA"])}',
                ])
                descriptions.append(example + suffix)
                labels.append(category)

    return descriptions, labels


def train_categorization_model():
    """
    RF-14: Entrena TF-IDF + RandomForest para categorización.
    Guarda model.joblib y tfidf_vectorizer.joblib en /app/models/.
    """
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.model_selection import train_test_split

    os.makedirs(MODEL_DIR, exist_ok=True)

    logger.info("RF-14: Generando datos de entrenamiento para categorización...")
    descriptions, labels = generate_training_data()
    clean_descs = [clean_text(d) for d in descriptions]
    logger.info(f"  {len(descriptions)} ejemplos de entrenamiento")

    X_train, X_test, y_train, y_test = train_test_split(
        clean_descs, labels, test_size=0.2, random_state=42, stratify=labels
    )

    vectorizer = TfidfVectorizer(
        max_features=5000,
        ngram_range=(1, 2),
        analyzer='word',
        sublinear_tf=True,
    )

    classifier = RandomForestClassifier(
        n_estimators=200,
        max_depth=None,
        min_samples_split=2,
        random_state=42,
        n_jobs=-1,
    )

    logger.info("RF-14: Entrenando TF-IDF + RandomForest...")
    X_train_vec = vectorizer.fit_transform(X_train)
    classifier.fit(X_train_vec, y_train)

    X_test_vec = vectorizer.transform(X_test)
    accuracy = classifier.score(X_test_vec, y_test)
    logger.info(f"  Precisión en test: {accuracy:.1%}")

    joblib.dump(vectorizer, VECTORIZER_PATH)
    joblib.dump(classifier, MODEL_PATH)
    logger.info(f"  Vectorizador → {VECTORIZER_PATH}")
    logger.info(f"  Modelo       → {MODEL_PATH}")

    return accuracy


def validate_expense_prediction_models():
    """
    RF-22: Valida que Ridge/RandomForest/GradientBoosting están disponibles.
    Los modelos de predicción de gastos se entrenan on-demand en app.py
    (son específicos de cada usuario, no se persisten).
    """
    from sklearn.linear_model import Ridge
    from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
    from sklearn.metrics import mean_absolute_error

    logger.info("RF-22: Validando modelos de predicción de gastos...")

    # Serie sintética de prueba
    serie_test = [450.0, 520.0, 480.0, 510.0, 490.0, 530.0, 505.0]
    meses_test = [
        '2024-01', '2024-02', '2024-03', '2024-04',
        '2024-05', '2024-06', '2024-07',
    ]

    for ModelClass, nombre in [
        (Ridge(alpha=1.0), 'Ridge'),
        (RandomForestRegressor(n_estimators=50, max_depth=3, random_state=42), 'RandomForest'),
        (GradientBoostingRegressor(n_estimators=50, max_depth=2, random_state=42), 'GradientBoosting'),
    ]:
        # Construir features de prueba
        ventana = 2
        X, y = [], []
        for i in range(ventana, len(serie_test)):
            lags = serie_test[i - ventana: i]
            fila = list(lags) + [np.mean(lags), lags[-1] - lags[0], i,
                                  int(meses_test[i].split('-')[1])]
            X.append(fila)
            y.append(serie_test[i])
        X_arr, y_arr = np.array(X), np.array(y)

        ModelClass.fit(X_arr[:-1], y_arr[:-1])
        pred = ModelClass.predict(X_arr[-1:])
        mae = mean_absolute_error([y_arr[-1]], pred)
        logger.info(f"  {nombre}: pred={pred[0]:.2f}€ | MAE={mae:.2f}€ ✓")

    logger.info("RF-22: Todos los modelos de predicción disponibles ✓")


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='%(message)s')

    print("=" * 60)
    print("Finora AI — Entrenamiento de modelos")
    print("=" * 60)

    accuracy = train_categorization_model()
    print(f"\nRF-14 Categorización: precisión {accuracy:.1%}")
    print(f"  → {VECTORIZER_PATH}")
    print(f"  → {MODEL_PATH}")

    print()
    validate_expense_prediction_models()
    print("\nRF-22 Predicción de gastos: modelos validados (on-demand)")

    print("\nEntrenamiento completado con éxito.")