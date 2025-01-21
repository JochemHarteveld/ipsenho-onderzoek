1. Clone repository

2. docker compose up

3. Verbinden met de PostgreSQL-database:

   Klik in pgAdmin op Add New Server.
   Vul de verbindingsgegevens in:
   Name: Hemiron DB (of een naam naar keuze).
   Host: postgres (de naam van de container).
   Port: 5432 (standaard PostgreSQL poort).
   Username: user (zoals gedefinieerd in je docker-compose.yml).
   Password: password (zoals gedefinieerd in je docker-compose.yml).
   Klik op Save.
