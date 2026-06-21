# Troubleshooting: "Service files is unavailable" (S3 su VPS)

Se Directus restituisce **Service Unavailable** quando carichi un file, lo storage S3 non è raggiungibile. Segui questi passaggi sulla **VPS**.

## 1. Controlla i log di Directus

Sulla VPS, dalla cartella del progetto:

```bash
docker compose logs directus --tail 100
```

Cerca messaggi tipo:
- `Access Denied` / `InvalidAccessKeyId` → credenziali AWS sbagliate
- `NoSuchBucket` → bucket inesistente o nome errato
- `NetworkingError` / `timeout` → la VPS non raggiunge S3 (rete/firewall)

## 2. Verifica che le variabili AWS arrivino al container

Sulla VPS:

```bash
docker compose exec directus env | grep -E "STORAGE_S3|AWS_"
```

Deve mostrare:
- `STORAGE_S3_DRIVER=s3`
- `STORAGE_S3_KEY=AKIA...` (non vuoto)
- `STORAGE_S3_SECRET=...` (non vuoto)
- `STORAGE_S3_BUCKET=nome-bucket`
- `STORAGE_S3_REGION=eu-west-1` (o la tua regione)
- `STORAGE_S3_ROOT=directus_files_nome-progetto`

Se qualcosa è **vuoto** o manca:
- Controlla che nella **stessa cartella** del `docker-compose.yml` ci sia il file **`.env`**
- Nel `.env` devono essere impostate (senza spazi intorno a `=`):
  ```env
  AWS_ACCESS_KEY_ID=AKIA...
  AWS_SECRET_ACCESS_KEY=...
  AWS_S3_BUCKET=nome-bucket
  AWS_S3_REGION=eu-west-1
  ```
- Dopo aver modificato il `.env`, riavvia: `docker compose down && docker compose up -d`

## 3. Verifica su AWS

- **Bucket**: esiste ed è nella stessa regione indicata in `AWS_S3_REGION`?
- **IAM**: l’utente delle chiavi ha una policy che permette almeno:
  - `s3:PutObject`
  - `s3:GetObject`
  - `s3:DeleteObject`
  - `s3:ListBucket`
  sul bucket (o su `arn:aws:s3:::NOME-BUCKET/*` e `arn:aws:s3:::NOME-BUCKET`).

## 4. Connettività dalla VPS verso S3

Sulla VPS:

```bash
curl -I https://s3.eu-west-1.amazonaws.com
```

Se non risponde o va in timeout, la VPS potrebbe non avere uscita HTTPS verso AWS (firewall o rete).

## 5. Firewall: può bloccare S3?

Sì. Se un firewall blocca l’**uscita** verso S3, Directus non riesce a caricare/scaricare file e puoi vedere **timeout** o **NetworkingError** nei log.

**Cosa deve passare:**
- **Porta 443 (HTTPS)** in uscita verso gli endpoint S3 (es. `*.s3.eu-west-1.amazonaws.com` o `s3.eu-west-1.amazonaws.com`).

**Controlli sulla VPS:**

1. **Dall’host** (sostituisci `eu-west-1` con la tua regione se diversa):
   ```bash
   curl -v --connect-timeout 5 https://s3.eu-west-1.amazonaws.com
   ```
   Se va in timeout o “Connection refused”, l’host non raggiunge S3.

2. **Dal container Directus** (stessa rete usata da Directus):
   ```bash
   docker compose exec directus sh -c "wget -q -O - --timeout=5 https://s3.eu-west-1.amazonaws.com 2>&1 || true"
   ```
   Se fallisce, il container non vede S3 (firewall o regole Docker/iptables).

3. **Porta 443 aperta in uscita:**
   ```bash
   timeout 3 bash -c 'cat < /dev/null > /dev/tcp/s3.eu-west-1.amazonaws.com/443' 2>&1
   ```
   Se vedi “Connection timed out” o “Connection refused”, la porta 443 in uscita è bloccata.

**Dove controllare il firewall:**
- **Firewall sulla VPS** (ufw, iptables, firewalld): assicurati che non blocchi l’**outbound** sulla 443 (di solito è permesso; controlla se hai regole restrittive in OUTPUT).
- **Firewall del provider** (panel della VPS / security group): che consenta traffico **in uscita** sulla porta 443 verso Internet (o verso gli IP AWS se usi whitelist).
- **Rete aziendale / VPN**: se la VPS è dietro una rete che filtra l’uscita, potrebbe essere bloccato l’accesso a `*.amazonaws.com`.

Se dopo questi test la VPS **non** raggiunge S3, il problema è di rete/firewall e va risolto lì prima di credenziali o ACL.

## 6. Errore 403 / AccessControlListNotSupported con DELETE o upload

Se i log mostrano richieste S3 (DELETE/PUT) verso `directus-bucket-nome-progetto.s3.eu-west-1.amazonaws.com` ma ricevi **403** o **AccessControlListNotSupported**:

- Il bucket probabilmente ha **Object Ownership = "Bucket owner enforced"** (ACL disabilitate, default sui nuovi bucket AWS).
- Directus non deve inviare un ACL: nel `docker-compose` **non** deve essere impostata `STORAGE_S3_ACL` (è stata rimossa per evitare questo errore).
- Se l’hai aggiunta manualmente, togli la riga `STORAGE_S3_ACL: "private"` e riavvia: `docker compose down && docker compose up -d`.

## 7. Riepilogo modifiche utili

- Nel `docker-compose` è stato aggiunto **`env_file: .env`** per il servizio Directus, così le variabili vengono lette dal file nella cartella del progetto.
- **`STORAGE_S3_ROOT: "directus_files_nome-progetto"`** è impostato: i file vanno sotto `directus_files_nome-progetto/` nel bucket.

Dopo ogni modifica al `.env` o al compose, riavvia i container:

```bash
docker compose down && docker compose up -d
```
