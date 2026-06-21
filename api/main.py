from fastapi import FastAPI, Response, HTTPException
from fastapi.responses import StreamingResponse
import os
import subprocess
from datetime import datetime
import io

app = FastAPI()

@app.get("/")
def home():
    return {"status": "FastAPI è pronto"}

@app.get("/backup/database")
async def backup_database():
    """
    Endpoint per effettuare il backup del database PostgreSQL di Directus.
    Restituisce un file .sql che può essere scaricato.
    """
    try:
        # Genera un nome file con timestamp
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_filename = f"directus_backup_{timestamp}.sql"

        # Credenziali del database (dallo stesso container Docker)
        db_host = "database"
        db_port = "5432"
        db_name = "directus"
        db_user = "directus"
        db_password = os.getenv("DATABASE_URL", "").split(":")[-2].split("@")[0]

        # Se DATABASE_URL non è configurato correttamente, usa la password dal .env
        if not db_password:
            # Fallback: leggi direttamente dall'environment
            db_password = os.getenv("DB_PASSWORD", "")

        # Comando pg_dump per creare il backup
        # Usiamo PGPASSWORD environment variable per evitare prompt interattivi
        env = os.environ.copy()
        env['PGPASSWORD'] = db_password

        command = [
            'pg_dump',
            '-h', db_host,
            '-p', db_port,
            '-U', db_user,
            '-d', db_name,
            '--no-password',
            '-F', 'p',  # Plain text format
            '--clean',  # Include DROP commands
            '--if-exists',  # Use IF EXISTS per evitare errori
            '--create'  # Include CREATE DATABASE
        ]

        # Esegui pg_dump
        result = subprocess.run(
            command,
            env=env,
            capture_output=True,
            text=True,
            check=True
        )

        # Crea uno stream per il download
        backup_content = result.stdout
        backup_bytes = io.BytesIO(backup_content.encode('utf-8'))

        # Restituisci il file come download
        return StreamingResponse(
            backup_bytes,
            media_type="application/sql",
            headers={
                "Content-Disposition": f"attachment; filename={backup_filename}"
            }
        )

    except subprocess.CalledProcessError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Errore durante il backup del database: {e.stderr}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Errore generico durante il backup: {str(e)}"
        )
