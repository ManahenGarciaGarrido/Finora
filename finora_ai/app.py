"""
Finora AI Service — RF-14, RF-21, RF-22, RF-25, RF-26, RF-27

Microservicio Flask que expone los modelos de IA de los notebooks de Finora:
- POST /categorize                   → RF-14: Categorización automática de transacciones
- POST /categorize/batch             → RF-14: Categorización en lote
- POST /savings                      → RF-21/HU-08: Recomendaciones de ahorro inteligente
- POST /predict-expenses             → RF-22/HU-09: Predicción ML de gastos (Ridge/RF/GBM)
- POST /evaluate-savings-goal        → RF-21: Evaluación de viabilidad de objetivo de ahorro
- POST /detect-anomalies             → RF-23/HU-10: Detección de gastos anómalos (Z-score)
- POST /detect-subscriptions         → RF-24/HU-11: Identificación de suscripciones periódicas
- POST /chat                         → RF-25/HU-12/CU-04: Asistente conversacional IA financiero
- POST /affordability                → RF-26/HU-13: Análisis "¿Puedo permitírmelo?"
- POST /recommendations              → RF-27/HU-14: Recomendaciones de optimización financiera
- POST /generate-sample-transactions → RF-01: Generador IA de transacciones realistas
- GET  /health                       → Health check para Docker

Los algoritmos de predicción de gastos están basados en los notebooks:
  - Notebooks/rf22_prediccion_gastos_ml.ipynb (seleccionar_modelo, construir_features)
  - Notebooks/rf21_hu08_ahorro_inteligente.ipynb (evaluar_objetivo, calcular_capacidad_ahorro)
"""

import os
import re
import json
import math
import random
import string
import calendar
import unicodedata
import logging
from collections import defaultdict
from datetime import datetime, timedelta
from flask import Flask, request, jsonify
from flask_cors import CORS

import numpy as np

# ─── Logging ────────────────────────────────────────────────────────────────
logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app, origins=["*"])


# ─── Constantes RF-14 ────────────────────────────────────────────────────────
CONFIDENCE_THRESHOLD = 50  # % mínimo para no usar fallback
FALLBACK_EXPENSE = 'Otros'
FALLBACK_INCOME  = 'Otros ingresos'

SPANISH_STOPWORDS = {
    "de", "la", "el", "en", "un", "una", "los", "las", "con",
    "del", "al", "es", "por", "para", "como", "sa", "sl", "slu",
    "pago", "compra", "cargo", "abono", "ref", "num", "op",
    "es", "sociedad", "anonima", "limitada",
}

# ─── Constantes RF-22 ────────────────────────────────────────────────────────
VENTANA = 2           # ventana de lags para predicción temporal
PRECISION_MINIMA = 0.60  # precisión mínima para que el modelo sea fiable

# ─── Constantes RF-21 ────────────────────────────────────────────────────────
# Regla 50/30/20: necesidades/deseos/ahorro — porcentajes de referencia
REFERENCE_BUDGETS = {
    'Alimentación': 0.15,
    'Vivienda':     0.30,
    'Transporte':   0.10,
    'Salud':        0.08,
    'Educación':    0.05,
    'Ropa':         0.05,
    'Ocio':         0.10,
    'Servicios':    0.08,
}


# ─── Carga del modelo de categorización (RF-14) ─────────────────────────────

_model = None
_vectorizer = None
_model_loaded = False

MODEL_PATH = os.path.join(os.path.dirname(__file__), 'models', 'model.joblib')
VECTORIZER_PATH = os.path.join(os.path.dirname(__file__), 'models', 'tfidf_vectorizer.joblib')


def _load_models():
    """Carga los modelos ML entrenados. Si no existen, usa el motor de reglas."""
    global _model, _vectorizer, _model_loaded
    try:
        import joblib
        if os.path.exists(VECTORIZER_PATH):
            _vectorizer = joblib.load(VECTORIZER_PATH)
            logger.info(f"TF-IDF vectorizer cargado desde {VECTORIZER_PATH}")
        if os.path.exists(MODEL_PATH):
            _model = joblib.load(MODEL_PATH)
            logger.info(f"Modelo ML cargado desde {MODEL_PATH}")
        _model_loaded = True
    except Exception as e:
        logger.warning(f"No se pudo cargar el modelo ML: {e}. Usando motor de reglas.")
        _model_loaded = False


def _clean_text(text: str) -> str:
    """Normaliza descriptores bancarios para NLP (igual que en el notebook RF-14)."""
    if not text:
        return ''
    text = text.lower()
    text = unicodedata.normalize('NFD', text)
    text = ''.join(c for c in text if unicodedata.category(c) != 'Mn')
    text = re.sub(r'\d+', ' ', text)
    text = text.translate(str.maketrans('', '', string.punctuation))
    tokens = [w for w in text.split() if w not in SPANISH_STOPWORDS and len(w) > 2]
    return ' '.join(tokens)


# ─── Motor de reglas RF-14 (fallback sin modelo ML) ─────────────────────────
RULES = [
    ('income', 'Salario',     ['nomina', 'salario', 'sueldo', 'payroll', 'salary'], 1.0),
    ('income', 'Freelance',   ['factura', 'honorarios', 'freelance', 'comision'],   0.9),
    ('expense','Alimentación',['supermercado','mercadona','carrefour','lidl','aldi','eroski','hipercor','consum'], 1.0),
    ('expense','Transporte',  ['gasolina','gasolinera','repsol','cepsa','taxi','uber','cabify','renfe','metro','bus','tren'], 0.95),
    ('expense','Ocio',        ['netflix','spotify','amazon','disney','cine','teatro','restaurante','bar','cafeteria'], 0.9),
    ('expense','Salud',       ['farmacia','medico','hospital','clinica','dentista','fisioterapia','sanitas'], 0.95),
    ('expense','Vivienda',    ['alquiler','hipoteca','comunidad','iberdrola','endesa','naturgy','gas','agua','luz'], 0.95),
    ('expense','Servicios',   ['vodafone','movistar','orange','seguro','mutua','mapfre','axa','internet','fibra'], 0.85),
    ('expense','Educación',   ['universidad','colegio','academia','curso','formacion','libro','udemy','coursera'], 0.9),
    ('expense','Ropa',        ['zara','mango','primark','bershka','stradivarius','nike','adidas','ropa','calzado'], 0.9),
]


def _rule_based_category(desc_clean: str, tx_type: str):
    best_cat = None
    best_conf = 0.0
    for rule_type, cat, keywords, weight in RULES:
        if rule_type != tx_type:
            continue
        for kw in keywords:
            if kw in desc_clean:
                conf = weight * 85
                if len(kw) >= 5:
                    conf = weight * 90
                if desc_clean.startswith(kw):
                    conf = weight * 95
                if conf > best_conf:
                    best_conf = conf
                    best_cat = cat
    return best_cat, round(min(best_conf, 100))


def _ml_category(desc_clean: str, tx_type: str):
    if not _model or not _vectorizer:
        return None, 0
    try:
        X = _vectorizer.transform([desc_clean])
        y_pred = _model.predict(X)[0]
        if hasattr(_model, 'predict_proba'):
            proba = _model.predict_proba(X)[0]
            confidence = round(float(max(proba)) * 100)
        elif hasattr(_model, 'decision_function'):
            scores = _model.decision_function(X)[0]
            e_scores = np.exp(scores - np.max(scores))
            proba = e_scores / e_scores.sum()
            confidence = round(float(max(proba)) * 100)
        else:
            confidence = 75
        return y_pred, confidence
    except Exception as e:
        logger.warning(f"Error en ML inference: {e}")
        return None, 0


# ─── Algoritmos RF-22: Predicción de gastos (basados en notebooks) ───────────

def _seleccionar_modelo(n_muestras: int):
    """
    Elige el modelo de regresión según la cantidad de datos disponibles.
    Criterio del notebook rf22_prediccion_gastos_ml.ipynb:
      ≤4 muestras → Ridge  (regularización, evita overfitting con pocos datos)
      ≤8 muestras → RandomForest
      >8 muestras → GradientBoosting
    """
    from sklearn.linear_model import Ridge
    from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor

    if n_muestras <= 4:
        return Ridge(alpha=1.0), "Ridge"
    elif n_muestras <= 8:
        return RandomForestRegressor(n_estimators=50, max_depth=3, random_state=42), "RandomForest"
    else:
        return GradientBoostingRegressor(n_estimators=100, max_depth=2, random_state=42), "GradientBoosting"


def _construir_features(serie: list, meses_list: list, ventana: int = VENTANA):
    """
    Construye matriz de features para regresión temporal.
    Features: lags, media móvil, tendencia, índice ordinal, mes calendario.
    Basado en rf22_prediccion_gastos_ml.ipynb :: construir_features().
    """
    X, y = [], []
    for i in range(ventana, len(serie)):
        lags      = serie[i - ventana: i]
        media_mov = float(np.mean(lags))
        tendencia = float(lags[-1] - lags[0]) if ventana > 1 else 0.0
        idx_mes   = i
        mes_cal   = int(meses_list[i].split("-")[1]) if i < len(meses_list) else ((i % 12) + 1)

        fila = list(lags) + [media_mov, tendencia, idx_mes, mes_cal]
        X.append(fila)
        y.append(serie[i])
    return np.array(X, dtype=float), np.array(y, dtype=float)


def _detectar_tendencia(serie: list) -> str:
    """
    Detecta tendencia de la serie usando regresión lineal (numpy.polyfit).
    Devuelve 'increasing', 'decreasing' o 'stable'.
    Basado en rf22_prediccion_gastos_ml.ipynb :: detectar_tendencia_detallada().
    """
    if len(serie) < 2:
        return 'stable'
    x = np.arange(len(serie), dtype=float)
    try:
        coeffs = np.polyfit(x, serie, 1)
        pendiente = coeffs[0]
        media = float(np.mean(serie))
        pct_mes = (pendiente / media * 100) if media > 0 else 0.0
        if pct_mes > 5:
            return 'increasing'
        elif pct_mes < -5:
            return 'decreasing'
        else:
            return 'stable'
    except Exception:
        return 'stable'


