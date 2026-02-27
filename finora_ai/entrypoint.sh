#!/bin/sh
# RF-14: Entrypoint del servicio de IA
# Si no existe el modelo entrenado, lo genera antes de arrancar el servidor

MODEL_PATH="/app/models/model.joblib"
VECTORIZER_PATH="/app/models/tfidf_vectorizer.joblib"

if [ ! -f "$MODEL_PATH" ]; then
    echo "[finora-ai] Modelo no encontrado. Entrenando modelo inicial..."
    python /app/train_model.py
    echo "[finora-ai] Modelo entrenado correctamente."
else
    echo "[finora-ai] Modelo encontrado. Saltando entrenamiento."
fi

# Arrancar gunicorn
exec gunicorn --bind "0.0.0.0:${PORT:-5001}" --workers 2 --timeout 60 app:app