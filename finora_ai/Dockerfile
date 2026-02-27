FROM python:3.11-slim

LABEL maintainer="Finora Team"
LABEL description="Finora AI Service - RF-14 Categorización automática, RF-21 Ahorro, RF-22 Predicciones"

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

# Directorio para modelos (se monta como volumen o se generan al inicio)
RUN mkdir -p /app/models && chown finora-ai:finora-ai /app/models

# Copiar modelo pre-entrenado si existe
COPY models/ /app/models/ 2>/dev/null || true

USER finora-ai

ENV FLASK_ENV=production
ENV PORT=5001

EXPOSE 5001

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5001/health')"

# Usar gunicorn en producción para múltiples workers
CMD ["gunicorn", "--bind", "0.0.0.0:5001", "--workers", "2", "--timeout", "60", "app:app"]