def _predict_category_ml(serie: list, meses_list: list, cat_name: str) -> dict:
    """
    Entrena el modelo seleccionado y predice el siguiente mes para una categoría.
    Incluye intervalo de confianza basado en MAE histórico (leave-one-out adaptado).
    Basado en rf22_prediccion_gastos_ml.ipynb :: entrenar_y_evaluar().
    """
    from sklearn.metrics import mean_absolute_error

    X, y = _construir_features(serie, meses_list)
    if len(X) == 0:
        # Con 1-2 meses: EMA simple
        if len(serie) == 1:
            pred = serie[0]
        else:
            pred = serie[-1] * 0.6 + serie[-2] * 0.4
        return {
            'categoria': cat_name,
            'prediccion': round(pred, 2),
            'pred_min': round(max(0, pred * 0.8), 2),
            'pred_max': round(pred * 1.2, 2),
            'modelo': 'EMA',
            'precision': 0.5,
            'tendencia': _detectar_tendencia(serie),
        }

    modelo, nombre_modelo = _seleccionar_modelo(len(X))

    # Evaluación leave-one-out adaptada (máx 3 splits)
    maes = []
    for i in range(1, min(len(X), 4)):
        X_tr, X_te = X[:-i], X[-i:]
        y_tr, y_te = y[:-i], y[-i:]
        if len(X_tr) == 0:
            continue
        try:
            modelo.fit(X_tr, y_tr)
            pred_val = modelo.predict(X_te)
            maes.append(mean_absolute_error(y_te, pred_val))
        except Exception:
            continue

    # Entrenar con todos los datos
    try:
        modelo.fit(X, y)
    except Exception as e:
        logger.warning(f"Error entrenando modelo para {cat_name}: {e}")
        pred = float(np.mean(serie[-3:]))
        return {
            'categoria': cat_name,
            'prediccion': round(pred, 2),
            'pred_min': round(max(0, pred * 0.8), 2),
            'pred_max': round(pred * 1.2, 2),
            'modelo': 'Mean',
            'precision': 0.4,
            'tendencia': _detectar_tendencia(serie),
        }

    # Features del próximo mes
    lags_next  = serie[-VENTANA:]
    media_next = float(np.mean(lags_next))
    tend_next  = float(lags_next[-1] - lags_next[0]) if VENTANA > 1 else 0.0
    idx_next   = len(serie)
    ultimo_mes = int(meses_list[-1].split("-")[1]) if meses_list else 1
    mes_next   = (ultimo_mes % 12) + 1

    X_next = np.array([list(lags_next) + [media_next, tend_next, idx_next, mes_next]])

    try:
        pred_central = float(modelo.predict(X_next)[0])
        pred_central = max(0.0, pred_central)
    except Exception:
        pred_central = float(np.mean(serie[-3:]))

    # Intervalo de confianza basado en MAE histórico
    mae_medio = float(np.mean(maes)) if maes else abs(pred_central * 0.15)
    pred_min  = max(0.0, round(pred_central - mae_medio * 1.5, 2))
    pred_max  = round(pred_central + mae_medio * 1.5, 2)

    # Precisión del modelo
    media_y = float(np.mean(y)) if len(y) > 0 else 1.0
    precision = 1 - (mae_medio / (media_y + 1e-6))
    precision = float(np.clip(precision, 0, 1))

    return {
        'categoria':   cat_name,
        'prediccion':  round(pred_central, 2),
        'pred_min':    pred_min,
        'pred_max':    pred_max,
        'modelo':      nombre_modelo,
        'precision':   round(precision, 3),
        'mae':         round(mae_medio, 2),
        'tendencia':   _detectar_tendencia(serie),
        'cumple_umbral': precision >= PRECISION_MINIMA,
    }


# ─── Algoritmos RF-21: Ahorro inteligente (basados en notebooks) ─────────────

def _calcular_capacidad_ahorro(ingreso_promedio: float, gasto_promedio: float,
                                compromisos_previos: float = 0) -> dict:
    """
    Calcula la capacidad de ahorro disponible tras compromisos existentes.
    Basado en rf21_hu08_ahorro_inteligente.ipynb :: calcular_capacidad_ahorro().
    """
    ahorro_bruto = ingreso_promedio - gasto_promedio
    disponible   = ahorro_bruto - compromisos_previos
    return {
        'ahorro_bruto':  round(ahorro_bruto, 2),
        'comprometido':  round(compromisos_previos, 2),
        'disponible':    round(disponible, 2),
    }


def _evaluar_objetivo(monto_total: float, plazo_meses: int,
                       capacidad: dict) -> dict:
    """
    Evalúa si un objetivo de ahorro es realista y genera alternativas.
    Basado en rf21_hu08_ahorro_inteligente.ipynb :: evaluar_objetivo().
    """
    disponible = capacidad['disponible']
    ahorro_necesario = round(monto_total / plazo_meses, 2) if plazo_meses > 0 else float('inf')
    es_realista = ahorro_necesario <= disponible
    porcentaje_uso = round((ahorro_necesario / disponible * 100), 1) if disponible > 0 else float('inf')

    if disponible <= 0:
        ahorro_recomendado = 0.0
        alerta = 'No tienes capacidad de ahorro disponible con tus patrones actuales.'
    elif es_realista:
        ahorro_recomendado = ahorro_necesario
        alerta = None
    else:
        ahorro_recomendado = round(disponible * 0.80, 2)
        alerta = (
            f'Para alcanzar {monto_total:.0f}€ en {plazo_meses} meses necesitas '
            f'{ahorro_necesario:.0f}€/mes, pero solo tienes {disponible:.0f}€ libres.'
        )

    alternativas = []
    if not es_realista and disponible > 0:
        plazo_alt = round(monto_total / ahorro_recomendado) if ahorro_recomendado > 0 else None
        if plazo_alt:
            alternativas.append({
                'tipo': 'plazo_mayor',
                'descripcion': f'Ahorrar {ahorro_recomendado:.0f}€/mes → objetivo en ~{plazo_alt} meses',
                'ahorro_mensual': ahorro_recomendado,
                'plazo_meses': plazo_alt,
            })
        monto_reducido = round(ahorro_necesario * 0.6, 2)
        plazo_reducido = round(monto_total / monto_reducido) if monto_reducido > 0 else None
        if plazo_reducido:
            alternativas.append({
                'tipo': 'monto_menor',
                'descripcion': f'Reducir a {monto_reducido:.0f}€/mes → objetivo en ~{plazo_reducido} meses',
                'ahorro_mensual': monto_reducido,
                'plazo_meses': plazo_reducido,
            })

    return {
        'ahorro_necesario':   ahorro_necesario,
        'ahorro_recomendado': ahorro_recomendado,
        'es_realista':        es_realista,
        'porcentaje_disponible_usado': porcentaje_uso,
        'alerta': alerta,
        'alternativas': alternativas,
    }


# ─── Endpoints ───────────────────────────────────────────────────────────────

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'ok',
        'service': 'finora-ai',
        'model_loaded': _model is not None,
        'vectorizer_loaded': _vectorizer is not None,
        'version': '2.0.0',
    })


@app.route('/categorize', methods=['POST'])
def categorize():
    """
    RF-14: Categoriza una transacción y devuelve categoría + nivel de confianza.

    Body: { "description": str, "type": "income"|"expense" }
    Returns: { "category": str, "confidence": int, "is_fallback": bool, "method": str }
    """
    data = request.get_json(silent=True) or {}
    description = data.get('description', '').strip()
    tx_type = data.get('type', 'expense')

    if not description:
        return jsonify({'error': 'description is required'}), 400
    if tx_type not in ('income', 'expense'):
        return jsonify({'error': 'type must be income or expense'}), 400

    desc_clean = _clean_text(description)

    category, confidence = _ml_category(desc_clean, tx_type)
    method = 'ml'

    if category is None or confidence < CONFIDENCE_THRESHOLD:
        rule_cat, rule_conf = _rule_based_category(desc_clean, tx_type)
        if rule_cat and rule_conf >= CONFIDENCE_THRESHOLD:
            category = rule_cat
            confidence = rule_conf
            method = 'rules'

    is_fallback = category is None or confidence < CONFIDENCE_THRESHOLD
    if is_fallback:
        category = FALLBACK_EXPENSE if tx_type == 'expense' else FALLBACK_INCOME
        method = 'fallback'

    logger.info(f"[categorize] desc='{description[:40]}' → {category} ({confidence}%, {method})")

    return jsonify({
        'category': category,
        'confidence': confidence,
        'is_fallback': is_fallback,
        'method': method,
        'clean_text': desc_clean,
    })


@app.route('/categorize/batch', methods=['POST'])
def categorize_batch():
    """
    RF-14: Categoriza múltiples transacciones en una sola llamada.

    Body: { "transactions": [{ "description": str, "type": str }, ...] }
    Returns: { "results": [{ "category": str, "confidence": int, ... }, ...] }
    """
    data = request.get_json(silent=True) or {}
    transactions = data.get('transactions', [])

    if not transactions:
        return jsonify({'error': 'transactions list is required'}), 400
    if len(transactions) > 500:
        return jsonify({'error': 'Maximum 500 transactions per batch'}), 400

    results = []
    for tx in transactions:
        description = tx.get('description', '').strip()
        tx_type = tx.get('type', 'expense')

        if not description:
            results.append({
                'category': FALLBACK_EXPENSE if tx_type == 'expense' else FALLBACK_INCOME,
                'confidence': 0,
                'is_fallback': True,
                'method': 'fallback',
            })
            continue

        desc_clean = _clean_text(description)
        category, confidence = _ml_category(desc_clean, tx_type)
        method = 'ml'

        if category is None or confidence < CONFIDENCE_THRESHOLD:
            rule_cat, rule_conf = _rule_based_category(desc_clean, tx_type)
            if rule_cat and rule_conf >= CONFIDENCE_THRESHOLD:
                category = rule_cat
                confidence = rule_conf
                method = 'rules'

        is_fallback = category is None or confidence < CONFIDENCE_THRESHOLD
        if is_fallback:
            category = FALLBACK_EXPENSE if tx_type == 'expense' else FALLBACK_INCOME
            method = 'fallback'

        results.append({
            'category': category,
            'confidence': confidence,
            'is_fallback': is_fallback,
            'method': method,
        })

    return jsonify({'results': results})


