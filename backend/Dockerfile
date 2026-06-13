FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source code
COPY . .

# Expose port; run migrations, seed (idempotent, best-effort), then launch uvicorn
EXPOSE 8000
CMD ["sh", "-c", "alembic upgrade head && (python -m app.seed.run || echo 'seed skipped') && uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
