# Model Project - Template Backend

Questo è un **template riutilizzabile** per avviare velocemente un nuovo progetto backend
con lo stesso stack tecnologico usato in produzione. Copia questa cartella, sostituisci i
placeholder, compila i segreti e sei pronto a partire.

> Il template NON contiene segreti reali: il file `.env` va creato da te a partire da `.env.example`.

---

## 1. Cos'è il template (lo stack)

| Servizio       | Tecnologia                   | A cosa serve                                                        |
| -------------- | ---------------------------- | ------------------------------------------------------------------- |
| `database`     | PostgreSQL 16 + PostGIS 3.4  | Database principale (con estensioni geospaziali PostGIS)            |
| `cache`        | Redis 7                      | Cache per Directus (predisposta; di default `CACHE_ENABLED=false`) |
| `directus`     | Directus 11.14.0             | CMS headless / API dati + pannello admin (porta `8055`)            |
| `fastapi-app`  | FastAPI + Uvicorn (Python)   | API di utility, include endpoint di backup DB (porta `8001`)       |
| Storage file   | AWS S3                       | Storage dei file caricati su Directus                              |
| Orchestrazione | Docker Compose               | Avvia e collega tutti i servizi                                    |

---

## 2. Struttura dei file

```
.
├── README.md                         # Questo file
├── docker-compose.yml                # Definizione di tutti i servizi
├── .env.example                      # Modello variabili d'ambiente (da copiare in .env)
├── .gitignore                        # Esclude .env, data/, venv, backup, ecc.
├── test_aws.sh                       # Script per testare le credenziali AWS / bucket S3
├── api/                              # Servizio FastAPI
│   ├── Dockerfile                    # Immagine Python 3.11 + postgresql-client
│   ├── requirements.txt              # Dipendenze Python
│   └── main.py                       # App FastAPI + endpoint /backup/database
└── Guide utili/                      # Guide operative
    ├── SSH_ACCESS_GUIDE.md           # Accesso a FastAPI via tunnel SSH (produzione)
    ├── S3_STORAGE_TROUBLESHOOTING.md # Risoluzione problemi storage S3
    └── BACKUP_RESTORE_GUIDE.md       # Backup e ripristino del database
```

---

## 3. Setup di un nuovo progetto

### Passo 1 - Copia il template
Copia il contenuto di questa cartella `model project/` nella cartella del tuo nuovo progetto
(es. `~/developerGit/mio-nuovo-backend`).

### Passo 2 - Sostituisci i placeholder
Fai un **find-and-replace** in tutti i file:

| Placeholder      | Sostituire con                              | Esempio                      |
| ---------------- | ------------------------------------------- | ---------------------------- |
| `nome-progetto`  | nome del progetto in minuscolo con trattini | `mio-nuovo-backend`          |
| `NOME_PROGETTO`  | nome del progetto (descrizioni/percorsi)    | `Mio Nuovo Backend`          |

File che contengono i placeholder:
- `docker-compose.yml` (`STORAGE_S3_ROOT: "directus_files_nome-progetto"`)
- `.env.example` (commento sul bucket)
- `test_aws.sh` (`BUCKET_NAME`)
- `Guide utili/S3_STORAGE_TROUBLESHOOTING.md`
- `Guide utili/BACKUP_RESTORE_GUIDE.md`

> Nota: il nome dei container Docker (es. `nome-progetto-database-1`) viene generato
> automaticamente da Docker in base al nome della cartella del progetto. Verifica il nome
> reale con `docker compose ps`.

### Passo 3 - Crea il bucket S3 e l'utente IAM
1. Crea un bucket S3 (es. `directus-bucket-nome-progetto`) nella regione scelta (default `eu-west-1`).
2. Crea un utente IAM con una policy che permetta almeno, sul bucket:
   - `s3:PutObject`
   - `s3:GetObject`
   - `s3:DeleteObject`
   - `s3:ListBucket`
3. Genera Access Key ID e Secret Access Key per quell'utente.

### Passo 4 - Crea il file `.env`
Copia `.env.example` in `.env` e compila tutti i valori:

```bash
cp .env.example .env
```

| Variabile               | Descrizione                                                      |
| ----------------------- | ---------------------------------------------------------------- |
| `DB_PASSWORD`           | Password del database PostgreSQL (scegline una robusta)          |
| `DIRECTUS_SECRET`       | Stringa segreta per Directus (es. un UUID)                       |
| `ADMIN_EMAIL`           | Email dell'admin Directus iniziale                               |
| `ADMIN_PASSWORD`        | Password dell'admin Directus iniziale                            |
| `PUBLIC_URL`            | URL pubblico di Directus (in locale `http://localhost:8055`)     |
| `AWS_ACCESS_KEY_ID`     | Access Key dell'utente IAM                                       |
| `AWS_SECRET_ACCESS_KEY` | Secret Key dell'utente IAM                                       |
| `AWS_S3_BUCKET`         | Nome del bucket S3                                               |
| `AWS_S3_REGION`         | Regione del bucket (es. `eu-west-1`)                             |

> IMPORTANTE: NON committare mai il file `.env`. È già escluso dal `.gitignore`.

### Passo 5 - Avvia
Dalla cartella del progetto:

```bash
docker compose up --build
```

Servizi disponibili:
- Directus (admin + API): http://localhost:8055
- FastAPI (utility/backup): http://localhost:8001 — docs su http://localhost:8001/docs

(Opzionale) Verifica le credenziali AWS prima dell'avvio:

```bash
chmod +x test_aws.sh
./test_aws.sh
```

---

## 4. Comandi quotidiani

```bash
# Avvio dopo aver creato nuove feature/estensioni
docker compose up --build

# Avvio normale (senza ricostruire le immagini)
docker compose up

# Stop: premi Ctrl+C nel terminale, poi
docker compose down
```

Se usi un ambiente virtuale Python per sviluppare le utility FastAPI:

```bash
source api/.venv/bin/activate
```

---

## 5. Sicurezza

- Il file `.env` contiene segreti: è escluso dal versionamento tramite `.gitignore`.
- In produzione il servizio FastAPI è pensato per restare privato: vedi
  [Guide utili/SSH_ACCESS_GUIDE.md](Guide%20utili/SSH_ACCESS_GUIDE.md) per l'accesso via tunnel SSH.

---

## 6. Riferimenti / Guide

- [Accesso FastAPI via SSH](Guide%20utili/SSH_ACCESS_GUIDE.md) - come raggiungere FastAPI in produzione.
- [Troubleshooting storage S3](Guide%20utili/S3_STORAGE_TROUBLESHOOTING.md) - errori "Service Unavailable", 403, ecc.
- [Backup e ripristino DB](Guide%20utili/BACKUP_RESTORE_GUIDE.md) - come fare backup e restore del database.