@app.route('/savings', methods=['POST'])
def savings_recommendations():
    """
    RF-21 / HU-08: Recomendaciones de ahorro inteligente.

    Body: {
        "transactions": [{ "amount": float, "type": str, "category": str, "date": str }],
        "monthly_income": float
    }
    Returns: {
        "recommendations": [...],
        "savings_potential": float,
        "score": int,
        "savings_capacity": { ahorro_bruto, disponible },
        "monthly_summary": { ingresos, gastos, meses_analizados }
    }
    """
    data = request.get_json(silent=True) or {}
    transactions = data.get('transactions', [])
    monthly_income = float(data.get('monthly_income', 0))

    if not transactions:
        return jsonify({'recommendations': [], 'savings_potential': 0, 'score': 50})

    # ── Agrupar por mes (algoritmo del notebook rf21) ─────────────────────────
    meses: dict = defaultdict(lambda: {
        'ingresos': 0.0,
        'gastos': 0.0,
        'por_categoria': defaultdict(float),
    })
    for tx in transactions:
        clave = tx.get('date', '')[:7]
        if not clave or len(clave) < 7:
            continue
        if tx.get('type') == 'income':
            meses[clave]['ingresos'] += float(tx.get('amount', 0))
        elif tx.get('type') == 'expense':
            cat = tx.get('category', 'Otros')
            amount = float(tx.get('amount', 0))
            meses[clave]['gastos'] += amount
            meses[clave]['por_categoria'][cat] += amount

    # ── Promedios mensuales ───────────────────────────────────────────────────
    n_meses = len(meses)
    if n_meses == 0:
        return jsonify({'recommendations': [], 'savings_potential': 0, 'score': 50})

    ingreso_promedio = (
        sum(v['ingresos'] for v in meses.values()) / n_meses
        if n_meses > 0 else monthly_income
    )
    # Priorizar el parámetro explícito si se provee y es mayor
    if monthly_income > 0 and monthly_income > ingreso_promedio:
        ingreso_promedio = monthly_income

    gasto_promedio = sum(v['gastos'] for v in meses.values()) / n_meses

    # Totales por categoría (promedio mensual)
    cat_totals_all: dict = defaultdict(list)
    for v in meses.values():
        for cat, monto in v['por_categoria'].items():
            cat_totals_all[cat].append(monto)
    categoria_promedio = {
        cat: sum(montos) / len(montos)
        for cat, montos in cat_totals_all.items()
    }

    # ── Capacidad de ahorro (rf21 :: calcular_capacidad_ahorro) ──────────────
    capacidad = _calcular_capacidad_ahorro(ingreso_promedio, gasto_promedio)

    # ── Recomendaciones por categoría excedida ────────────────────────────────
    recommendations = []
    savings_potential = 0.0

    if ingreso_promedio > 0:
        for cat, promedio in sorted(categoria_promedio.items(), key=lambda x: -x[1]):
            ref_pct = REFERENCE_BUDGETS.get(cat, 0.10)
            budget = ingreso_promedio * ref_pct
            if promedio > budget * 1.20:   # margen del 20%
                excess = promedio - budget
                savings_potential += excess
                pct_over = round((promedio / budget - 1) * 100)
                recommendations.append({
                    'category':         cat,
                    'current_spend':    round(promedio, 2),
                    'suggested_budget': round(budget, 2),
                    'potential_saving': round(excess, 2),
                    'message': (
                        f'Estás gastando un {pct_over}% más de lo recomendado en {cat}. '
                        f'Podrías ahorrar hasta {excess:.2f}€ mensuales.'
                    ),
                    'priority': 'high' if excess > ingreso_promedio * 0.05 else 'medium',
                })

    # ── Score de salud financiera (0-100) ────────────────────────────────────
    if ingreso_promedio > 0:
        savings_rate = max(0, (ingreso_promedio - gasto_promedio) / ingreso_promedio)
        # Score: tasa de ahorro del 20% → 100 puntos
        score = min(100, round(savings_rate * 500))
    else:
        score = 50

    logger.info(
        f"[savings] {n_meses} meses | ingreso_prom={ingreso_promedio:.0f}€ "
        f"| gasto_prom={gasto_promedio:.0f}€ | score={score}"
    )

    return jsonify({
        'recommendations':  recommendations[:5],
        'savings_potential': round(savings_potential, 2),
        'score':            score,
        'savings_capacity': capacidad,
        'monthly_summary': {
            'ingreso_promedio':   round(ingreso_promedio, 2),
            'gasto_promedio':     round(gasto_promedio, 2),
            'meses_analizados':   n_meses,
            'categoria_promedio': {k: round(v, 2) for k, v in categoria_promedio.items()},
        },
    })


@app.route('/evaluate-savings-goal', methods=['POST'])
def evaluate_savings_goal():
    """
    RF-21 / HU-08: Evalúa la viabilidad de un objetivo de ahorro concreto.

    Body: {
        "transactions": [...],
        "monthly_income": float,
        "goal": { "monto_total": float, "plazo_meses": int }
    }
    Returns: {
        "es_realista": bool,
        "ahorro_recomendado": float,
        "ahorro_necesario": float,
        "alerta": str|null,
        "alternativas": [...],
        "capacidad": { ahorro_bruto, disponible }
    }
    """
    data = request.get_json(silent=True) or {}
    transactions = data.get('transactions', [])
    monthly_income = float(data.get('monthly_income', 0))
    goal = data.get('goal', {})

    monto_total  = float(goal.get('monto_total', 0))
    plazo_meses  = int(goal.get('plazo_meses', 12))

    if monto_total <= 0:
        return jsonify({'error': 'goal.monto_total must be positive'}), 400

    # Calcular promedios de las transacciones
    meses: dict = defaultdict(lambda: {'ingresos': 0.0, 'gastos': 0.0})
    for tx in transactions:
        clave = tx.get('date', '')[:7]
        if not clave or len(clave) < 7:
            continue
        if tx.get('type') == 'income':
            meses[clave]['ingresos'] += float(tx.get('amount', 0))
        elif tx.get('type') == 'expense':
            meses[clave]['gastos'] += float(tx.get('amount', 0))

    n_meses = len(meses)
    if n_meses == 0:
        ingreso_promedio = monthly_income
        gasto_promedio = monthly_income * 0.8
    else:
        ingreso_promedio = max(
            monthly_income,
            sum(v['ingresos'] for v in meses.values()) / n_meses
        )
        gasto_promedio = sum(v['gastos'] for v in meses.values()) / n_meses

    capacidad = _calcular_capacidad_ahorro(ingreso_promedio, gasto_promedio)
    evaluacion = _evaluar_objetivo(monto_total, plazo_meses, capacidad)

    return jsonify({**evaluacion, 'capacidad': capacidad})


@app.route('/predict-expenses', methods=['POST'])
def predict_expenses():
    """
    RF-22 / HU-09: Predicción ML de gastos para el próximo mes.

    Algoritmo basado en el notebook rf22_prediccion_gastos_ml.ipynb:
    - seleccionar_modelo(): Ridge (≤4 meses), RandomForest (≤8), GradientBoosting (>8)
    - construir_features(): lags + media móvil + tendencia + índice + mes calendario
    - entrenar_y_evaluar(): leave-one-out adaptado con intervalo de confianza

    Body: {
        "transactions": [{ "amount": float, "type": str, "category": str, "date": "YYYY-MM-DD" }]
    }
    Returns: {
        "predictions": [{ "categoria": str, "prediccion": float, "pred_min": float,
                          "pred_max": float, "modelo": str, "tendencia": str }],
        "total_predicted": float,
        "total_pred_min": float,
        "total_pred_max": float,
        "trend": str,
        "last_month_total": float,
        "months_of_data": int
    }
    """
    data = request.get_json(silent=True) or {}
    transactions = data.get('transactions', [])

    if not transactions:
        return jsonify({'predictions': [], 'total_predicted': 0, 'trend': 'stable'})

    # ── Agrupar gastos por mes y categoría ────────────────────────────────────
    monthly_by_cat: dict = defaultdict(lambda: defaultdict(float))

    for tx in transactions:
        if tx.get('type') != 'expense':
            continue
        cat    = tx.get('category', 'Otros')
        amount = float(tx.get('amount', 0))
        try:
            month_key = tx.get('date', '')[:7]
            if not month_key or len(month_key) < 7:
                continue
        except Exception:
            continue
        monthly_by_cat[cat][month_key] += amount

    if not monthly_by_cat:
        return jsonify({'predictions': [], 'total_predicted': 0, 'trend': 'stable'})

    # ── Construir series temporales ordenadas ─────────────────────────────────
    # Lista global de meses ordenados
    all_months = sorted({
        m for cat_data in monthly_by_cat.values() for m in cat_data.keys()
    })

    if not all_months:
        return jsonify({'predictions': [], 'total_predicted': 0, 'trend': 'stable'})

    months_of_data = len(all_months)

    # ── Predicción ML por categoría (notebook rf22) ───────────────────────────
    predictions_list = []
    total_last_month = 0.0

    # Serie de totales por categoría (rellena 0 en meses sin gasto)
    for cat, monthly in monthly_by_cat.items():
        serie = [monthly.get(m, 0.0) for m in all_months]
        result = _predict_category_ml(serie, all_months, cat)
        predictions_list.append(result)

        # Acumular último mes real para calcular tendencia global
        total_last_month += serie[-1] if serie else 0.0

    # ── Totales ───────────────────────────────────────────────────────────────
    total_predicted = round(sum(p['prediccion'] for p in predictions_list), 2)
    total_pred_min  = round(sum(p['pred_min']   for p in predictions_list), 2)
    total_pred_max  = round(sum(p['pred_max']   for p in predictions_list), 2)

    # Tendencia global
    all_totals = [
        sum(monthly_by_cat[cat].get(m, 0.0) for cat in monthly_by_cat)
        for m in all_months
    ]
    global_trend = _detectar_tendencia(all_totals)
    if total_predicted > total_last_month * 1.05:
        global_trend = 'increasing'
    elif total_predicted < total_last_month * 0.95:
        global_trend = 'decreasing'

    # Ordenar por predicción descendente
    predictions_list.sort(key=lambda x: -x['prediccion'])

    logger.info(
        f"[predict-expenses] {months_of_data} meses | {len(predictions_list)} categorías "
        f"| total_pred={total_predicted:.2f}€ | trend={global_trend}"
    )

    return jsonify({
        'predictions':        predictions_list,
        'total_predicted':    total_predicted,
        'total_pred_min':     total_pred_min,
        'total_pred_max':     total_pred_max,
        'trend':              global_trend,
        'last_month_total':   round(total_last_month, 2),
        'months_of_data':     months_of_data,
    })


# ─── RF-23 / HU-10: Detección de anomalías en gastos ────────────────────────

@app.route('/detect-anomalies', methods=['POST'])
def detect_anomalies():
    """
    RF-23 / HU-10: Detecta gastos inusuales usando Z-score por categoría.

    Un gasto se considera anómalo si su Z-score > 2.0 (> 2 desviaciones estándar
    sobre la media histórica de esa categoría). Severidad 'high' si Z > 3.0.

    Requiere mínimo 3 transacciones por categoría para calcular estadísticas.

    Body: {
        "transactions": [{ "id", "amount", "type", "category", "date", "description" }]
    }
    Returns: {
        "anomalies": [...],
        "total_anomalies": int,
        "categories_analyzed": int,
        "summary": { category: { mean, std, count } }
    }
    """
    data = request.get_json(silent=True) or {}
    transactions = data.get('transactions', [])

    # Agrupar gastos por categoría
    cat_history: dict = defaultdict(list)
    for tx in transactions:
        if tx.get('type') != 'expense':
            continue
        cat    = tx.get('category', 'Otros')
        amount = float(tx.get('amount', 0))
        if amount <= 0:
            continue
        cat_history[cat].append({
            'id':          tx.get('id', ''),
            'amount':      amount,
            'date':        tx.get('date', ''),
            'description': tx.get('description', '') or cat,
        })

    anomalies  = []
    cat_stats  = {}

    for cat, txs in cat_history.items():
        if len(txs) < 3:
            continue

        amounts = [t['amount'] for t in txs]
        mean    = float(np.mean(amounts))
        std     = float(np.std(amounts))
        cat_stats[cat] = {'mean': round(mean, 2), 'std': round(std, 2), 'count': len(txs)}

        if std < 0.01:
            # Todos los importes son iguales → no hay anomalías
            continue

        for tx in txs:
            z_score = (tx['amount'] - mean) / std
            if z_score <= 2.0:
                continue

            severity      = 'high' if z_score >= 3.0 else 'medium'
            pct_above_avg = round((tx['amount'] - mean) / mean * 100, 1)

            anomalies.append({
                'id':              tx['id'],
                'date':            tx['date'],
                'category':        cat,
                'amount':          round(tx['amount'], 2),
                'mean_amount':     round(mean, 2),
                'z_score':         round(z_score, 2),
                'percent_above_avg': pct_above_avg,
                'severity':        severity,
                'description':     tx['description'],
                'message':         (
                    f"Gasto {pct_above_avg:.0f}% superior al promedio de {cat} "
                    f"({mean:.2f}€ de media)"
                ),
            })

    # Ordenar: más recientes primero, después por severidad
    anomalies.sort(key=lambda x: (x['date'], x['z_score']), reverse=True)

    logger.info(
        f"[detect-anomalies] {len(cat_history)} categorías | "
        f"{len(anomalies)} anomalías encontradas"
    )

    return jsonify({
        'anomalies':           anomalies[:30],
        'total_anomalies':     len(anomalies),
        'categories_analyzed': len(cat_history),
        'category_stats':      cat_stats,
    })


