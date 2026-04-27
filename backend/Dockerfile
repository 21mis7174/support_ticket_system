# syntax=docker/dockerfile:1
# Backend Dockerfile - Following rules from dockerfile_best_practices.txt & performance.txt
# RULE-D002: Pin base image (python:3.11-slim, not :latest)
# RULE-D003: Use slim for reduced size
# RULE-D020: Layer ordering: dependencies → source
# RULE-D021: Copy requirements first
# RULE-P005: Clean package manager caches
# RULE-P013: Cache mounts for pip for faster rebuilds

FROM python:3.11-slim
LABEL maintainer="Support Ticket System" \
      description="FastAPI backend service"

WORKDIR /app

# Set environment
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Copy dependency manifest first (RULE-D021)
COPY requirements.txt .

# Install dependencies with cache mount (RULE-P013, BuildKit cache)
# RULE-P005: No cache directory needed
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir -r requirements.txt

# RULE-D040: Run as non-root user
RUN useradd --no-log-init --create-home --uid 1001 appuser

# Copy application source (RULE-D021: after dependencies)
COPY --chown=appuser:appuser app/ ./app/
COPY --chown=appuser:appuser run.py .

# Create necessary directories with correct permissions
RUN mkdir -p /app/logs && chown -R appuser:appuser /app

# Health check (RULE-C012)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
