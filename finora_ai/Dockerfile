FROM python:3.11-slim

LABEL maintainer="Finora Team"
LABEL description="Finora AI Service — RF-14 Categorización, RF-21 Ahorro, RF-22 Predicciones ML"

# Seguridad: no ejecutar como root
RUN useradd -m -u 1001 finora-ai

WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Instalar dependencias Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código de la aplicación
COPY app.py .
COPY train_model.py .
COPY entrypoint.sh .

# Copiar notebooks de referencia (RF-14, RF-21, RF-22)
# Documentan los algoritmos de IA implementados en app.py
COPY notebooks/ /app/notebooks/

# Modelos pre-entrenados en ubicación inmutable dentro de la imagen.
# IMPORTANTE: /app/models es el punto de montaje del volumen Docker, por lo que
# cualquier archivo copiado allí durante el build queda OCULTO cuando el volumen
# se monta en tiempo de ejecución. Para que el vectorizador TF-IDF pre-entrenado
# esté disponible, lo copiamos a /app/models_default/ (fuera del volumen).
# El entrypoint.sh lo copia al volumen si no existe (primer arranque).
RUN mkdir -p /app/models /app/models_default
COPY models/ /app/models_default/

RUN chown -R finora-ai:finora-ai /app/models /app/models_default /app/notebooks

USER finora-ai

ENV FLASK_ENV=production
ENV PORT=5001

EXPOSE 5001

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=5 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5001/health')"

# Entrypoint:
#   1. Restaura vectorizador pre-entrenado al volumen si no existe
#   2. Entrena modelo de categorización si no existe
#   3. Arranca gunicorn
ENTRYPOINT ["/bin/sh", "/app/entrypoint.sh"]