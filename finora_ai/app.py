"""
Finora AI Service — RF-14 Categorización automática con IA

Microservicio Flask que expone los modelos de IA de los notebooks de Finora:
- POST /categorize        → RF-14: Categorización automática de transacciones
- POST /savings           → RF-21/HU-08: Recomendaciones de ahorro inteligente
- POST /predict-expenses  → RF-22/HU-09: Predicción de gastos
- GET  /health            → Health check para Docker
"""

import os
import re
import string
import unicodedata
import logging
from flask import Flask, request, jsonify
from flask_cors import CORS

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

# ─── Carga del modelo y vectorizador ────────────────────────────────────────

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
    # Quitar tildes
    text = unicodedata.normalize('NFD', text)
    text = ''.join(c for c in text if unicodedata.category(c) != 'Mn')
    # Quitar dígitos, signos de puntuación y caracteres especiales
    text = re.sub(r'\d+', ' ', text)
    text = text.translate(str.maketrans('', '', string.punctuation))
    # Quitar stopwords
    tokens = [w for w in text.split() if w not in SPANISH_STOPWORDS and len(w) > 2]
    return ' '.join(tokens)


# ─── Motor de reglas (fallback sin modelo ML) ────────────────────────────────
RULES = [
    # Ingresos
    ('income', 'Salario',     ['nomina', 'salario', 'sueldo', 'payroll', 'salary'], 1.0),
    ('income', 'Freelance',   ['factura', 'honorarios', 'freelance', 'comision'],   0.9),
    # Gastos
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
    """Motor de reglas como fallback cuando no hay modelo ML."""
    best_cat = None
    best_conf = 0.0
    for rule_type, cat, keywords, weight in RULES:
        if rule_type != tx_type:
            continue
        for kw in keywords:
            if kw in desc_clean:
                conf = weight * 85
                # Keywords más largas → más específico → más confianza
                if len(kw) >= 5:
                    conf = weight * 90
                if desc_clean.startswith(kw):
                    conf = weight * 95
                if conf > best_conf:
                    best_conf = conf
                    best_cat = cat
    return best_cat, round(min(best_conf, 100))


def _ml_category(desc_clean: str, tx_type: str):
    """Usa el modelo ML si está disponible."""
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
            import numpy as np
            # Softmax sobre decision_function
            e_scores = np.exp(scores - np.max(scores))
            proba = e_scores / e_scores.sum()
            confidence = round(float(max(proba)) * 100)
        else:
            confidence = 75
        return y_pred, confidence
    except Exception as e:
        logger.warning(f"Error en ML inference: {e}")
        return None, 0


# ─── Endpoints ───────────────────────────────────────────────────────────────

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'ok',
        'service': 'finora-ai',
        'model_loaded': _model is not None,
        'vectorizer_loaded': _vectorizer is not None,
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

    # Primero intentar con ML
    category, confidence = _ml_category(desc_clean, tx_type)
    method = 'ml'

    # Si ML no está disponible o confianza baja, intentar reglas
    if category is None or confidence < CONFIDENCE_THRESHOLD:
        rule_cat, rule_conf = _rule_based_category(desc_clean, tx_type)
        if rule_cat and rule_conf >= CONFIDENCE_THRESHOLD:
            category = rule_cat
            confidence = rule_conf
            method = 'rules'

    # RF-14: Fallback a "Otros" si confianza < 50%
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
    Returns: { "recommendations": [...], "savings_potential": float, "score": int }
    """
    data = request.get_json(silent=True) or {}
    transactions = data.get('transactions', [])
    monthly_income = float(data.get('monthly_income', 0))

    if not transactions:
        return jsonify({'recommendations': [], 'savings_potential': 0, 'score': 50})

    # Agrupar gastos por categoría
    category_totals = {}
    total_expense = 0.0
    for tx in transactions:
        if tx.get('type') == 'expense':
            cat = tx.get('category', 'Otros')
            amount = float(tx.get('amount', 0))
            category_totals[cat] = category_totals.get(cat, 0) + amount
            total_expense += amount

    # Porcentajes de referencia para ahorro saludable (regla 50/30/20)
    REFERENCE_PCTS = {
        'Alimentación':  0.15,
        'Ocio':          0.10,
        'Transporte':    0.10,
        'Servicios':     0.08,
        'Ropa':          0.05,
        'Salud':         0.08,
        'Vivienda':      0.30,
        'Educación':     0.05,
    }

    recommendations = []
    savings_potential = 0.0

    if monthly_income > 0:
        for cat, total in sorted(category_totals.items(), key=lambda x: -x[1]):
            ref_pct = REFERENCE_PCTS.get(cat, 0.10)
            budget = monthly_income * ref_pct
            if total > budget * 1.2:  # 20% de margen
                excess = total - budget
                savings_potential += excess
                pct_over = round((total / budget - 1) * 100)
                recommendations.append({
                    'category': cat,
                    'current_spend': round(total, 2),
                    'suggested_budget': round(budget, 2),
                    'potential_saving': round(excess, 2),
                    'message': f'Estás gastando un {pct_over}% más de lo recomendado en {cat}. '
                               f'Podrías ahorrar hasta {excess:.2f}€ mensuales.',
                    'priority': 'high' if excess > monthly_income * 0.05 else 'medium',
                })

    # Score de salud financiera (0-100)
    if monthly_income > 0:
        savings_rate = max(0, (monthly_income - total_expense) / monthly_income)
        score = min(100, round(savings_rate * 200))  # 50% savings_rate = 100 score
    else:
        score = 50

    return jsonify({
        'recommendations': recommendations[:5],  # Top 5
        'savings_potential': round(savings_potential, 2),
        'score': score,
        'total_expense': round(total_expense, 2),
        'category_breakdown': {k: round(v, 2) for k, v in category_totals.items()},
    })


@app.route('/predict-expenses', methods=['POST'])
def predict_expenses():
    """
    RF-22 / HU-09: Predicción de gastos para el próximo mes.

    Body: {
        "transactions": [{ "amount": float, "type": str, "category": str, "date": "YYYY-MM-DD" }]
    }
    Returns: { "predictions": { "category": float }, "total_predicted": float, "trend": str }
    """
    data = request.get_json(silent=True) or {}
    transactions = data.get('transactions', [])

    if not transactions:
        return jsonify({'predictions': {}, 'total_predicted': 0, 'trend': 'stable'})

    # Organizar gastos por mes y categoría
    monthly_by_cat = {}  # {category: {YYYY-MM: total}}

    for tx in transactions:
        if tx.get('type') != 'expense':
            continue
        cat = tx.get('category', 'Otros')
        amount = float(tx.get('amount', 0))
        date_str = tx.get('date', '')

        # Extraer año-mes
        try:
            month_key = date_str[:7]  # YYYY-MM
            if not month_key or len(month_key) < 7:
                continue
        except Exception:
            continue

        if cat not in monthly_by_cat:
            monthly_by_cat[cat] = {}
        monthly_by_cat[cat][month_key] = monthly_by_cat[cat].get(month_key, 0) + amount

    predictions = {}
    for cat, monthly in monthly_by_cat.items():
        values = list(monthly.values())
        if not values:
            continue
        # Media ponderada: últimos meses tienen más peso
        if len(values) == 1:
            predictions[cat] = round(values[0], 2)
        elif len(values) == 2:
            predictions[cat] = round(values[-1] * 0.6 + values[-2] * 0.4, 2)
        else:
            # Media exponencialmente ponderada (EMA simple)
            recent = values[-3:]  # Últimos 3 meses
            weights = [0.2, 0.3, 0.5][:len(recent)]
            total_weight = sum(weights)
            ema = sum(v * w for v, w in zip(recent, weights)) / total_weight
            predictions[cat] = round(ema, 2)

    total_predicted = round(sum(predictions.values()), 2)

    # Determinar tendencia comparando con mes anterior
    last_month_total = sum(list(monthly.values())[-1] for monthly in monthly_by_cat.values() if monthly)
    if total_predicted > last_month_total * 1.05:
        trend = 'increasing'
    elif total_predicted < last_month_total * 0.95:
        trend = 'decreasing'
    else:
        trend = 'stable'

    return jsonify({
        'predictions': predictions,
        'total_predicted': total_predicted,
        'trend': trend,
        'last_month_total': round(last_month_total, 2),
    })


# ─── Bootstrap ───────────────────────────────────────────────────────────────

_load_models()

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5001))
    debug = os.environ.get('FLASK_ENV') == 'development'
    logger.info(f"Finora AI Service iniciando en puerto {port} (debug={debug})")
    app.run(host='0.0.0.0', port=port, debug=debug)