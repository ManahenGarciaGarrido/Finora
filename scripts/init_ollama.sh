#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# RF-25: Descarga el modelo LLM de Ollama si no está ya disponible.
# Ejecutar UNA SOLA VEZ tras el primer `docker compose up`:
#
#   chmod +x scripts/init_ollama.sh
#   ./scripts/init_ollama.sh
#
# Modelos disponibles (edita OLLAMA_MODEL en docker-compose.yml):
#   llama3.2:1b  → 1.3 GB, CPU ≥4 GB RAM  (recomendado para Azure B2s)
#   llama3.2:3b  → 2.0 GB, CPU ≥8 GB RAM
#   llama3.1:8b  → 4.7 GB, GPU recomendada
# ─────────────────────────────────────────────────────────────────

MODEL=${OLLAMA_MODEL:-llama3.2:1b}

echo "==> Esperando a que Ollama esté listo..."
until curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; do
  sleep 2
done

echo "==> Ollama listo. Descargando modelo: $MODEL"
docker exec finora-ollama ollama pull "$MODEL"

echo "==> Modelo '$MODEL' listo. El asistente Finn está operativo."