# ─── RF-24 / HU-11: Detección automática de suscripciones ───────────────────

@app.route('/detect-subscriptions', methods=['POST'])
def detect_subscriptions():
    """
    RF-24 / HU-11: Identifica suscripciones y gastos recurrentes automáticamente.

    Algoritmo:
    1. Agrupa gastos por descripción normalizada (TF-IDF clean text)
    2. Filtra grupos con ≥ 2 ocurrencias y variación de importe < 10%
    3. Calcula intervalos entre fechas → clasifica periodicidad:
       semanal (6-8d), mensual (25-35d), trimestral (85-95d), anual (330-400d)
    4. Calcula coste mensual equivalente y próximo cargo estimado

    Body: {
        "transactions": [{ "amount", "type", "category", "date", "description" }]
    }
    Returns: {
        "subscriptions": [...],
        "total_subscriptions": int,
        "total_monthly_cost": float,
        "total_annual_cost": float
    }
    """
    from datetime import datetime, timedelta

    data = request.get_json(silent=True) or {}
    transactions = data.get('transactions', [])

    # Agrupar gastos por descripción normalizada
    desc_groups: dict = defaultdict(list)
    for tx in transactions:
        if tx.get('type') != 'expense':
            continue
        amount = float(tx.get('amount', 0))
        if amount <= 0:
            continue

        raw_desc = (tx.get('description') or '').strip()
        clean    = _clean_text(raw_desc) if raw_desc else ''
        # Si la descripción limpia es muy corta, usar categoría como clave alternativa
        key = clean if len(clean) >= 3 else tx.get('category', 'sin_descripcion')

        desc_groups[key].append({
            'amount':      amount,
            'date':        tx.get('date', ''),
            'description': raw_desc or tx.get('category', ''),
            'category':    tx.get('category', 'Otros'),
        })

    subscriptions = []

    for key, txs in desc_groups.items():
        if len(txs) < 2:
            continue

        # Ordenar por fecha
        try:
            txs_sorted = sorted(txs, key=lambda x: x['date'])
        except Exception:
            continue

        # Verificar que los importes son similares (variación < 10%)
        amounts     = [t['amount'] for t in txs_sorted]
        mean_amount = float(np.mean(amounts))
        if mean_amount <= 0:
            continue
        amount_std = float(np.std(amounts))
        variation  = amount_std / mean_amount

        if variation > 0.10:
            continue  # Importe demasiado variable para ser suscripción

        # Calcular intervalos entre fechas consecutivas
        dates = []
        for tx in txs_sorted:
            try:
                dates.append(datetime.strptime(tx['date'], '%Y-%m-%d'))
            except Exception:
                pass

        if len(dates) < 2:
            continue

        intervals  = [(dates[i + 1] - dates[i]).days for i in range(len(dates) - 1)]
        mean_interval = float(np.mean(intervals))
        interval_std  = float(np.std(intervals))

        # Rechazar si la periodicidad es muy irregular
        if len(intervals) > 1 and mean_interval > 0 and interval_std / mean_interval > 0.25:
            continue

        # Clasificar periodicidad
        if 6 <= mean_interval <= 8:
            period       = 'weekly'
            period_label = 'Semanal'
            monthly_cost = mean_amount * 4.33
        elif 25 <= mean_interval <= 35:
            period       = 'monthly'
            period_label = 'Mensual'
            monthly_cost = mean_amount
        elif 85 <= mean_interval <= 95:
            period       = 'quarterly'
            period_label = 'Trimestral'
            monthly_cost = mean_amount / 3
        elif 330 <= mean_interval <= 400:
            period       = 'annual'
            period_label = 'Anual'
            monthly_cost = mean_amount / 12
        else:
            continue  # Periodicidad no reconocida

        # Próximo cargo estimado
        last_date   = dates[-1]
        next_charge = (last_date + timedelta(days=int(round(mean_interval)))).strftime('%Y-%m-%d')
        days_until  = (datetime.strptime(next_charge, '%Y-%m-%d') - datetime.now()).days

        subscriptions.append({
            'name':             txs_sorted[-1]['description'] or key,
            'category':         txs_sorted[-1]['category'],
            'amount':           round(mean_amount, 2),
            'monthly_cost':     round(monthly_cost, 2),
            'periodicity':      period,
            'periodicity_label': period_label,
            'occurrences':      len(txs_sorted),
            'last_charge':      txs_sorted[-1]['date'],
            'next_charge':      next_charge,
            'days_until_next':  days_until,
            'amount_variation': round(variation * 100, 1),
        })

    # Ordenar por coste mensual descendente
    subscriptions.sort(key=lambda x: -x['monthly_cost'])
    total_monthly = sum(s['monthly_cost'] for s in subscriptions)

    logger.info(
        f"[detect-subscriptions] {len(desc_groups)} grupos | "
        f"{len(subscriptions)} suscripciones detectadas | "
        f"coste mensual total={total_monthly:.2f}€"
    )

    return jsonify({
        'subscriptions':      subscriptions,
        'total_subscriptions': len(subscriptions),
        'total_monthly_cost': round(total_monthly, 2),
        'total_annual_cost':  round(total_monthly * 12, 2),
    })


# ─── RF-25 / HU-12 / CU-04: Asistente conversacional IA ────────────────────

# Palabras clave por intención (NLP basado en reglas)
_INTENT_KEYWORDS = {
    'affordability': [
        'puedo comprar', 'puedo permitir', 'puedo pagar', 'me puedo permitir',
        'puedo darme', 'puedo gastar', 'me alcanza', 'tengo suficiente para',
        'puedo costear', 'afford',
    ],
    'spending': [
        'cuánto gasté', 'cuanto gasté', 'cuánto he gastado', 'mis gastos',
        'gasto total', 'en qué gasté', 'gastos del mes', 'cuánto he gastado',
        'gasto mensual', 'gasté este mes',
    ],
    'income': [
        'cuánto gané', 'cuanto gané', 'mis ingresos', 'ingresos del mes',
        'cuánto ingresé', 'cuánto cobré', 'ingresos totales',
    ],
    'category': [
        'categoría', 'categoria', 'en qué categoría', 'por categoría',
        'qué categoría', 'categorías', 'más gasto en', 'más gasté en',
        'mayor gasto', 'dónde gasto', 'donde gasto más',
    ],
    'savings': [
        'ahorro', 'objetivo', 'meta de ahorro', 'cuánto ahorro',
        'mis objetivos', 'ahorro mensual', 'mis metas', 'objetivo de ahorro',
    ],
    'subscriptions': [
        'suscripción', 'suscripciones', 'pagos recurrentes', 'recurrente',
        'subscription', 'pagos fijos', 'qué suscripciones',
    ],
    'recommendations': [
        'consejo', 'consejos', 'recomendación', 'recomendaciones',
        'cómo ahorrar', 'cómo mejorar', 'optimizar', 'mejorar mis finanzas',
        'qué puedo hacer', 'sugerencia', 'ayuda financiera',
    ],
    'balance': [
        'saldo', 'balance', 'cuánto tengo', 'cuánto me queda',
        'dinero disponible', 'dinero que tengo', 'fondos',
    ],
    'trend': [
        'tendencia', 'evolución', 'comparado', 'mes pasado', 'mes anterior',
        'más que antes', 'comparación', 'cómo va', 'aumentado', 'reducido',
    ],
}


def _detect_intent(message: str) -> str:
    """Detecta la intención del mensaje del usuario."""
    msg = message.lower()
    for intent, keywords in _INTENT_KEYWORDS.items():
        for kw in keywords:
            if kw in msg:
                return intent
    return 'general'


def _build_financial_summary(transactions: list) -> dict:
    """Construye un resumen financiero a partir de las transacciones."""
    from datetime import datetime, timedelta
    now = datetime.now()
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    prev_month_start = (month_start - timedelta(days=1)).replace(day=1)

    total_income = 0.0
    total_expenses = 0.0
    this_month_income = 0.0
    this_month_expenses = 0.0
    prev_month_expenses = 0.0
    category_spend: dict = {}

    for tx in transactions:
        try:
            tx_date = datetime.strptime(tx['date'], '%Y-%m-%d')
        except Exception:
            continue
        amount = float(tx.get('amount', 0))
        tx_type = tx.get('type', '')
        category = tx.get('category', 'Otros')

        if tx_type == 'income':
            total_income += amount
            if tx_date >= month_start:
                this_month_income += amount
        elif tx_type == 'expense':
            total_expenses += amount
            if tx_date >= month_start:
                this_month_expenses += amount
                category_spend[category] = category_spend.get(category, 0.0) + amount
            elif tx_date >= prev_month_start:
                prev_month_expenses += amount

    top_categories = sorted(category_spend.items(), key=lambda x: -x[1])
    balance = total_income - total_expenses

    return {
        'balance':              round(balance, 2),
        'total_income':         round(total_income, 2),
        'total_expenses':       round(total_expenses, 2),
        'this_month_income':    round(this_month_income, 2),
        'this_month_expenses':  round(this_month_expenses, 2),
        'prev_month_expenses':  round(prev_month_expenses, 2),
        'category_spend':       {k: round(v, 2) for k, v in category_spend.items()},
        'top_categories':       top_categories[:5],
        'savings_this_month':   round(this_month_income - this_month_expenses, 2),
    }


