# Guida al Backup e Ripristino del Database Directus

> Nota: nei comandi seguenti `nome-progetto-database-1` è il nome del container del database.
> Docker lo genera come `<nome-cartella-progetto>-database-1`. Verifica il nome reale con `docker compose ps`.

## Come Creare un Backup

### 1. Tramite API FastAPI
Una volta avviata l'applicazione, puoi scaricare un backup del database chiamando:

```bash
curl -O http://localhost:8001/backup/database
```

Oppure apri semplicemente il browser e vai a:
```
http://localhost:8001/backup/database
```

Il file verrà scaricato automaticamente con un nome tipo `directus_backup_20260105_143052.sql`.

### 2. Tramite Docker (Metodo Manuale)
Puoi anche creare un backup manualmente usando Docker:

```bash
docker exec -it nome-progetto-database-1 pg_dump -U directus directus > backup.sql
```

## Come Ripristinare un Backup

### Metodo 1: Ripristino Completo (Consigliato)

Questo metodo elimina tutti i dati esistenti e ripristina completamente il database dal backup.

#### Passo 1: Ferma tutti i container
```bash
docker-compose down
```

#### Passo 2: Elimina i dati del database esistente
```bash
# ATTENZIONE: Questo elimina tutti i dati!
rm -rf ./data/database/*
```

#### Passo 3: Riavvia solo il database
```bash
docker-compose up -d database
```

#### Passo 4: Attendi che il database sia pronto e completamente avviato
```bash
# Aspetta 10-30 secondi, poi controlla che il database sia healthy
docker-compose ps

# Dovresti vedere: STATUS "Up XX seconds (healthy)"
# Se vedi "health: starting", aspetta ancora e ricontrolla
```

**IMPORTANTE**: Non procedere finché lo STATUS non mostra `(healthy)`. Il database deve essere completamente inizializzato.

#### Passo 5: Verifica che il container sia in esecuzione
```bash
# Se il container si è fermato dopo aver eliminato i dati, riavvialo
docker-compose ps

# Se vedi il database come "Exited", esegui:
docker-compose up -d database

# Aspetta che diventi healthy
```

#### Passo 6: Ripristina il backup
```bash
# Sostituisci con il percorso corretto del tuo file backup
# Il percorso è relativo alla directory corrente
docker exec -i nome-progetto-database-1 psql -U directus -d directus < backup/directus_backup_20260105_114201.sql
```

**Note**:
- Se ricevi l'errore "container is not running", torna al Passo 5
- Se ricevi "database system is starting up", aspetta ancora qualche secondo

#### Passo 7: Riavvia tutti i servizi
```bash
docker-compose up -d
```

### Metodo 2: Ripristino senza Ricreare il Database

Se vuoi ripristinare il backup senza eliminare completamente il database (più veloce ma può avere conflitti):

#### Passo 1: Copia il file backup nel container
```bash
docker cp directus_backup_20260105_143052.sql nome-progetto-database-1:/tmp/backup.sql
```

#### Passo 2: Ripristina il backup
```bash
docker exec -it nome-progetto-database-1 psql -U directus -d directus -f /tmp/backup.sql
```

#### Passo 3: Riavvia i servizi
```bash
docker-compose restart directus fastapi-app
```

### Metodo 3: Ripristino da Zero (Database Vuoto)

Se preferisci partire da zero con il backup:

#### Passo 1: Accedi al container del database
```bash
docker exec -it nome-progetto-database-1 bash
```

#### Passo 2: Elimina e ricrea il database
```bash
# Dentro al container
psql -U directus -d postgres -c "DROP DATABASE IF EXISTS directus;"
psql -U directus -d postgres -c "CREATE DATABASE directus;"
exit
```

#### Passo 3: Ripristina il backup
```bash
docker exec -i nome-progetto-database-1 psql -U directus -d directus < directus_backup_20260105_143052.sql
```

#### Passo 4: Riavvia i servizi
```bash
docker-compose restart directus fastapi-app
```

## Verifica del Ripristino

Dopo aver ripristinato il backup, verifica che tutto funzioni:

1. Accedi a Directus: http://localhost:8055
2. Login con le credenziali admin (dall'env file)
3. Controlla che i dati siano presenti

## Backup Automatici (Opzionale)

### Creare uno script di backup automatico

Crea un file `backup.sh`:

```bash
#!/bin/bash
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/directus_backup_$TIMESTAMP.sql"

# Crea la directory se non esiste
mkdir -p $BACKUP_DIR

# Crea il backup
curl -o "$BACKUP_FILE" http://localhost:8001/backup/database

# Mantieni solo gli ultimi 7 backup
ls -t $BACKUP_DIR/directus_backup_*.sql | tail -n +8 | xargs -r rm

echo "Backup creato: $BACKUP_FILE"
```

Rendi lo script eseguibile:
```bash
chmod +x backup.sh
```

### Configurare cron per backup giornalieri

Aggiungi al crontab:
```bash
crontab -e
```

Aggiungi questa riga per backup giornaliero alle 2 AM:
```
0 2 * * * cd /path/to/NOME_PROGETTO && ./backup.sh >> ./backups/backup.log 2>&1
```

## Note Importanti

1. **Compatibilità delle Versioni**: Assicurati che la versione di PostgreSQL usata per il ripristino sia compatibile con quella usata per creare il backup.

2. **Dimensione del Database**: Per database molto grandi, il ripristino può richiedere tempo. Sii paziente.

3. **Permessi**: I backup includono tutti i permessi e gli utenti. Se hai problemi di accesso dopo il ripristino, verifica le credenziali.

4. **Backup Incrementali**: I backup creati con questo metodo sono completi (full backup), non incrementali.

5. **Spazio su Disco**: Assicurati di avere abbastanza spazio per il file di backup. Un database di 1GB produrrà un file SQL di dimensioni simili (o maggiori in formato testo).

## Risoluzione Problemi

### Errore: "database is being accessed by other users"
```bash
# Disconnetti tutti gli utenti
docker exec -it nome-progetto-database-1 psql -U directus -d postgres -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'directus' AND pid <> pg_backend_pid();"
```

### Errore durante il ripristino: "already exists"
Se il backup include `--clean` e `--if-exists`, questi errori sono normali e possono essere ignorati.

### Il backup è vuoto o molto piccolo
Verifica che il database abbia dati prima del backup:
```bash
docker exec -it nome-progetto-database-1 psql -U directus -d directus -c "SELECT schemaname, tablename FROM pg_tables WHERE schemaname = 'public';"
```
