# Guida Accesso FastAPI (Privato)

Questo backend è configurato per essere **inaccessibile dall'esterno** per sicurezza.
Per accedere alla documentazione o alle API dal tuo computer, devi usare un **Tunnel SSH**.

## Procedura di Accesso

1.  **Apri il Terminale**
    Apri un terminale sul tuo Mac.

2.  **Lancia il Tunnel**
    Esegui questo comando (sostituisci `IP_DEL_SERVER` con l'IP reale del server Coolify):
    ```bash
    ssh -L 8001:127.0.0.1:8001 root@IP_DEL_SERVER
    ```
    *Ti verrà chiesta la password del server. Inseriscila e premi Invio.*

3.  **Lascia il Terminale Aperto**
    Non chiudere la finestra del terminale. Finché è aperta, il collegamento è attivo.

4.  **Apri il Browser**
    Vai su: [http://localhost:8001/docs](http://localhost:8001/docs)

## Note
-   Se chiudi il terminale, il sito `localhost:8001` smetterà di funzionare.
-   Per ripristinare l'accesso, basta rilanciare il comando al punto 2.
