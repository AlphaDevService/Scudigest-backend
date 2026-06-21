FROM python:3.11-slim

# Installa postgresql-client per pg_dump
RUN apt-get update && \
    apt-get install -y postgresql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
# Expose the port for Coolify/Docker
EXPOSE 8000

# Run without reload for production
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