def _generate_chat_response(intent: str, message: str, summary: dict, goals: list) -> dict:
    """Genera una respuesta contextualizada según la intención detectada."""
    balance = summary['balance']
    this_month_exp = summary['this_month_expenses']
    this_month_inc = summary['this_month_income']
    prev_month_exp = summary['prev_month_expenses']
    top_cats = summary['top_categories']
    savings  = summary['savings_this_month']

    def fmt(amount):
        return f"{amount:,.2f}€".replace(',', '.')

    if intent == 'spending':
        cat_detail = ''
        if top_cats:
            lines = [f"• {cat}: {fmt(amt)}" for cat, amt in top_cats[:3]]
            cat_detail = '\n'.join(lines)
        vs_prev = ''
        if prev_month_exp > 0:
            diff = this_month_exp - prev_month_exp
            pct  = abs(diff) / prev_month_exp * 100
            if diff > 0:
                vs_prev = f" ({pct:.0f}% más que el mes anterior)"
            else:
                vs_prev = f" ({pct:.0f}% menos que el mes anterior)"

        response = f"Este mes has gastado **{fmt(this_month_exp)}**{vs_prev}."
        if cat_detail:
            response += f"\n\nTus principales categorías de gasto:\n{cat_detail}"
        if savings > 0:
            response += f"\n\n💚 Llevas **{fmt(savings)}** ahorrados este mes."
        elif savings < 0:
            response += f"\n\n⚠️ Estás gastando más de lo que ingresas este mes ({fmt(abs(savings))} de déficit)."

    elif intent == 'income':
        response = f"Este mes has ingresado **{fmt(this_month_inc)}**."
        if this_month_exp > 0:
            rate = (savings / this_month_inc * 100) if this_month_inc > 0 else 0
            if rate > 0:
                response += f"\n\nDespués de gastos, te quedan **{fmt(savings)}** ({rate:.0f}% de tasa de ahorro)."

    elif intent == 'category':
        if top_cats:
            lines = [f"{i+1}. **{cat}**: {fmt(amt)}" for i, (cat, amt) in enumerate(top_cats[:5])]
            cat_list = '\n'.join(lines)
            response = f"Tus categorías de mayor gasto este mes:\n\n{cat_list}"
        else:
            response = "Aún no hay suficientes transacciones este mes para analizar por categorías."

    elif intent == 'savings':
        if goals:
            goal_lines = []
            for g in goals[:3]:
                name    = g.get('name', 'Objetivo')
                current = float(g.get('current_amount', 0))
                target  = float(g.get('target_amount', 1))
                pct     = min(current / target * 100, 100) if target > 0 else 0
                goal_lines.append(f"• **{name}**: {fmt(current)} / {fmt(target)} ({pct:.0f}%)")
            goals_text = '\n'.join(goal_lines)
            response = f"Tus objetivos de ahorro:\n\n{goals_text}"
            if savings > 0:
                response += f"\n\nEste mes llevas **{fmt(savings)}** de ahorro, ¡sigue así!"
        else:
            if savings > 0:
                response = f"Este mes llevas **{fmt(savings)}** ahorrados. No tienes objetivos de ahorro configurados. ¡Te recomiendo crear uno!"
            else:
                response = "Este mes tu balance de ahorro es negativo. Te recomiendo revisar tus gastos y establecer un objetivo de ahorro."

    elif intent == 'balance':
        response = f"Tu balance total es **{fmt(balance)}**."
        if balance > 0:
            response += f"\n\nEste mes has ingresado **{fmt(this_month_inc)}** y gastado **{fmt(this_month_exp)}**."
        else:
            response += "\n\n⚠️ Tu balance acumulado es negativo. Considera revisar tus finanzas."

    elif intent == 'subscriptions':
        response = "Para ver tus suscripciones y pagos recurrentes, ve a **Predicciones IA → Suscripciones**. Allí encontrarás un análisis detallado de todos tus pagos periódicos con el coste mensual equivalente."

    elif intent == 'recommendations':
        recs = []
        for cat, amt in top_cats[:3]:
            ref = REFERENCE_BUDGETS.get(cat, 0.10)
            ref_amt = this_month_inc * ref if this_month_inc > 0 else 0
            if ref_amt > 0 and amt > ref_amt * 1.2:
                saving = round(amt - ref_amt, 2)
                recs.append(f"• Reduce **{cat}** de {fmt(amt)} a ~{fmt(ref_amt)} → ahorrarías {fmt(saving)}/mes")
        if recs:
            response = "Áreas donde puedes optimizar:\n\n" + '\n'.join(recs)
            response += "\n\nPara un análisis completo ve a **Predicciones IA → Ahorro**."
        else:
            response = "¡Tus finanzas parecen bien equilibradas! Puedes ver análisis detallados en **Predicciones IA**."

    elif intent == 'trend':
        if prev_month_exp > 0 and this_month_exp > 0:
            diff = this_month_exp - prev_month_exp
            pct  = abs(diff) / prev_month_exp * 100
            if diff > 5:
                response = f"Tus gastos han **aumentado un {pct:.0f}%** respecto al mes anterior ({fmt(prev_month_exp)} → {fmt(this_month_exp)})."
            elif diff < -5:
                response = f"Tus gastos han **disminuido un {pct:.0f}%** respecto al mes anterior ({fmt(prev_month_exp)} → {fmt(this_month_exp)}). ¡Muy bien!"
            else:
                response = f"Tus gastos se mantienen estables respecto al mes anterior (~{fmt(this_month_exp)})."
        else:
            response = "No tengo suficiente historial para comparar tendencias. Sigue registrando tus transacciones."

    elif intent == 'affordability':
        response = "Para analizar si puedes permitirte una compra, pregúntame directamente: **\"¿Puedo comprar [artículo] por [cantidad]€?\"** Por ejemplo: *\"¿Puedo comprar un portátil de 800€?\"*"

    else:  # general
        response = (
            f"Hola! Soy tu asistente financiero de Finora. "
            f"Este mes has gastado **{fmt(this_month_exp)}** y tu balance total es **{fmt(balance)}**.\n\n"
            "Puedo ayudarte con preguntas como:\n"
            "• *\"¿Cuánto gasté este mes?\"*\n"
            "• *\"¿En qué categoría gasto más?\"*\n"
            "• *\"¿Puedo comprarme un ordenador de 600€?\"*\n"
            "• *\"¿Cómo van mis objetivos de ahorro?\"*\n"
            "• *\"Dame recomendaciones para ahorrar\"*"
        )

    return {
        'response': response,
        'intent':   intent,
        'type':     'text',
    }


@app.route('/chat', methods=['POST'])
def chat():
    """
    RF-25 / HU-12 / CU-04: Asistente conversacional IA financiero.

    Procesa preguntas en lenguaje natural sobre las finanzas del usuario.
    Detecta la intención y genera una respuesta contextualizada con datos reales.

    Body: {
        "message":      str,          — pregunta del usuario
        "transactions": [...],        — historial de transacciones
        "goals":        [...],        — objetivos de ahorro (opcional)
        "history":      [...]         — historial de conversación previo (opcional)
    }
    Returns: {
        "response": str,
        "intent":   str,
        "type":     "text" | "chart" | "affordability"
    }
    """
    data         = request.get_json(silent=True) or {}
    message      = (data.get('message') or '').strip()
    transactions = data.get('transactions', [])
    goals        = data.get('goals', [])

    if not message:
        return jsonify({'error': 'message es requerido'}), 400

    summary = _build_financial_summary(transactions)

    intent = _detect_intent(message)
    result = _generate_chat_response(intent, message, summary, goals)
    logger.info(f"[chat] motor=rules | intent={intent} | message_len={len(message)}")
    return jsonify(result)


# ─── RF-26 / HU-13: Análisis de affordability ──────────────────────────────

def _extract_amount(text: str) -> float | None:
    """Extrae una cantidad monetaria del texto en lenguaje natural."""
    # Patrones: 800€, 800 euros, €800, 1.500€, 1500 eur
    patterns = [
        r'(\d[\d.,]*)\s*(?:€|euros?|eur)',
        r'(?:€|euros?|eur)\s*(\d[\d.,]*)',
        r'(\d[\d.,]+)',
    ]
    for pattern in patterns:
        match = re.search(pattern, text.lower())
        if match:
            raw = match.group(1).replace('.', '').replace(',', '.')
            try:
                val = float(raw)
                if val > 0:
                    return val
            except ValueError:
                continue
    return None


