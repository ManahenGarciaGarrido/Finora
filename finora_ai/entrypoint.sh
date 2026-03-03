#!/bin/sh
# Finora AI Service — Entrypoint
# RF-14: Entrena el modelo de categorización si no existe
# RF-22: Valida disponibilidad de modelos de predicción de gastos

MODEL_PATH="/app/models/model.joblib"
VECTORIZER_PATH="/app/models/tfidf_vectorizer.joblib"

if [ ! -f "$MODEL_PATH" ] || [ ! -f "$VECTORIZER_PATH" ]; then
    echo "[finora-ai] Modelos no encontrados. Ejecutando entrenamiento inicial..."
    python /app/train_model.py
    if [ $? -eq 0 ]; then
        echo "[finora-ai] Modelos entrenados correctamente."
    else
        echo "[finora-ai] ADVERTENCIA: Error en entrenamiento. El servicio usará motor de reglas."
    fi
else
    echo "[finora-ai] Modelos encontrados. Saltando entrenamiento."
    echo "  → RF-14 vectorizer: $VECTORIZER_PATH"
    echo "  → RF-14 model:      $MODEL_PATH"
fi

echo "[finora-ai] Notebooks de referencia disponibles en /app/notebooks/"
ls /app/notebooks/ 2>/dev/null | sed 's/^/  → /' || true

# Arrancar gunicorn con 2 workers
exec gunicorn \
    --bind "0.0.0.0:${PORT:-5001}" \
    --workers 2 \
    --timeout 60 \
    --access-logfile - \
    --error-logfile - \
    app:app