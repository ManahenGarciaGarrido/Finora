"""
RF-14: Script para entrenar y guardar el modelo de categorización.

Este script:
1. Genera datos sintéticos de entrenamiento (o carga datos reales si existen)
2. Entrena un modelo TF-IDF + RandomForest
3. Guarda el vectorizador y el modelo en /app/models/

Ejecutar: python train_model.py
También se ejecuta automáticamente la primera vez que arranca el contenedor
si los modelos no existen (ver app.py).
"""

import os
import re
import string
import unicodedata
import random
import joblib
import logging

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

    # Generar variaciones
    descriptions, labels = [], []
    for category, examples in raw_data.items():
        for example in examples:
            # Variación original
            descriptions.append(example)
            labels.append(category)
            # Variantes con sufijos
            for _ in range(3):
                suffix = random.choice(['', f' {random.randint(1, 999):03d}',
                                        f' REF{random.randint(100, 999)}',
                                        f' {random.choice(["MADRID","BARCELONA","VALENCIA","SEVILLA"])}'])
                descriptions.append(example + suffix)
                labels.append(category)

    return descriptions, labels


def train_and_save():
    """Entrena el modelo y lo guarda en disco."""
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.pipeline import Pipeline
    from sklearn.model_selection import train_test_split

    os.makedirs(MODEL_DIR, exist_ok=True)

    logger.info("Generando datos de entrenamiento...")
    descriptions, labels = generate_training_data()
    clean_descs = [clean_text(d) for d in descriptions]

    logger.info(f"  {len(descriptions)} ejemplos de entrenamiento generados")

    X_train, X_test, y_train, y_test = train_test_split(
        clean_descs, labels, test_size=0.2, random_state=42, stratify=labels
    )

    # Vectorizador TF-IDF
    vectorizer = TfidfVectorizer(
        max_features=5000,
        ngram_range=(1, 2),
        analyzer='word',
        sublinear_tf=True,
    )

    # Clasificador Random Forest
    classifier = RandomForestClassifier(
        n_estimators=200,
        max_depth=None,
        min_samples_split=2,
        random_state=42,
        n_jobs=-1,
    )

    # Entrenar
    logger.info("Entrenando modelo TF-IDF + RandomForest...")
    X_train_vec = vectorizer.fit_transform(X_train)
    classifier.fit(X_train_vec, y_train)

    # Evaluar
    X_test_vec = vectorizer.transform(X_test)
    accuracy = classifier.score(X_test_vec, y_test)
    logger.info(f"  Precisión en test: {accuracy:.1%}")

    # Guardar
    joblib.dump(vectorizer, VECTORIZER_PATH)
    joblib.dump(classifier, MODEL_PATH)
    logger.info(f"  Vectorizador guardado en {VECTORIZER_PATH}")
    logger.info(f"  Modelo guardado en {MODEL_PATH}")

    return accuracy


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='%(message)s')
    accuracy = train_and_save()
    print(f"\nModelo entrenado con éxito — precisión: {accuracy:.1%}")
    print("Archivos generados:")
    print(f"  - {VECTORIZER_PATH}")
    print(f"  - {MODEL_PATH}")