@app.route('/affordability', methods=['POST'])
def affordability():
    """
    RF-26 / HU-13: ¿Puedo permitírmelo? Análisis multi-factor de affordability.

    Analiza si el usuario puede permitirse una compra basándose en:
    - Balance acumulado disponible
    - Gastos fijos recurrentes próximos
    - Impacto en objetivos de ahorro activos
    - Tendencia de gastos del último mes

    Body: {
        "query":        str,    — pregunta del usuario ("¿Puedo comprar X por Y€?")
        "amount":       float,  — importe (opcional, se extrae del query si no se provee)
        "transactions": [...],  — historial de transacciones
        "goals":        [...],  — objetivos de ahorro activos
        "subscriptions": [...]  — suscripciones detectadas (para calcular gastos fijos)
    }
    Returns: {
        "verdict":          "yes" | "no" | "caution",
        "amount":           float,
        "concept":          str,
        "available_balance": float,
        "balance_after":    float,
        "monthly_surplus":  float,
        "impact_on_goals":  [...],
        "alternatives":     [...],
        "months_to_save":   int | null,
        "analysis":         str,
        "recommendation":   str
    }
    """
    from datetime import datetime

    data          = request.get_json(silent=True) or {}
    query         = (data.get('query') or '').strip()
    amount        = data.get('amount')
    transactions  = data.get('transactions', [])
    goals         = data.get('goals', [])
    subscriptions = data.get('subscriptions', [])

    # Extraer importe si no se proporcionó
    if amount is None:
        amount = _extract_amount(query)
    if amount is None or amount <= 0:
        return jsonify({'error': 'No se pudo extraer el importe de la consulta'}), 400

    amount = float(amount)

    # Extraer concepto de la query (texto entre "comprar/permitir" y el importe)
    concept_match = re.search(
        r'(?:comprar?|permitirme|pagar|gastar(?:me)?)\s+(?:un[ao]?\s+)?([^0-9€]+?)(?:\s+(?:de|por|a)\s+)?(?:\d|€|$)',
        query.lower()
    )
    concept = concept_match.group(1).strip().rstrip(' de por') if concept_match else 'artículo'

    # Calcular métricas financieras
    summary = _build_financial_summary(transactions)
    available_balance = summary['balance']
    this_month_inc    = summary['this_month_income']
    this_month_exp    = summary['this_month_expenses']
    monthly_surplus   = this_month_inc - this_month_exp

    # Calcular gasto fijo mensual de suscripciones
    fixed_monthly = sum(float(s.get('monthly_cost', 0)) for s in subscriptions)

    # Calcular balance_after
    balance_after = available_balance - amount

    # Analizar impacto en objetivos de ahorro
    impact_on_goals = []
    for g in goals:
        name      = g.get('name', 'Objetivo')
        target    = float(g.get('target_amount', 0))
        current   = float(g.get('current_amount', 0))
        remaining = target - current
        if remaining > 0 and amount > 0:
            months_delayed = 0
            if monthly_surplus > 0:
                months_delayed = round(amount / monthly_surplus)
            pct_impact = min(amount / remaining * 100, 100) if remaining > 0 else 0
            impact_on_goals.append({
                'goal_name':     name,
                'months_delayed': months_delayed,
                'pct_impact':    round(pct_impact, 1),
            })

    # Lógica de veredicto
    can_cover = available_balance >= amount
    comfortable_cover = available_balance >= amount * 1.5

    if can_cover and comfortable_cover and monthly_surplus > 0:
        verdict = 'yes'
    elif can_cover and (not comfortable_cover or monthly_surplus <= 0):
        verdict = 'caution'
    else:
        verdict = 'no'

    # Calcular meses para ahorrar si no es viable
    months_to_save = None
    if verdict == 'no' and monthly_surplus > 0:
        deficit = amount - available_balance
        months_to_save = math.ceil(deficit / monthly_surplus) if monthly_surplus > 0 else None

    def fmt(v):
        return f"{v:,.2f}€".replace(',', '.')

    # Generar análisis y recomendación
    if verdict == 'yes':
        analysis = (
            f"Tu balance disponible es {fmt(available_balance)}, suficiente para cubrir "
            f"{fmt(amount)} con {fmt(balance_after)} restante."
        )
        recommendation = f"Sí puedes permitirte {concept}. Tendrás {fmt(balance_after)} de balance tras la compra."
    elif verdict == 'caution':
        analysis = (
            f"Técnicamente puedes cubrir {fmt(amount)} desde tu balance de {fmt(available_balance)}, "
            f"pero te quedaría poco margen ({fmt(balance_after)})."
        )
        recommendation = f"Puedes comprar {concept} con precaución. Asegúrate de no tener gastos imprevistos próximos."
    else:
        shortfall = amount - available_balance
        analysis = (
            f"Tu balance disponible ({fmt(available_balance)}) es insuficiente para {fmt(amount)}. "
            f"Te faltan {fmt(shortfall)}."
        )
        if months_to_save:
            recommendation = f"Ahorrando {fmt(monthly_surplus)}/mes, podrías comprar {concept} en ~{months_to_save} meses."
        else:
            recommendation = f"Revisa tus ingresos y gastos antes de realizar esta compra."

    # Alternativas
    alternatives = []
    if verdict in ('no', 'caution'):
        if months_to_save and months_to_save <= 6:
            alternatives.append(f"Espera {months_to_save} mes(es) ahorrando {fmt(monthly_surplus)}/mes")
        alternatives.append(f"Busca versiones más económicas de {concept}")
        if fixed_monthly > 0:
            alternatives.append(f"Revisa tus suscripciones ({fmt(fixed_monthly)}/mes) para liberar presupuesto")

    logger.info(f"[affordability] amount={amount} | verdict={verdict} | balance={available_balance}")
    return jsonify({
        'verdict':          verdict,
        'amount':           amount,
        'concept':          concept,
        'available_balance': round(available_balance, 2),
        'balance_after':    round(balance_after, 2),
        'monthly_surplus':  round(monthly_surplus, 2),
        'fixed_monthly':    round(fixed_monthly, 2),
        'impact_on_goals':  impact_on_goals,
        'alternatives':     alternatives,
        'months_to_save':   months_to_save,
        'analysis':         analysis,
        'recommendation':   recommendation,
    })


# ─── RF-27 / HU-14: Recomendaciones de optimización financiera ───────────────

@app.route('/recommendations', methods=['POST'])
def recommendations():
    """
    RF-27 / HU-14: Recomendaciones inteligentes de optimización financiera.

    Analiza patrones de gasto y genera recomendaciones priorizadas por impacto.
    Compara gastos con la regla 50/30/20 y con umbrales de referencia por categoría.

    Body: {
        "transactions":    [...],    — historial de transacciones (mín 1 mes)
        "monthly_income":  float,    — ingreso mensual promedio
        "subscriptions":   [...]     — suscripciones detectadas (opcional)
    }
    Returns: {
        "recommendations": [{
            "category":          str,
            "title":             str,
            "description":       str,
            "potential_saving":  float,
            "priority":          "high" | "medium" | "low",
            "type":              "overspending" | "subscription" | "savings_rate" | "emergency"
        }],
        "total_potential_saving": float,
        "financial_score":        int (0-100),
        "analysis_months":        int
    }
    """
    from datetime import datetime

    data           = request.get_json(silent=True) or {}
    transactions   = data.get('transactions', [])
    monthly_income = float(data.get('monthly_income', 0))
    subscriptions  = data.get('subscriptions', [])

    # Calcular métricas del último mes
    summary        = _build_financial_summary(transactions)
    this_month_exp = summary['this_month_expenses']
    this_month_inc = summary['this_month_income'] or monthly_income
    category_spend = summary['category_spend']
    savings        = summary['savings_this_month']

    # Contar meses de histórico
    dates = []
    for tx in transactions:
        try:
            dates.append(datetime.strptime(tx['date'], '%Y-%m-%d'))
        except Exception:
            pass
    analysis_months = 1
    if len(dates) >= 2:
        delta = (max(dates) - min(dates)).days
        analysis_months = max(1, round(delta / 30))

    recommendations_list = []

    # 1. Gastos por encima del presupuesto de referencia (regla 50/30/20)
    for cat, ref_pct in REFERENCE_BUDGETS.items():
        actual = category_spend.get(cat, 0)
        if actual <= 0 or this_month_inc <= 0:
            continue
        budget = this_month_inc * ref_pct
        if actual > budget * 1.3:  # > 30% por encima del presupuesto
            saving = round(actual - budget, 2)
            recommendations_list.append({
                'category':         cat,
                'title':            f'Reducir gasto en {cat}',
                'description':      (
                    f'Gastas {actual:.2f}€ en {cat}, un {((actual-budget)/budget*100):.0f}% '
                    f'por encima del presupuesto recomendado ({budget:.2f}€). '
                    f'Podrías ahorrar ~{saving:.2f}€/mes.'
                ),
                'potential_saving': saving,
                'priority':         'high' if actual > budget * 1.5 else 'medium',
                'type':             'overspending',
            })

    # 2. Suscripciones (si hay muchas, sugerir revisión)
    if len(subscriptions) >= 3:
        total_sub_cost = sum(float(s.get('monthly_cost', 0)) for s in subscriptions)
        recommendations_list.append({
            'category':         'Suscripciones',
            'title':            f'Revisar {len(subscriptions)} suscripciones activas',
            'description':      (
                f'Tienes {len(subscriptions)} suscripciones con un coste de '
                f'{total_sub_cost:.2f}€/mes ({total_sub_cost*12:.2f}€/año). '
                'Revisa si utilizas todas activamente.'
            ),
            'potential_saving': round(total_sub_cost * 0.3, 2),  # Estimado 30% optimizable
            'priority':         'medium',
            'type':             'subscription',
        })

    # 3. Tasa de ahorro baja (< 10% del ingreso)
    if this_month_inc > 0:
        savings_rate = savings / this_month_inc if this_month_inc > 0 else 0
        if savings_rate < 0.10:
            target_saving = this_month_inc * 0.20
            rec_saving    = round(target_saving - max(savings, 0), 2)
            recommendations_list.append({
                'category':         'Ahorro',
                'title':            'Aumentar tasa de ahorro al 20%',
                'description':      (
                    f'Tu tasa de ahorro actual es del {savings_rate*100:.0f}%. '
                    f'Se recomienda ahorrar al menos el 20% ({target_saving:.2f}€/mes). '
                    f'Intenta ahorrar {rec_saving:.2f}€ adicionales al mes.'
                ),
                'potential_saving': max(rec_saving, 0),
                'priority':         'high' if savings_rate < 0 else 'medium',
                'type':             'savings_rate',
            })

    # 4. Gasto en categoría "no presupuestada" muy alto
    unbudgeted_cats = [cat for cat in category_spend if cat not in REFERENCE_BUDGETS]
    for cat in unbudgeted_cats:
        amt = category_spend[cat]
        if this_month_inc > 0 and amt / this_month_inc > 0.15:
            saving = round(amt * 0.3, 2)
            recommendations_list.append({
                'category':         cat,
                'title':            f'Alto gasto en {cat}',
                'description':      (
                    f'Gastas {amt:.2f}€ en {cat}, lo que representa el '
                    f'{(amt/this_month_inc*100):.0f}% de tus ingresos. '
                    f'Considera reducirlo en un 30% para ahorrar {saving:.2f}€/mes.'
                ),
                'potential_saving': saving,
                'priority':         'medium',
                'type':             'overspending',
            })

    # Ordenar por potencial de ahorro descendente
    recommendations_list.sort(key=lambda x: (-x['potential_saving'], x['priority']))
    total_saving = sum(r['potential_saving'] for r in recommendations_list)

    # Score financiero (0-100)
    score = 100
    if savings < 0:
        score -= 40
    elif savings / this_month_inc < 0.10 and this_month_inc > 0:
        score -= 20
    score -= min(len(recommendations_list) * 5, 30)
    score = max(0, min(100, score))

    logger.info(
        f"[recommendations] {len(recommendations_list)} recomendaciones | "
        f"ahorro_potencial={total_saving:.2f}€ | score={score}"
    )

    return jsonify({
        'recommendations':        recommendations_list[:10],
        'total_potential_saving': round(total_saving, 2),
        'financial_score':        score,
        'analysis_months':        analysis_months,
    })


# ═══════════════════════════════════════════════════════════════════════════════
# RF-01 — Generador IA de transacciones bancarias realistas para España
# ═══════════════════════════════════════════════════════════════════════════════
#
# Endpoint: POST /generate-sample-transactions
#
# Flujo:
#   1. El generador estadístico produce un historial rico y coherente con
#      98+ comercios españoles reales y patrones estacionales
#   2. El caller (banks.js) escala los ingresos proporcionalmente para cuadrar
#      el saldo exacto y categoriza el lote completo con el modelo ML ya existente
# ──────────────────────────────────────────────────────────────────────────────

# ---------------------------------------------------------------------------
# Catálogo de comercios para el generador de fallback (reglas estadísticas)
# ---------------------------------------------------------------------------
# freq: weekly=3-5×/mes, biweekly=1-3×/mes, monthly=~1×/mes, rare=~30%/mes
# range: [min_cents, max_cents]

