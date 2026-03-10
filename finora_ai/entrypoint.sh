#!/bin/sh
# Finora AI Service — Entrypoint
#
# RF-14: Gestiona el vectorizador TF-IDF pre-entrenado y el modelo de categorización.
# RF-22: Valida disponibilidad de algoritmos de predicción de gastos (Ridge/RF/GBM).
#
# IMPORTANTE: El volumen Docker monta /app/models en tiempo de ejecución,
# sobreescribiendo los archivos copiados durante el build. Por eso los modelos
# default se guardan en /app/models_default/ y se copian al volumen si no existen.
#
# SEGURIDAD: El script inicia como root para corregir permisos del volumen,
# luego cede el proceso a finora-ai (UID 1001) con gosu.

MODEL_PATH="/app/models/model.joblib"
VECTORIZER_PATH="/app/models/tfidf_vectorizer.joblib"
DEFAULT_VECTORIZER="/app/models_default/tfidf_vectorizer.joblib"

# ── Paso 0: Corregir permisos del volumen (root) ──────────────────────────────
# El volumen Docker puede contener archivos con owner root de arranques previos,
# lo que impide que finora-ai escriba los modelos entrenados.
chown -R finora-ai:finora-ai /app/models 2>/dev/null || true
chmod -R 755 /app/models 2>/dev/null || true

# ── Paso 1: Restaurar vectorizador pre-entrenado si el volumen está vacío ────
# El vectorizador TF-IDF fue entrenado con el corpus del notebook RF-14.
# Si el volumen está vacío (primer arranque), copiamos el vectorizador default.
if [ ! -f "$VECTORIZER_PATH" ] && [ -f "$DEFAULT_VECTORIZER" ]; then
    echo "[finora-ai] Copiando vectorizador TF-IDF pre-entrenado al volumen..."
    cp "$DEFAULT_VECTORIZER" "$VECTORIZER_PATH"
    chown finora-ai:finora-ai "$VECTORIZER_PATH" 2>/dev/null || true
    echo "[finora-ai] Vectorizador restaurado desde imagen Docker."
fi

# ── Paso 2: Entrenar modelo de categorización si no existe ────────────────────
if [ ! -f "$MODEL_PATH" ]; then
    echo "[finora-ai] Modelo de categorización no encontrado. Entrenando..."
    gosu finora-ai python /app/train_model.py
    if [ $? -eq 0 ]; then
        echo "[finora-ai] Modelos entrenados correctamente."
    else
        echo "[finora-ai] ADVERTENCIA: Error en entrenamiento. El servicio usará motor de reglas."
    fi
else
    echo "[finora-ai] Modelos listos:"
    echo "  → RF-14 vectorizer: $VECTORIZER_PATH"
    echo "  → RF-14 model:      $MODEL_PATH"
fi

echo ""
echo "[finora-ai] Notebooks de referencia (algoritmos documentados):"
ls /app/notebooks/ 2>/dev/null | sed 's/^/  → /' || true
echo ""

# ── Paso 3: Arrancar gunicorn como finora-ai ──────────────────────────────────
exec gosu finora-ai gunicorn \
    --bind "0.0.0.0:${PORT:-5001}" \
    --workers 4 \
    --timeout 120 \
    --preload \
    --access-logfile - \
    --error-logfile - \
    app:app