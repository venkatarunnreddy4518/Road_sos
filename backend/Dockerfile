FROM python:3.11-slim

WORKDIR /app

# Install Python dependencies. Every dependency ships a prebuilt wheel and
# psycopg uses the [binary] package (bundles its own libpq), so no compiler or
# system dev libs are needed. Dropping the apt layer removes ~96 MB of network
# downloads (the flaky step in CI dind) and shrinks the image.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source code
COPY . .

# Expose port; run migrations, seed (idempotent, best-effort), then launch uvicorn
EXPOSE 8000
CMD ["sh", "-c", "alembic upgrade head && (python -m app.seed.run || echo 'seed skipped') && uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