_FB_MERCHANTS = [
    # ── Alimentación ──────────────────────────────────────────────────────────
    {'desc': 'Mercadona',           'pm': 'debit_card',  'freq': 'weekly',   'range': (1500,  8500)},
    {'desc': 'Carrefour Express',   'pm': 'debit_card',  'freq': 'biweekly', 'range': (1800, 11000)},
    {'desc': 'Lidl',                'pm': 'debit_card',  'freq': 'biweekly', 'range': ( 900,  6000)},
    {'desc': 'Dia Supermercados',   'pm': 'debit_card',  'freq': 'biweekly', 'range': ( 600,  4000)},
    {'desc': 'Aldi',                'pm': 'debit_card',  'freq': 'monthly',  'range': ( 800,  4500)},
    {'desc': 'Consum',              'pm': 'debit_card',  'freq': 'biweekly', 'range': (1000,  6000)},
    {'desc': 'Froiz',               'pm': 'debit_card',  'freq': 'monthly',  'range': (1200,  5500)},
    {'desc': 'Cafetería',           'pm': 'debit_card',  'freq': 'weekly',   'range': ( 150,   550)},
    {'desc': 'Bar La Tasca',        'pm': 'debit_card',  'freq': 'weekly',   'range': ( 200,   800)},
    {'desc': 'Restaurante',         'pm': 'debit_card',  'freq': 'biweekly', 'range': (1200,  4000)},
    {'desc': "McDonald's",          'pm': 'debit_card',  'freq': 'monthly',  'range': ( 600,  1500)},
    {'desc': 'Burger King',         'pm': 'debit_card',  'freq': 'monthly',  'range': ( 700,  1700)},
    {'desc': 'KFC',                 'pm': 'debit_card',  'freq': 'monthly',  'range': ( 700,  1800)},
    {'desc': 'Telepizza',           'pm': 'debit_card',  'freq': 'monthly',  'range': (1300,  2800)},
    {'desc': "Domino's Pizza",      'pm': 'credit_card', 'freq': 'monthly',  'range': (1200,  2600)},
    {'desc': 'Starbucks',           'pm': 'debit_card',  'freq': 'weekly',   'range': ( 350,   850)},
    {'desc': 'Costa Coffee',        'pm': 'debit_card',  'freq': 'biweekly', 'range': ( 250,   700)},
    {'desc': 'Glovo',               'pm': 'credit_card', 'freq': 'biweekly', 'range': (1200,  3200)},
    {'desc': 'Just Eat',            'pm': 'credit_card', 'freq': 'biweekly', 'range': (1100,  3000)},
    {'desc': 'Uber Eats',           'pm': 'credit_card', 'freq': 'biweekly', 'range': (1200,  3500)},
    {'desc': 'Vips',                'pm': 'debit_card',  'freq': 'monthly',  'range': ( 900,  2500)},
    {'desc': 'Mercadona Online',    'pm': 'credit_card', 'freq': 'rare',     'range': (3500,  9000)},
    # ── Transporte ────────────────────────────────────────────────────────────
    {'desc': 'Repsol',              'pm': 'debit_card',  'freq': 'biweekly', 'range': (3800,  8000)},
    {'desc': 'BP',                  'pm': 'debit_card',  'freq': 'biweekly', 'range': (3600,  7500)},
    {'desc': 'Cepsa',               'pm': 'debit_card',  'freq': 'monthly',  'range': (4000,  7800)},
    {'desc': 'Galp',                'pm': 'debit_card',  'freq': 'monthly',  'range': (3900,  7500)},
    {'desc': 'Renfe Cercanías',     'pm': 'debit_card',  'freq': 'monthly',  'range': (1500,  5000)},
    {'desc': 'Metro Madrid',        'pm': 'debit_card',  'freq': 'monthly',  'range': (1250,  2600)},
    {'desc': 'Cabify',              'pm': 'credit_card', 'freq': 'monthly',  'range': ( 700,  2500)},
    {'desc': 'Bolt',                'pm': 'credit_card', 'freq': 'monthly',  'range': ( 500,  2000)},
    {'desc': 'BlaBlaCar',           'pm': 'credit_card', 'freq': 'rare',     'range': ( 800,  3500)},
    {'desc': 'Aparcamiento',        'pm': 'debit_card',  'freq': 'biweekly', 'range': ( 300,  1800)},
    {'desc': 'Bicing / EMT',        'pm': 'debit_card',  'freq': 'monthly',  'range': ( 800,  3000)},
    {'desc': 'ALSA',                'pm': 'debit_card',  'freq': 'rare',     'range': ( 800,  4500)},
    {'desc': 'ITV',                 'pm': 'debit_card',  'freq': 'rare',     'range': (3500,  7000)},
    # ── Ropa ──────────────────────────────────────────────────────────────────
    {'desc': 'Zara',                'pm': 'debit_card',  'freq': 'monthly',  'range': (2000, 11000)},
    {'desc': 'H&M',                 'pm': 'credit_card', 'freq': 'monthly',  'range': (1500,  6500)},
    {'desc': 'Mango',               'pm': 'credit_card', 'freq': 'monthly',  'range': (1800, 10000)},
    {'desc': 'Pull&Bear',           'pm': 'debit_card',  'freq': 'monthly',  'range': (1500,  7000)},
    {'desc': 'Primark',             'pm': 'debit_card',  'freq': 'monthly',  'range': (1000,  4500)},
    {'desc': 'Massimo Dutti',       'pm': 'credit_card', 'freq': 'monthly',  'range': (3000, 16000)},
    {'desc': 'Shein',               'pm': 'credit_card', 'freq': 'monthly',  'range': (1200,  5500)},
    {'desc': 'Bershka',             'pm': 'debit_card',  'freq': 'monthly',  'range': (1200,  6000)},
    {'desc': 'Stradivarius',        'pm': 'debit_card',  'freq': 'monthly',  'range': (1200,  6000)},
    # ── Ocio ──────────────────────────────────────────────────────────────────
    {'desc': 'Cines Yelmo',         'pm': 'debit_card',  'freq': 'monthly',  'range': ( 700,  1500)},
    {'desc': 'Steam',               'pm': 'credit_card', 'freq': 'monthly',  'range': ( 500,  6000)},
    {'desc': 'PlayStation Store',   'pm': 'credit_card', 'freq': 'monthly',  'range': ( 599,  5999)},
    {'desc': 'Xbox Game Pass',      'pm': 'direct_debit','freq': 'monthly',  'range': ( 999,  1499)},
    {'desc': 'Nintendo eShop',      'pm': 'credit_card', 'freq': 'rare',     'range': ( 499,  5999)},
    {'desc': 'FNAC',                'pm': 'credit_card', 'freq': 'rare',     'range': (1000, 10000)},
    {'desc': 'Bowling / Karting',   'pm': 'debit_card',  'freq': 'rare',     'range': ( 800,  3000)},
    # ── Cultura ───────────────────────────────────────────────────────────────
    {'desc': 'Teatro / Concierto',  'pm': 'credit_card', 'freq': 'rare',     'range': (1500,  9000)},
    {'desc': 'Casa del Libro',      'pm': 'debit_card',  'freq': 'monthly',  'range': ( 800,  3500)},
    {'desc': 'Museo / Exposición',  'pm': 'debit_card',  'freq': 'rare',     'range': ( 500,  2200)},
    # ── Compras ───────────────────────────────────────────────────────────────
    {'desc': 'Amazon',              'pm': 'credit_card', 'freq': 'biweekly', 'range': ( 800, 12000)},
    {'desc': 'El Corte Inglés',     'pm': 'credit_card', 'freq': 'monthly',  'range': (1800, 18000)},
    {'desc': 'MediaMarkt',          'pm': 'credit_card', 'freq': 'rare',     'range': (5000, 55000)},
    {'desc': 'AliExpress',          'pm': 'credit_card', 'freq': 'monthly',  'range': ( 500,  6000)},
    {'desc': 'Wallapop / Vinted',   'pm': 'bizum',       'freq': 'rare',     'range': (1000,  8000)},
    # ── Tecnología ────────────────────────────────────────────────────────────
    {'desc': 'PcComponentes',       'pm': 'credit_card', 'freq': 'rare',     'range': (2000, 45000)},
    {'desc': 'Apple Store',         'pm': 'credit_card', 'freq': 'rare',     'range': (3000, 70000)},
    # ── Vivienda ──────────────────────────────────────────────────────────────
    {'desc': 'IKEA',                'pm': 'credit_card', 'freq': 'rare',     'range': (3000, 45000)},
    {'desc': 'Leroy Merlin',        'pm': 'debit_card',  'freq': 'rare',     'range': (1800, 30000)},
    {'desc': 'Mr. Bricolage',       'pm': 'debit_card',  'freq': 'rare',     'range': (1200, 10000)},
    {'desc': 'Ferretería',          'pm': 'debit_card',  'freq': 'rare',     'range': ( 500,  6000)},
    # ── Salud ─────────────────────────────────────────────────────────────────
    {'desc': 'Farmacia García',     'pm': 'debit_card',  'freq': 'monthly',  'range': ( 400,  5000)},
    {'desc': 'Farmacia Central',    'pm': 'debit_card',  'freq': 'monthly',  'range': ( 400,  5500)},
    {'desc': 'Dentista',            'pm': 'debit_card',  'freq': 'rare',     'range': (5500, 22000)},
    {'desc': 'Óptica Universitaria','pm': 'credit_card', 'freq': 'rare',     'range': (7000, 30000)},
    {'desc': 'Fisioterapeuta',      'pm': 'debit_card',  'freq': 'rare',     'range': (3000,  8000)},
    # ── Belleza / Cuidado Personal ────────────────────────────────────────────
    {'desc': 'Peluquería',          'pm': 'debit_card',  'freq': 'monthly',  'range': (1200,  6000)},
    {'desc': 'Centro de Estética',  'pm': 'debit_card',  'freq': 'monthly',  'range': (1800,  7500)},
    {'desc': 'Douglas',             'pm': 'debit_card',  'freq': 'monthly',  'range': (1200,  8000)},
    {'desc': 'Primor',              'pm': 'debit_card',  'freq': 'monthly',  'range': ( 800,  4500)},
    # ── Educación ─────────────────────────────────────────────────────────────
    {'desc': 'Udemy',               'pm': 'credit_card', 'freq': 'rare',     'range': ( 999,  4999)},
    {'desc': 'Academia de idiomas', 'pm': 'bank_transfer','freq': 'monthly', 'range': (5000, 11000)},
    {'desc': 'Librería',            'pm': 'debit_card',  'freq': 'monthly',  'range': ( 800,  4000)},
    # ── Mascotas ──────────────────────────────────────────────────────────────
    {'desc': 'Kiwoko',              'pm': 'debit_card',  'freq': 'monthly',  'range': (1800,  6000)},
    {'desc': 'Tiendanimal',         'pm': 'debit_card',  'freq': 'monthly',  'range': (1500,  5000)},
    {'desc': 'Veterinario',         'pm': 'debit_card',  'freq': 'rare',     'range': (3000, 16000)},
    {'desc': 'Peluquería canina',   'pm': 'debit_card',  'freq': 'monthly',  'range': (2200,  5500)},
    # ── Deportes ──────────────────────────────────────────────────────────────
    {'desc': 'Decathlon',           'pm': 'debit_card',  'freq': 'rare',     'range': (1800, 13000)},
    {'desc': 'Pádel / Tenis',       'pm': 'debit_card',  'freq': 'biweekly', 'range': ( 600,  1400)},
    {'desc': 'Nike / Adidas',       'pm': 'credit_card', 'freq': 'rare',     'range': (2500, 14000)},
    {'desc': 'Polideportivo',       'pm': 'debit_card',  'freq': 'monthly',  'range': ( 500,  1800)},
    # ── Viajes ────────────────────────────────────────────────────────────────
    {'desc': 'Airbnb',              'pm': 'credit_card', 'freq': 'rare',     'range': (7000, 32000)},
    {'desc': 'Booking.com',         'pm': 'credit_card', 'freq': 'rare',     'range': (5500, 38000)},
    {'desc': 'Vueling',             'pm': 'credit_card', 'freq': 'rare',     'range': (3500, 22000)},
    {'desc': 'Renfe AVE',           'pm': 'credit_card', 'freq': 'rare',     'range': (2200, 16000)},
]

