"""
Finora AI Service — RF-14, RF-21, RF-22

Microservicio Flask que expone los modelos de IA de los notebooks de Finora:
- POST /categorize              → RF-14: Categorización automática de transacciones
- POST /categorize/batch        → RF-14: Categorización en lote
- POST /savings                 → RF-21/HU-08: Recomendaciones de ahorro inteligente
- POST /predict-expenses        → RF-22/HU-09: Predicción ML de gastos (Ridge/RF/GBM)
- POST /evaluate-savings-goal   → RF-21: Evaluación de viabilidad de objetivo de ahorro
- GET  /health                  → Health check para Docker

Los algoritmos de predicción de gastos están basados en los notebooks:
  - Notebooks/rf22_prediccion_gastos_ml.ipynb (seleccionar_modelo, construir_features)
  - Notebooks/rf21_hu08_ahorro_inteligente.ipynb (evaluar_objetivo, calcular_capacidad_ahorro)
"""

import os
import re
import math
import string
import unicodedata
import logging
from collections import defaultdict
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


# ─── Bootstrap ───────────────────────────────────────────────────────────────

_load_models()

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5001))
    debug = os.environ.get('FLASK_ENV') == 'development'
    logger.info(f"Finora AI Service v2.0 iniciando en puerto {port} (debug={debug})")
    app.run(host='0.0.0.0', port=port, debug=debug)