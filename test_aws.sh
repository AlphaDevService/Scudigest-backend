#!/bin/bash

# Script per testare le credenziali AWS e mostrare i bucket S3
# Usa le credenziali dal .env senza sovrascrivere la configurazione AWS CLI esistente

echo "=== Test Credenziali AWS ==="
echo ""

# Controlla se AWS CLI è installato
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI non è installato. Installa con: brew install awscli"
    exit 1
fi

# Carica le variabili d'ambiente dal file .env
if [ -f .env ]; then
    # Carica le credenziali in variabili locali (non export)
    AWS_KEY=$(grep "^AWS_ACCESS_KEY_ID=" .env | cut -d '=' -f2)
    AWS_SECRET=$(grep "^AWS_SECRET_ACCESS_KEY=" .env | cut -d '=' -f2)
    echo "✓ Credenziali caricate da .env"
else
    echo "❌ File .env non trovato"
    exit 1
fi

# Verifica che le credenziali siano state caricate
if [ -z "$AWS_KEY" ] || [ -z "$AWS_SECRET" ]; then
    echo "❌ Credenziali AWS non trovate nel file .env"
    exit 1
fi

echo "✓ Access Key ID: ${AWS_KEY:0:10}..."
echo ""

# Testa le credenziali verificando l'identità
echo "--- Verifica Identità AWS ---"
AWS_ACCESS_KEY_ID="$AWS_KEY" AWS_SECRET_ACCESS_KEY="$AWS_SECRET" aws sts get-caller-identity 2>/dev/null
if [ $? -ne 0 ]; then
    echo "❌ Credenziali non valide o errore di connessione"
    exit 1
fi
echo ""

# Nome del bucket
BUCKET_NAME="directus-bucket-nome-progetto"

echo "📦 Bucket: $BUCKET_NAME"
echo ""

# Mostra il contenuto del bucket
echo "--- Contenuto del Bucket ---"
content=$(AWS_ACCESS_KEY_ID="$AWS_KEY" AWS_SECRET_ACCESS_KEY="$AWS_SECRET" aws s3 ls "s3://$BUCKET_NAME" --recursive --human-readable 2>&1)
if [ $? -ne 0 ]; then
    echo "❌ Errore nell'accesso al bucket"
    echo "$content"
    exit 1
fi

if [ -z "$content" ]; then
    echo "Il bucket è vuoto"
else
    echo "$content"
    echo ""
    # Conta gli oggetti
    object_count=$(echo "$content" | wc -l)
    total_size=$(echo "$content" | awk '{sum+=$3} END {print sum}')
    echo "📊 Totale oggetti: $object_count"
fi

echo ""
echo "=== Test Completato ==="