_FB_FIXED_TEMPLATES = [
    {'desc': 'Netflix',            'pm': 'direct_debit',  'day': 5,  'base': 1599, 'var': 0.00},
    {'desc': 'Spotify',            'pm': 'direct_debit',  'day': 8,  'base':  999, 'var': 0.00},
    {'desc': 'Vodafone',           'pm': 'direct_debit',  'day': 10, 'base': 3850, 'var': 0.04},
    {'desc': 'Iberdrola',          'pm': 'direct_debit',  'day': 15, 'base': 6000, 'var': 0.30},
    {'desc': 'Comunidad vecinos',  'pm': 'bank_transfer', 'day': 3,  'base': 8000, 'var': 0.00},
    {'desc': 'Seguro coche',       'pm': 'direct_debit',  'day': 20, 'base': 6200, 'var': 0.05},
    {'desc': 'Seguro hogar',       'pm': 'direct_debit',  'day': 7,  'base': 2800, 'var': 0.00},
]


def _fb_generate(balance_eur: float, months: int) -> list:
    """
    Generador estadístico de transacciones bancarias con presupuesto mensual controlado.

    Estrategia de presupuesto:
      variable_budget = (salary - fixed_this_month - savings_floor) * spending_mult
    Los gastos variables se generan como un pool de candidatos aleatorios que se
    consumen en orden aleatorio hasta agotar el presupuesto.
    Esto garantiza ahorro positivo (≥12%) cada mes sin sacrificar aleatoriedad.
    """
    today = datetime.now()

    salary_cents  = max(170000, min(340000,
                        round((balance_eur / 2.8 + 1100) / 10) * 1000))
    salary_day    = random.randint(25, 29)
    rent_cents    = int(salary_cents * (0.25 + random.random() * 0.10))
    has_gym       = random.random() > 0.55
    gym_cents     = random.randint(3990, 5500) if has_gym else 0
    has_hbo       = random.random() > 0.55
    has_prime     = random.random() > 0.50
    has_disney    = random.random() > 0.65
    has_parking   = random.random() > 0.70
    parking_cents = random.choice([6000, 7000, 8000, 9000, 10000]) if has_parking else 0
    agua_cents    = random.randint(1800, 3500)
    # Paga extra reducida (45-60%) para no generar picos de ingresos exagerados
    extra_pay     = int(salary_cents * (0.45 + random.random() * 0.15))

    fixed = [
        {'desc': 'Alquiler mensual',  'pm': 'bank_transfer', 'day': 1,
         'base': rent_cents,    'var': 0.00},
        *_FB_FIXED_TEMPLATES,
        {'desc': 'Canal Isabel II',   'pm': 'direct_debit',  'day': 22,
         'base': agua_cents,    'var': 0.15},
        *([{'desc': 'Gimnasio', 'pm': 'direct_debit', 'day': 2,
             'base': gym_cents, 'var': 0.00}] if has_gym else []),
        *([{'desc': 'HBO Max',  'pm': 'direct_debit', 'day': 12,
             'base': 899,       'var': 0.00}] if has_hbo else []),
        *([{'desc': 'Amazon Prime', 'pm': 'direct_debit', 'day': 18,
             'base': 499,       'var': 0.00}] if has_prime else []),
        *([{'desc': 'Disney+', 'pm': 'direct_debit', 'day': 14,
             'base': 899,       'var': 0.00}] if has_disney else []),
        *([{'desc': 'Plaza garaje', 'pm': 'bank_transfer', 'day': 2,
             'base': parking_cents, 'var': 0.00}] if has_parking else []),
    ]

    txs = []

    for m_offset in range(months, 0, -1):  # excluye el mes actual (parcial)
        yr = today.year
        mo = today.month - m_offset
        while mo <= 0:
            mo += 12
            yr -= 1
        month_idx  = mo - 1
        max_day_mo = calendar.monthrange(yr, mo)[1]

        # Estacional: sólo afecta a precios individuales variables
        if month_idx == 11:         seasonal = 1.08
        elif month_idx in (6, 7):   seasonal = 1.05
        elif month_idx == 0:        seasonal = 0.90
        else:                       seasonal = 1.0

        # Factor de frugalidad mensual (0.72–0.96): modula el presupuesto disponible
        spending_mult = max(0.72, min(0.96, random.gauss(0.85, 0.06)))

        # ── Nómina ────────────────────────────────────────────────────────────
        drift     = 1 + (months - m_offset) * 0.0008
        s_amt     = int(salary_cents * drift)
        s_day_adj = min(salary_day, max_day_mo)
        s_date    = datetime(yr, mo, s_day_adj)
        if s_date <= today:
            txs.append({'date': s_date.strftime('%Y-%m-%d'), 'desc': 'Nómina',
                        'pm': 'bank_transfer', 'cents': s_amt, 'type': 'income'})

        # ── Paga extra (jun=5, dic=11) ────────────────────────────────────────
        if month_idx in (5, 11):
            ex_date = datetime(yr, mo, random.randint(14, 18))
            if ex_date <= today:
                txs.append({'date': ex_date.strftime('%Y-%m-%d'), 'desc': 'Paga extra',
                            'pm': 'bank_transfer', 'cents': extra_pay, 'type': 'income'})

        # ── Ingresos variables (frecuencia y rangos moderados) ────────────────
        if random.random() < 0.25:
            day = random.randint(1, 20)
            txs.append({'date': datetime(yr, mo, day).strftime('%Y-%m-%d'),
                        'desc': 'Freelance cliente', 'pm': 'bank_transfer',
                        'cents': random.randint(15000, 40000), 'type': 'income'})

        if random.random() < 0.30:
            day   = random.randint(1, 28)
            descs = ['Cashback tarjeta', 'Devolución Hacienda', 'Reembolso seguro',
                     'Intereses cuenta', 'Reembolso Amazon', 'Bonificación banco']
            txs.append({'date': datetime(yr, mo, day).strftime('%Y-%m-%d'),
                        'desc': random.choice(descs), 'pm': 'bank_transfer',
                        'cents': random.randint(1000, 6000), 'type': 'income'})

        # ── Gastos fijos ──────────────────────────────────────────────────────
        fixed_this_month = 0
        for fe in fixed:
            try:
                d       = min(fe['day'], max_day_mo)
                tx_date = datetime(yr, mo, d)
                if tx_date > today:
                    continue
                variation = 1 + (random.random() * 2 - 1) * fe['var']
                if fe['desc'] == 'Iberdrola' and month_idx in (10, 11, 0, 1):
                    variation *= 1.30
                amt = max(1, int(fe['base'] * variation))
                txs.append({'date': tx_date.strftime('%Y-%m-%d'),
                            'desc': fe['desc'], 'pm': fe['pm'],
                            'cents': amt, 'type': 'expense'})
                fixed_this_month += amt
            except (ValueError, KeyError):
                pass

        # ── Presupuesto de gastos variables ───────────────────────────────────
        # savings_floor: mínimo 12%, media 20% del salario mensual (en cents)
        savings_floor   = int(salary_cents * max(0.12, random.gauss(0.20, 0.04)))
        variable_budget = max(20000, int(
            (salary_cents - fixed_this_month - savings_floor) * spending_mult
        ))

        # ── Pool de candidatos variables (aleatorios) ─────────────────────────
        candidates = []
        for m in _FB_MERCHANTS:
            freq = m['freq']
            if freq == 'weekly':      n = random.randint(2, 4)
            elif freq == 'biweekly':  n = random.randint(1, 2)
            elif freq == 'monthly':   n = 1 if random.random() > 0.35 else 0
            else:                     n = 1 if random.random() < 0.18 else 0

            lo, hi = m['range']
            for _ in range(n):
                day = random.randint(1, max_day_mo)
                try:
                    tx_date = datetime(yr, mo, day)
                except ValueError:
                    continue
                if tx_date > today:
                    continue
                amt = int(random.randint(lo, hi) * seasonal)
                candidates.append((tx_date, m, amt))

        # Mezclar aleatoriamente y consumir hasta agotar el presupuesto
        random.shuffle(candidates)
        spent = 0
        for tx_date, m, amt in candidates:
            if spent >= variable_budget:
                break
            txs.append({'date': tx_date.strftime('%Y-%m-%d'),
                        'desc': m['desc'], 'pm': m['pm'],
                        'cents': amt, 'type': 'expense'})
            spent += amt

    return txs



@app.route('/generate-sample-transactions', methods=['POST'])
def generate_sample_transactions():
    """
    RF-01: Genera un historial de transacciones demo realista para una cuenta nueva.

    Body JSON:
      - balance_eur  (float): Saldo objetivo en euros
      - months       (int):   Meses de historial (default 18, rango 6-36)

    Respuesta:
      {
        "transactions": [{"date","desc","pm","cents","type"}, ...],
        "source": "estadistico"
      }

    El caller (banks.js) se encarga de:
      1. Escalar ingresos proporcionalmente para cuadrar income - expenses = targetBalance
         (sin añadir transacciones de ajuste artificiales)
      2. Pasar descripciones a /categorize/batch para categorización ML
      3. Insertar cada tx con amount = cents / 100
    """
    data        = request.get_json(silent=True) or {}
    balance_eur = float(data.get('balance_eur', 2000))
    months      = max(6, min(int(data.get('months', 18)), 36))

    txs = _fb_generate(balance_eur, months)
    logger.info(f'[generate-tx] Generador estadístico produjo {len(txs)} transacciones')

    return jsonify({'transactions': txs, 'source': 'estadistico'})


# ─── Bootstrap ───────────────────────────────────────────────────────────────

_load_models()

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5001))
    debug = os.environ.get('FLASK_ENV') == 'development'
    logger.info(f"Finora AI Service v2.0 iniciando en puerto {port} (debug={debug})")
    app.run(host='0.0.0.0', port=port, debug=debug)